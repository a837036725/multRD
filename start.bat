@echo off
cls
color 0a
MODE con: COLS=40 LINES=15
:cho
echo.
echo  ===============================
echo         Please Choose
echo  ===============================
echo.
echo  1. install
echo.
echo  2. uninstall
echo.

set rtype=
set /p rtype=  please input the number:
IF NOT "%rtype%"=="" SET rtype=%rtype:~0,1%
if /i "%rtype%"=="1" .\install.bat
if /i "%rtype%"=="2" .\uninstall.bat

goto cho