@echo off
rem ============================================================
rem DSH Watchdog - 启动 DeepSeek Harness Web 服务（被看门狗调用）
rem 请根据你的实际安装环境修改 DSH_BIN 路径
rem ============================================================
setlocal

rem ---- DeepSeek Harness 全局安装的入口脚本 ----
rem 默认：<npm 全局目录>\node_modules\@deepseek-ai\dsh\lib\bin.js
set "DSH_BIN=%USERPROFILE%\AppData\Roaming\npm\node_modules\@deepseek-ai\dsh\lib\bin.js"

rem ---- 如果上面路径不对，可以在这里改成你自己的，例如：----
rem set "DSH_BIN=D:\tools\npm\node_modules\@deepseek-ai\dsh\lib\bin.js"

if not exist "%DSH_BIN%" (
    echo [ERROR] DSH entry not found: %DSH_BIN%
    exit /b 1
)

rem 切到用户主目录，避免路径问题
cd /d "%USERPROFILE%"

rem 以后台方式启动 Web 服务（不自动打开浏览器）
"%ProgramFiles%\nodejs\node.exe" "%DSH_BIN%" web --no-open >> "%~dp0dsh-autostart.log" 2>&1
