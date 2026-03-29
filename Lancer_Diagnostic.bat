@echo off
title Diagnostique de lancement - Etude App
color 0E

:: Force le dossier de travail sur le projet principal
cd /d "e:\etude"

echo ==========================================================
echo   Lancement de l'application en mode diagnostique...
echo   (Veuillez patienter, Flutter va afficher les erreurs ici)
echo ==========================================================
echo.

call C:\Users\solta\develop\flutter\bin\flutter.bat run -d windows

echo.
echo ==========================================================
echo   Le programme s'est arrete. Lisez l'erreur au-dessus.
echo ==========================================================
pause
exit /b
