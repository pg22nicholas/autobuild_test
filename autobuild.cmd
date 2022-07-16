@echo on
@echo :
@echo : Hi %USERNAME%

set SRC=.
set BUILD=.\build
set RELEASE="E:\Programming projects\VFS-not-onedrive\Pipelines\release"
set LOGFILE=.\autobuild.log
set GITHUB_REPO="https://github.com/pg22nicholas/autobuild_test.git"
set RunUAT_DIR="E:\Programs\UE_4.27\Engine\Build\BatchFiles\RunUAT"

goto :getopts
:usage
@echo Usage:
@echo   c:\> autobuild [--debug] [--help] [--pull]
@echo .
goto :bye

:: set up the environment
:getopts
if /I "%1"=="/?" goto :usage
if /I "%1"=="--help" goto :usage
::shift copies %2 into %1
if /I "%1"=="--debug" set DEBUG=true & shift 
if /I "%1"=="--pull" set PULL=true & shift
shift
if not "%1"=="" goto :getopts


if DEFINED DEBUG (
    @echo Debug:         %DEBUG%
    @echo Pull from Git: %PULL%
)

if DEFINED PULL goto :source-control
goto :build-it

:: pull from source control
:source-control
    git switch develop
    git pull %GITHUB_REPO%

:: Build the project
:build-it
set DEST=%SRC%\Build
if EXIST %DEST% rmdir /S /Q %DEST% >>%LOGFILE%
mkdir %DEST% >>%LOGFILE%

@echo start build

set CURR_DIR=%cd%
call %RunUAT_DIR% BuildCookRun -project="%CURR_DIR%\autobuild_test.uproject" -noP4 -platform=Win64 -clientconfig=Development -serverconfig=Development -cook -allmaps -build -stage -pak -archive -archivedirectory="%CURR_DIR%\build"

:: Create the release
:generate-release
if not exist %RELEASE%\oldest mkdir %RELEASE%\oldest
if not exist %RELEASE%\yesterday mkdir %RELEASE%\yesterday
if not exist %RELEASE%\today mkdir %RELEASE%\today

robocopy %RELEASE%\yesterday %RELEASE%\oldest /MOVE /s
robocopy %RELEASE%\today %RELEASE%\yesterday /MOVE /s
robocopy %DEST%\WindowsNoEditor %RELEASE%\today /MOVE /s

:: Publish the release
:publish

:: clean up
:bye
set DEBUG=
set PULL=
set SRC=
set BUILD=
set RELEASE=
set GITHUB_REPO=
set DEST=
set CURR_DIR=