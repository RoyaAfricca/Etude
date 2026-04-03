@echo off
set PUB_CACHE=E:\.pub-cache
set GRADLE_USER_HOME=E:\.gradle
cd /d E:\etude

echo [DEBUT] %date% %time% > E:\etude\build_log.txt

C:\Users\solta\develop\flutter\bin\flutter.bat build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build/app/outputs/symbols >> E:\etude\build_log.txt 2>&1

if exist "E:\etude\build\app\outputs\flutter-apk\app-release.apk" (
    echo [BUILD_SUCCESS] >> E:\etude\build_log.txt
    if not exist "E:\etude\Adel" mkdir "E:\etude\Adel"
    copy /Y "E:\etude\build\app\outputs\flutter-apk\app-release.apk" "E:\etude\Adel\application_etude.apk"
    if not exist "E:\etude\final" mkdir "E:\etude\final"
    copy /Y "E:\etude\build\app\outputs\flutter-apk\app-release.apk" "E:\etude\final\application_etude_1.2.1.apk"
    copy /Y "E:\etude\build\app\outputs\flutter-apk\app-release.apk" "E:\etude\website\etude_app_arm64.apk"
    echo [COPIE_OK] >> E:\etude\build_log.txt
) else (
    echo [BUILD_FAILED] >> E:\etude\build_log.txt
)

echo [FIN] %date% %time% >> E:\etude\build_log.txt
