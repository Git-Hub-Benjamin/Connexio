@echo off
REM Connexio Launcher Script for Windows
REM Place this in a folder in your PATH

set CONNEXIO_PATH=%LOCALAPPDATA%\Connexio\connexio.exe

if exist "%CONNEXIO_PATH%" (
    start "" "%CONNEXIO_PATH%" %*
) else if exist "build\windows\x64\runner\Release\connexio.exe" (
    start "" "build\windows\x64\runner\Release\connexio.exe" %*
) else (
    echo Connexio not found. Please build first with setup.sh
    exit /b 1
)
