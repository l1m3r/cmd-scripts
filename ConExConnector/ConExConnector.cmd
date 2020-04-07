@echo off
REM  ---------- Just some preliminary stuff ------------
set "WSC3=   "
goto :os_chk
REM OS check
REM defines arch= -> 1=x86 2=x64 3=W6432  0=err
REM defines OSVER=x.y (using the command 'ver')
REM Win2000	= 5.0
REM WinXP	= 5.1 5.2
REM Vista	= 6.0
REM Win7	= 6.1
REM Win8	= 6.2
:os_chk_ret
set "ERRORLEVEL="

REM  just title and version please
set "version=1.0_20200407"
set "title=%~nx0 - Ver. %version%"
(title !title!)

set "ccl=!cmdcmdline!"
set "ccl=!ccl:"=!"

REM Just once set finalPause=0 to exit script without another pause,
REM if "/C" (execute and end) is not found in cmdcmdline.
if not defined finalPause if /I "!ccl!" EQU "!ccl:/C=!" (
	set "finalPause=0"		& REM no /C in ccl.
) else set "finalPause=1"	& REM /C was in ccl.

REM Make sure unicode in/output is used.
if "!ccl!" EQU "!ccl:/U=!" if 1 EQU SkipThisUntilItsNeeded (
	cmd.exe /U /E:ON /F:ON /V:ON /S /C "%~0 %*"
	set "ERL=!ERRORLEVEL!"
	exit /B !ERL!
)


REM ---- Variables required for prog_find
set "progPath=%~dp0"
set "pf_tmpath=!progPath!"
set requiredPrograms=findstr.exe nslookup.exe powershell.exe reg.exe tasklist.exe
REM fc.exe comp.exe sfk.exe

REM Find/check up on required Programs in %requiredPrograms%
if not defined requiredPrograms goto :prog_find_ret
	set "prog_find_ret=prog_find_ret"
	goto :prog_find
:prog_find_ret
if defined prog_missing goto :ERR



set "RunOrDebugEcho=@"
set "RemOrDebugRun=REM"
set "RemOrVerbRun=REM"
set "RunOrQuietRem=@"



REM ----------------------- MAIN PROGRAMM ---------------------------

REM  ---- MISSING/TODO:
REM   1. make sure OS is >= Win7
REM   2. enable drag'n'drop on the running script if no input file given as argument.
REM   3. add argument parsing for ALL config options to enable usage without a config file.
REM   
REM   N. several checks here and there (IPv6?, isConanFolderCorrect, ...).
REM   N+1. IPv6 ?


cd /D "%~dp0"
REM   ----------- Some basic vars ----------
set "allUsrVars=cfg_ThisFQDN cfg_ThisIP cfg_ThisPort cfg_ThisPwd cfg_useBE cfg_ThisPrio cfg_PathConExSB cfg_KeepIntroClips cfg_ThisModlist"
set "cfg_AutoRestart=true"
set "cfg_WaitDelay=4"
set "cec_cfgFiExt=CECcfg"
set "cec_cfgSetStr=cfg_"
set "cec_nsluAdrStr=address" & REM This may be language dependent (so far tested with English and German versions of Windows).
set "cec_nsluTimeout=10"
set "cec_regPath=HKCU\Software\Valve\Steam"
set "cec_regVar=SteamPath"
set "cec_appM=appmanifest_440900.acf"
set "cec_priorities=LOW BELOWNORMAL NORMAL ABOVENORMAL HIGH REALTIME"
set "cec_GameExe=ConansandBox.exe"
(set CRLF=^
%=this line is empty=%
)



REM   ----------- Check for other running instances of this scrip and/or ConEx ----------

set /A "ERL=80"
set "errMSG=Found at least one running instance Conan Exiles."
tasklist.exe /FO csv /NH /FI "ImageName EQ !cec_GameExe!" | findstr.exe /I "!cec_GameExe!" >NUL && goto :ERR


set /A "cnt=-1"
for /F "usebackq tokens=1 delims=[]" %%I IN (`tasklist.exe /V /FO csv /NH /FI "ImageName EQ cmd.exe" ^| find.exe /N /I "!title!"`) do set /A "cnt+=1"
set /A "ERL+=1+!cnt!"
set "errMSG=Found !cnt! other running instance^(s^) of this script."
if !cnt! NEQ 0 goto :ERR




REM   ----------- Process the config file Argument ----------
REM Read/parse passed config file.
setlocal DISABLEDELAYEDEXPANSION
set "cec_inparg=%~1" & setlocal ENABLEDELAYEDEXPANSION

set "ERL=20"
set "errMSG=No config/input file defined. Usage: "%~nx0 ^<(Full)PathToFile^>""
set "errMSG=!errMSG!!CRLF!!CRLF!!WSC3!Tip: Create a link to "%~nx0" for every CECcfg-file you use"
set "errMSG=!errMSG!!CRLF!!WSC3!     and edit each by attaching the full path to one of those CECcfg-files"
set "errMSG=!errMSG!!CRLF!!WSC3!     like in the usage example above."
set "errMSG=!errMSG!!CRLF!!WSC3!     Or just drag'n'drop the config on the script-file."
if not defined cec_inparg goto :ERR
REM COULD USE call :chkFiSysObj HERE
set "errMSG=Couldn't find config/input file '!cec_inparg!'."
if not exist "!cec_inparg!" goto :ERR

REM Check whats what with "cec_inparg"
set "cnt=0"
for %%I IN ("!cec_inparg!") do (
	set /A cnt+=1
	setlocal DISABLEDELAYEDEXPANSION
	set "cec_inparg_f=%%~fI"
	REM set "cec_inparg_dp=%%~dpI"
	set "cec_inparg_n=%%~nI"
	set "cec_inparg_x=%%~xI"
	set "cec_inparg_a=%%~aI"
	set "cec_inparg_nx=%%~nxI"
)
setlocal ENABLEDELAYEDEXPANSION
set "errMSG="!cec_inparg_nx!" is not a .!cec_cfgFiExt!-File."
if /I "!cec_inparg_x!" NEQ ".!cec_cfgFiExt!" goto :ERR
set "errMSG="!cec_inparg!" defines a dir - not a file (!cec_inparg_a!)."
if /I "!cec_inparg_a:~0,1!" NEQ "-" goto :ERR
REM if /I "!cec_inparg_a:~0,1!" EQU "D" goto :ERR
set "errMSG="!cec_inparg!" defines not a single File (!cnt!)."
if !cnt! NEQ 1 goto :ERR

REM Clear all user variables.
for %%I IN (!allUsrVars!) do set "%%I="

REM Parse the !cec_cfgFiExt!-File and import the defined variables.
set "ERL=21"
for /F usebackq^ tokens^=2^ delims^=^" %%I IN (`findstr.exe /B /I /R /C:"set \"%cec_cfgSetStr%..*^=.*\"" "!cec_inparg_f!"`) do set "ERL=0" & set "%%~I"
set "errMSG="!cec_inparg!" doesn't contain any 'set "!cec_cfgSetStr!^<^>=^<^>"' defintions."
if !ERL! NEQ 0 goto :ERR



REM   ----------- Find the path to Steam & Conan Exiles. ----------
set "ERL=22"
if defined cfg_PathConExSB goto :gotPath
	set "errMSG=!CRLF!!CRLF!!WSC3!You may want to set the correct path manually in '!cec_inparg_nx!'.!CRLF!!WSC3!Look for "cfg_PathConExSB" in there."
	for /F "usebackq tokens=3 skip=1" %%I IN (`reg.exe query "!cec_regPath!" /v "!cec_regVar!" 2^>NUL `) do set "cfg_PathConExSB=%%~I"
	if not defined cfg_PathConExSB (
		set "errMSG=Quering the registry for Steams path failed.!errMSG!"
		goto :ERR
	)
	set "ERL=23"
	set "cfg_PathConExSB=!cfg_PathConExSB:/=\!\SteamApps"
	if not exist "!cfg_PathConExSB!\!cec_appM!" (
		set "errMSG=Couldn't find "!cec_appM!" in "!cfg_PathConExSB!".!CRLF!!WSC3!^(for now^) This script only works with Conan Exile in Steams default library folder.!errMSG!"
		goto :ERR
	)
	set "ERL=24"
	for /F "usebackq tokens=1,*" %%I IN (`findstr.exe /R /I /C:"^		*\"installdir\"		*\"..*\"" "!cfg_PathConExSB!\!cec_appM!" 2^>NUL`) do set "ERL=0" & set "cfg_PathConExSB=!cfg_PathConExSB!\common\%%~J\ConanSandbox"
	if !ERL! NEQ 0 (
		set "errMSG=Couldn't find Conans path in "!cec_appM!".!CRLF!!WSC3!Have you actually installed the game ^(through Steam^)?!errMSG!."
		goto :ERR
	)
	set "ERL=25"
	set "errMSG=The "ConanSandbox" path doesn't seem to exist.!CRLF!!WSC3!"!cfg_PathConExSB!"!errMSG!"
	if not exist "!cfg_PathConExSB!\." goto :ERR
:gotPath



REM   ----------- Check and/or modify vars set by the config file. ----------
set "cec_InGameDefCfg=!cfg_PathConExSB!\Config\DefaultGame.ini"
set "cec_InGameModList=!cfg_PathConExSB!\servermodlist.txt"
set "cec_exe=!cfg_PathConExSB!\Binaries\Win64\!cec_GameExe!"
if defined cfg_useBE set "cec_exe=!cec_exe:~0,-4!_BE!cec_exe:~-4!" & REM Change normal exe to the one with BattleEye
set "ERL=26"
set "errMSG=Conans main executeable doesn't exist where it's supposed to be.!CRLF!!WSC3!"!cec_exe!""
if not exist "!cec_exe!" goto :ERR

REM Check/set the process priority.
set "ERL=27"
if not defined cfg_ThisPrio (
	set "cfg_ThisPrio=ABOVENORMAL"
	goto :gotPrio
) & REM else ...
	for %%I IN (!cec_priorities!) do if /I "%%~I" EQU "!cfg_ThisPrio!" set "ERL=0"
	set "errMSG=The valu '!cfg_ThisPrio!' set as priority in '!cec_inparg_nx!' is not allowed."
	if !ERL! NEQ 0 goto :ERR
:gotPrio

set "ERL=27"
set "errMSG="!cfg_WaitDelay!" is not an (allowed) number for 'cfg_WaitDelay'."
if defined cfg_WaitDelay (
	set /A "cfg_WaitDelay=!cfg_WaitDelay!"
	if "!cfg_WaitDelay!" NEQ "%cfg_WaitDelay%" goto :ERR & REM only works in bracketed block.
	if !cfg_WaitDelay! LSS 0 goto :ERR
) else set "cfg_WaitDelay=0"

if defined cfg_AutoRestart (
	set "cfg_AutoRestart=-autorestart"
) else set "cfg_AutoRestart= "

REM Create auto generated cfg_ThisModlist path+name.
if not defined cfg_ThisModlist set "cfg_ThisModlist=%~dp0.\cecModList - !cec_inparg_n!.txt"



REM   ----------- Lookup the servers IP address from its FQDN ----------
if defined cfg_ThisIP goto :gotIP
	set "ERL=28"
	set "errMSG=Neither cfg_ThisIP nor cfg_ThisFQDN were defined in '!cec_inparg_nx!'."
	if not defined cfg_ThisFQDN goto :ERR

	echo[
	echo[  --- Looking up the IP of "!cfg_ThisFQDN!" (this may take a bit).
	set "ERL=29"
	REM -type^=AAAA+A
	for /F "skip=2 tokens=1,2 delims=: " %%I IN ('nslookup.exe -timeout^=!cec_nsluTimeout! -type^=A "!cfg_ThisFQDN!" 2^>NUL') do if /I "%%~I" EQU "!cec_nsluAdrStr!" set "cfg_ThisIP=%%~J"
	set "errMSG=Couldn't find the IP address of '!cfg_ThisFQDN!' (cfg_ThisFQDN)."
	if not defined cfg_ThisIP goto :ERR
:gotIP



REM   ----------- Check IP Address ----------
REM Maybe rewrite with [0-9], [1-9][0-9], 1[0-9][0-9], 2[0-4][0-9], 25[0-5]
REM FINDSTR /r "^[1-9][0-9]*$ ^0$"
set "IPpVars=ipp1 ipp2 ipp3 ipp4"
for %%I IN (!IPpVars!) do set "%%~I=" & REM Clear vars.
for /F "tokens=1,2,3,4 delims=." %%I IN ("!cfg_ThisIP!") do (
	set /A "ipp1=%%~I"
	set /A "ipp2=%%~J"
	set /A "ipp3=%%~K"
	set /A "ipp4=%%~L"
) >NUL 2>&1
set "ERL=30"
set "errMSG="
for %%I IN (!IPpVars!) do if not defined %%~I (
	set /A "ERL+=1"
	set "errMSG=!errMSG!%%~I,"
)
set "errMSG='!cfg_ThisIP!' is not a legitimate IPv4 address. ^(!errMSG!^)"
if !ERL! NEQ 30 goto :ERR

set "blargh=!ipp1!.!ipp2!.!ipp3!.!ipp4!"
set "errMSG='!cfg_ThisIP!' is not a legitimate IPv4 address. ^(NEQ !blargh!^)"
if "!blargh!" NEQ "!cfg_ThisIP!" goto :ERR

set "ERL=35"
set "cnt=4"
for %%I IN (!IPpVars!) do if !%%~I! GEQ 0 if !%%~I! LEQ 255 set /A "cnt-=1"
set /A "ERL+=!cnt!"
set "errMSG='!cfg_ThisIP!' is not a legitimate IP. !cnt! blocks are wrong."
if !cnt! NEQ 0 goto :ERR



REM ----------- Check network port ---------------------
if not defined cfg_ThisPort goto :gotPort
	set "cnt="
	set /A "cnt=!cfg_ThisPort!" >NUL 2>&1
	set "cfg_ThisIP=!cfg_ThisIP!:!cfg_ThisPort!"
	if "!cnt!" EQU "!cfg_ThisPort!" if !cnt! LEQ 65535 if !cnt! GTR 0 goto :gotPort
	
	set "ERL=10!cnt!"
	set "errMSG=Someting is wrong with the port defined in '!cfg_ThisPort!' (too small/big or NEQ !cnt!).
	goto :ERR
:gotPort



REM   ----------- Disable the intro-movies of ConEx ----------
if defined cfg_KeepIntroClips (
	echo[  -- Keeping the intro clips/videos.
	goto :KeepIntroMovs
) & REM ELSE the stuff below...
	if not exist "!cec_InGameDefCfg!" goto :KeepIntroMovs
	REM  Search for replaceable strings in DefGameCfg.
	findstr.exe /B /R /I "^\+StartupMovies\= ^bWaitForMoviesToComplete\=True" "!cec_InGameDefCfg!" 
	set /A "ERL=41-1+!ERRORLEVEL!" & REM should be =1 if none were and =0 if at least one was found.
	set "errMSG=Used findstr with wrong syntax."
	if !ERL! GTR 41 goto :ERR

	REM Replace the strings in DefGameCfg.
	if !ERL! EQU 41 (
		REM No need to modify so reset ERL to 0.
		set "ERL=0"
		goto :KeepIntroMovs
	)
	powershell.exe -Command "(Get-Content -Path '!cec_InGameDefCfg!') -ireplace '^\+StartupMovies\=', '-StartupMovies='  -ireplace '^bWaitForMoviesToComplete\=.*$', 'bWaitForMoviesToComplete=False' | Out-File -encoding ASCII '!cec_InGameDefCfg!'"
	set /A "ERL=50+!ERRORLEVEL!"
	set "errMSG=Failed to modify 'DefaultGame.ini'.
	if !ERL! NEQ 50 goto :ERR
:KeepIntroMovs



REM   ----------- Done with almost everything -> proceeding to start ConEx ----------
echo[
echo[  --- Showing connection data for !cfg_WaitDelay!s (press ctrl+c to cancel).
echo[!WSC3!ServerIP= "!cfg_ThisIP!"
echo[!WSC3!Password= "!cfg_ThisPwd!"
set /A "cfg_WaitDelay+=1"
ping -n !cfg_WaitDelay! 127.0.0.1 > NUL
REM  Removing the internal/"ingame" servermodlist is necessary to ensure the checks for changes below work under all conditions.
set "errMSG=Couldn't remove internal ModList:!CRLF!!WSC3!"!cec_InGameModList!""
del /F "!cec_InGameModList!" >NUL 2>&1
set /A "ERL=60+%ERRORLEVEL%"
if exist "!cec_InGameModList!" goto :ERR
echo[
echo[  --- Starting Conan Exiles @!TIME!.
powershell.exe write-host -fore Red -back yellow (' '+' '+' Do NOT close this window^^! '+' '+' ')
(title %title%) & REM because the PS command overwrites the window-title.
echo[!WSC3!After you quit Conan Exiles or it restarts itself
echo[!WSC3!this script checks for modlist updates.

for %%I IN ("!cec_exe!") do (
	pushd "%%~dpI"
	set "cec_exe=%%~nxI"
)
REM start ... /D "!cfg_PathConExSB!\Binaries\Win64" ... <- This doesn't work together with /!cfg_ThisPrio!
start "%~nx0" /!cfg_ThisPrio! /WAIT "!cec_exe!" +connect !cfg_ThisIP! +password "!cfg_ThisPwd!" -modlist="!cfg_ThisModlist!" !cfg_AutoRestart!
set "ERL=!ERRORLEVEL!"
echo[
echo[!WSC3!... closed @!TIME! (ERL=!ERL!).
popd


REM   ----------- Post-game processing (check/update cfg_ThisModlist) ----------
echo[
echo[  --- Checking for new modlist.
if not exist "!cec_InGameModList!" (
	REM  since we deleted the internal modlist before starting ConEx
	REM  we can assume cfg_ThisModList was correct if no new internal on was created.
	echo[!WSC3!No need to update.
	goto :waiter
)
	REM Check servermodlist.txt for differences
	REM set "modlistsAreDiff="
	REM fc.exe /OFF "!cec_InGameModList!" "!cfg_ThisModlist!" >NUL 2>&1
	REM set "modlistsAreDiff=%ERRORLEVEL%"
	REM if not defined modlistsAreDiff goto :ERR
	REM if !modlistsAreDiff! EQU 0 goto :noChange
	echo[
	echo[!WSC3!List was changed. Do you want to save those changes?
	echo[!WSC3!Do NOT do this if you've joined any other servers
	echo[!WSC3!with different modlists WITHOUT quiting Conan Exiles
	echo[!WSC3!completly and answereing this question inbetween.
	echo[
	set "answer=n"
	set /P "answer=Answer ([y]es/no, nothing=no, press 'enter' to submit): "
	if /I "!answer!" EQU "!answer:y=!" goto :noChange
	REM moving the modified/newer internal modlist to cfg_ThisModlist
	copy /D /V /Y "!cec_InGameModList!" "!cfg_ThisModlist!" >NUL
	set /A "ERL=70+%ERRORLEVEL%"
	set "errMSG=Overwriting the old with the new list failed.
	if %ERL% NEQ 70 goto :ERR
		echo[
		echo[!WSC3!New list succesfully saved.
	:waiter
		REM  Wait a bit before quitting if there were no changes OR the new list was saved.
		set /A "cfg_WaitDelay+=2"
		echo[!WSC3!Closing in ~!cfg_WaitDelay! seconds.
		ping -n !cfg_WaitDelay! 127.0.0.1 >NUL 2>&1
	goto :noChange
:noChange
REM  all non-error outcomes of the modlist checker don't need to pause before quitting.
set "finalPause=0"


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
	REM (If finalPause==1) OR (if not defined finalPause) -> pause
	if %ERL% EQU 0 (title !title! - fin.)
	echo[
	pause
:finQuit
endlocal
exit /B %ERL%
exit



:os_chk
REM ---------- Begin OS Check
set ERL=1
if "%OS%"=="Windows_NT" goto :isWinNT
echo[
echo[   The OS is not a version of Windows NT.
pause
exit /B
exit
:isWinNT
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 (
	set "errMSG=Couldn't enable the cmd extensions - quiting..."
	goto :ERR
)
VERIFY OTHER 2>nul
setlocal ENABLEDELAYEDEXPANSION
IF ERRORLEVEL 1 (
	set "errMSG=Couldn't enable the delayed cmd extensions - quiting..."
	goto :ERR
)

set "arch="
if defined PROCESSOR_ARCHITECTURE if "%PROCESSOR_ARCHITECTURE%"=="x86" (
	if not defined PROCESSOR_ARCHITEW6432 (
		set arch=1
	) else if /I "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
		set arch=3
	) else set arch=0
) else if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
	set arch=2
) else set arch=0
set "errMSG=CPU architecture is not defined."
if not defined arch goto :ERR
set "errMSG=CPU architecture is neither "x86" nor "AMD64""
if "%arch%"=="0" goto :ERR

set "OSVER="
for /F "usebackq tokens=2 delims=[]" %%I IN (`ver`) do for /F "tokens=2,3 delims=. " %%J IN ("%%~I") do set OSVER=%%J.%%K
set "errMSG=Couldn't identify the version of this OS."
if not defined OSVER goto :ERR

REM ---------- End OS Check
goto :os_chk_ret



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
