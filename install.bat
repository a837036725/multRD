@echo off

%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

for /f "tokens=3"  %%i in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "ReleaseId"') do (
set num=%%i
)

if exist .\termsrv\termsrv.dll.%num% (
goto main
) else (
echo Can not find the right dll file in termsrv folder, please put it into the termsrv folder and try again
echo File type: termsrv.dll.ReleaseId
echo Your ReleaseId: %num%
goto end
)

:main
net stop TermService /y
takeown /f C:\Windows\System32\termsrv.dll
cacls C:\Windows\System32\termsrv.dll /E /C /G everyone:F
set bakpath=C:\Windows\System32\termsrv.dll.bak
echo %date:~0,4%_%date:~5,2%_%date:~8,2%_%time:~0,2%_%time:~3,2% > .\chtm
(set/p dt=)< .\chtm
del .\chtm
if exist %bakpath% (
move %bakpath% "C:\Windows\System32\termsrv.dll_%dt%.bak"
move C:\Windows\System32\termsrv.dll %bakpath%
) else (
move C:\Windows\System32\termsrv.dll %bakpath%
)

copy .\termsrv\termsrv.dll.%num% C:\Windows\System32\termsrv.dll
net start TermService /y

:end
pause
@echo on
