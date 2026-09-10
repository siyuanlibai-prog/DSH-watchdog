# ============================================================
# DSH Watchdog - 安装开机自启任务
# 以【管理员】身份运行：powershell -File setup-autostart.ps1
# 效果：注册 SYSTEM 开机任务，系统启动后自动拉起 DSH
# ============================================================
param(
    [string]$TaskName = "DHS-Web-Auto"
)

$ErrorActionPreference = "Continue"
$log = Join-Path $PSScriptRoot "setup-autostart.log"
Start-Transcript -Path $log -Append -Force | Out-Null

$startCmd = Join-Path $PSScriptRoot "start-dsh.cmd"

Write-Host "=== 1. 删除旧任务(如有) ==="
schtasks /Delete /TN $TaskName /F 2>&1 | Out-Null

Write-Host "=== 2. 创建开机自启任务 (ONSTART + SYSTEM) ==="
schtasks /Create /TN $TaskName /TR $startCmd /SC ONSTART /RU SYSTEM /RL HIGHEST /F
Write-Host "创建退出码: $LASTEXITCODE"

Write-Host "=== 3. 立即运行任务测试 ==="
schtasks /Run /TN $TaskName
Start-Sleep -Seconds 12

Write-Host "=== 4. 任务状态 ==="
schtasks /Query /TN $TaskName /V /FO LIST 2>&1 | Select-String "状态|Status|上次运行时间|Last Run|上次结果|Last Result|任务要运行|Next Run"

Write-Host "=== 5. 端口检查 ==="
netstat -ano | Select-String "LISTENING" | Select-String ":3080"

Stop-Transcript | Out-Null
