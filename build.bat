@echo off
REM
REM

pip install --upgrade pyinstaller

pyinstaller ^
  --onefile ^
  --noconsole ^
  --name xRManager ^
  --icon=assets\ico.ico ^
  --add-data "gui;gui" ^
  --add-data "assets;assets" ^
  --collect-all webview ^
  --collect-all clr_loader ^
  --collect-all pythonnet ^
  main.py

echo.
echo Файл - .\dist\xRManager
pause
