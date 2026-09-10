# ============================================================
# DSH Watchdog - 检查 DSH 服务端口，挂掉就自动拉起
# 由计划任务每隔 N 分钟调用一次（见 setup-watchdog.ps1）
# ============================================================
param(
    [int]$Port = 3080,
    [string]$StartScript = "",
    [string]$LogFile = ""
)

if (-not $StartScript) { $StartScript = Join-Path $PSScriptRoot "start-dsh.cmd" }
if (-not $LogFile)     { $LogFile = Join-Path $PSScriptRoot "watchdog.log" }

$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 检查目标端口是否在监听
$listen = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue

if (-not $listen) {
    # 服务没在运行，重启它
    Add-Content $LogFile "$stamp [WATCHDOG] DSH not running (port $Port closed). Restarting..."
    try {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$StartScript`"" -WindowStyle Hidden
        Add-Content $LogFile "$stamp [WATCHDOG] Restart command issued."
    } catch {
        Add-Content $LogFile "$stamp [WATCHDOG] Restart FAILED: $($_.Exception.Message)"
    }
} else {
    # 服务正常运行；首次运行时初始化日志
    if (-not (Test-Path $LogFile)) {
        Add-Content $LogFile "$stamp [WATCHDOG] DSH is running normally."
    }
}
