# ============================================================
# DSH Watchdog - 可选组件：桌面小狗宠物（看门狗的可视化形态）
# 一只会走路的小狗在桌面上小跑；右键或双击退出。
# 依赖素材：assets/dog-frame-0.png ~ dog-frame-5.png（6 帧走路动画）
# 运行：powershell -STA -File watchdog-pet.ps1
# ============================================================
param(
    [string]$AssetDir = ""
)

if (-not $AssetDir) { $AssetDir = Join-Path $PSScriptRoot "assets" }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 单实例保护：如果已有一只小狗在跑，新启动的直接退出
$me = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "watchdog-pet\.ps1" -and $_.ProcessId -ne $PID }
if ($me) { exit }

# 加载 6 帧走路动画（朝右跑）
$framesRight = @()
for ($i = 0; $i -lt 6; $i++) {
    $path = Join-Path $AssetDir ("dog-frame-{0}.png" -f $i)
    if (-not (Test-Path $path)) {
        Write-Host "素材缺失: $path （请在 assets 目录放置 dog-frame-0~5.png 六帧动画）"
        exit 1
    }
    $framesRight += [System.Drawing.Image]::FromFile($path)
}

# 预生成朝左的镜像帧
$framesLeft = @()
foreach ($f in $framesRight) {
    $clone = $f.Clone()
    $clone.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
    $framesLeft += $clone
}

$w = $framesRight[0].Width
$h = $framesRight[0].Height

$pet = New-Object System.Windows.Forms.Form
$pet.FormBorderStyle = 'None'
$pet.StartPosition = 'Manual'
$pet.ShowInTaskbar = $false
$pet.TopMost = $true
$pet.BackColor = [System.Drawing.Color]::Magenta
$pet.TransparencyKey = [System.Drawing.Color]::Magenta
$pet.Size = New-Object System.Drawing.Size($w, $h)
$pet.DoubleBuffered = $true
$pet.Text = "Watchdog Pet"

$pb = New-Object System.Windows.Forms.PictureBox
$pb.Size = New-Object System.Drawing.Size($w, $h)
$pb.Location = New-Object System.Drawing.Point(0, 0)
$pb.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
$pb.BackColor = [System.Drawing.Color]::Magenta
$pb.Image = $framesRight[0]
$pet.Controls.Add($pb)

$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$pet.Location = New-Object System.Drawing.Point(($wa.Right - 300), ($wa.Bottom - 150))

# 随机游荡
$rnd = New-Object System.Random
$script:vx = 3
$script:vy = 2

# 走路动画：切换帧
$script:frameIdx = 0
$anim = New-Object System.Windows.Forms.Timer
$anim.Interval = 110
$anim.Add_Tick({
    $script:frameIdx = ($script:frameIdx + 1) % 6
    if ($script:vx -lt 0) { $pb.Image = $framesLeft[$script:frameIdx] }
    else { $pb.Image = $framesRight[$script:frameIdx] }
})
$anim.Start()

# 移动游走
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60
$timer.Add_Tick({
    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $p = $pet.Location
    $x = $p.X + $script:vx
    $y = $p.Y + $script:vy
    if ($x -lt 0 -or $x -gt ($wa.Right - $w)) {
        $script:vx = -$script:vx
        $x = [Math]::Max(0, [Math]::Min($x, ($wa.Right - $w)))
    }
    if ($y -lt 0 -or $y -gt ($wa.Bottom - $h)) {
        $script:vy = -$script:vy
        $y = [Math]::Max(0, [Math]::Min($y, ($wa.Bottom - $h)))
    }
    if ($rnd.Next(140) -eq 0) {
        $script:vx = $rnd.Next(-5, 6)
        $script:vy = $rnd.Next(-3, 4)
        if ($script:vx -eq 0 -and $script:vy -eq 0) { $script:vx = 2 }
    }
    $pet.Location = New-Object System.Drawing.Point($x, $y)
})
$timer.Start()

# 右键菜单：退出（看门狗下班）
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$itemExit = New-Object System.Windows.Forms.ToolStripMenuItem("退出看门狗")
$itemExit.Add_Click({
    $timer.Stop()
    $anim.Stop()
    $pet.Close()
})
[void]$menu.Items.Add($itemExit)
$pet.ContextMenuStrip = $menu

# 双击退出
$pet.Add_DoubleClick({
    $timer.Stop()
    $anim.Stop()
    $pet.Close()
})

$pet.Add_FormClosing({
    foreach ($f in $framesRight) { $f.Dispose() }
    foreach ($f in $framesLeft) { $f.Dispose() }
})

[System.Windows.Forms.Application]::Run($pet)
