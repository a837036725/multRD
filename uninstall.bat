@echo off

%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

if exist C:\Windows\System32\termsrv.dll.bak (

net stop termservice /y

takeown /f C:\Windows\System32\termsrv.dll
cacls C:\Windows\System32\termsrv.dll /E /C /G everyone:F

del C:\Windows\System32\termsrv.dll
move C:\Windows\System32\termsrv.dll.bak C:\Windows\System32\termsrv.dll
net start termservice /y

) else (
echo Backup file loss, please manully copy termsrv.dll to C:\Windows\System32\
)
@echo on
pause
