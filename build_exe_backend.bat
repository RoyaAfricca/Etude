@echo off
set "FLUTTER=C:\Users\solta\develop\flutter\bin\flutter.bat"
set "PUB_CACHE=E:\.pub-cache"
set "GRADLE_USER_HOME=E:\.gradle"
set "PROJECT=E:\etude"
set "ISCC=E:\InnoSetup\ISCC.exe"

echo [DEBUT_EXE] %date% %time% > E:\etude\build_exe_log.txt

cd /d E:\etude

echo Nettoyage... >> E:\etude\build_exe_log.txt
call "%FLUTTER%" clean >> E:\etude\build_exe_log.txt 2>&1

echo Compilation Windows... >> E:\etude\build_exe_log.txt
call "%FLUTTER%" build windows --release --obfuscate --split-debug-info=build/windows/outputs/symbols >> E:\etude\build_exe_log.txt 2>&1

if errorlevel 1 (
    echo [BUILD_FAILED] >> E:\etude\build_exe_log.txt
    exit /b 1
)

echo Generation MSIX... >> E:\etude\build_exe_log.txt
call "%FLUTTER%" pub run msix:create >> E:\etude\build_exe_log.txt 2>&1

echo Creation dossier portable... >> E:\etude\build_exe_log.txt
mkdir "Adel\EtudeWindows" 2>nul
xcopy /E /Y /Q "%PROJECT%\build\windows\x64\runner\Release\*" "%PROJECT%\Adel\EtudeWindows\" >> E:\etude\build_exe_log.txt 2>&1

echo Generation Installateur EXE... >> E:\etude\build_exe_log.txt
if exist "%ISCC%" (
    "%ISCC%" "%PROJECT%\installer.iss" >> E:\etude\build_exe_log.txt 2>&1
) else (
    echo INFO: ISCC.exe non trouve >> E:\etude\build_exe_log.txt
)

echo [FIN_EXE] %date% %time% >> E:\etude\build_exe_log.txt
