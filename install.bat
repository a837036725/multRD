@echo off
setlocal enabledelayedexpansion

%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

echo Windows远程桌面多用户登录补丁工具
echo =====================================

:: 获取Windows版本
for /f "tokens=3" %%i in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "ReleaseId" 2^>nul') do (
    set releaseId=%%i
)

:: 如果ReleaseId不存在，尝试获取DisplayVersion (Windows 11)
if "!releaseId!"=="" (
    for /f "tokens=3" %%i in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "DisplayVersion" 2^>nul') do (
        set displayVersion=%%i
        if "%%i"=="21H2" set releaseId=22H2
        if "%%i"=="22H2" set releaseId=22H2
        if "%%i"=="23H2" set releaseId=22H2
    )
)

echo 检测到Windows版本: !releaseId!

:: 定义十六进制补丁
set "original_22H2=39813C0600000F84D9610100"
set "original_2004=39813C0600000F84D9510100"
set "original_20H2=39813C0600000F84D9510100"
set "original_1903=39813C0600000F845D610100"
set "original_1909=39813C0600000F845D610100"
set "original_1803=8B993C0600008BB938060000"
set "replacement=B8000100008981380600009000"

:: 根据版本选择补丁
set "original_pattern="
if "!releaseId!"=="22H2" set "original_pattern=!original_22H2!"
if "!releaseId!"=="2004" set "original_pattern=!original_2004!"
if "!releaseId!"=="20H2" set "original_pattern=!original_20H2!"
if "!releaseId!"=="1903" set "original_pattern=!original_1903!"
if "!releaseId!"=="1909" set "original_pattern=!original_1909!"
if "!releaseId!"=="1803" set "original_pattern=!original_1803!"

:: 如果版本大于22H2或未知版本，尝试通用模式
if "!original_pattern!"=="" (
    echo 未知版本或版本大于22H2，尝试通用模式搜索...
    set "search_pattern=39813C060000"
    set "use_generic=1"
) else (
    set "use_generic=0"
)

:: 停止TermService服务
echo 正在停止TermService服务...
net stop TermService /y >nul 2>&1

:: 获取文件所有权
echo 正在获取文件所有权...
takeown /f C:\Windows\System32\termsrv.dll >nul 2>&1
cacls C:\Windows\System32\termsrv.dll /E /C /G everyone:F >nul 2>&1

:: 备份原始文件
echo 正在备份原始文件...
set bakpath=C:\Windows\System32\termsrv.dll.bak
echo %date:~0,4%_%date:~5,2%_%date:~8,2%_%time:~0,2%_%time:~3,2% > .\chtm
(set/p dt=)< .\chtm
del .\chtm

if exist !bakpath! (
    move !bakpath! "C:\Windows\System32\termsrv.dll_!dt!.bak" >nul 2>&1
    echo 现有备份文件已重命名
)
copy C:\Windows\System32\termsrv.dll !bakpath! >nul 2>&1
echo 文件已备份到: !bakpath!

:: 将dll转换为十六进制
echo 正在转换dll文件为十六进制...
certutil -encodehex C:\Windows\System32\termsrv.dll termsrv_hex.txt 12 >nul 2>&1

:: 处理十六进制文件
echo 正在应用十六进制补丁...

if "!use_generic!"=="1" (
    call :apply_generic_patch
) else (
    call :apply_specific_patch "!original_pattern!" "!replacement!"
)

if !errorlevel! neq 0 (
    echo 补丁应用失败！
    goto restore_backup
)

:: 将修改后的十六进制转换回dll
echo 正在转换十六进制回dll文件...
certutil -decodehex termsrv_hex_patched.txt C:\Windows\System32\termsrv.dll 12 >nul 2>&1

if !errorlevel! neq 0 (
    echo 转换失败！
    goto restore_backup
)

:: 清理临时文件
del termsrv_hex.txt >nul 2>&1
del termsrv_hex_patched.txt >nul 2>&1

:: 启动TermService服务
echo 正在启动TermService服务...
net start TermService /y >nul 2>&1

echo.
echo 补丁应用成功！
echo 建议重启计算机以确保更改生效。
echo.
echo 测试方法:
echo 1. 以管理员权限打开cmd
echo 2. 创建测试用户: net user test password /add
echo 3. 添加到远程桌面用户组: net localgroup "remote desktop users" test /add
echo 4. 使用mstsc连接到127.0.0.2测试

shutdown -r -t 300
echo 系统将在5分钟后重启，如需取消请运行: shutdown -a
goto end

:apply_specific_patch
set "search_hex=%~1"
set "replace_hex=%~2"

:: 读取十六进制文件并处理
powershell -Command "& {$content = Get-Content 'termsrv_hex.txt' | Where-Object {$_ -notmatch '^[0-9a-fA-F]{8}  '} | ForEach-Object {$_ -replace ' ', ''} | Out-String; $content = $content -replace '`r`n', ''; $pattern = '%search_hex%'; $replacement = '%replace_hex%'; if ($content -match $pattern) { Write-Host '找到匹配模式，正在替换...'; $content = $content -replace $pattern, $replacement; $content | Out-File 'termsrv_hex_temp.txt' -Encoding ascii -NoNewline; exit 0 } else { Write-Host '未找到匹配模式'; exit 1 }}"

if !errorlevel! neq 0 (
    echo 未找到指定的十六进制模式
    exit /b 1
)

:: 重新格式化十六进制文件
powershell -Command "& {$content = Get-Content 'termsrv_hex_temp.txt'; $formatted = ''; for ($i = 0; $i -lt $content.Length; $i += 32) { $line = $content.Substring($i, [Math]::Min(32, $content.Length - $i)); $formatted += ('{0:x8}  ' -f ($i/2)) + ($line -replace '(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)','$1 $2 $3 $4 $5 $6 $7 $8 $9 $10 $11 $12 $13 $14 $15 $16').TrimEnd() + \"`r`n\" }; $formatted | Out-File 'termsrv_hex_patched.txt' -Encoding ascii -NoNewline}"

del termsrv_hex_temp.txt >nul 2>&1
exit /b 0

:apply_generic_patch
:: 通用模式：搜索"39813C060000"开头的24位字符
powershell -Command "& {$content = Get-Content 'termsrv_hex.txt' | Where-Object {$_ -notmatch '^[0-9a-fA-F]{8}  '} | ForEach-Object {$_ -replace ' ', ''} | Out-String; $content = $content -replace '`r`n', ''; $pattern = '39813C060000[0-9a-fA-F]{12}'; if ($content -match $pattern) { Write-Host '找到通用模式，正在替换...'; $replacement = '%replacement%'; $content = $content -replace $pattern, $replacement; $content | Out-File 'termsrv_hex_temp.txt' -Encoding ascii -NoNewline; exit 0 } else { Write-Host '未找到通用模式'; exit 1 }}"

if !errorlevel! neq 0 (
    echo 未找到通用十六进制模式
    exit /b 1
)

:: 重新格式化十六进制文件
powershell -Command "& {$content = Get-Content 'termsrv_hex_temp.txt'; $formatted = ''; for ($i = 0; $i -lt $content.Length; $i += 32) { $line = $content.Substring($i, [Math]::Min(32, $content.Length - $i)); $formatted += ('{0:x8}  ' -f ($i/2)) + ($line -replace '(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)(..)','$1 $2 $3 $4 $5 $6 $7 $8 $9 $10 $11 $12 $13 $14 $15 $16').TrimEnd() + \"`r`n\" }; $formatted | Out-File 'termsrv_hex_patched.txt' -Encoding ascii -NoNewline}"

del termsrv_hex_temp.txt >nul 2>&1
exit /b 0

:restore_backup
echo 正在恢复备份文件...
if exist !bakpath! (
    copy !bakpath! C:\Windows\System32\termsrv.dll >nul 2>&1
    echo 已恢复原始文件
)
net start TermService /y >nul 2>&1
goto end

:end
pause
@echo on
