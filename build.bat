@echo off
REM Сборка xRManager.exe в один файл со своей иконкой.
REM Запускать из папки проекта (там же, где main.py).

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
echo Готово. Файл: dist\xRManager.exe
pause