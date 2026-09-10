# 🐕 DSH Watchdog — DeepSeek Harness 看门狗

> 让本地运行的 DeepSeek Harness 服务（默认端口 `3080`）永不掉线：**挂了自动拉起、开机自动启动、故障自动恢复**，还附赠一只会走路的桌面小狗。

A lightweight watchdog toolkit for locally-hosted [DeepSeek Harness](https://github.com/deepseek-ai) services. It monitors the service port, restarts the process when it dies, auto-starts on boot, and ships with an optional desktop pet.

---

## ✨ 功能特性

| 能力 | 说明 |
|---|---|
| 🔍 端口守护 | 每隔 N 分钟（默认 2 分钟）检查服务端口，未监听则自动拉起 |
| 🚀 开机自启 | 注册 SYSTEM 开机任务，系统启动后自动运行服务 |
| 🧯 故障演练 | 一键模拟服务挂掉，验证看门狗能否自动恢复 |
| 🐶 桌面宠物（可选） | 一只在桌面小跑的小狗，右键/双击即可退出 |
| 🛡️ 系统级守护 | 计划任务以 `SYSTEM` + 最高权限运行，普通用户无法误杀 |
| 📝 完整日志 | 每次检测、重启动作都记录到日志文件 |

---

## 🧠 工作原理

```
┌─────────────────────────────────────────────────────────────┐
│                    Task Scheduler（系统计划任务）              │
│                                                             │
│   DHS-Watchdog（每 2 分钟）  ──►  watchdog-dsh.ps1           │
│                                    │ 检查端口 3080           │
│                                    ▼                       │
│                           ┌─ 正在监听 ─► 无事发生            │
│                           │                                │
│                           └─ 未监听 ──► start-dsh.cmd       │
│                                         │ 启动 node 进程     │
│                                         ▼                   │
│                              DeepSeek Harness Web 服务       │
│                                                             │
│   DHS-Web-Auto（开机）  ──►  start-dsh.cmd（系统启动即拉起）   │
└─────────────────────────────────────────────────────────────┘
```

两个计划任务互为补充：

- **DHS-Watchdog**：周期性巡检，解决"服务运行中意外挂掉"的问题（进程被杀、崩溃、端口被占释放等）；
- **DHS-Web-Auto**：开机兜底，解决"重启电脑后服务没起来"的问题。

> 💡 为什么用 `SYSTEM` 账户跑？因为服务进程运行在 Session 0（系统会话），普通用户权限（即使管理员）也**杀不掉**它，只有 SYSTEM 级别的任务才能完成重启动作。这也是本项目最核心的"坑"——详见 [常见问题](#-常见问题)。

---

## 📁 目录结构

```
dsh-watchdog/
├── watchdog-dsh.ps1      # 核心守护脚本：检查端口 → 拉起服务
├── start-dsh.cmd         # 服务启动命令（按你的环境改 DSH_BIN 路径）
├── setup-watchdog.ps1    # 一键注册看门狗计划任务（管理员运行）
├── setup-autostart.ps1   # 一键注册开机自启任务（管理员运行）
├── drill-watchdog.ps1    # 故障演练：模拟挂掉并验证自动恢复（管理员运行）
├── watchdog-pet.ps1      # [可选] 桌面小狗宠物
├── start-pet.vbs         # [可选] 宠物隐藏启动器（可配开机自启）
├── assets/               # [可选] 宠物素材目录（dog-frame-0~5.png）
└── README.md
```

---

## 🚀 快速开始

### 环境要求

- Windows 10 / 11
- 已全局安装 DeepSeek Harness：`npm install -g @deepseek-ai/dsh`
- 管理员权限（注册计划任务需要）

### 第 1 步：配置启动命令

编辑 `start-dsh.cmd`，确认 `DSH_BIN` 指向你的 DSH 入口：

```bat
set "DSH_BIN=%USERPROFILE%\AppData\Roaming\npm\node_modules\@deepseek-ai\dsh\lib\bin.js"
```

> 不同安装方式入口不同，例如用 `npx` 或自定义目录安装时，改成你自己的绝对路径即可。可以先手动双击运行一次，确认能正常拉起服务（日志写入 `dsh-autostart.log`）。

### 第 2 步：注册看门狗任务

以管理员身份打开 PowerShell：

```powershell
# 注册每 2 分钟巡检一次的看门狗
powershell -ExecutionPolicy Bypass -File .\setup-watchdog.ps1

# 注册开机自启
powershell -ExecutionPolicy Bypass -File .\setup-autostart.ps1
```

### 第 3 步：验证

```powershell
# 查看两个任务
schtasks /Query /TN DHS-Watchdog /V /FO LIST
schtasks /Query /TN DHS-Web-Auto /V /FO LIST

# 查看看门狗日志
Get-Content .\watchdog.log -Tail 10
```

看到日志类似 `[WATCHDOG] DHS is running normally.` 即表示巡检正常。

---

## 🧯 故障演练（可选）

确认"挂了能自动拉起"最直接的方式——模拟故障：

```powershell
# 管理员运行：强制结束 3080 端口进程 → 触发看门狗 → 等待恢复 → 验证
powershell -ExecutionPolicy Bypass -File .\drill-watchdog.ps1
```

预期输出：`已结束 PID: xxxx` → `看门狗已执行` → 端口恢复监听。

---

## 🐶 桌面宠物（可选）

如果想让看门狗"看得见"：

1. 在 `assets\` 目录放置 6 帧小狗走路动画：`dog-frame-0.png` ~ `dog-frame-5.png`（建议透明背景 PNG，尺寸一致）；
2. 运行：
   ```powershell
   powershell -STA -ExecutionPolicy Bypass -File .\watchdog-pet.ps1
   ```
3. 想要开机自启：创建一个快捷方式指向 `start-pet.vbs`，放入 `shell:startup` 文件夹。

> 素材缺失时脚本会给出提示，不影响其他组件使用。

---

## 🧹 卸载

```powershell
# 管理员：删除两个计划任务
schtasks /Delete /TN DHS-Watchdog /F
schtasks /Delete /TN DHS-Web-Auto /F

# 可选：杀掉当前服务进程（先确认不再需要）
```

删除本项目目录即完成全部清理。任务删除后看门狗不会再拉起任何进程。

---

## ⚙️ 脚本详解

### watchdog-dsh.ps1 — 核心守护

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-Port` | `3080` | 要守护的服务端口 |
| `-StartScript` | 同目录 `start-dsh.cmd` | 拉起服务的启动命令 |
| `-LogFile` | 同目录 `watchdog.log` | 日志文件路径 |

### setup-watchdog.ps1 — 注册巡检任务

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-TaskName` | `DHS-Watchdog` | 计划任务名 |
| `-IntervalMinutes` | `2` | 巡检间隔（分钟） |
| `-Port` | `3080` | 传给守护脚本的端口 |

### setup-autostart.ps1 — 注册开机任务

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-TaskName` | `DHS-Web-Auto` | 计划任务名 |

---

## ❓ 常见问题

**Q：为什么我杀了进程，过几分钟又活了？**
A：因为 `DHS-Watchdog` 任务在巡检。这是设计行为——它就是来防止服务挂掉的。要停掉服务，先删除/禁用该任务。

**Q：为什么普通管理员也杀不掉服务进程？**
A：服务以 `SYSTEM` 身份运行在 Session 0，普通提权（管理员）进程对 Session 0 进程没有终止权限。用 SYSTEM 计划任务或 `psexec -s` 才能杀。

**Q：我明明删了任务，怎么还在运行？**
A：检查是否存在**带受限安全描述符**的任务——这类任务在普通权限下用 `Get-ScheduledTask` / `schtasks` 查不到（列表会少一截），需要**管理员权限**（UAC 提升）才能看到和删除。这是 Windows Task Scheduler 的隐藏机制。

**Q：巡检间隔可以更短吗？**
A：可以，`setup-watchdog.ps1 -IntervalMinutes 1` 即可（更短会提高系统开销，不建议低于 1 分钟）。

**Q：端口不是 3080 怎么办？**
A：所有脚本都支持 `-Port` 参数，注册任务时一并传入即可：
```powershell
.\setup-watchdog.ps1 -Port 4000
```

---

## ⚠️ 安全说明

- 本项目**不包含任何密钥、凭证或用户数据**，只包含守护逻辑脚本；
- 计划任务以 `SYSTEM` 权限运行，请确保脚本目录不被不可信用户写入（防止脚本被替换）；
- 本项目是独立的运维工具，与 DeepSeek Harness 官方无关联。

---

## 📄 License

[MIT](LICENSE)
