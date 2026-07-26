@echo off
echo === Kogutopedia - Firebase Setup ===
echo.

:: Check Firebase CLI
where firebase >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [1/4] Installing Firebase CLI...
    npm install -g firebase-tools
) else (
    echo [1/4] Firebase CLI already installed
)

:: Install FlutterFire CLI
echo [2/4] Installing FlutterFire CLI...
C:\tools\flutter\bin\dart.bat pub global activate flutterfire_cli

:: Login to Firebase (interactive)
echo [3/4] Please login to Firebase in the browser...
firebase login --no-localhost

:: Configure Firebase
echo [4/4] Configuring Firebase for Kogutopedia...
C:\tools\flutter\bin\dart.bat pub global run flutterfire_cli configure --project=kogutopedia

echo.
echo === Setup complete! ===
echo Now run: flutter pub get
pause
