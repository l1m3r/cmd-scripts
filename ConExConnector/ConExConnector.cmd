@echo off
REM  ---------- Just some preliminary stuff ------------
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
set version=0.7_20200404
set title=%~nx0 - Ver. %version%
title %title%

set "ccl=%cmdcmdline%"
set "ccl=%ccl:"=%"

REM Just once set cmdClose=1 to exit batch without another pause,
REM if "/C" (execute and end) is not found in cmdcmdline.
if not defined cmdClose if "%ccl%" EQU "%ccl:/C=%" (
	set "cmdClose=1"
) else set "cmdClose=0"

REM Make sure unicode in/output is used.
if "%ccl%" EQU "%ccl:/U=%" (
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
	set prog_find_ret=prog_find_ret
	goto :prog_find
:prog_find_ret
if defined prog_missing goto :ERR



set "RunOrDebugEcho=@"
set "RemOrDebugRun=REM"
set "RemOrVerbRun=REM"
set "RunOrQuietRem=@"



REM ----------------------- MAIN PROGRAMM ---------------------------

REM  ---- MISSING:
REM   1. make sure OS is >= Win7
REM   2. make sure conex isn't already running when we start it. -> tasklist.exe
REM   3. 
REM   N. several checks here and there (IPv6?, isConanFolderCorrect, ...).
REM   N+1. IPv6 ?


cd /D "%~dp0"
REM   ----------- Some basic vars ----------
set "cfg_AutoRestart=true"
set "cfg_WaitDelay=4"
set "cec_cfgFiExt=CECcfg"
set "cec_cfgSetStr=cfg_"
set "cec_nsluAdrStr=address" & REM This may be language dependent (so far tested with English and German versions of Windows).
set "cec_nsluTimeout=10"
set "cec_regPath=HKCU\Software\Valve\Steam"
set "cec_regVar=SteamPath"
set "cec_priorities=LOW BELOWNORMAL NORMAL ABOVENORMAL HIGH REALTIME"
set "cec_appM=appmanifest_440900.acf"
(set LF=^
%=this line is empty=%
)


REM   ----------- Process the config file Argument ----------
REM Read/parse passed config file.
setlocal DISABLEDELAYEDEXPANSION
set "cec_inparg=%~1" & setlocal ENABLEDELAYEDEXPANSION

set "ERL=20"
set "errMSG=No config/input file defined. Usage: '%~nx0 <(Full)PathToFile>'"
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
)
setlocal ENABLEDELAYEDEXPANSION
set "errMSG="!cec_inparg_n!!cec_inparg_x!" is not a .!cec_cfgFiExt!-File."
if /I "!cec_inparg_x!" NEQ ".!cec_cfgFiExt!" goto :ERR
set "errMSG="!cec_inparg!" defines a dir - not a file."
if /I "!cec_inparg_a:~0,1!" EQU "D" goto :ERR
set "errMSG="!cec_inparg!" defines not a single File (!cnt!)."
if !cnt! NEQ 1 goto :ERR

REM Clear all user variables.
set "allUsrVars=cfg_PathConExSB cfg_KeepIntroClips cfg_ThisModlist cfg_ThisPwd cfg_ThisFQDN cfg_ThisIP cfg_ThisPort cfg_ThisPrio"
for %%I IN (!allUsrVars!) do set "%%I="

REM Parse the !cec_cfgFiExt!-File and import the defined variables.
set "ERL=21"
for /F usebackq^ tokens^=2^ delims^=^" %%I IN (`findstr.exe /B /I /R /C:"set \"%cec_cfgSetStr%..*^=.*\"" "!cec_inparg_f!"`) do set "ERL=0" & set "%%~I"
set "errMSG="!cec_inparg!" doesn't contain any 'set "!cec_cfgSetStr!^<^>=^<^>"' defintions. (!ERL!)"
if !ERL! NEQ 0 goto :ERR



REM   ----------- Find the path to Steam & Conan Exiles. ----------
set "ERL=22"
if defined cfg_PathConExSB goto :gotPath
	for /F "usebackq tokens=3 skip=1" %%I IN (`reg.exe query "!cec_regPath!" /v "!cec_regVar!" 2^>NUL `) do set "cfg_PathConExSB=%%~I"
	set "errMSG=Quering the registry for Steams path failed."
	if not defined cfg_PathConExSB goto :ERR
	
	set "cfg_PathConExSB=!cfg_PathConExSB:/=\!\SteamApps"
	set "errMSG=Couldn't find "!cec_appM!" in "!cfg_PathConExSB!".!LF!   (for now) This script only works with Conan Exile in Steams default library folder."
	if not exist "!cfg_PathConExSB!\!cec_appM!" goto :ERR
	
	for /F "usebackq tokens=1,*" %%I IN (`findstr.exe /R /I /C:"^		*\"installdir\"		*\"..*\"" "!cfg_PathConExSB!\!cec_appM!"`) do set "ERL=0" & set "cfg_PathConExSB=!cfg_PathConExSB!\common\%%~J\ConanSandbox"
	set "errMSG=Couldn't find Conans path in "!cec_appM!"."
	if !ERL! NEQ 0 goto :ERR
	
	set "ERL=23"
	set "errMSG=The "ConanSandbox" path doesn't seem to exist."
	if not exist "!cfg_PathConExSB!\." goto :ERR
:gotPath



REM   ----------- Check and/or modify vars set by the config file. ----------
set "ERL=24"
set "cec_InGameDefCfg=!cfg_PathConExSB!\Config\DefaultGame.ini"
set "cec_InGameModList=!cfg_PathConExSB!\servermodlist.txt"
set "cec_exe=!cfg_PathConExSB!\Binaries\Win64\ConanSandbox.exe"
set "errMSG=Conans main executeable doesn't exist where it's supposed to be."
if not exist "!cec_exe!" goto :ERR

set "ERL=25"
if defined cfg_ThisIP goto :gotIP
set "errMSG=Neither cfg_ThisIP nor cfg_ThisFQDN were defined."
if not defined cfg_ThisFQDN goto :ERR

REM Check/set the process priority.
set "ERL=26"
if not defined cfg_ThisPrio (
	set "cfg_ThisPrio=ABOVENORMAL"
	goto :gotPrio
) & REM else ...
	for %%I IN (!cec_priorities!) do if /I "%%~I" EQU "!cfg_ThisPrio!" set "ERL=0"
	set "errMSG='!cfg_ThisPrio!' is not a priority (!ERL!)."
	if !ERL! NEQ 0 goto :ERR
:gotPrio

if defined cfg_AutoRestart (
	set "cfg_AutoRestart=-cfg_AutoRestart"
) else set "cfg_AutoRestart= "

REM Create auto generated cfg_ThisModlist path+name.
if not defined cfg_ThisModlist set "cfg_ThisModlist=%~dp0.\cecModList - !cec_inparg_n!.txt"



REM   ----------- Lookup the servers IP from its FQDN ----------
echo[
echo[  --- Looking up the IP of "!cfg_ThisFQDN!" (this may take a few seconds).
REM -type^=AAAA+A
for /F "skip=2 tokens=1,2 delims=: " %%I IN ('nslookup.exe -timeout^=!cec_nsluTimeout! -type^=A "!cfg_ThisFQDN!" 2^>NUL') do if /I "%%~I" EQU "!cec_nsluAdrStr!" set "cfg_ThisIP=%%~J"
set "errMSG=Couldn't find the IP address of '!cfg_ThisFQDN!'."
if not defined cfg_ThisIP goto :ERR


:gotIP
REM   ----------- Check IP Address ----------
REM Maybe rewrite with [0-9], [1-9][0-9], 1[0-9][0-9], 2[0-4][0-9], 25[0-5]
REM FINDSTR /r "^[1-9][0-9]*$ ^0$"
set "IPpVars=ipp1 ipp2 ipp3 ipp4"
for %%I IN (!IPpVars!) do set "%%~I="
for /F "tokens=1,2,3,4 delims=." %%I IN ("!cfg_ThisIP!") do (
	set /A "ipp1=%%~I"
	set /A "ipp2=%%~J"
	set /A "ipp3=%%~K"
	set /A "ipp4=%%~L"
) >NUL 2>&1
set "ERL=0"
set "errMSG="
for %%I IN (!IPpVars!) do if not defined %%~I (
	set /A ERL+=1
	set "errMSG=!errMSG!%%~I,"
)
if !ERL! NEQ 0 (
	set "errMSG='!cfg_ThisIP!' is not a legitimate IP. ^(!errMSG!^)"
	set /A ERL+=10
	goto :ERR
)
set "blargh=!ipp1!.!ipp2!.!ipp3!.!ipp4!"
if "!blargh!" NEQ "!cfg_ThisIP!" (
	set "errMSG='!cfg_ThisIP!' is not a legitimate IP. ^(NEQ !blargh!^)"
	goto :ERR
)
set "erl=4"
REM
for %%I IN (!IPpVars!) do if !%%~I! GEQ 0 if !%%~I! LEQ 255 set /A ERL-=1
set "errMSG='!cfg_ThisIP!' is not a legitimate IP. !ERL! blocks are wrong."
if !ERL! NEQ 0 (
	set /A ERL+=50
	goto :ERR
)


REM ----------- Check network port ---------------------
if not defined cfg_ThisPort goto :gotPort
	set "ERL="
	set /A "ERL=!cfg_ThisPort!" >NUL 2>&1
	if "!ERL!" EQU "!cfg_ThisPort!" if !ERL! LEQ 65535 if !ERL! GTR 0 (
		set "cfg_ThisIP=!cfg_ThisIP!:!cfg_ThisPort!"
		set "ERL=0"
		goto :gotPort
	)
	set "errMSG=Someting is wrong with your port '!cfg_ThisPort!' (!ERL!).
	set "ERL=10!ERL!"
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
	set "ERL=%ERRORLEVEL%" & REM should be =1 if none were and =0 if at least one was found.
	set "errMSG=Used findstr with wrong syntax."
	if %ERL% GTR 1 goto :ERR

	REM Replace the strings in DefGameCfg.
	if %ERL% EQU 1 (
		REM No need to modify so reset ERL to 0.
		set "ERL=0"
		goto :KeepIntroMovs
	)
	powershell.exe -Command "(Get-Content -Path '!cec_InGameDefCfg!') -ireplace '^\+StartupMovies\=', '-StartupMovies='  -ireplace '^bWaitForMoviesToComplete\=.*$', 'bWaitForMoviesToComplete=False' | Out-File -encoding ASCII '!cec_InGameDefCfg!'"
	set "ERL=!ERRORLEVEL!"
	set "errMSG=Failed to modify 'DefaultGame.ini' (!ERL!).
	if %ERL% NEQ 0 goto :ERR
:KeepIntroMovs



REM   ----------- Done with almost everything -> proceeding to start ConEx ----------
echo[
echo[  --- Showing connection data for !cfg_WaitDelay! seconds (press ctrl+c to cancel).
echo[   ServerIP= "!cfg_ThisIP!"
echo[   Password= "!cfg_ThisPwd!"
set /A cfg_WaitDelay+=1
ping -n !cfg_WaitDelay! 127.0.0.1 > NUL
REM  Removing the internal/"ingame" servermodlist is necessary to ensure the checks for changes below work under all conditions.
set "errMSG=Couldn't remove internal ModList: "!cec_InGameModList!"
del /F "!cec_InGameModList!" >NUL 2>&1
if exist "!cec_InGameModList!" goto :ERR
echo[
echo[  --- Starting Conan Exiles @!TIME!.
powershell.exe write-host -fore Red -back yellow (' '+' '+' Do NOT close this window^^! '+' '+' ')
echo[   After you quit Conan Exiles or it restarts itself this script checks for modlist updates.

for %%I IN ("!cec_exe!") do (
	pushd "%%~dpI"
	set "cec_exe=%%~nxI"
)
REM start ... /D "!cfg_PathConExSB!\Binaries\Win64" ... <- This doesn't work together with /!cfg_ThisPrio!
start "%~nx0" /!cfg_ThisPrio! /WAIT "!cec_exe!" +connect !cfg_ThisIP! +password "!cfg_ThisPwd!" -modlist="!cfg_ThisModlist!" !cfg_AutoRestart!
set "ERL=!ERRORLEVEL!"
echo[
echo[   ... closed @!TIME! (ERL=!ERL!).
popd[


REM   ----------- Post-game processing (check/update cfg_ThisModlist) ----------
echo[
echo[  --- Checking modlist for changes.
if not exist "!cec_InGameModList!" (
	echo[   No need to update.
	goto :EOFi
)
REM Check servermodlist.txt for differences
REM set "modlistsAreDiff="
REM fc.exe /OFF "!cec_InGameModList!" "!cfg_ThisModlist!" >NUL 2>&1
REM set "modlistsAreDiff=%ERRORLEVEL%"
REM if not defined modlistsAreDiff goto :ERR
REM if !modlistsAreDiff! EQU 0 goto :noChange
	echo[
	echo[   List was changed. Do you want to save those changes?
	echo[   Do NOT do this if you've joined any other servers with different modlists
	echo[   WITHOUT quiting Conan Exiles completly and answereing this question inbetween.
	echo[
	set "answer=n"
	set /P "answer=Answer (yes/no, nothing=no): "
	if "!answer!" EQU "!answer:y=!" goto :noChange
	REM moving the modified/newer internal modlist to cfg_ThisModlist
	echo[
	copy /D /V /Y "!cec_InGameModList!" "!cfg_ThisModlist!" >NUL
	set "ERL=%ERRORLEVEL%"
	set "errMSG=Overwriting the old with the new list failed (!ERL!).
	if %ERL% NEQ 0 goto :ERR
:noChange


goto :EOFi



REM ------------ Subroutines not belonging to the 'real' script follow here. ------------------

:ERR
echo[
title %title% - ERROR (%ERL%)
echo[
echo[  ERROR:
echo[   !errMSG!
echo[
REM set /A ERL+=1
:EOFi
if "%cmdClose%"=="1" (
	endlocal
	exit /B %ERL%
	exit
)
REM (If cmdClose==0) OR (if not defined cmdClose) -> pause
title %title% - fin.
echo[
set /A cfg_WaitDelay*=2
REM echo[  closing in ~!cfg_WaitDelay! seconds ...
REM ping -n !cfg_WaitDelay! 127.0.0.1 > NUL
pause
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
exit /b
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
		set "errMSG=Required programm "%%~I" could not be found (!ERL!)."
		set lERL=0
	)
)
set "pf_tmpath="
goto :%prog_find_ret%





:chkFiSysObj
REM ---------- Begin Check-File-System-Object
REM Aufruf:
REM call :chkFiSysObj <obj>, 1full, 2drive, 3path, 4name, 5ext, 6size, 7attr, 8time
REM Unused Variables between used ones must/can be set to "nul"
REM return-value = ERL = isFile
REM   >1	(cnt-1) Object(s) found with placeholders in %~1.
REM    1	Obj is a file.
REM    0	Obj is a directory.
REM   -1	Obj does not exist.
REM   -2	placeholders in %~1 and no fitting files(!) found. no vars defined.
REM   -3	forbidden chars in %~1.
REM if not defined (6, 7 or 8) -> object does not exist.
%RemOrVerbRun% echo[
%RemOrVerbRun% echo[ ---- %~0 begin - %*
set "chkFSO_Obj=%~1"
REM Cleanup input
set "chkFSO_Obj=!chkFSO_Obj:&=!"
set "chkFSO_Obj=!chkFSO_Obj:|=!"
set "chkFSO_Obj=!chkFSO_Obj:>=!"
set "chkFSO_Obj=!chkFSO_Obj:<=!"
set "chkFSO_Obj=!chkFSO_Obj:"=!"
if "!chkFSO_Obj!" NEQ "%~1" (
	set ERL=-3
	REM verbotene Zeichen in %~1
	%RemOrVerbRun% echo[ ---- %~0 - input contains forbidden chars.
	goto :EOF_chkFiSysObj
)
shift /1
set "chkFSO_atr="
set ERL=0
for %%I IN ("!chkFSO_Obj!") do (
	set "chkFSO_atr=%%~aI"
	set /A ERL+=1
	set "%~1=%%~fI"
	set "%~2=%%~dI"
	set "%~3=%%~pI"
	set "%~4=%%~nI"
	set "%~5=%%~xI"
	set "%~6=%%~zI"
	set "%~7=%%~aI"
	set "%~8=%%~tI"
) 2>nul
REM set ERL= return-value / isFile
if %ERL% EQU 0 (
	REM no files found.
	%RemOrVerbRun% echo[ ---- %~0 - no file^(s^) found, no vars defined.
	set ERL=-2
	goto :EOF_chkFiSysObj
)
echo["!chkFSO_Obj!" | findstr.exe "* ?" 2>&1 >nul
if !ERRORLEVEL! EQU 0 (
	REM input contains placeholders -> erl++
	%RemOrVerbRun% echo[ ---- %~0 - %ERL% object^(s^) found ^(with placeholders^).
	set /A ERL+=1
) else if %ERL% EQU 1 if not defined chkFSO_atr (
	REM obj is nonexistent.
	%RemOrVerbRun% echo[ ---- %~0 - obj is nonexistent, some vars defined.
	set ERL=-1
) else if /I "D"=="%chkFSO_atr:~0,1%" (
	REM obj is a directory.
	%RemOrVerbRun% echo[ ---- %~0 - obj is a directory, vars defined.
	set ERL=0
)
:EOF_chkFiSysObj
REM Cleanup
for /F "usebackq delims==" %%I IN (`set chkFSO_`) do set "%%I="
if defined nul set "nul="
%RemOrVerbRun% echo[ ---- %~0 end.
exit /B %ERL%
REM ---------- End Check-File-System-Object

