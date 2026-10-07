@echo off
title TravelPool
cd /d "%~dp0"
echo ==================================================
echo   TravelPool - starting up
echo ==================================================
echo.
echo [1/2] Checking dependencies...
call npm install
if errorlevel 1 goto failed
echo.
set BROWSER=chrome
echo [2/2] Starting backend + frontend...
echo The app will open at http://localhost:5173
echo Press Ctrl+C twice in this window to stop.
echo.
call npm run dev
goto end
:failed
echo.
echo Dependency install failed. Check your internet connection and try again.
:end
echo.
pause
