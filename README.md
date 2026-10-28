# xiaoqian-server-deploy · 小千服务器部署

把 AI 群友「小千」部署到一台**独立的 Windows 云服务器**上，让她 24 小时在微信和 QQ 里聊天：私聊、群聊、主动接话、记住每个人、发表情包、看图、替主人去别的群说话并 @ 人。

这个仓库是一个 **Claude Code / Agent skill**：

| 文件 | 内容 |
|---|---|
| [`SKILL.md`](SKILL.md) | 完整部署流程（10 节，从买服务器到上线、更新） |
| [`scripts/`](scripts) | 按编号执行的 PowerShell / Python 脚本，都是实际部署用过的 |
| [`references/troubleshooting.md`](references/troubleshooting.md) | 排错手册：现象 → 根因 → 解法 |

## 小千全家桶

| 仓库 | 是什么 |
|---|---|
| [小千 · 本地版](https://github.com/AnthonyZZH/xiaoqian-wechat) | 自己电脑上跑，LM Studio 本地模型，画图、派活给 agent |
| [小千 · 服务器版](https://github.com/AnthonyZZH/xiaoqian-wechat/tree/server) | 云服务器 24 小时在线，DeepSeek API，转告、@人、识图 |
| **服务器部署 skill**（当前） | 从买服务器到上线的流程、脚本和排错手册 |
| [她的图书馆](https://github.com/AnthonyZZH/ai-memory-public) | 多个 AI 共用的长期记忆、人格、成长引擎和社交补丁（去隐私公开版） |

## 部署出来是什么样

```
你的手机微信/QQ（大号）
        │  聊天
        ▼
┌──────────── Windows 云服务器（4 核 8G，Windows Server 2022）────────────┐
│  微信 4.x（小号） ◄── UI 自动化 ── xiaoqian-wechat server 分支（控制面板）│
│                                        │  只发聊天素材，HTTPS             │
│  QQ（小号）+ NapCat ── OneBot(127.0.0.1) ┼──────────────► DeepSeek API      │
│                                        │                                  │
│  看门狗计划任务：面板挂了 5 分钟内拉起；RDP 断开后自动切回控制台           │
└───────────────────────────────────────────────────────────────────────────┘
```

- 微信端程序：[xiaoqian-wechat 的 `server` 分支](https://github.com/AnthonyZZH/xiaoqian-wechat/tree/server)（本机版在 `main`）。
- 大脑：DeepSeek API（`deepseek-flash`，默认关闭思考）。每个聊天只带最近 20 条 + 滚动摘要 + 最多 5 条相关记忆，**不会越聊越贵**。
- QQ 端：QQ + NapCat，OneBot WebSocket 只监听本机，带令牌。

## 你需要准备

- 一台云服务器：阿里云 ECS（或同类），**Windows Server 2022、4 核 8G**、国内地域。2 核会卡。
- 微信小号、QQ 小号（服务器上登录）；主人用大号和她聊。
- DeepSeek API 密钥。
- 一台能 SSH 和远程桌面的电脑（手机用「Windows App」也能临时管理）。

## 流程一览

| 步骤 | 做什么 | 脚本 |
|---|---|---|
| 1 | 买服务器；安全组只放行自己 IP 的 3389/22 | — |
| 2 | 远程桌面 + 只允许公钥的 SSH | — |
| 3 | 检查环境、建目录、开防火墙、拦截第三方签名服务 | `01`–`05` |
| 4 | QQ + NapCat：安装、WebUI/OneBot 仅本机 + 随机令牌、快速登录 | `06a`–`06e` |
| 5 | 微信 4.x + 小千 server 分支 + 依赖 + 配置（允许的聊天、人设、DeepSeek） | `07a`–`07d` |
| 6 | 无人值守桌面：RDP 断开自动切回控制台、微信自动置顶 | `08a`–`08c` |
| 7 | 自动开始 + 崩溃记录 + 看门狗 | `09`–`09c` |
| 8 | 不发送测试（读一轮、调模型、拦截发送） | `10a`–`10b` |
| 9 | 每日清理报告（先只出报告） | `11a`–`11c` |

细节和每一步的注意事项都在 [`SKILL.md`](SKILL.md)。

## 怎么用

**作为 skill：** 把整个目录放到 `~/.claude/skills/xiaoqian-server-deploy/`，然后对 Claude Code 说"按 xiaoqian-server-deploy 部署小千服务器"或"小千服务器出问题了帮我排查"。

**手动：** 照 `SKILL.md` 一节一节做；脚本都用管理员 PowerShell 运行，遇到已存在的东西会停下而不是覆盖。

## 安全说明

- 仓库里没有任何服务器地址、账号、令牌或密钥。版本相关的安装包哈希是参数，请从官网下载后自己核对，并检查腾讯/微软的数字签名。
- 令牌在服务器上随机生成，只写进权限收紧的配置文件，不打印。DeepSeek 密钥只放机器环境变量。
- 入站只靠云安全组放行自己的 IP；NapCat WebUI / OneBot 只监听 127.0.0.1；出站拦截 NapCat 可选的第三方签名服务。
- 微信是熟人圈，按"好用"配置；QQ 进陌生人群，按"严格"配置。

## 贡献者

- [AnthonyZZH](https://github.com/AnthonyZZH)：发起与维护，需求与验收
- Codex（OpenAI）：服务器初始化与各步骤脚本、安全加固补丁、DeepSeek 大脑、转告与识图实现、配对测试
- Claude（Anthropic）：规划与审查、问题排查、修复补丁、无人值守与守护方案、本技能整理
