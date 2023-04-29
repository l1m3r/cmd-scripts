@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "version=0.1.0_20230429"
set "title=%~nx0 - Ver. %version%"
(title !title!)

set "ccl=!cmdcmdline!"
set "ccl=!ccl:"=!"

::# Just once set finalPause=0 to exit script without another pause,
::# if "/C" (execute and end) is not found in cmdcmdline.
if not defined finalPause if /I "!ccl!" EQU "!ccl:/C=!" (
	set "finalPause=0"		& REM no /C in ccl.
) else set "finalPause=1"	& REM /C was in ccl.


set "sfkURL=http://stahlworks.com/dev/sfk/sfk.exe"
for %%I IN (%sfkURL%) do set "exeSFK=%%~nxI"

set "SS4VH_regPath=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970"
set "SS4VH_regVar=InstallLocation"
set "SS4VH_appM=appmanifest_892970.acf"
set "path_sub=valheim_Data\globalgamemanagers"

set "s2f= hit at offset 0x"

set "chan_nmbrs=2 4 5 6 8 "
set "hex_lead=0000803F0"
set "hex_tail=0000000000000000040000"


cd /D "%~dp0"

::# ---- Variables required for prog_find
set "progPath=%~dp0"
set "pf_tmpath=!progPath!"
set requiredPrograms=findstr.exe reg.exe powershell.exe %exeSFK%

set "ERL=0"
::# Find/check up on required Programs in %requiredPrograms%
if not defined requiredPrograms goto :prog_find_ret
	set "prog_find_ret=prog_find_ret"
	goto :prog_find
:prog_find_ret

if not defined prog_missing goto :READY
	if /I "%prog_missing%" NEQ "%exeSFK%" goto :ERR
	echo[ ################## ATTENTION #####################
	echo[ #
	echo[ #   This script will now download "%exeSFK%" from
	echo[ #   %sfkURL%
	echo[ #   and use/execute(^^!) it to read/patch/modify
	echo[ #   VH's ".\%path_sub%"
	echo[ #
	echo[ #            THIS MAY BE UNSAFE ^^!^^!^^!
	echo[ #   because
	echo[ #   - the file will not be verified here.
	echo[ #   - it could be replaced with malware.
	echo[ #   - the URL is susceptible to MITM attacks.
	echo[ #
	echo[ #   If you're not comfortable with this
	echo[ #   press CTRL+C now, download it manually into
	echo[ #   "%~dp0"
	echo[ #   and maybe check it on http://virustotal.com
	echo[ #
	echo[ ##################################################
	pause
	
	::#  exeSFK is missing -> downloading it to the current directory
	set "exePS+A=powershell.exe -nologo -noprofile -command"
	set "exePS_PPSC=$ProgressPreference = 'SilentlyContinue'"
	%exePS+A% "%exePS_PPSC%; Invoke-WebRequest '%sfkURL%' -OutFile '%exeSFK%'"
	set "ERL=%ERRORLEVEL%"
	
	if %ERL% NEQ 0 (
		set "ERL=4%ERL%"
		set "errMSG=Required application "%exeSFK%" is missing and downloading it failed."
		goto :ERR
	)
:READY


::#  Read VH's installation path from Windows's registry.
set "VH_Path="
for /F "usebackq tokens=3 skip=1" %%I IN (`reg.exe query "!SS4VH_regPath!" /v "!SS4VH_regVar!" 2^>NUL `) do set "VH_Path=%%~I"
if not defined VH_Path (
	set "ERL=20"
	set "errMSG=Quering the registry for Steams VH path failed."
	goto :ERR
)
set "VH_Path=%VH_Path%\%path_sub%"

if not exist "!VH_Path!" (
	set "ERL=21"
	set "errMSG=VH's game folder doesn't contain the file ".\!path_sub!""
	goto :ERR
)

::# Enumerate current number of configured speakers and make sure patching is at least "kinda safe".
set "cnt_tHits="
set "cnt_spk="
for %%I IN (%chan_nmbrs%) do (
	set "cnt_lHits=0"
	::#  search file "path_sub" for HEX-string and count hits.
	for /F "usebackq" %%J in (`%exeSFK% hexfind "!VH_Path!" -binary /%hex_lead%%%~nI%hex_tail%/ ^| findstr.exe /N /C:"%s2f%"`) do set /A "cnt_lHits+=1
	
	::#  generate and store results in vars.
	if !cnt_lHits! GTR 0 (
		set "cnt_tHits=!cnt_tHits!+!cnt_lHits!"
		REM set /A "cnt_lHits*=%%~nI"
		set "cnt_spk=!cnt_spk!+%%~nI*!cnt_lHits!"
	)
	REM echo[ spkL="%%~I" --- cnt_lHits=!cnt_lHits! --- cnt_tHits=!cnt_tHits! --- cnt_spk=!cnt_spk!
)
set "cnt_lHits="

::#  summarize the results.
set /A cnt_tHitsS=!cnt_tHits!
set /A cnt_spkS=!cnt_spk!

if !cnt_tHitsS! NEQ 1 (
	set ERL=22
	set "errMSG=Didn't find exactly one location to patch ^(#=!cnt_tHitsS! [!cnt_spk!]^)."
	goto :ERR
)

::#  Remove the current configured # of speakers for the list of valid #s.
set "chan_nmbrs=!chan_nmbrs:%cnt_spkS% =!"

set "cnt_spkN="
echo[
echo[ ##################################################
echo[ #
echo[ #   VH is currently configured to use %cnt_spkS% speakers.
echo[ #   Enter one of the valid alternative values
echo[ #   (%chan_nmbrs:~0,-1%) to modify or nothing to quit.
echo[ #
set /P cnt_spkN= #   New # of speakers:
echo[ #
echo[ ##################################################
echo[

if not defined cnt_spkN goto :EOFi

set /A "cnt_spk=cnt_spkN"

if "%cnt_spk%" NEQ "!cnt_spkN!" (
	set "ERL=23"
	set "errMSG=You entered something unsupported ("%cnt_spkN%" vs. "%cnt_spk%")."
	goto :ERR
)

if "%chan_nmbrs%" EQU "!chan_nmbrs:%cnt_spkN% =!" (
	set "ERL=24"
	set "errMSG=You entered an invalid value ("%cnt_spkN%")."
	goto :ERR
)

echo[
echo[
set "sfk_cmd=%exeSFK% replace "!VH_Path!" -binary /%hex_lead%%cnt_spkS%%hex_tail%/%hex_lead%%cnt_spkN%%hex_tail%/"
!sfk_cmd!

echo[
echo[ ##################################################
echo[ #
echo[ #  Does everything look alright up there ^^^^ ?
echo[ #  If not press CTRL+C now.
echo[ #
echo[ ##################################################
echo[
pause
echo[

!sfk_cmd! -yes
set "ERL=%ERRORLEVEL%"

if %ERL% NEQ 1 (
	set "ERL=3%ERL%"
	set "errMSG=Error patching ".\%path_sub%" (see above for details)."
	goto :ERR
)

set "ERL=0"
goto :EOFi




REM ------------ Subroutines not belonging to the 'real' script follow here. ------------------

:ERR
echo[
(title !title! - ERROR: %ERL%)
echo[
echo[  --- ERROR (%ERL%):
echo[%WSC3%!errMSG!
echo[
REM set /A ERL+=1
:EOFi
if "%finalPause%"=="0" goto :finQuit
	::# (If finalPause==1) OR (if not defined finalPause) -> pause
	if %ERL% EQU 0 (title !title! - fin.)
	echo[
	pause
:finQuit
endlocal
exit /B %ERL%





:prog_find
REM  Check if all required programms are available.
set "errMSG=The return goto marker of "prog_find" is missing."
if not defined prog_find_ret goto :ERR
set "prog_missing="
if defined pf_tmpath set pf_tmpath=.;%pf_tmpath%;%path%
if not defined pf_tmpath set pf_tmpath=.;%path%
set lERL=0
for %%I IN (%requiredPrograms%) do (
	if "%%~xI" EQU "" (
		set /A lERL+=1
		FOR %%B IN (%PathExt%) DO FOR %%A IN ("%%~nI%%B") DO if "%%~$pf_tmpath:A" NEQ "" set /A lERL-=1
		REM lERL-=1 could happen >1 times (x.exe, x.com, ...).
		if !lERL! LSS 0 set /A lERL=0
	) else (
		if "%%~$pf_tmpath:I" EQU "" set /A lERL+=1
	)
	if !lERL! NEQ 0 (
		set /A ERL+=1
		set prog_missing=%%~I
		set "errMSG=Required programm "%%~I" could not be found."
		set lERL=0
	)
)
set "pf_tmpath="
goto :%prog_find_ret%
