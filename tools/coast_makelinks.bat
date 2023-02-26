@ECHO OFF
TITLE %CD%
CD /D %~dp0

ECHO ++ coastrock-exp ++
ECHO ===================
ECHO/

REM - Check for admin rights.. https://superuser.com/questions/204760/batch-script-how-to-check-for-admin-rights
REM - - Because links require admin rights. Deleting files don't though..?
fsutil dirty query %systemdrive% >nul
IF %errorlevel% EQU 1 (
	ECHO Run this script with admin rights!
	PAUSE
	GOTO :EOF
)

REM - I really do not like copy-pasting the same file paths a bilion times
REM - - And for everyone's sake, verify the file paths first
SET "_PATH_POP=T:\SteamLibrary\steamapps\common\Team Fortress 2\tf\custom\orin\scripts\population"
SET "_PATH_GIT=D:\Software\GitHub\repos\coastrock-exp\scripts\population"
IF NOT EXIST "%_PATH_POP%" (
	SET /P "_PATH_POP=Default path to Team Fortress 2 is incorrect.. Please provide the right path: "
)
IF NOT EXIST "%_PATH_GIT%" (
	SET /P "_PATH_GIT=Default path to GitHib is incorrect.. Please provide the right path: "
)

mklink "%_PATH_POP%\mvm_coastrock_rc1_1_exp_sunny_side_up.pop" "%_PATH_GIT%\mvm_coastrock_rc1_1_exp_sunny_side_up.pop"
mklink "%_PATH_POP%\mvm_coastrock_rc1_1_TEST_REMORIN.pop" "%_PATH_GIT%\mvm_coastrock_rc1_1_TEST_REMORIN.pop"
mklink "%_PATH_POP%\robot_remorin.pop" "%_PATH_GIT%\robot_remorin.pop"
mklink "%_PATH_POP%\..\vscripts\exp_sunny_side.nut" "%_PATH_GIT%\..\vscripts\exp_sunny_side.nut"

TIMEOUT 10