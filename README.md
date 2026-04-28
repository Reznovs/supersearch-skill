# SuperSearch

> 3-4 引擎统一搜索 + 交叉验证引用 —— 让 AI 为每一段话负责。

[![Version](https://img.shields.io/badge/version-1.1.0-blue)]()
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![agentskills.io](https://img.shields.io/badge/agentskills.io-compatible-purple)](https://agentskills.io)
[![Engines](https://img.shields.io/badge/engines-3--4-orange)]()

---

## 为什么选择 SuperSearch？

单一搜索引擎覆盖面窄、深度不够、幻觉率高。SuperSearch 并行编排 3-4 个引擎，自动交叉验证，给每段输出标注来源和可信度。

| | 单引擎搜索 | SuperSearch |
|---|---|---|
| 搜索引擎数 | 1 | 3-4 并行（Tavily + Exa + Brave + WebSearch*） |
| 交叉验证 | 无 | 自动，多源比对 |
| 引用标注 | 无 | 段落级 `[1][2][3] (正确率: 95%)` |
| 本地化搜索 | 无 | 按话题地域自动调整语言配比 |
| 幻觉检测 | 无 | 多源验证，冲突显式标注 |
| 平台兼容 | 绑定单一工具 | Claude Code / Codex / OpenCode 通用 |

> *WebSearch 仅美国 IP 可用，非美国自动降级为 3 引擎，不影响交叉验证质量。

---

## 快速开始

```bash
git clone https://github.com/Reznovs/supersearch-skill.git
cd supersearch-skill
bash scripts/setup.sh
```

脚本自动完成：环境检测 → API Key 引导 → 多平台部署 → MCP 注册。

---

## 工作原理

```
用户请求
    │
    ├── "全面搜索 / 交叉验证 / 多方对比" ──→ Broad Search（广域搜索）
    │       │
    │       ├── Step 0: IP 检测（美国 → 4 引擎 : 非美国 → 3 引擎）
    │       ├── Step 1: 话题分类 → 语言配比
    │       ├── Step 2: 所有引擎并行搜索
    │       ├── Step 3: 交叉验证 + 正确率评分
    │       └── Step 4: 段落级引用输出
    │
    └── "找代码 / 查新闻 / 快速搜索" ──→ Precise Search（精确搜索）
            │
            ├── 代码相关 → Exa
            ├── 新闻事件 → Brave
            ├── 深度调研 → Tavily
            └── 快速查询 → WebSearch（美国）/ Tavily（非美国）
```

---

## 引擎能力

| 引擎 | 擅长领域 | 特色 |
|------|---------|------|
| **Tavily** | 深度研究、网页爬取 | 多页聚合、结构化摘要 |
| **Exa** | 代码示例、学术论文 | GitHub/StackOverflow 索引、学术过滤 |
| **Brave** | 新闻、多媒体 | 时效性强、本地搜索 |
| **WebSearch** | 通用搜索 | 内置工具、无需 API Key（仅美国 IP） |

---

## 安装

### 前置要求

- **系统**：Linux、macOS 或 Windows（PowerShell 5.1+）
- **Node.js**：18+
- **Agent 平台**：Claude Code / Codex / OpenCode 至少一个
- 3 个 API Key（均有免费额度）：
  - [Tavily](https://app.tavily.com) — 深度研究
  - [Exa](https://dashboard.exa.ai) — 代码 + 学术
  - [Brave](https://brave.com/search/api/) — 新闻 + 通用

### 一键安装（推荐）

**Linux / macOS:**

```bash
git clone https://github.com/Reznovs/supersearch-skill.git
cd supersearch-skill
bash scripts/setup.sh
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/Reznovs/supersearch-skill.git
cd supersearch-skill
powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
```

<details>
<summary>手动安装</summary>

**Linux / macOS:**
```bash
# 1. 复制项目到 Skill 目录
cp -r supersearch-skill ~/.claude/skills/supersearch/

# 2. 配置 API Keys
cp .env.example .env
# 编辑 .env 填入你的 API Keys

# 3. 注册 Brave MCP Server
claude mcp add brave-search -- npx -y @brave/brave-search-mcp-server --brave-api-key <your_key>
```

**Windows (PowerShell):**
```powershell
# 1. 复制项目到 Skill 目录
Copy-Item -Recurse supersearch-skill "$env:USERPROFILE\.claude\skills\supersearch"

# 2. 配置 API Keys
Copy-Item .env.example .env
# 编辑 .env 填入你的 API Keys

# 3. 注册 Brave MCP Server
claude mcp add brave-search -- npx -y @brave/brave-search-mcp-server --brave-api-key <your_key>
```

</details>

<details>
<summary>Codex / OpenCode 安装</summary>

**Codex (Linux/macOS):**
```bash
cp -r supersearch-skill ~/.codex/skills/user/supersearch/
cp .env.example .env
```

**Codex (Windows):**
```powershell
Copy-Item -Recurse supersearch-skill "$env:USERPROFILE\.codex\skills\user\supersearch"
Copy-Item .env.example .env
```

**OpenCode (Linux/macOS):**
```bash
cp -r supersearch-skill ~/.config/opencode/skills/supersearch/
cp .env.example .env
```

**OpenCode (Windows):**
```powershell
Copy-Item -Recurse supersearch-skill "$env:USERPROFILE\.config\opencode\skills\supersearch"
Copy-Item .env.example .env
```

安装后需在对应平台的配置中注册 Tavily、Exa、Brave 的 MCP Server。

</details>

---

## 使用方式

### Broad Search — 广域搜索

触发词：`全面搜索`、`交叉验证`、`多方对比`、`广泛调研`、`fact check`、`comprehensive search`

```
"帮我全面搜索一下 DeepSeek V4 的发布信息"
"交叉验证 XXX 是否属实"
"多方对比 XXX 的信息"
```

### Precise Search — 精确搜索

触发词：`找代码`、`查新闻`、`搜一下`、`quick search`

```
"帮我找 Python 使用 anthropic SDK streaming 的代码示例"    → Exa
"查一下 XXX 的最新新闻"                                   → Brave
"深度调研 XXX 这个主题"                                   → Tavily
```

### 输出示例

每个逻辑段落后统一标注引用编号和正确率：

```
## 搜索结果: DeepSeek V4 发布信息

### 要点总结
DeepSeek 于 2026 年 4 月 24 日正式发布 V4 Preview 版本。同时推出 V4-Pro (1.6T)
和 V4-Flash (284B) 双版本，均支持 100 万 token 上下文窗口，MIT 协议开源。
Flash 版 API 定价仅 2 元/百万 token，对行业价格体系冲击较大。
[1][2][3][4] (正确率: 100%)

### 详细发现

**架构创新**: 采用 CSA + HCA 混合注意力机制和 DSA 稀疏注意力。
在 100 万 token 长上下文下大幅降低计算和显存成本。
[4][5] (正确率: 80%)

**国产芯片适配**: 华为昇腾确认支持 V4。但关于训练中华为芯片的实际占比，
不同分析给出的结论存在差异。
[6][7] (存在分歧)
  来源 6 (搜狐科技): 华为芯片占比超过 50%
  来源 7 (Bloomberg): 实际占比远低于预期

---

### 来源
[1] DeepSeek API Docs — https://api-docs.deepseek.com/news/news260424
[2] Fortune — https://fortune.com/2026/04/24/deepseek-v4
[3] CNBC — https://www.cnbc.com/2026/04/24/deepseek-v4
[4] Simon Willison 评测 — https://simonwillison.net/2026/Apr/24/deepseek-v4/
[5] MIT Technology Review — https://www.technologyreview.com/2026/04/24/1136422/
[6] 搜狐科技 — https://www.sohu.com/a/1013995823_121448078
[7] Bloomberg — https://www.bloomberg.com/news/articles/2026-04-24/deepseek
```

引用格式说明：
- `[1][2][3] (正确率: 95%)` — 多源高度一致，可信
- `[1][2] (存在分歧)` — 来源矛盾，列出双方说法
- `[3] (单一来源)` — 仅一个来源，无法交叉验证

---

## 搜索本地化

SuperSearch 自动根据话题地域调整搜索语言：

| 话题类型 | 示例 | 中文占比 | 策略 |
|---------|------|---------|------|
| 中国话题 | 华为、小米、国产芯片 | 70-80% | 中文为主 |
| 全球话题 | iPhone、AI、Bitcoin | 50% | 中英均衡 |
| 特定国家 | 日本地震、法国游行 | — | 当地语言 70% + 英文 30% |

---

## 常见问题

<details>
<summary><b>需要付费吗？</b></summary>

不需要。四个引擎均有免费额度：
- **WebSearch** — 内置工具，完全免费（仅美国 IP）
- **Tavily** — 免费额度足够个人使用
- **Exa** — 免费额度足够个人使用
- **Brave** — 每月免费 $5（约 2000 次查询）

</details>

<details>
<summary><b>没有美国 IP 怎么办？</b></summary>

完全不影响使用。系统自动检测 IP，非美国时跳过 WebSearch，使用 Tavily + Exa + Brave 三个引擎。三引擎仍可充分交叉验证。

</details>

<details>
<summary><b>API Key 安全吗？</b></summary>

API Keys 保存在 `.env` 文件中，已在 `.gitignore` 中排除，不会被提交到 Git。

</details>

<details>
<summary><b>为什么不只用一个引擎？</b></summary>

单一引擎覆盖面有限，容易遗漏信息。多引擎并行搜索 + 交叉验证可以：
- 扩大信息覆盖面
- 降低幻觉率（多源一致 = 高可信度）
- 发现信息冲突（不同来源说法不一时显式标注）

</details>

<details>
<summary><b>和 Perplexity / ChatGPT 搜索有什么区别？</b></summary>

- **Agent-native** — SuperSearch 是给 AI Agent 用的 Skill，不是独立产品
- **多引擎并行** — 同时调用 3-4 个搜索引擎，不是单一后端
- **引用评分** — 每段标注正确率百分比，不只是附几个链接
- **跨平台** — 遵循 agentskills.io 标准，Claude/Codex/OpenCode 通用

</details>

<details>
<summary><b>支持哪些平台？</b></summary>

- **Claude Code**（推荐）— 完整支持，一键安装
- **Codex** — 通过 MCP 集成支持
- **OpenCode** — 通过 MCP 集成支持

遵循 [agentskills.io](https://agentskills.io) 开放标准。

</details>

---

## 参与贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送并创建 Pull Request

贡献方向：Bug 报告、文档改进、新引擎支持、引用格式优化、本地化策略完善。

---

## 相关链接

- [agentskills.io 规范](https://agentskills.io/specification) — Agent Skill 开放标准
- [Tavily](https://tavily.com) — 深度研究搜索 API
- [Exa](https://exa.ai) — 代码 + 学术搜索 API
- [Brave Search](https://brave.com/search/api/) — 新闻 + 通用搜索 API
- [Claude Code](https://claude.ai/code) — Anthropic Claude Code

---

## 许可证

[MIT License](LICENSE)
