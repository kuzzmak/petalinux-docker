@echo off
setlocal enabledelayedexpansion

REM Initialize variables
set plnx_ver=

REM Parse arguments
:parse
if "%~1"=="" goto :validate
if "%~1"=="--plnx_ver" (
    set plnx_ver=%~2
    if "%~2"=="" (
        echo Error: --plnx_ver requires a value
        goto :error
    )
    shift
) else (
    echo Error: Unknown argument %~1
    goto :error
)
shift
goto :parse

:validate
if "%plnx_ver%"=="" (
    echo Error: --plnx_ver is required
    goto :error
)

REM If validation passes, print the variables
echo Building petalinux build image for version %plnx_ver%
goto :end

:error
echo Usage: example.bat --plnx_ver version
exit /b 1

:end

set plnx_installers_dir="C:\Users\tonkec\Documents\petalinux\installers"
set plnx_installer_dir=%plnx_installers_dir%\%plnx_ver%

REM Check if the directory exists
if not exist "%plnx_installer_dir%" (
    echo Petalinux directory with installer does not exist on path "%plnx_installer_dir%".
    exit /b 1
)

for /r "%plnx_installer_dir%" %%f in (*) do (
    set plnx_installer=%%f
)

if not exist "%plnx_installer%" (
    echo Petalinux installer not found in directory "%plnx_installer_dir%".
    exit /b 1
)

echo Petalinux installer found: %plnx_installer%

REM Set the image name
set IMAGE_NAME=build-plnx

REM Extract the filename from the full path
for %%f in ("%plnx_installer%") do set FILENAME=%%~nxf

REM Remove the prefix 'petalinux-v'
set TEMP=%FILENAME:petalinux-v=%

REM Extract the version number up to the first '-'
for /f "tokens=1 delims=-" %%a in ("%TEMP%") do set PLNX_VER=%%a

REM Build the Docker image
docker build ^
    -f Dockerfile ^
    --build-arg="PLNX_VER=%PLNX_VER%" ^
    --build-arg="INSTALLER_NAME=%FILENAME%" ^
    -t %IMAGE_NAME%:%PLNX_VER% ^
    --build-context installers=%plnx_installer_dir% .

REM Check if the build was successful
if %errorlevel% neq 0 (
    echo Docker build failed!
    exit /b %errorlevel%
)

echo Docker image %IMAGE_NAME%:%PLNX_VER% built successfully!
