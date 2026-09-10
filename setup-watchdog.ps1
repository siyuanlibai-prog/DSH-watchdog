# ============================================================
# DSH Watchdog - 安装看门狗计划任务
# 以【管理员】身份运行：powershell -File setup-watchdog.ps1
# 效果：注册一个 SYSTEM 计划任务，每 N 分钟检查一次 DSH 端口
# ============================================================
param(
    [string]$TaskName = "DHS-Watchdog",
    [int]$IntervalMinutes = 2,
    [int]$Port = 3080
)

$ErrorActionPreference = "Continue"
$log = Join-Path $PSScriptRoot "setup-watchdog.log"
Start-Transcript -Path $log -Append -Force | Out-Null

$watchdog = Join-Path $PSScriptRoot "watchdog-dsh.ps1"
$taskCmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $watchdog + '" -Port ' + $Port

Write-Host "=== 1. 删除旧任务(如有) ==="
schtasks /Delete /TN $TaskName /F 2>&1 | Out-Null

Write-Host "=== 2. 创建看门狗任务 (每 $IntervalMinutes 分钟) ==="
schtasks /Create /TN $TaskName /TR $taskCmd /SC MINUTE /MO $IntervalMinutes /RU SYSTEM /RL HIGHEST /F
Write-Host "创建退出码: $LASTEXITCODE"

Write-Host "=== 3. 立即运行一次 ==="
schtasks /Run /TN $TaskName
Start-Sleep -Seconds 5

Write-Host "=== 4. 看门狗日志(应追加新记录) ==="
Get-Content (Join-Path $PSScriptRoot "watchdog.log") -Tail 3 -ErrorAction SilentlyContinue

Write-Host "=== 5. 确认服务端口 ==="
netstat -ano | Select-String "LISTENING" | Select-String ":$Port"

Stop-Transcript | Out-Null
