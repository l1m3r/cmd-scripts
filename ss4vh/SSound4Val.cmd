@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "CRLFs=?"
(set CRLF_=^
%=this line is empty=%
)

::#  just title and version
set "version=0.2.2_20231121"
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
set "pwrSH=powershell.exe"

set "VH_regPath=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970"
set "VH_regVar=InstallLocation"
set "file2mod=globalgamemanagers"
set "path_sub=valheim_Data\%file2mod%"
set "VH_exe=valheim.exe"

set "chan_nmbrs=2 4 5 6 8 "
set "hex_Speaker=0000803F0-SpkN-0000000000000000040000"
set "hex_PhyInp=803f000000000200000009000000080000000"
REM                                         trailing ^=1/0
set GFXsets="gfx-enable-gfx-jobs=1" "gfx-enable-native-gfx-jobs=1" "scripting-runtime-version=latest"


cd /D "%~dp0"

call :log "Searching for required programs."
::# ---- Variables required for prog_find
set _requiredPrograms=findstr.exe reg.exe tasklist.exe %pwrSH% %exeSFK%

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
	echo[ #    %sfkURL%
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
	set "exePS+A=%pwrSH% -nologo -noprofile -command"
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


::#   ----------- Check for other running instances of this scrip and/or Valheim ----------
set /A "ERL=80"
set "errMSG=Found at least one running instance "!VH_exe!"."
tasklist.exe /FO csv /NH /FI "ImageName EQ !VH_exe!" | findstr.exe /I "!VH_exe!" >NUL && goto :ERR


set /A "cnt=-1"
for /F "usebackq tokens=1 delims=[]" %%I IN (`tasklist.exe /V /FO csv /NH /FI "ImageName EQ cmd.exe" ^| find.exe /N /I "!title!"`) do set /A "cnt+=1"
set /A "ERL+=!cnt!"
set "errMSG=Found !cnt! other running instance^(s^) of "%~nx0"."
if !cnt! NEQ 0 goto :ERR


::#   ----------- Main script ----------

set "inp="
set "inp=%~1"
::#  Parse argument %1
if not defined inp goto :searchPaths
	call :log "processing argument #1="!inp!""
	if "!inp!" NEQ "%~1" (
		set "ERL=50"
		set "errMSG=First argument "!inp!" is bonkers."
		goto :ERR
	)
	
	call :chkFiSysObj "!inp!" VH_Path nul nul inp_name inp_ext inp_size inp_attr nul
	set "ERL=%ERRORLEVEL%"
	
	if %ERL% EQU 1 if %inp_size% GTR 1 if not defined inp_ext if /I "!inp_name!" EQU "%file2mod%" if "%inp_attr:~1,1%" EQU "-" goto :searchPaths_end
	::# ELSE
	set "errMSG=Your argument!CRLF_! "!inp!"!CRLF_!didn't meet all conditions:!CRLF_! ? cnt: %ERL% EQU 1!CRLF_! ? size=%inp_size%!CRLF_! ? ext="%inp_ext%" EQU ""!CRLF_! ? name: "!inp_name!" EQU "%file2mod%"!CRLF_! ? read-only: %inp_attr:~1,1% EQU -"
	set "ERL=51"
goto :ERR


::#  Read VH's installation path from Windows's registry.
:searchPaths
	call :log "Looking for VH's "%file2mod%" (standard + fetched blindly from registry)."
	
	set "fldrVH=steamapps\common\Valheim"
	set psblLocations="%ProgramFiles%\Steam\%fldrVH%" "%ProgramFiles(x86)%\Steam\%fldrVH%"
	
	::# Fetch VH's direct path
	set "VH_Path="
	call :ReadReg VH_Path "!VH_regPath!" "!VH_regVar!"
	if defined VH_Path set psblLocations=%psblLocations% "%VH_Path%"
	
	::# Fetch Steam's path and add VH's subfolder.
	set "regKey2=HKLM\SOFTWARE\Wow6432Node\Valve\Steam"
	for %%I IN ("%regKey2%" "%regKey2:Wow6432Node\=%") do (
		set "VH_Path="
		call :ReadReg VH_Path "%%~I" "InstallPath"
		if defined VH_Path set psblLocations=!psblLocations! "!VH_Path!\%fldrVH%"
	)
	::# Fetch Steam's path from Windows's 'uninstall' and add VH's subfolder.
	set "regKey3=HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam"
	for %%I IN ("%regKey3%" "%regKey3:Wow6432Node\=%") do (
		set "VH_Path="
		call :ReadReg VH_Path "%%~I" "UninstallString"
		if defined VH_Path for %%J IN ("!VH_Path!") do set psblLocations=!psblLocations! "%%~dpJ%fldrVH%"
	)
	
	::# Search all possible standard locations for %file2mod%.
	set "errMSG=!CRLF_!"
	set "VH_Path="
	for %%I IN (%psblLocations%) do (
		set "errMSG=!errMSG! %%~I!CRLF_!"
		for %%J IN (inp_full inp_ext inp_size inp_attr) do if defined %%~J set "%%~J="
		
		call :chkFiSysObj "%%~I\%path_sub%" inp_full nul nul nul inp_ext inp_size inp_attr nul
		set "ERL=!ERRORLEVEL!"
		if !ERL! EQU 1 if !inp_size! GTR 1 if not defined inp_ext if "!inp_attr:~1,1!" EQU "-" (
			call :log " -> Found @ "!inp_full!""
			if defined VH_Path if /I "!VH_Path!" NEQ "!inp_full!" echo[ --------------- FOUND A DIFFERENT LOCATION^!^! ^(this is WiP, please let me know about it.^)
			set "VH_Path=!inp_full!"
		)
	)
	if defined VH_Path goto :searchPaths_end
	REM else
		set "errMSG=Couldn't find ".\%path_sub%" in any of the 'normal' locations:!errMSG!!CRLF_! -> Try drag'n'dropping the file "%file2mod%"!CRLF_!    on "%~nx0" instead.!CRLF_!    (but NOT on the open cmd shell window^!^)"
		set "ERL=20"
	goto :ERR
:searchPaths_end



::# Enumerate current number of configured speakers and make sure patching is at least "kinda safe".
:readHex
	call :log "Searching for valid HEX-strings."
	set "cnt_HitsTotal="
	set "cnt_spk="

	for %%I IN (%chan_nmbrs%) do (
		set "cnt_HitsLocal=0"
		::#  search file "path_sub" for HEX-string and count hits.
		call :HexFindCount "!VH_Path!" "!hex_Speaker:-SpkN-=%%~nI!" cnt_HitsLocal
		set "cnt_HitsLocal=!ERRORLEVEL!"
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

	::#  summarize the results. (calculate the value of the formula in !cnt_HitsTotal!)
	set /A cnt_HitsTotalS=!cnt_HitsTotal!
	set /A cnt_spkS=!cnt_spk!

	if !cnt_HitsTotalS! NEQ 1 (
		set ERL=22
		set "errMSG=Didn't find exactly one location to patch ^(#=!cnt_HitsTotalS! [!cnt_spk!]^)."
		goto :ERR
	)


:stepSND
	::#  Remove the current configured # of speakers from the list of valid #s.
	set "chan_nmbrs=!chan_nmbrs:%cnt_spkS% =!"
	set "cnt_spkN="
	echo[
	echo[
	echo[
	echo[ ############### Surround Sound ###################
	echo[ #
	echo[ #   Valheim's current number of used speakers:
	echo[ #                 %cnt_spkS%
	echo[ #   Enter one of the valid alternative values
	echo[ #              %chan_nmbrs:~0,-1%
	echo[ #   to modify or nothing to skip this step.
	echo[ #
	set /P cnt_spkN= #   New # of speakers:
	echo[ #
	echo[ ##################################################
	echo[

	if not defined cnt_spkN goto :stepSND_end
	set /A "cnt_spk=cnt_spkN" 2>NUL
	if "%cnt_spk%" NEQ "!cnt_spkN!" (
		set "ERL=23"
		set "errMSG=You entered something unsupported ("%cnt_spkN%" vs. "%cnt_spk%")."
		goto :ERR
	)
	if "%chan_nmbrs%" EQU "!chan_nmbrs:%cnt_spkN% =!" (
		set "ERL=24"
		set "errMSG=You entered an invalid value ("%cnt_spkN%" vs. "%chan_nmbrs:~0,-1%")."
		goto :ERR
	)
	%exeSFK% replace "!VH_Path!" -binary /!hex_Speaker:-SpkN-=%cnt_spkS%!/!hex_Speaker:-SpkN-=%cnt_spkN%!/ -yes -dump
	set "ERL=%ERRORLEVEL%"
	if %ERL% NEQ 1 (
		set "ERL=3%ERL%"
		set "errMSG=Error patching ".\%path_sub%" (see above for details)."
		goto :ERR
	)
	set "ERL=0"
:stepSND_end




:stepPhysInp
	::# search for m_UsePhysicalKeys=1
	call :HexFindCount "!VH_Path!" "%hex_PhyInp%1"
	set "PhysInpUsed=%ERRORLEVEL%"
	::# search for m_UsePhysicalKeys=0
	call :HexFindCount "!VH_Path!" "%hex_PhyInp%0"
	set "PhysInpUsed=%PhysInpUsed%;%ERRORLEVEL%"
	
	if "%PhysInpUsed%" NEQ "0;1" if "%PhysInpUsed%" NEQ "1;0" (
		set /A "ERL=-2000000+1000*!PhysInpUsed:;=+!"
		set "errMSG=Searching for VH's "physical input state" returned 'false' results: %PhysInpUsed%"
		goto :ERR
	)
	
	set "inpTypTxt-0='NORMAL' keyboard input (+language/layout)"
	set "inpTypTxt-1='PHYSICAL' keyboard key-codes"
	
	set "usrChoice="
	echo[
	echo[
	echo[
	echo[ ############### Keyboard Input ###################
	echo[ #
	echo[ #   Valheim is currently configured to use 
	echo[ #     !inpTypTxt-%PhysInpUsed:~0,1%!
	echo[ #   instead of
	echo[ #     !inpTypTxt-%PhysInpUsed:~2,1%!.
	echo[ #
	echo[ #   Enter anything to switch or nothing to skip.
	set /P usrChoice= #   [INPUT]:
	echo[ #
	echo[ ##################################################
	echo[
	if not defined usrChoice goto :stepPhysInp_end
	
	%exeSFK% replace "!VH_Path!" -binary /%hex_PhyInp%%PhysInpUsed:~0,1%/%hex_PhyInp%%PhysInpUsed:~2,1%/ -yes -dump
	set "ERL=%ERRORLEVEL%"
	if %ERL% NEQ 1 (
		set "ERL=5%ERL%"
		set "errMSG=Error patching ".\%path_sub%" (see above for details)."
		goto :ERR
	)
	set "ERL=0"
:stepPhysInp_end




:stepGFX
	::#   adding GFX config stuff to boot.config
	set "VH_PathBC=!VH_Path:%file2mod%=!boot.config"
	set "usrChoice="
	echo[
	echo[
	echo[
	echo[ ############### GFX settings #####################
	echo[ #
	echo[ #   Do you want to add the following settings
	for %%I IN (%GFXsets%) do echo[ #      "%%~I"
	echo[ #   to VH's boot.config file?
	echo[ #     "!VH_PathBC!"
	echo[ #
	echo[ #   Enter anything for YES or nothing to skip.
	set /P usrChoice= #   [INPUT]:
	echo[ #
	echo[ ##################################################
	echo[
	if not defined usrChoice goto :stepGFX_end

	::#		Check existence of the vars of each var/value pair.
	for %%I IN (%GFXsets%) do (
		for /F "tokens=1,2 delims==" %%J IN ("%%~I") do (
			findstr /B /I "%%~J=" "!VH_PathBC!" >NUL && (
				echo[ # Boot.config already contains "%%~J".
			) || (
				echo[ + Adding "%%~J=%%~K" to VH's "boot.config" file.
				echo[%%~J=%%~K>>"!VH_PathBC!"
			)
		)
	)
:stepGFX_end
goto :EOFi




::# ------------ Function/Subroutines not belonging to the 'real' script follow here. ------------------

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
echo[+INFO: !bla!
endlocal & exit /b



::# ---------- Function HexFindCount
::#
::#  HexFindCount must be used like this:
::#		call :HexFindCount 1file 2hexString [3rtnVar]
::#  Returns/Sets:
::#		[rtnVar]		number of times 2hexString was found in 1file
::#  Errorlevel:
::#		GEQ 0	->	same as rtnVar
::#		LSS 0	->	sfk hexfind -|errorlevel|
::#
:HexFindCount
setlocal
	set "mod_ERL=-1"
	if "%~2" EQU "" goto :HexFindCount_end
	
	set "string2count= hit at offset 0x"
	set "mod_rtn=-1"
	set "mod_ERL="
	::# do (sfk hexfind .... & echo %string2count% + =!ERRORLEVEL!) | findstr ...
	::#		-> split by = and last %%J is sfk's ERL.
	for /F "usebackq tokens=1,2 delims==" %%I in (`^
		(^
			%exeSFK% hexfind "%~1" -binary "/%~2/" 2^>NUL ^
			^& echo[ ^& echo[%string2count%ERR^=^^^!ERRORLEVEL^^^!^
		^) ^| findstr.exe /N /C:"%string2count%" ^
	`) do (
		set /A "mod_rtn+=1"
		set /A "mod_ERL=%%~J" 2>NUL
	)
	if not defined mod_ERL set "mod_ERL=-1000
	if %mod_ERL% GTR 1 (
		set /A "mod_ERL*=-1"
	) else if %mod_ERL% GEQ 0 (
		set "mod_ERL=%mod_rtn%"
	)
	REM if %mod_ERL% LSS 0 echo[--ERROR HexFindCount=%mod_ERL%
:HexFindCount_end
endlocal &(
	if %mod_ERL% GEQ 0 if "%~3" NEQ "" set "%~3=%mod_rtn%"
	REM  else if %mod_ERL% LSS 0 set "errMSG=%mod_errMSG%"
	exit /B %mod_ERL%
)
::# ---------- End HexFindCount




::# ---------- Function ReadReg
::#
::#  ReadReg must be used like this:
::#    call :ReadReg 1rtnVar 2regPath 3regEntry
::#  Requires:
::#     ... all three args required ...
::#  Returns/Sets:
::#     rtnVar    Value of the requested reg-key will be stored here.
::#  Errorlevel:	????
::#
:ReadReg
setlocal
	set "mod_rtn="
	for /F "usebackq tokens=2* skip=2" %%I IN (`reg.exe query "%~2" /v "%~3" 2^>NUL`) do set "mod_rtn=%%~J"
	set "mod_ERL=%ERRORLEVEL%"
endlocal &(
	REM if %mod_ERL% GTR 0 
		if /I "%~1" NEQ "NUL" if "%mod_rtn%" NEQ "" set "%~1=%mod_rtn%"
	REM  else if %mod_ERL% LSS 0 set "errMSG=%mod_errMSG%"
	exit /B %mod_ERL%
)
::# ---------- End ReadReg




::# ---------- Function ProgFind
::#
::#  ProgFind must be used like this:
::#    call :ProgFind 1"<path(s)>" 2rtnVar 3programs/files [4to [5look [6for ...]]]
::#  Requires:
::#     "<path(s)>" This is a ;-separated list of paths (like the %path% variable).
::#     rtnVar      The names of missing files will be stored in the variable with this name.
::#     %%3 - %%*   These are the programs/files to look for.
::#  Returns/Sets:
::#     rtnVar    unless it was set to "nul".
::#     errMSG    only if ERL NEQ 0
::#  Errorlevel:
::#      >= 1     # file(s) could not be found.
::#         0     All files were found.
::#     <= -1     An error occurred.
::#
:ProgFind
	SETLOCAL EnableDelayedExpansion EnableExtensions
	if "%~n0" EQU "ProgFind" call :varset
	for /F "usebackq delims==" %%I IN (`set mod_ 2^>nul`) do set "%%I=" REM Cleanup
	set "AllowedVarChars=a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 # _ . + -"
	set "mod_Name=:ProgFind"
	%RemOrVerbRun% echo[
	%RemOrVerbRun% echo[  ---- %mod_Name% begin
	set "mod_ERL=-1"
	::# Check %1 - paths
	set "mod_paths="
	set "mod_paths=%~1"
	if not defined mod_paths (
		set "mod_errMSG=%mod_Name% - mod_paths (%%1) is not defined."
		%RemOrVerbRun% echo[  -- Error: !mod_errMSG!
		goto :ProgFind_End
	)
	::# TBD? - Check paths for illegal Chars?
	::# Check %2 - rtnVarName
	set "mod_tmp="
	set "mod_tmp=%~2"
	if not defined mod_tmp (
		set "mod_errMSG=%mod_Name% - mod_tmp (%%2) is not defined."
		%RemOrVerbRun% echo[  -- Error: !mod_errMSG!
		goto :ProgFind_End
	)
	::# Remove every allowed char.
	for %%A IN (!AllowedVarChars!) do for /F "tokens=1" %%B IN ("%%~A") do if defined mod_tmp (
		set "mod_tmp=!mod_tmp:%%~B=!"
	)
	if defined mod_tmp (
		REM only illegal chars left
		set "mod_errMSG=%mod_Name% - mod_tmp (%%2) contains illegal chars."
		%RemOrVerbRun% echo[  -- Error: !mod_errMSG!
		goto :ProgFind_End
	)

	::# TBD? check other inputs... %*
	::# read params %3 ... programs/files [to [look [for]]]

	::#  main 'for' loop to look for files/programs
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
	::# Remove trailing "  "
	set "mod_pMissing=!mod_pMissing:~0,-2!"
	::# Check if the 'for' loop did sth. - post check of %3....
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
::# Clear all local vars ...
endlocal &(
	REM ... except the required ones.
	if %mod_ERL% GTR 0 (
		if /I "%~2" NEQ "NUL" set "%~2=%mod_pMissing%"
	) else if %mod_ERL% LSS 0 set "errMSG=%mod_errMSG%"
	exit /B %mod_ERL%
)
::# ---------- End ProgFind




::# ---------- Function Check-File-System-Object
::# Usage:
::# call :chkFiSysObj <obj>, 1full, 2drive, 3path, 4name, 5ext, 6size, 7attr, 8time
::# Unused variables between used ones must/can be set to "nul"
::# return-value = ERL = isFile
::#   >1	(cnt-1) Object(s) found with placeholders in %~1.
::#    1	Obj is a file.
::#    0	Obj is a directory.
::#   -1	Obj does not exist.
::#   -2	placeholders in %~1 and no fitting files(!) found. no vars defined.
::#   -3	forbidden chars in %~1.
::# if not defined (6, 7 or 8) -> object does not exist.
::#
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

	::# Check %1 - Obj
	set "mod_Obj="
	set "mod_Obj=%~1"
	if not defined mod_Obj (
		set "errMSG=%mod_Name% - mod_Obj (%%1) is not defined."
		%RemOrVerbRun% echo[ errMSG !errMSG!
		set mod_ERL=-3
		goto :chkFiSysObj_End
	)

	::# Cleanup input Obj
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

	::# read params 1-8, ignore empty ones and those that are NUL
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

	::# Remove last whitespace
	set "mod_String=!mod_String:~0,-1!"
	::# Remove every allowed char.
	if defined mod_string for %%A IN (!AllowedVarChars!) do if defined mod_string set "mod_String=!mod_String:%%~A=!"
	if defined mod_String (
		REM only illegal chars left
		set "errMSG=%mod_Name% - at least one VarName (1-8) contains illegal chars."
		%RemOrVerbRun% echo[ errMSG !errMSG!
		set "mod_ERL=-5"
		goto :chkFiSysObj_End
	)

	::# the actual chkfisysobj operation.
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
	::# set mod_ERL= return-value / isFile
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

endlocal &(
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
::# ---------- End Check-File-System-Object
