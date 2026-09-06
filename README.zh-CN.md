# Codex Quota Bar

**在 Mac 菜单栏中，同时查看 router 里的多个 Codex 账号额度。**

[English](README.md) · [安装](#安装) · [架构](docs/architecture.md) · [验收记录](docs/validation.md)

这是连接 [CodexBar](https://github.com/steipete/CodexBar) 和 [Subrouter](https://github.com/manaflow-ai/subrouter) 的本地插件。读取各账号的剩余额度、预计重置时间和登录状态，支持自定义账号别名。插件不接触 OAuth 文件，不替换路由引擎。

> v0.1.0 是实验版本：已用两个本地账号检查菜单展示。**尚不支持把 router 账号加入 Widget。**

## 亮点

- **多个订阅放在同一张卡片。** 各账号独立显示短期及周额度，不把不同套餐的百分比相加。
- **无需重复导入登录凭据。** 账号认证继续由 Subrouter 管理；插件只读取本地额度接口。
- **一个 JavaScript 文件。** 复用 CodexBar 菜单栏，无需维护改版应用或新增后台服务。
- **明确区分额度与登录状态。** 未知数据不显示成 0；账号别名保存在本机。
- **复用系统语言设置。** CodexBar 主界面可跟随 macOS；插件设置名及错误信息暂为英文。

## 安装

前提：macOS 14+、CodexBar，以及已经登录账号并监听 `http://127.0.0.1:31415` 的 Subrouter。本次检查版本为 CodexBar 0.56.7 / Subrouter 0.1.130。插件不负责安装 router 或配置 Codex 请求路由。

1. 从 [Release](https://github.com/DeepCogNeural/codex-quota-bar/releases/tag/v0.1.0) 下载 `subrouter.js`。
2. 打开 CodexBar 的 **Settings → Plugins → Install plugin**，选择文件。
3. **Router URL** 填 `http://127.0.0.1:31415`。别名可以留空，也可以填 `{"first@example.com":"个人","second@example.com":"工作"}`。
4. 在授权界面确认 Auth / Secrets 都是 none，输入上述本地地址并批准。
5. 启用 Subrouter，点击 Refresh。

也可以把文件复制到 `~/.config/codexbar/providers/subrouter.js`，重启 CodexBar 后从设置中授权。不要覆盖整个 CodexBar 配置文件，也不要复制别人的授权记录。

## 怎么看

- 数字是**剩余百分比**；`5h` / `7d` 是额度窗口长度。
- 本版重置时间使用 UTC 时间格式，由 router 返回的剩余秒数估算。
- `✓` 为 router 已检查且登录有效；`!` 为无效；`?` 为未确认。登录有效不等于已经验证模型请求成功。
- `—` 为无数据，不是 0。读取失败时旧数字不能当作最新额度。
- **General → Language → System** 跟随系统语言，改变语言后重启 CodexBar 使设置完整生效。

## 功能边界

本插件不负责切换账号、不显示当前对话实际使用的账号，也不保证额度耗尽后的无缝接力。调度由 Subrouter 决定。仅展示基础窗口，排除模型专项额度，最多八个账号、每账号八个窗口。

CodexBar 本身有 Claude / Antigravity 的接入及 Widget，但**本地插件不能进入其 Widget**。这两个平台需在 CodexBar 中独立配置，不是本插件已经接入。当前通用卡片展示文字行，不能把示意图理解为已实现的进度条界面。

## 与上游的区别

CodexBar 提供界面及插件运行环境；Subrouter 提供账号、额度数据和路由；本仓库提供两者间的映射与安装说明。不包含上游应用二进制，也不是换名后的完整应用。Widget 为后续计划。

删除时使用 CodexBar 的 **Plugins → Delete…**。不会删除 router 账号或修改 Codex 配置。

如果对你有帮助，欢迎自愿 [Star](https://github.com/DeepCogNeural/codex-quota-bar)。也欢迎提交脱敏问题和兼容性结果。MIT 许可，独立项目。
