@echo off

%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

winver

:chover
echo.
echo  ===============================
echo         请选择系统版本
echo  ===============================
echo.
echo  1. 1809
echo.
echo  2. 1903
echo.
echo  3. 1909
echo.
echo  4. 2004
echo.
echo  5. 202H
echo.
echo  6. server2019
echo.
echo  7. 手动输入
echo.

set rtype=
set /p rtype=  please input the number:
IF NOT "%rtype%"=="" SET rtype=%rtype:~0,1%
if /i "%rtype%"=="1" (
set num=1809
goto main
)
if /i "%rtype%"=="2" (
set num=1903
goto main
)
if /i "%rtype%"=="3" (
set num=1909
goto main
)
if /i "%rtype%"=="4" (
set num=2004
goto main
)
if /i "%rtype%"=="5" (
set num=202H
goto main
)
if /i "%rtype%"=="6" (
set num=server2019
goto main
)
if /i "%rtype%"=="7" (
set /p num= 请输入版本号:
goto main
)
goto chover

:main
net stop TermService
takeown /f C:\Windows\System32\termsrv.dll
cacls C:\Windows\System32\termsrv.dll /E /C /G everyone:F
set bakpath=C:\Windows\System32\termsrv.dll.bak
echo %date:~0,4%_%date:~5,2%_%date:~8,2%_%time:~0,2%_%time:~3,2% > .\chtm
(set/p dt=)< .\chtm
del .\chtm
if exist %bakpath% (
move %bakpath% "C:\Windows\System32\termsrv.dll_%dt%.bak"
move C:\Windows\System32\termsrv.dll %bakpath%
) else if exist .\termsrv\termsrv.dll.%num% (
move C:\Windows\System32\termsrv.dll %bakpath%
) else (
echo 未在termsrv文件夹中找到相应的dll文件，请放入文件后重试
echo 文件格式为：termsrv.dll.版本号
goto end
)

copy .\termsrv\termsrv.dll.%num% C:\Windows\System32\termsrv.dll

:end
net start TermService

pause
@echo on
