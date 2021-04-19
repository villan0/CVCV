@echo off
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d D:\a\wallpaper.bmp /f
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
