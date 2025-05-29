@echo off
setlocal enabledelayedexpansion

%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

echo Windows远程桌面多用户登录补丁卸载工具
echo =======================================

:: 检查备份文件是否存在
set bakpath=C:\Windows\System32\termsrv.dll.bak

if not exist !bakpath! (
    echo 错误: 备份文件不存在 (!bakpath!)
    echo 请检查是否存在带时间戳的备份文件，如：
    echo C:\Windows\System32\termsrv.dll_yyyy_mm_dd_hh_mm.bak
    echo 如果存在，请手动重命名为 termsrv.dll.bak 后重新运行此脚本
    goto end
)

echo 找到备份文件: !bakpath!

:: 停止TermService服务
echo 正在停止TermService服务...
net stop TermService /y >nul 2>&1

:: 获取文件所有权
echo 正在获取文件所有权...
takeown /f C:\Windows\System32\termsrv.dll >nul 2>&1
cacls C:\Windows\System32\termsrv.dll /E /C /G everyone:F >nul 2>&1

:: 删除当前的dll文件
echo 正在删除修改后的dll文件...
del C:\Windows\System32\termsrv.dll >nul 2>&1

:: 恢复备份文件
echo 正在恢复原始dll文件...
move !bakpath! C:\Windows\System32\termsrv.dll >nul 2>&1

if !errorlevel! neq 0 (
    echo 恢复失败！请手动复制备份文件
    goto end
)

:: 启动TermService服务
echo 正在启动TermService服务...
net start TermService /y >nul 2>&1

echo.
echo 原始dll文件已成功恢复！
echo 远程桌面多用户登录功能已禁用。
echo 建议重启计算机以确保更改生效。

:end
pause
@echo on
