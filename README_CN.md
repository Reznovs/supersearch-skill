# SuperSearch

> 3-4 引擎统一搜索（WebSearch 按 IP 区域自动启用），段落级引用标注 + 正确率评分——让 AI 为每一段话负责。

## 📋 目录

- [简介](#简介)
- [功能特性](#功能特性)
- [适用场景](#适用场景)
- [前置要求](#前置要求)
- [安装](#安装)
- [使用方式](#使用方式)
- [配置说明](#配置说明)
- [示例](#示例)
- [常见问题](#常见问题)
- [许可证](#许可证)
- [贡献指南](#贡献指南)
- [相关链接](#相关链接)

## 简介

**SuperSearch** 是一个面向 AI Agent 的搜索编排 Skill。它集成了 3-4 个搜索引擎（Tavily、Exa、Brave + WebSearch 美国 IP 自动启用），解决当前 AI 搜索面临的三大核心问题：

1. **广度不够** — 单一搜索引擎覆盖范围有限，无法获得多角度信息
2. **深度不够** — 缺少深度爬取和多页聚合能力，难以进行系统调研
3. **幻觉度高** — AI 经常虚构听起来合理但不存在的信息，且不标注来源

SuperSearch 的核心理念是**让 AI 为自己的输出负责**。每个逻辑段落后统一标注引用编号和正确率，让读者顺畅读完内容后一眼看到来源和可信度。

### 核心亮点

- **干净可读** — 不在每句话后塞引用标记，段落后置引用，阅读流畅
- **正确率评分** — 每段末尾附 `[1][2][3] (正确率: 90%)`，来源一致性和可信度一目了然
- **智能本地化** — 自动识别话题地域归属，中国话题搜中文为主、欧洲话题搜当地语言为主
- **来源透明** — 末尾完整列出所有引用来源和链接

### 与同类工具的区别

| 特性 | 普通搜索 Agent | SuperSearch |
|------|--------------|-------------|
| 搜索引擎数 | 1-2 个 | 3-4 个（Tavily+Exa+Brave+WebSearch 按 IP 自动启用） |
| 交叉验证 | 无 | 自动交叉验证，正确率评分 |
| 引用标注 | 无或不规范 | 段落级引用 + 正确率百分比 |
| 本地化搜索 | 无 | 按话题地域自动调整语言配比 |
| 跨平台 | 绑定特定工具 | agentskills.io 标准，Claude/Codex/OpenCode 通用 |
| 开源 | 不透明 | MIT 开源 |

## 功能特性

- **3-4 引擎统一编排** — Tavily（深度研究+爬取）、Exa（代码+学术）、Brave（新闻+多媒体）+ WebSearch（通用，仅美国 IP），Broad Search 模式一键并行
- **段落级引用标注** — 每个逻辑段落后统一标注引用编号和正确率，如 `[1][2][3] (正确率: 95%)`，不打断阅读
- **搜索本地化** — 智能识别话题地域：中国话题 70-80% 中文搜索、全球话题 50:50、某国话题侧重当地语言
- **大范围搜索 (Broad Search)** — 3-4 引擎并行（按 IP 自动检测），自动去重、交叉验证、按可信度排序
- **精确搜索 (Precise Search)** — 意图识别，自动选择最佳引擎（代码→Exa、新闻→Brave、深度→Tavily）
- **跨平台兼容** — 遵循 [agentskills.io](https://agentskills.io) 开放标准，Claude Code / Codex / OpenCode 通用
- **一键安装** — `setup.sh` 脚本自动部署和 MCP 注册
- **API Key 安全** — `.env` 文件管理密钥，`.gitignore` 防泄露

## 适用场景

### 推荐使用

- **事实核验** — 不确定信息准确性，需要多方求证
- **数据调研** — 需要全面数据（市场规模、统计数据、价格趋势）
- **新闻事件追踪** — 了解最新事件的多角度报道
- **技术调研** — 查找代码示例、API 用法、库对比（Exa 优势）
- **学术文献检索** — 找论文、学术文章（Exa 学术过滤）
- **深度调研** — 爬取多网页、聚合多源信息（Tavily 优势）

### 不推荐使用

- **简单问答** — "今天天气怎么样" 不需要交叉验证
- **非事实性问题** — "给我写一首诗" 不需要搜索
- **安全漏洞扫描** — 请使用专门的安全 Skill

## 前置要求

- **运行环境**：Node.js 18+
- **Agent 平台**：Claude Code / Codex / OpenCode 至少一个
- **API Keys**（均提供免费额度）：
  - Tavily → [app.tavily.com](https://app.tavily.com)
  - Exa → [dashboard.exa.ai](https://dashboard.exa.ai)
  - Brave → [brave.com/search/api](https://brave.com/search/api/)
- **网络**：能访问以上 API 服务

## 安装

### 一键安装

```bash
git clone https://github.com/<your-org>/supersearch-skill.git
cd supersearch-skill
bash scripts/setup.sh
```

脚本自动完成：环境检测 → API Key 引导 → Brave MCP 注册 → 多平台文件部署 → 验证。

### 手动安装

```bash
cp -r supersearch-skill ~/.cc-switch/skills/supersearch/
cp .env.example .env
# 编辑 .env 填入 API Keys
claude mcp add brave-search -- npx -y @brave/brave-search-mcp-server --brave-api-key <your_key>
```

### AI 安装提示词

> "请帮我安装 SuperSearch Skill。克隆仓库后运行 scripts/setup.sh，我的 API Keys 分别是 Tavily: xxx, Exa: xxx, Brave: xxx。"

## 使用方式

### 触发 Skill

**大范围搜索 (Broad Search)** — 并行 3-4 引擎（按 IP 自动检测）+ 交叉验证：
```
"帮我全面搜索一下 XXX"
"多方对比 XXX 的信息"
"交叉验证 XXX 是否属实"
"广泛调研 XXX"
```

**精确搜索 (Precise Search)** — 自动选择最佳引擎：
```
"帮我找 XXX 的代码示例"       → Exa
"查一下 XXX 的最新新闻"       → Brave
"深度调研 XXX 这个主题"       → Tavily
```

### 输出解读

每个段落末尾都有引用标注：

- `[1][2][3] (正确率: 95%)` — 3 个来源高度一致，可信
- `[1][2] (存在分歧)` — 来源矛盾，列出双方说法
- `[3] (单一来源)` — 仅一个来源，无法交叉验证

末尾列出所有引用来源和完整链接。

### 搜索本地化

SuperSearch 自动根据话题地域调整搜索语言：

| 你搜索的内容 | 中文占比 | 说明 |
|------------|---------|------|
| 华为新手机 | 75% | 中国话题，中文为主 |
| iPhone 17 | 50% | 全球话题，中英均衡 |
| 法国养老金改革 | 70%法语 | 当地话题，目标语言为主 |

## 示例

### 示例 1：大范围搜索 — 事实核验

**用户输入**：
> "帮我全面搜索一下 DeepSeek V4 的发布信息"

**AI 输出**：
```
## 搜索结果: DeepSeek V4 发布信息

### 要点总结
DeepSeek 于 2026 年 4 月 24 日正式发布 V4 Preview 版本。同时推出 V4-Pro (1.6T)
和 V4-Flash (284B) 双版本，均支持 100 万 token 上下文窗口，MIT 协议开源。
Flash 版 API 定价仅 2 元/百万 token，对行业价格体系冲击较大。
[1][2][3][4] (正确率: 100%)

### 详细发现

**发布时间线**: 从最初预计 2 月推迟到 3 月，最终在 4 月 24 日落地。
创始人内部沟通中提到 4 月下旬正式发布的目标得以兑现。
[1][2][3] (正确率: 100%)

**架构创新**: 采用 CSA + HCA 混合注意力机制和 DSA 稀疏注意力。
在 100 万 token 长上下文下大幅降低计算和显存成本。
[4][5] (正确率: 80%)

**国产芯片适配**: 华为昇腾确认支持 V4。但关于训练中华为芯片的实际占比，
不同分析给出的结论存在差异。
[6][7] (正确率: 50%)

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

### 示例 2：精确搜索 — 找代码

**用户输入**：
> "帮我找 Python 中使用 anthropic SDK 实现 streaming 的代码示例"

**AI 输出**（自动选择 Exa get_code_context_exa）：
```
## 搜索结果: Python Anthropic SDK streaming 示例

Anthropic Python SDK 支持通过 streaming 参数启用流式响应。
官方推荐使用 async client 进行生产环境的流式调用。

[展示代码示例]
[1][2] (正确率: 100%)

---

### 来源
[1] Anthropic 官方文档 — https://docs.anthropic.com/en/api/messages-streaming
[2] GitHub anthropic-sdk-python — https://github.com/anthropics/anthropic-sdk-python
```

## 常见问题

**Q: 需要付费吗？**
A: 不需要。四个引擎均有免费额度：WebSearch 是内置工具（免费），但仅美国 IP 可用，Tavily 和 Exa 提供免费额度，Brave 每月免费 $5（约 2000 次）。个人使用足够。

**Q: API Key 安全吗？**
A: API Keys 保存在 `.env` 文件中，已在 `.gitignore` 忽略，不会被提交到 Git。

**Q: 为什么有的段落标"单一来源"？**
A: Precise Search 模式只调用一个引擎，无法交叉验证。需要多方确认请用 Broad Search。

**Q: 支持哪些平台？**
A: Claude Code（推荐）、Codex、OpenCode。遵循 agentskills.io 开放标准。

**Q: Brave MCP 注册失败？**
A: 检查 Node.js 版本（需 18+），或手动执行：
```bash
claude mcp add brave-search -- npx -y @brave/brave-search-mcp-server --brave-api-key <你的key>
```

## 许可证

MIT License. 详见 [LICENSE](LICENSE)

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

### 贡献方向
- 报告 Bug 或使用问题
- 改进文档和示例
- 添加新的搜索引擎支持
- 改进引用标注输出格式
- 完善本地化搜索策略

## 相关链接

- [agentskills.io 规范](https://agentskills.io/specification) — Agent Skill 开放标准
- [Brave Search MCP Server](https://github.com/brave/brave-search-mcp-server) — 官方 Brave MCP
- [Tavily](https://tavily.com) — Tavily 搜索 API
- [Exa](https://exa.ai) — Exa 搜索 API
- [Claude Code](https://claude.ai/code) — Anthropic Claude Code
