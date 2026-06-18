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
REM   - webview_windows 0.4.0's native plugin uses deprecated <experimental/coroutine>,
REM     which newer MSVC toolchains (the "Visual Studio 18" preview installed here) reject
REM     outright. Patched by adding this line to the END of:
REM       %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\webview_windows-0.4.0\windows\CMakeLists.txt
REM     target_compile_definitions(${PLUGIN_NAME} PRIVATE _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)
REM     This lives in the GLOBAL pub cache, not this repo -- if you clear the pub cache,
REM     reinstall Flutter, or build on another machine, you'll need to reapply this patch
REM     (run `flutter pub get` once first so the package gets fetched, then edit that file).

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
