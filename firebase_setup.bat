@echo off
chcp 65001 >nul
title Kogutopedia - Firebase Setup
echo === Kogutopedia - Firebase Setup ===
echo.

:: Check Firebase CLI
where firebase >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [1/4] Instalowanie Firebase CLI...
    npm install -g firebase-tools
) else (
    echo [1/4] Firebase CLI OK
)

pause
:: Install FlutterFire CLI
echo [2/4] Instalowanie FlutterFire CLI...
C:\tools\flutter\bin\dart.bat pub global activate flutterfire_cli

:: Login to Firebase
echo [3/4] Logowanie do Firebase (otworzy sie przegladarka)...
C:\tools\flutter\bin\dart.bat pub global run flutterfire_cli configure --project=kogutopedia

echo.
echo === Gotowe! ===
echo Teraz mozesz zbudowac apke: flutter build apk --release
pause
