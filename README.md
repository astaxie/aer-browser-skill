# AER Browser Skill

让 Codex 通过 AER 的原生 CLI 读取和操作浏览器中已经打开的网页，复用现有登录状态。

安装后，可以直接对 Codex 说：

```text
用 $aer-browser 看一下 AER 当前打开的网页，帮我分析页面结构。
```

这个仓库发布 `aer-browser` skill，包含指令、启动器、安装脚本和操作参考。运行它需要单独安装带原生 CLI 的 AER macOS 应用。

## 能做什么

| 能力 | 说明 |
| --- | --- |
| 查找浏览器会话与页面 | 枚举运行中的 Profile/session 和已打开的标签页 |
| 阅读网页 | 获取有长度上限的页面正文，以及当前视口内可操作控件的名称、角色和引用 |
| 操作页面 | 点击链接和按钮、填写普通文本、选择下拉选项、滚动、等待页面结果 |
| 页面导航 | 在任务绑定的现有标签页中打开其他地址 |
| 导出内容 | 导出文章 Markdown 或整页 PNG；微信文章归档按应用内实时指南执行 |
| 管理任务 | 查看状态、完成、停止，以及交给用户接管后继续 |

Codex 先读取页面快照，再使用返回的控件引用执行操作，并重新观察结果。这个流程适合分析页面、整理文章、操作表单和验证网页交互。

## 环境要求

- macOS，以及支持本地 skill 和终端命令的 Codex 环境。
- 已安装 AER，应用包内包含 `Contents/MacOS/aer-browser` 和配套指南。
- 操作网页时 AER 需要处于运行状态，并已打开目标 HTTP(S) 页面。
- 下方克隆安装方式需要 Git；skill 运行时使用系统 Bash，无需额外安装 Node.js、Python、MCP 服务或浏览器扩展。

当前发布包针对 macOS。安装 skill 不会安装 AER；请使用你已有的 AER 应用或项目提供的可信分发版本。

## 安装到 Codex

克隆仓库，再运行安装脚本：

```bash
git clone https://github.com/astaxie/aer-browser-skill.git
cd aer-browser-skill

bash skills/aer-browser/scripts/install-codex.sh \
  --app "/Applications/AER.app" \
  --dest "$HOME/.agents/skills/aer-browser"
```

将 `--app` 改为你实际的 AER 应用绝对路径。路径包含空格或中文时保留引号。如果 AER 位于 `/Applications/AER.app` 或 `~/Applications/AER.app`，且能唯一确定应用，也可以省略 `--app`。

上面的命令使用 Codex 官方文档列出的用户级目录 `~/.agents/skills`。如果你已有的 Codex 环境从 `~/.codex/skills` 加载技能，可以省略 `--dest`；脚本默认安装到 `${CODEX_HOME:-$HOME/.codex}/skills/aer-browser`。同一环境选择一个位置即可，避免出现同名技能。

安装脚本会保存本机应用路径；更新已有 skill 时，先将旧版本备份到技能目录外的 `skill-backups`。本机路径文件 `local-app-path` 已被本仓库忽略。

Codex 会自动检测技能变化。安装后在下一轮输入 `$aer-browser`；如果没有出现，重新启动 Codex 后再试。目录规则参见 [Codex 官方技能文档](https://developers.openai.com/codex/skills/)。

### 检查安装

以下路径与上面的 `--dest` 对应；如果安装到其他位置，请同步修改：

```bash
AER_SKILL_DIR="$HOME/.agents/skills/aer-browser"

bash "$AER_SKILL_DIR/scripts/aer-browser.sh" --resolve
bash "$AER_SKILL_DIR/scripts/aer-browser.sh" skill
bash "$AER_SKILL_DIR/scripts/aer-browser.sh" profiles
```

- `--resolve` 应返回 AER 原生 CLI 的路径。
- `skill` 应输出应用自带的指南，最后包含 `[aer-browser:skill] end of guide`。
- `profiles` 应返回 JSON。空数组表示尚未发现运行中的 AER 会话，可以打开 AER 后重试。

## 在 Codex 中使用

```text
用 $aer-browser 分析当前网页，列出主要内容区、导航入口和可操作控件。
```

```text
用 $aer-browser 查看 AER 中打开的这篇文章，提取主要观点，导出 Markdown 到我指定的目录。
```

```text
用 $aer-browser 检查我打开的本地测试页面，填写标题、选择分类，并验证保存后的结果。
```

```text
用 $aer-browser 把当前文章导出为完整 PNG 截图。
```

有多个 Profile/session 时，Codex 会选择与请求匹配的会话；无法区分时会询问。需要操作登录后的页面时，先在 AER 中完成登录并打开页面。

### 人工确认

AER 对需要确认的操作返回 `waiting_confirmation`。这表示操作仍在等待，并未执行。请在 AER 的 **智能体 → 网页任务** 面板检查并确认；旧版可能显示为 **任务 / Tasks**。

Skill 不会代替用户批准，也不会重复发送等待中的操作。密码、支付信息、验证码等字段需要用户直接处理。

## 工作原理

```text
Codex 读取 SKILL.md
  → 启动器定位已安装的 AER
  → 读取 AER 随版本提供的实时指南
  → 选择 session 和页面，创建手动任务
  → 页面快照 → 操作 → 验证 → 完成
```

Skill 使用轻量引导和实时指南的方式，让命令说明随已安装的 AER 版本更新。`manual:true` 表示由 Codex 决定步骤，AER 的本地服务执行浏览器动作。

启动器依次检查 `AER_BROWSER_APP`、安装时保存的应用路径、PATH 上的原生 `aer-browser`，以及标准 Applications 目录。详细命令见 [CLI 工作流](skills/aer-browser/references/workflow.md)。

## 当前能力边界

页面快照提供受限正文和视口内控件，不能当成完整 DOM 树或完整视觉布局。当前公共 CLI 尚未提供任意 JavaScript/CDP、iframe 或 Shadow DOM 遍历、canvas 操作、文件上传、新建或关闭标签页、自动登录等能力。

微信归档是否适用取决于文章与已安装版本的指南。遇到不支持的控件或页面，Codex 会说明具体限制并交给用户处理。

## 验证记录

2026-11-06，在 macOS 上使用 **AER 0.4.26110514** 完成了：

- **10 项启动器与安装检查**：复杂路径、参数传递、实时指南、错误处理、PATH 符号链接、安装、更新备份及旧版保护等。
- **15 项真实浏览器检查**：会话与页面发现、快照、失效引用拒绝、填写、选择、提交、等待、滚动、导航、任务管理及导出等。
- 在已有登录会话中实际读取页面，并完成页面结构分析。

真实浏览器自动化测试使用隔离 Profile 和本地测试页面。填写与提交测试由测试程序操作隔离实例的原生确认界面；发布的 skill 仍要求用户自行确认。测试不代表所有第三方网站兼容，成功归档真实微信文章也未验收。

## 仓库结构

```text
skills/aer-browser/
├── SKILL.md
├── agents/openai.yaml
├── scripts/
│   ├── aer-browser.sh
│   └── install-codex.sh
└── references/
    ├── install.md
    ├── workflow.md
    └── troubleshooting.md
```

更新时在本仓库运行 `git pull --ff-only`，再用原来的 `--dest` 重跑安装命令。排查问题请看 [安装与应用定位](skills/aer-browser/references/install.md) 和 [故障处理](skills/aer-browser/references/troubleshooting.md)。

## 致谢

引导 skill 加载浏览器实时指南的设计参考了 [ego-lite 的 ego-browser skill](https://github.com/citrolabs/ego-lite/tree/main/skills/ego-browser)。本仓库包含面向 AER 的指令与启动器；具体能力以所安装 AER 的实时指南为准。
