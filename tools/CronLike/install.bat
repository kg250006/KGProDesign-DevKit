@echo off
cd /d "%~dp0"
echo Installing dependencies...
pip install -r requirements.txt
echo.
echo Done! Start CronLike with run-CronLike.vbs (no console) or run-debug.bat.
pause
