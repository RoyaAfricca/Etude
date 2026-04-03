@echo off
set "FLUTTER=C:\Users\solta\develop\flutter\bin\flutter.bat"
set "ISCC=E:\InnoSetup\ISCC.exe"
set "OUTDIR=E:\etude\website\03042026"

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo [1/4] Build Windows...
call "%FLUTTER%" clean
call "%FLUTTER%" build windows --release
if %errorlevel% neq 0 exit /b %errorlevel%

echo [2/4] Copy to Adel...
if not exist "Adel\EtudeWindows" mkdir "Adel\EtudeWindows"
xcopy /E /Y /Q "build\windows\x64\runner\Release\*" "Adel\EtudeWindows\"

echo [3/4] Inno Setup...
if exist "%ISCC%" (
    "%ISCC%" "installer.iss"
) else (
    echo ISCC not found at %ISCC%
)

echo [4/4] MSIX...
call "%FLUTTER%" pub run msix:create

echo Done.
pause
