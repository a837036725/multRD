@echo off

%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

net stop termservice

takeown /f C:\Windows\System32\termsrv.dll
cacls C:\Windows\System32\termsrv.dll /E /C /G everyone:F

del C:\Windows\System32\termsrv.dll
if exist C:\Windows\System32\termsrv.dll.bak (
move C:\Windows\System32\termsrv.dll.bak C:\Windows\System32\termsrv.dll
net start termservice
) else (
echo 备份文件丢失，请手动拷贝termsrv.dll至C:\Windows\System32
)
@echo on
pause