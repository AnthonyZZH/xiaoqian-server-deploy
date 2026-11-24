---
name: xiaoqian-server-deploy
description: Deploy the 小千 (xiaoqian-wechat server edition) WeChat bot and the QQ/NapCat stack onto a dedicated Windows cloud server (Alibaba Cloud ECS, Windows Server 2022) — buying and locking down the server, installing QQ+NapCat and WeChat 4.x, configuring the DeepSeek API brain, keeping the headless desktop rendering, auto-restart, verification without sending, and troubleshooting. Use when setting up, rebuilding, migrating or debugging such a server.
---

# 小千服务器部署

把「小千」放到一台独立的 Windows 云服务器上，24 小时在 QQ / 微信里聊天。微信端用
[xiaoqian-wechat 的 `server` 分支](https://github.com/AnthonyZZH/xiaoqian-wechat/tree/server)（DeepSeek API 当大脑），QQ 端用 QQ + NapCat（OneBot）。

脚本在 `scripts/`，按编号顺序执行；都以管理员 PowerShell 运行，默认目录 `C:\xiaoqian\`。
所有脚本**遇到已存在的东西就停**，不会覆盖；出错只打印固定事件码，不打印令牌、聊天内容。
踩过的坑见 [references/troubleshooting.md](references/troubleshooting.md)，**动手前先读一遍**。

## 0. 原则

- **服务器专用**：不要和个人电脑共用，不要用"云电脑"（服务商能看到桌面）。
- **小号**：QQ、微信都用小号，主人用大号跟她聊。
- **微信是熟人圈，按"好用"配置**；QQ 进陌生人群，按"严格"配置。不要把 QQ 那套限制搬到微信上。
- **密钥只走文件，不进聊天、不进命令行、不进日志**：DeepSeek key 放机器环境变量 `XQ_DEEPSEEK_API_KEY`。
- 改服务器之前先备份（`*.bak-before-xxx`），部署时校验文件哈希。

## 1. 买服务器（主人操作）

- 阿里云 ECS，**Windows Server 2022 中文版**，**4 核 8G**（如 ecs.e-c1m2.xlarge），系统盘 40G 以上；国内地域（QQ/微信登录更稳）。
- 2 核不够：微信 + QQ + NapCat + Python 界面自动化会卡。
- 免费试用/按量付费到期前记得转包年包月。
- **安全组**入方向只放行：`3389`（远程桌面）和 `22`（SSH），来源只填**自己家宽带的公网 IP**。家里 IP 变了要去控制台改；连不上时可用「云助手」发命令（不受安全组限制）。

## 2. 远程管理通道

1. 远程桌面登录（电脑 `mstsc`，手机 App Store「Windows App」，开发商 Microsoft）。手机必须连家里 Wi-Fi（安全组只放行家里 IP）。
2. 开 OpenSSH Server，**只允许公钥**：`PasswordAuthentication no`、`KbdInteractiveAuthentication no`，管理员公钥写入 `C:\ProgramData\ssh\administrators_authorized_keys`（ACL 仅 Administrators/SYSTEM）。默认 shell 设成 PowerShell。
3. 之后用 `ssh -i <私钥> administrator@<服务器IP>` 操作。多行脚本：本地写好 → `scp` 到 `C:/xiaoqian/setup/` → `powershell -File` 执行。

## 3. 基础环境

```
scripts/01-preflight.ps1        # 只读检查：系统、C 盘剩余、python/node/git
scripts/02-directories.ps1      # 建 C:\xiaoqian\{app,data}\{wechat,qq,...}
scripts/03-firewall.ps1         # 开防火墙（默认放行），让后面的出站拦截生效
scripts/05-block-third-party-sign.ps1   # 拦截 NapCat 可选的第三方签名服务（hosts + 出站规则）
```

装：Python 3.12、Node LTS、Git、**VC++ x64 运行库**（没有它 NapCat 报 MSVCP140.dll 缺失）。国内镜像：pip 用阿里云、npm 用 npmmirror。
所有安装包从官网下载，**核对 Authenticode 签名是腾讯/微软**再装。

## 4. QQ + NapCat（可选）

```
scripts/06a-qq-install.ps1 -Installer <QQ安装包> -ExpectedSha256 <哈希>
scripts/06b-napcat-extract.ps1 -Installer <NapCat.Shell.zip> -ExpectedSha256 <哈希>
scripts/06c-napcat-webui.ps1    # WebUI 只监听 127.0.0.1，随机 64 位令牌
```
主人在远程桌面里登录 QQ 小号一次，然后：
```
scripts/06d-onebot-config.ps1   # OneBot WebSocket 127.0.0.1:3001，独立随机令牌
scripts/06e-napcat-shortcut.ps1 # 生成 NapCat 快速登录快捷方式（QQ 号从本机目录读取，不写进脚本）
```
验证：不带令牌/错令牌连 `ws://127.0.0.1:3001` 必须被拒（1403）。
NapCat 控制台窗口**不要用鼠标点**，点了会进入"选择"模式卡住，按 Esc 退出。

## 5. 微信（xiaoqian-wechat server 分支）

```
scripts/07a-wechat-client.ps1 -Installer <WeChat 4.x 安装包> -ExpectedSha256 <哈希>
scripts/07b-get-wechat-app.ps1  # git clone server 分支到 C:\xiaoqian\app\wechat，数据目录 ACL 收紧
scripts/07c-dependencies.ps1    # venv + requirements
```
- 必须是**微信 4.x**（`mmui::MainWindow`，已在 4.2.0.9 上验证）；3.9 不兼容。
- 微信设置里**关掉自动更新**；升级后先跑第 8 节的不发送测试再上线。
- 准备 `C:\xiaoqian\data\wechat\xq-wechat-chats.json`（允许的聊天、主人名、别名等）和人设文本 `C:\xiaoqian\data\shared\persona-social.txt`，然后：
```
scripts/07d-configure.ps1       # 生成 settings.json 和人设；模型 deepseek-flash，读 XQ_DEEPSEEK_API_KEY
```
- 主人把 DeepSeek key 写进机器环境变量 `XQ_DEEPSEEK_API_KEY`（由主人自己操作，或从文件读取后写入并删除临时文件）。
- 想要原来的旧记忆/聊天历史：旧项目的 memory/history/senders 要按新命名（聊天类型+名字的哈希）转换后再拷，不能直接复制。
- 表情包库：把旧项目 `data/stickers/`（图片 + `index.json`，描述就在 index 里）拷到 `C:\xiaoqian\data\wechat\stickers\`；`_inbox` 是未审核的，按需。

## 6. 让无人值守的桌面一直"活着"

UI 自动化靠截屏判断消息是谁发的，**桌面必须在渲染、微信不能被挡住**。

```
scripts/08b-register-console-keeper.ps1   # RDP 断开（事件 24）→ 自动 tscon 回控制台
scripts/08c-console-now.ps1               # 手动立刻切回控制台
```
- server 分支的适配器会在每次读消息前**把微信置顶**，并把盖在上面的其他程序窗口最小化（`XQ_WECHAT_KEEP_FRONT=0` 可关）。
- **远程桌面用完要"断开"**，不要只把手机 App 切到后台——后台不算断开，屏幕停止刷新，面板会报 `screen grab failed`。

## 7. 启动与守护

```
scripts/09c-register-watchdog.ps1   # 安装 run_panel.py + 每 5 分钟检查，没在跑就拉起（自动开始）
```
- `run_panel.py`：设置数据目录、`--start` 自动开始、把硬崩溃现场写进 `C:\xiaoqian\data\wechat\logs\crash.log`。
- 手动开面板用 `09-Start-Xiaoqian-WeChat.cmd`（不自动开始）。
- 面板「同时照看所有已允许的聊天」勾上=多聊天模式；停机期间收到的消息**不会补回**（设计如此）。

## 8. 验证（不发消息）

从 SSH 不能直接操作桌面，用一次性交互计划任务：
```
scripts/10a-run-in-desktop.ps1 -Script C:\xiaoqian\setup\10b-no-send-test.py
```
`10b-no-send-test.py`：在主人私聊读一轮 → 调 DeepSeek → **拦截发送**，只记录回复长度和哈希。期望 `send_blocked`、`read_whitelisted_chat: true`。
先在微信里打开主人私聊、最后一条是主人发来的文字。

再让主人用大号实测：普通聊天、让她"去某群说一句"、"给某人发消息"（会在群里 @他）、发图、斗图、套提示词/读文件（应拒绝）。

## 9. 清理

```
scripts/11c-register-daily-dryrun.ps1   # 每天 03:30 只出报告（不删除）
scripts/11a-cleanup.ps1 -Apply          # 确认报告无误后再手动/定时 -Apply：媒体缓存 7 天、日志 14 天，C 盘 < 5GB 告警
```

## 10. 更新代码

- 改动以补丁形式维护、构建时校验哈希；部署时**逐文件哈希校验**、先备份、再重启面板（停掉 pythonw，看门狗会拉起）。
- 部署后跑第 8 节验证；有错先看面板日志区（会显示真实原因）和 `crash.log`。
