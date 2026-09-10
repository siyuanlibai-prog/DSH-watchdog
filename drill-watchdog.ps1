# ============================================================
# DSH Watchdog - 故障演练：模拟服务挂掉，验证看门狗自动拉起
# 以【管理员】身份运行：powershell -File drill-watchdog.ps1
# 注意：会强制结束当前 3080 端口的进程
# ============================================================
param(
    [int]$Port = 3080,
    [int]$WaitSeconds = 12
)

$ErrorActionPreference = "Continue"
$log = Join-Path $PSScriptRoot "drill-watchdog.log"
Start-Transcript -Path $log -Append -Force | Out-Null

Write-Host "=== 1. 模拟故障: 强制结束 $Port 端口的服务进程 ==="
$pids = (netstat -ano | Select-String ":$Port" | Select-String "LISTENING" | ForEach-Object { ($_ -split '\s+')[-1] }) | Select-Object -Unique
foreach ($p in $pids) {
    if ($p -match '^\d+$') {
        Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
        Write-Host "已结束 PID: $p"
    }
}
Start-Sleep -Seconds 3

Write-Host "=== 2. 确认端口已停止 ==="
$still = netstat -ano | Select-String ":$Port" | Select-String "LISTENING"
if (-not $still) { Write-Host "端口已停止监听 (故障状态确认)" }

Write-Host "=== 3. 手动触发一次看门狗 ==="
powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "watchdog-dsh.ps1") -Port $Port
Write-Host "看门狗已执行"

Write-Host "=== 4. 等待服务启动 ==="
Start-Sleep -Seconds $WaitSeconds

Write-Host "=== 5. 确认端口已恢复 ==="
netstat -ano | Select-String "LISTENING" | Select-String ":$Port"

Write-Host "=== 6. 看门狗日志(最后6条) ==="
Get-Content (Join-Path $PSScriptRoot "watchdog.log") -Tail 6 -ErrorAction SilentlyContinue

Stop-Transcript | Out-Null
