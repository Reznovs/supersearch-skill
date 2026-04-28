---
name: supersearch
description: |
  Unified multi-engine search orchestrating 3-4 engines (Tavily, Exa, Brave
  + WebSearch when US IP detected). Two modes: Broad Search (parallel
  multi-engine + cross-validation with clean paragraph-level citations and
  confidence scores) and Precise Search (intent-based tool selection). Intelligent localization: auto-adjusts
  query language ratio (Chinese 70-80% for China topics, 50:50 for global,
  70% local language for country-specific topics). Output: no emoji clutter,
  citations grouped at paragraph end with accuracy %, full source list at
  bottom. Trigger when user needs comprehensive, verified, or multi-source
  search with readable, well-formatted results.
license: MIT
compatibility: "agentskills.io standard. Compatible with Claude Code, Codex,
  OpenCode. Cross-platform: Linux, macOS, Windows (PowerShell). Requires
  Node.js 18+ and configured search MCP servers (Tavily, Exa, Brave).
  See references/platform-tools.md for per-platform tool names."
metadata:
  version: "1.1.0"
  keywords: "search, multi-engine, cross-validation, citation, verification,
    research, localization, clean-output"
allowed-tools:
  - WebSearch
  - mcp__tavily__tavily_search
  - mcp__tavily__tavily_extract
  - mcp__tavily__tavily_crawl
  - mcp__tavily__tavily_map
  - mcp__tavily__tavily_research
  - mcp__exa__web_search_exa
  - mcp__exa__get_code_context_exa
  - mcp__brave__brave_web_search
  - mcp__brave__brave_news_search
---

# SuperSearch — Unified Multi-Engine Search

## 1. Quick Decision: Broad vs Precise

Read the user's request. Match against these triggers:

**→ Broad Search (Mode A)** when user says or implies:
"全面搜索"、"交叉验证"、"多方对比"、"广泛调研"、"大范围搜索"、"帮我全面查"、
"verify this"、"fact check"、"multiple sources"、"comprehensive search"
Also: any claim that NEEDS cross-verification (prices, dates, statistics, news events).

**→ Precise Search (Mode B)** when user says or implies:
"找代码"、"查API"、"最新新闻"、"学术论文"、"爬取这个网站"、"搜一下"、"quick search"
Also: the task clearly matches a single tool's strength (see Section 5).

**If uncertain** → default to Broad Search. Over-verification is better than hallucination.

---

## 2. Search Localization — Language & Region Strategy

Before firing any search, analyze the topic's geographic/cultural origin. This determines the query language distribution.

### 2.1 Topic Classification

| Topic Type | Trigger Examples | Local Lang | English | Strategy |
|-----------|-----------------|------------|---------|----------|
| **China-topic** | OPPO, 华为, 小米, 字节跳动, 中国政策, 两会, 国产芯片 | 70-80% | 20-30% | Chinese queries dominate |
| **Country-specific** | 欧洲游行, 日本地震, 印度选举, 巴西经济 | 70% (target lang) | 30% | Local language prioritized |
| **Global/Universal** | Marvel movie, iPhone, Python, AI research, Bitcoin | 50% | 50% | Balanced bilingual search |
| **Uncertain** | Can't determine origin | 50% | 50% | Default balanced |

### 2.2 How to Apply (Broad Search, 3-4 engines)

> **IP check:** WebSearch is only available with a US IP. Run IP detection before Broad Search (see §4.1 Step 0). Non-US IPs skip WebSearch and use 3 engines.

For a **China-topic** (e.g., OPPO new phone):
```
Engine 1 (WebSearch): Chinese query  ←┐ [US only]
Engine 2 (Tavily):     Chinese query  ←┤ 75% Chinese
Engine 3 (Brave):      Chinese query  ←┘
Engine 4 (Exa):        English query  ← 25% English

[If non-US — 3 engines]:
Engine 1 (Tavily):     Chinese query  ←┐ 67% Chinese
Engine 2 (Brave):      Chinese query  ←┘
Engine 3 (Exa):        English query  ← 33% English
```

For a **Global topic** (e.g., Marvel new movie):
```
Engine 1 (WebSearch): Chinese query  ←┐ 50% Chinese [US only]
Engine 2 (Tavily):     English query  ←┘
Engine 3 (Exa):        English query  ←┐ 50% English
Engine 4 (Brave):      Chinese query  ←┘

[If non-US — 3 engines]:
Engine 1 (Tavily):     English query  ←┐ 50%
Engine 2 (Brave):      Chinese query  ←┤
Engine 3 (Exa):        English query  ←┘ 50%
```

For **Country-specific** (e.g., protest in France):
```
Engine 1 (WebSearch): French query   ←┐ [US only]
Engine 2 (Tavily):     French query   ←┤ 70% local language
Engine 3 (Brave):      French query   ←┘
Engine 4 (Exa):        English query  ← 30% English

[If non-US — 3 engines]:
Engine 1 (Tavily):     French query   ←┐ 67% local
Engine 2 (Brave):      French query   ←┘
Engine 3 (Exa):        English query  ← 33% English
```

### 2.3 Query Language Rules

- Chinese queries: use Chinese keywords + Chinese news sources
- English queries: use English keywords + global sources
- Local language queries: translate key terms to the target language
- Mix simplified + traditional Chinese INSIDE the same query if topic spans mainland + Taiwan/HK

---

## 3. Citation Rules — Clean & Readable

The core rule: **every logical section MUST cite its sources at the end.** Think of each section like a paragraph in a news article with a footnote, not a sentence-by-sentence academic paper.

### 3.1 Format

Citations are plain numbers `[1][2][3]` placed at the END of each logical section, followed by a confidence percentage.

```
Paragraph content. State facts naturally and fluently.
Don't break reading rhythm. Readers finish the paragraph then see source markers.
[1][2][3] (Confidence: 100%)
```

### 3.2 What is a "Logical Section"

A section is a group of sentences covering ONE topic or claim cluster. Don't cite every sentence — cite every topic block.

**Correct (one section, one citation group):**
```
Nvidia's stock price plunged ~10% on April 28. The decline was triggered by
DeepSeek's V4 model release reshaping the AI chip market landscape. Multiple
institutions downgraded Nvidia's target price. Analysts generally believe chip
demand will not recover in the short term.
[1][2][3][4] (Confidence: 85%)
```

**Wrong (too granular, kills readability):**
```
Nvidia's stock price plunged ~10% on April 28. [1][2]
The decline was related to DeepSeek's V4 model release. [3]
Multiple institutions downgraded the target price. [4]
```

### 3.3 Confidence Score Algorithm

**Prerequisite:** Confidence percentage requires **at least 2 independent sources**. If only 1 engine was used (single-engine mode or only 1 key configured), ALL sections must be marked as `(Single source)` — do NOT calculate a confidence percentage.

Calculate for each section based on the sources cited:

| Condition | Score |
|-----------|-------|
| 3+ independent authoritative sources, high agreement | 95-100% |
| 2-3 sources agree, minor wording differences | 80-90% |
| 2 sources agree, some ambiguity remains | 65-75% |
| Mixed signals, sources partially disagree | 45-60% |
| Only 1 source available | Mark as "Single source" (no percentage) |
| Sources clearly contradict each other | State the conflict explicitly |

**When sources contradict:**
```
The cause of this incident remains unclear. Source A considers X the primary
factor, while Source B argues Y is more critical.
[1][2] (Conflicting)
  Source 1 (Reuters): X is the primary factor
  Source 2 (BBC): Y is more critical
```

### 3.4 Numbering

- Number sources sequentially: [1], [2], [3]... across the entire response
- Same source can appear in multiple sections — reuse the same number
- All numbers must appear in the final source list
- Start from [1] in each response

---

## 4. Mode A: Broad Search — Parallel + Cross-Validation

### 4.1 Execution Protocol

0. **Check engine availability** — Determine which engines are available:
   - **Check IP region** — Run: `curl -s --max-time 3 "http://ip-api.com/json/?fields=countryCode" 2>/dev/null`
     - If `"countryCode":"US"` → WebSearch is available
     - Otherwise (non-US, timeout, error) → skip WebSearch
   - **Check API keys** — Check if each engine's key/tool is configured:
     - `TAVILY_API_KEY` set → Tavily available
     - `EXA_API_KEY` set → Exa available
     - `BRAVE_API_KEY` set → Brave available
     - Any key missing → that engine is unavailable
   - **AI-driven key recovery** — If engines are missing, ask the user:
     > "当前配置了 X 个引擎（[列表]）。以下引擎未配置：[缺失列表]。你有这些 API Key 吗？如果有请提供，我来配置。"
     - If user provides a key → update `.env` and `.supersearch-state`, add the engine
     - If user says no → proceed with available engines, no further prompts
   - **Validate keys at runtime** — Use optimistic strategy: proceed with all configured engines. If any engine returns 401/403 during search:
     - Skip that engine for the current search
     - Inform the user: "[Engine] API key is invalid or expired, skipping this engine"
     - Continue with remaining engines
   - **Minimum requirement:** at least 1 engine must be available. If 0 engines and user declines to provide keys, inform the user that at least 1 API key is required.
   - **Cross-validation note:** with only 1 engine, mark all results as "Single source". With 2+ engines, proceed normally.
1. **Classify the topic** (Section 2) — determine language distribution
2. **Write N queries** — N = number of available engines; distribute languages per Section 2
3. **Fire all available engines IN PARALLEL** with language-appropriate queries
4. **Synthesize results** — extract facts, group by topic, assign confidence
5. **Format output** — paragraph-level citations + source list

### 4.2 Engine-Specific Query Tips

| Engine | Query Strategy |
|--------|---------------|
| WebSearch | Natural language, broad phrasing; **US IP only** (see §4.1 Step 0) |
| Tavily | Use `tavily_search` for breadth, add `tavily_crawl` for depth |
| Exa | English works best; use `get_code_context_exa` for code |
| Brave | Use `brave_news_search` for time-sensitive, `brave_web_search` for general |

### 4.3 Result Synthesis

After all engines return:
1. **Extract facts** — list every distinct factual claim
2. **Group by topic** — cluster related claims into logical sections
3. **Check agreement** — how many independent sources support each claim?
4. **Assign confidence** — per Section 3.3 algorithm
5. **Write sections** — one section per topic cluster, citations at end
6. **Flag contradictions** — if sources disagree, state both sides explicitly

### 4.4 Source Independence Check

- Same fact from DIFFERENT search engines = independent confirmation (strong)
- Same fact from same domain via different engines = NOT independent (weak)
- Same fact, same author syndicated across sites = single source
- Two Chinese sources citing the same English report = single source

---

## 5. Mode B: Precise Search — Intent-Based Tool Selection

### 5.1 Intent → Tool Mapping

| User wants to... | Best tool | Why |
|-----------------|-----------|-----|
| Find code examples, API usage | **Exa** `get_code_context_exa` | GitHub + Stack Overflow index |
| Latest news, breaking events | **Brave** `brave_news_search` | Fresh index, news filtering |
| Deep research (multi-page) | **Tavily** `tavily_research` + `tavily_crawl` | Multi-source with summaries |
| Extract content from a website | **Tavily** `tavily_extract` / `tavily_map` | Page extraction, site mapping |
| Academic papers | **Exa** `web_search_exa` | Academic content filtering |
| Quick fact lookup | **WebSearch** (US IP only) / **Tavily** `tavily_search` (non-US) | Fastest when available |
| Image/video search | **Brave** `brave_web_search` | Multimedia capability |
| Local business / POI | **Brave** `brave_web_search` | Local search support |

### 5.2 Execution

1. Identify intent from user's request
2. Select the BEST single tool
3. Apply localization: write the query in the appropriate language
4. Fire the tool with optimized query
5. If poor results → fall back to second choice → Broad Search (if ≥2 engines available)

### 5.3 Fallback Chain

If **≥2 engines** available:
```
Primary tool fails/empty → Second choice → Broad Search (all available)
```

If **only 1 engine** available:
```
Primary tool fails/empty → Inform user: "[Engine] returned no results. Try rephrasing your query."
(No fallback — Broad Search with 1 engine is pointless)
```

---

## 6. Output Format Template

Every SuperSearch response MUST follow this structure:

```
## Search Results: [topic summary]

### Key Takeaways
[One coherent paragraph summarizing key findings. Readable, concise, no interruptions.
Multiple sentences flow naturally together.]
[1][2][3] (Confidence: XX%)

### Detailed Findings

**Topic A**: [Facts about this topic. Multiple sentences OK.]
[1][2] (Confidence: XX%)

**Topic B**: [Another topic cluster.]
[If sources conflict on this section, annotate directly below]
[3][4] (Conflicting)
  Source 3 (Reuters): Claim X
  Source 4 (Bloomberg): Claim Y

**Topic C**: [Topic with only one source.]
[5] (Single source)

---

### Sources
[1] Source Name — https://url1.com
[2] Source Name — https://url2.com
[3] Source Name — https://url3.com
[4] Source Name — https://url4.com
[5] Source Name — https://url5.com
```

### Rules for Output

- Section title uses `**bold**` for topic labels
- Each section is 1-5 sentences, don't split every sentence into its own section
- Citation group goes on its own line, right after the section text
- Confidence always follows the citation numbers
- Source list uses hyphens, format: `[N] Name — URL`
- NEVER use emoji in citations or markers
- **Single-engine rule:** If only 1 engine was used, ALL sections use `(Single source)` — never output a confidence percentage (no cross-validation was possible)

---

## 7. Quality Rules

### MUST
- Every section (Key Takeaways + each Detailed Findings subsection) MUST have a citation group
- Every citation number MUST appear in the final source list with URL
- Report contradictions honestly — state both sides, don't pick a winner
- Preserve original meaning when summarizing
- For Broad Search: use ALL available engines (3 or 4, per IP check in §4.1 Step 0), not a subset
- Apply localization: query language must match the topic's region

### MUST NOT
- NEVER fabricate sources — if you can't find it, say so
- NEVER present single-source claims as high confidence
- NEVER omit conflicting information that disagrees with consensus
- NEVER guess a URL — only cite URLs actually returned by the tools
- NEVER use emoji in citation markers or confidence display
- NEVER split every sentence into its own section with citations

---

## 8. Source Credibility

Higher weight (prefer these):
- Official company/government websites
- Major news outlets (Reuters, Bloomberg, AP, BBC, Xinhua, People's Daily)
- Academic papers (.edu, arxiv)
- Official API documentation / GitHub repos

Lower weight (use with caution):
- Personal blogs
- Social media posts
- Forum discussions
- AI-generated content sites
- Content farms / self-media copycats

---

## 9. Rate Limits

- **WebSearch**: No rate limit, available only with US IP (see §4.1 Step 0)
- **Tavily**: Generous limits; `tavily_research` is most token-intensive
- **Exa**: `get_code_context_exa` optimized for code, prefer over `web_search_exa`
- **Brave**: 1 query/sec on free tier, ~2000 queries/month

---

## 10. Reference Files

Load these when you need more detail:

- `references/tools-capabilities.md` — Full capability matrix, rate limits, coverage
- `references/search-strategies.md` — Query rewriting, intent recognition, localization details
- `references/citation-guide.md` — Extended citation examples and edge cases
- `references/platform-tools.md` — Exact tool function names per platform
