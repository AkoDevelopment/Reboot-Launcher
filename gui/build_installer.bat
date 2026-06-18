@echo off
REM Rebuilds the Project Ocean launcher installer and copies it to
REM C:\Users\khana\installer-output with the standard naming convention.
REM
REM Requirements (one-time setup):
REM   - Flutter SDK on PATH (or installed at C:\Users\khana\develop\flutter)
REM   - dart pub global activate flutter_distributor
REM   - Inno Setup 6 installed. If installed outside "C:\Program Files (x86)\Inno Setup 6",
REM     create a junction there pointing at the real install:
REM       mklink /J "C:\Program Files (x86)\Inno Setup 6" "<real install path>"

setlocal

set PATH=%PATH%;C:\Users\khana\develop\flutter\bin;C:\Users\khana\AppData\Local\Pub\Cache\bin

cd %~dp0

call flutter clean
call flutter_distributor package --platform windows --target exe
if errorlevel 1 (
    echo Build failed.
    exit /b 1
)

for /f "delims=" %%v in ('powershell -NoProfile -Command "(Get-Content pubspec.yaml | Select-String '^version:').ToString().Split(':')[1].Trim().Trim('\"')"') do set APP_VERSION=%%v

set SRC=dist\%APP_VERSION%\Output\reboot_launcher-%APP_VERSION%-windows-setup.exe
set DEST=C:\Users\khana\installer-output\ProjectOcean-%APP_VERSION%-windows-setup.exe

if not exist "%SRC%" (
    echo Could not find built installer at %SRC%
    exit /b 1
)

copy /Y "%SRC%" "%DEST%"
echo.
echo Installer copied to %DEST%
