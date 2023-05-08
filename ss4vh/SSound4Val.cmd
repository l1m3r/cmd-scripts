@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "CRLFs=?"
(set CRLF_=^
%=this line is empty=%
)

::#  just title and version
set "version=0.1.2_20230508"
set "title=%~nx0 - Ver. %version%"
(title !title!)

set "ccl=!cmdcmdline!"
set "ccl=!ccl:"=!"

::# Just once set finalPause=0 to exit script without another pause,
::# if "/C" (execute and end) is not found in cmdcmdline.
if not defined finalPause if /I "!ccl!" EQU "!ccl:/C=!" (
	set "finalPause=0"		& REM no /C in ccl.
) else set "finalPause=1"	& REM /C was in ccl.

set "RunOrDebugEcho=@"
set "RemOrDebugRun=REM"
set "RemOrVerbRun=REM"
set "RunOrQuietRem=@"

set "sfkURL=http://stahlworks.com/dev/sfk/sfk.exe"
for %%I IN (%sfkURL%) do set "exeSFK=%%~nxI"

set "VH_regPath=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970"
set "VH_regVar=InstallLocation"
set "file2mod=globalgamemanagers"
set "path_sub=valheim_Data\%file2mod%"

set "string2count= hit at offset 0x"

set "chan_nmbrs=2 4 5 6 8 "
set "hex_lead=0000803F0"
set "hex_tail=0000000000000000040000"


cd /D "%~dp0"


call :log "Searching for required programs."
::# ---- Variables required for prog_find
set _requiredPrograms=findstr.exe reg.exe powershell.exe %exeSFK%

set "ERL=0"
set "prog_missing="
::# Find/check up on required Programs in %_requiredPrograms%
if defined _requiredPrograms (
	call :ProgFind "%~dp0.;%path%" prog_missing !_requiredPrograms!
	set "ERL=!ERRORLEVEL!"
)

if not defined prog_missing goto :READY
	if /I "%prog_missing%" NEQ "%exeSFK%" (
		set "errMSG=The following %ERL% required programm(s) could not be found:!CRLF_!!prog_missing!"
		goto :ERR
	)
	echo[ ################## ATTENTION #####################
	echo[ #
	echo[ #   This script will now download the 3rd party
	echo[ #   program "%exeSFK%" from
	echo[ #   %sfkURL%
	echo[ #   and use/execute(^^!) it to read/patch/modify
	echo[ #   VH's file "%file2mod%"
	echo[ #
	echo[ #            THIS MAY BE UNSAFE ^^!^^!^^!
	echo[ #   because
	echo[ #   - "%exeSFK%" will not be verified here.
	echo[ #   - it could be replaced with malware.
	echo[ #   - the DL URL is susceptible to MITM attacks.
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

call :log " -> Found all required programs."

set "inp="
set "inp=%~1"
::#  Parse argument %1
if not defined inp goto :readReg
	call :log "processing argument #1="!inp!""
	if "!inp!" NEQ "%~1" (
		set "ERL=50"
		set "errMSG=First argument "!inp!" is bonkers."
		goto :ERR
	)
	
	call :chkFiSysObj "!inp!" VH_Path nul nul inp_name inp_ext inp_size inp_attr nul
	set "ERL=%ERRORLEVEL%"
	
	if %ERL% EQU 1 if %inp_size% GTR 1 if not defined inp_ext if /I "!inp_name!" EQU "%file2mod%" if "%inp_attr:~1,1%" EQU "-" goto :readHex
	::# ELSE
	set "errMSG=Your argument "!inp!" didn't meet all conditions:!CRLF_! ? cnt: %ERL% EQU 1!CRLF_! ? size=%inp_size%!CRLF_! ? ext="%inp_ext%" EQU ""!CRLF_! ? name: "!inp_name!" EQU "%file2mod%"!CRLF_! ? read-only: %inp_attr:~1,1% EQU -"
	set "ERL=51"
goto :ERR


::#  Read VH's installation path from Windows's registry.
:readReg
	call :log "Fetching VH's installation path from Windows's registry."
	set "VH_Path="
	set "errMSG=!CRLF_! -> Try drag'n'dropping the file ".\%path_sub%"!CRLF_!    on "%~nx0" instead.!CRLF_!    (but NOT on the open cmd shell window^!^)"
	for /F "usebackq tokens=3 skip=2" %%I IN (`reg.exe query "!VH_regPath!" /v "!VH_regVar!"`) do set "VH_Path=%%~I"
	if not defined VH_Path (
		set "errMSG=Quering the registry for Steams VH path failed.!errMSG!"
		set "ERL=20"
		goto :ERR
	)
	call :log " -> Found it: %VH_Path%"
	set "VH_Path=%VH_Path%\%path_sub%"

	if not exist "!VH_Path!" (
		set "ERL=21"
		set "errMSG=VH's game folder doesn't contain the file ".\!path_sub!"!errMSG!"
		goto :ERR
	)


::# Enumerate current number of configured speakers and make sure patching is at least "kinda safe".
:readHex
	call :log "Searching for valid HEX-strings."
	set "cnt_HitsTotal="
	set "cnt_spk="
	for %%I IN (%chan_nmbrs%) do (
		set "cnt_HitsLocal=0"
		::#  search file "path_sub" for HEX-string and count hits.
		for /F "usebackq" %%J in (`%exeSFK% hexfind "!VH_Path!" -binary /%hex_lead%%%~nI%hex_tail%/ ^| findstr.exe /N /C:"%string2count%"`) do set /A "cnt_HitsLocal+=1"
		call :log " -> Found !cnt_HitsLocal! hits for %%I speakers."
		
		::#  generate and store results in vars.
		if !cnt_HitsLocal! GTR 0 (
			set "cnt_HitsTotal=!cnt_HitsTotal!+!cnt_HitsLocal!"
			REM set /A "cnt_HitsLocal*=%%~nI"
			set "cnt_spk=!cnt_spk!+%%~nI*!cnt_HitsLocal!"
		)
		REM echo[ spkL="%%~I" --- cnt_HitsLocal=!cnt_HitsLocal! --- cnt_HitsTotal=!cnt_HitsTotal! --- cnt_spk=!cnt_spk!
	)
	set "cnt_HitsLocal="

	::#  summarize the results.
	set /A cnt_HitsTotalS=!cnt_HitsTotal!
	set /A cnt_spkS=!cnt_spk!

	if !cnt_HitsTotalS! NEQ 1 (
		set ERL=22
		set "errMSG=Didn't find exactly one location to patch ^(#=!cnt_HitsTotalS! [!cnt_spk!]^)."
		goto :ERR
	)


::#  Remove the current configured # of speakers from the list of valid #s.
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
echo[ #  Will only eactly one position/byte be modified?
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




::# ------------ Subroutines not belonging to the 'real' script follow here. ------------------

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
endlocal & exit /B %ERL%



:log
setlocal
set "bla=%~1"
echo[INFO: !bla!
endlocal & exit /b




REM ---------- Begin ProgFind
REM
REM  ProgFind must be used like this:
REM    call :ProgFind 1"<path(s)>" 2rtnVar 3programs/files [4to [5look [6for ...]]]
REM  Requires:
REM     "<path(s)>" This is a ;-separated list of paths (like the %path% variable).
REM     rtnVar      The names of missing files will be stored in the variable with this name.
REM     %%3 - %%*   These are the programs/files to look for.
REM  Returns/Sets:
REM     rtnVar    unless it was set to "nul".
REM     errMSG    only if ERL NEQ 0
REM  Errorlevel:
REM      >= 1     # file(s) could not be found.
REM         0     All files were found.
REM     <= -1     An error occurred.
REM
:ProgFind
	SETLOCAL EnableDelayedExpansion EnableExtensions
	if "%~n0" EQU "ProgFind" call :varset
	for /F "usebackq delims==" %%I IN (`set mod_ 2^>nul`) do set "%%I=" REM Cleanup
	set "AllowedVarChars=a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 # _ . + -"
	set "mod_Name=:ProgFind"
	%RemOrVerbRun% echo[
	%RemOrVerbRun% echo[  ---- %mod_Name% begin
	set "mod_ERL=-1"
	REM Check %1 - paths
	set "mod_paths="
	set "mod_paths=%~1"
	if not defined mod_paths (
		set "mod_errMSG=%mod_Name% - mod_paths (%%1) is not defined."
		%RemOrVerbRun% echo[  -- Error: !mod_errMSG!
		goto :ProgFind_End
	)
	REM TBD? - Check paths for illegal Chars?
	REM Check %2 - rtnVarName
	set "mod_tmp="
	set "mod_tmp=%~2"
	if not defined mod_tmp (
		set "mod_errMSG=%mod_Name% - mod_tmp (%%2) is not defined."
		%RemOrVerbRun% echo[  -- Error: !mod_errMSG!
		goto :ProgFind_End
	)
	REM Remove every allowed char.
	for %%A IN (!AllowedVarChars!) do for /F "tokens=1" %%B IN ("%%~A") do if defined mod_tmp (
		set "mod_tmp=!mod_tmp:%%~B=!"
	)
	if defined mod_tmp (
		REM only illegal chars left
		set "mod_errMSG=%mod_Name% - mod_tmp (%%2) contains illegal chars."
		%RemOrVerbRun% echo[  -- Error: !mod_errMSG!
		goto :ProgFind_End
	)

	REM TBD? check other inputs... %*
	REM read params %3 ... programs/files [to [look [for]]]

	REM  main 'for' loop to look for files/programs
	set "mod_pMissing= "
	set mod_#Missing=0
	set lERL=0
	set mod_cnt=0
	for %%I IN (%*) do (
		set /A mod_cnt+=1
		REM skip the first two params: paths and rtnVarName.
		if !mod_cnt! GTR 2 (
			%RemOrDebugRun% echo[  -- %mod_Name% - for loop #!mod_cnt! with "%%~I"
			%RemOrVerbRun% echo[  -- looking for "%%~I"
			if "%%~xI" EQU "" (
				set /A lERL+=1
				FOR %%A IN (%PathExt%) DO FOR %%B IN ("%%~nI%%A") DO if "%%~$mod_paths:B" NEQ "" (
					%RemOrVerbRun% echo[  --  found it with "%%~A" in "%%~$mod_paths:B"
					set /A lERL-=1
				)
				REM lERL-=1 could happen >1 times (x.exe, x.com, ...).
				if !lERL! LSS 0 set /A lERL=0
			) else (
				if "%%~$mod_paths:I" EQU "" (
					set /A lERL+=1
				) else (
					echo[ blargh >NUL
					%RemOrVerbRun% echo[  --  found it in "%%~$mod_paths:I"
				)
			)
			if !lERL! NEQ 0 (
				%RemOrVerbRun% echo[  --  couldn't find "%%~I"
				set /A "mod_#Missing+=1"
				set "mod_pMissing=!mod_pMissing:~0,-1!%%I  "
				set mod_errMSG=Required programm "%%~I" could not be found ^(!mod_#Missing!^).
				set lERL=0
			)
		)
	)
	set /A mod_cnt-=2
	REM Remove trailing "  "
	set "mod_pMissing=!mod_pMissing:~0,-2!"
	REM Check if the 'for' loop did sth. - post check of %3....
	set /A mod_ERL-=1
	if %mod_cnt% LSS 1 (
		set "mod_errMSG=%mod_Name% - program(s)/file(s) to look for not or improperly defined (%%3..)."
		%RemOrVerbRun% echo[  -- Error: !mod_errMSG!
		goto :ProgFind_End
	)
	set "mod_ERL=%mod_#Missing%"
:ProgFind_End
	if "!RemOrDebugRun!" NEQ "!RemOrDebugRun:@=!" (
		echo[
		echo[  %mod_Name% - "SET mod_" returns:
		set "mod_"
		echo[
	) 1>&2
	if "!RemOrVerbRun!" NEQ "!RemOrVerbRun:@=!" (
		echo[
		echo[  -- searched for %mod_cnt% programs/files. %mod_#Missing% are missing.
		echo[  ---- %mod_Name% end.
	)
REM Clear all local vars ...
endlocal &(
	REM ... except the required ones.
	if %mod_ERL% GTR 0 (
		if /I "%~2" NEQ "NUL" set "%~2=%mod_pMissing%"
	) else if %mod_ERL% LSS 0 set "errMSG=%mod_errMSG%"
	exit /B %mod_ERL%
)
REM ---------- End ProgFind




REM ---------- Begin Check-File-System-Object
REM Usage:
REM call :chkFiSysObj <obj>, 1full, 2drive, 3path, 4name, 5ext, 6size, 7attr, 8time
REM Unused variables between used ones must/can be set to "nul"
REM return-value = ERL = isFile
REM   >1	(cnt-1) Object(s) found with placeholders in %~1.
REM    1	Obj is a file.
REM    0	Obj is a directory.
REM   -1	Obj does not exist.
REM   -2	placeholders in %~1 and no fitting files(!) found. no vars defined.
REM   -3	forbidden chars in %~1.
REM if not defined (6, 7 or 8) -> object does not exist.

:chkFiSysObj
SETLOCAL EnableDelayedExpansion EnableExtensions
	if "%~n0" EQU "chkFiSysObj" call :varset
	for /F "usebackq delims==" %%I IN (`set mod_ 2^>nul`) do set "%%I=" REM Cleanup
	set "mod_Name=:chkFiSysObj"
	set "mod_params#=8"
	set "errMSG="
	set "AllowedVarChars=a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 # _ . + -"

	%RemOrVerbRun% echo[
	%RemOrVerbRun% echo[ ---- %mod_Name% begin - %*

	REM Check %1 - Obj
	set "mod_Obj="
	set "mod_Obj=%~1"
	if not defined mod_Obj (
		set "errMSG=%mod_Name% - mod_Obj (%%1) is not defined."
		%RemOrVerbRun% echo[ errMSG !errMSG!
		set mod_ERL=-3
		goto :chkFiSysObj_End
	)

	REM Cleanup input Obj
	set "mod_Obj=!mod_Obj:&=!"
	set "mod_Obj=!mod_Obj:|=!"
	set "mod_Obj=!mod_Obj:>=!"
	set "mod_Obj=!mod_Obj:<=!"
	set "mod_Obj=!mod_Obj:"=!"
	if "!mod_Obj!" NEQ "%~1" (
		set "errMSG=%mod_Name% - input (%%1) contains forbidden chars.."
		%RemOrVerbRun% echo[ errMSG !errMSG!
		set "mod_ERL=-4"
		goto :chkFiSysObj_End
	)

	REM read params 1-8, ignore empty ones and those that are NUL
	set "mod_String= "
	set mod_tmp=1
	:loop
		shift /1
		if /I "%~1" EQU "" goto :loop_end
		if !mod_tmp! GTR !mod_params#! goto :loop_end
		
		%RemOrVerbRun% echo[ --- reading param #!mod_tmp!: "%~1"
		if /I "%~1" NEQ "NUL" (
			set "mod_n!mod_tmp!=%~1"
			set "mod_String=!mod_String:~0,-1!%~1 "
		) 
		set /A mod_tmp+=1
		goto :loop
	:loop_end

	REM Remove last whitespace
	set "mod_String=!mod_String:~0,-1!"
	REM Remove every allowed char.
	if defined mod_string for %%A IN (!AllowedVarChars!) do if defined mod_string set "mod_String=!mod_String:%%~A=!"
	if defined mod_String (
		REM only illegal chars left
		set "errMSG=%mod_Name% - at least one VarName (1-8) contains illegal chars."
		%RemOrVerbRun% echo[ errMSG !errMSG!
		set "mod_ERL=-5"
		goto :chkFiSysObj_End
	)

	REM the actual chkfisysobj operation.
	set "mod_ERL=0"
	for %%I IN ("!mod_Obj!") do (
		set /A mod_ERL+=1
		set "mod_r1_Full=%%~fI"
		set "mod_r2_Drive=%%~dI"
		set "mod_r3_Path=%%~pI"
		set "mod_r4_Name=%%~nI"
		set "mod_r5_Ext=%%~xI"
		set "mod_r6_Size=%%~zI"
		set "mod_r7_Atr=%%~aI"
		set "mod_r8_DTS=%%~tI"
	) 2>nul
	REM set mod_ERL= return-value / isFile
	if %mod_ERL% EQU 0 (
		REM no files found.
		%RemOrVerbRun% echo[ ---- %~0 - no file^(s^) found, no vars defined.
		set "mod_ERL=-2"
		goto :chkFiSysObj_End
	)
	echo["%mod_Obj%" | findstr.exe "* ?" 2>&1 >nul
	if !ERRORLEVEL! EQU 0 (
		REM input contains placeholders -> ERL++
		%RemOrVerbRun% echo[ ---- %~0 - %mod_ERL% object^(s^) found ^(with placeholder^(s^)^).
		set /A "mod_ERL+=1"
	) else if %mod_ERL% EQU 1 if not defined mod_r7_Atr (
		REM obj is nonexistent.
		%RemOrVerbRun% echo[ ---- %~0 - obj is nonexistent, some vars defined.
		set "mod_ERL=-1"
	) else if /I "D" EQU "%mod_r7_Atr:~0,1%" (
		REM obj is a directory.
		%RemOrVerbRun% echo[ ---- %~0 - obj is a directory, vars defined.
		set "mod_ERL=0"
	)
:chkFiSysObj_End
if "!RemOrDebugRun!" NEQ "!RemOrDebugRun:@=!" (
	echo[
	echo[ %mod_Name% - "SET mod_" returns:
	set "mod_"
	echo[
) 1>&2

%RemOrVerbRun% echo[ ---- %mod_Name% end.

REM Clear all local vars ...
endlocal &(
	REM ... except the required ones.
	if %mod_ERL% GEQ -2 (
		set "%mod_n1%=%mod_r1_Full%"
		set "%mod_n2%=%mod_r2_Drive%"
		set "%mod_n3%=%mod_r3_Path%"
		set "%mod_n4%=%mod_r4_Name%"
		set "%mod_n5%=%mod_r5_Ext%"
		set "%mod_n6%=%mod_r6_Size%"
		set "%mod_n7%=%mod_r7_Atr%"
		set "%mod_n8%=%mod_r8_DTS%"
	) 2>nul else set "errMSG=%errMSG%"
	exit /B %mod_ERL%
)
REM ---------- End Check-File-System-Object
