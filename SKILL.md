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

# SuperSearch — Configuration Gate (MANDATORY — runs BEFORE everything else)

**YOU MUST COMPLETE THIS GATE BEFORE DOING ANYTHING ELSE. DO NOT SKIP. DO NOT PROCEED TO SEARCH.**

## Step 0: Read Configuration State

**0a. Find and read `.supersearch-state`** — This file is in the skill's root directory. Read it now.

The file contains 3 lines, one per engine:
```
TAVILY=<value>
EXA=<value>
BRAVE=<value>
```

**0b. Interpret each value:**

| Value | Meaning | Your action |
|-------|---------|-------------|
| `1` | Engine configured with valid API key | ✅ Ready — no action needed |
| `-1` | User explicitly has no key (marked "never ask") | ⏭️ Skip — do NOT ask about this engine |
| `0` | Not yet configured | 🚫 **BLOCKED — you MUST resolve this before ANY search** |

**0c. Check for blockers:**

- If **ALL engines are `1` or `-1`** (no `0` exists) → Configuration complete. Proceed to §1 (Quick Decision).
- If **ANY engine is `0`** → You are BLOCKED. Go to Step 0d immediately.

**0d. Resolve `0` engines — FORCE USER INTERACTION:**

For EACH engine with state `0`, ask the user:

```
[Engine Name] 尚未配置。
  选项：
    1. 提供 API Key → 我来配置该引擎
    2. 输入 n → 标记为「无」，以后不再询问

  获取 Key: [URL]
```

- **User provides key** → Validate it (call the API, check for 401/403). If valid, write to `.env`, update state to `1`. If invalid, tell user and ask again.
- **User says `n`** → Update state to `-1`. Tell user: "已标记为无。如需恢复，删除 `.supersearch-state` 文件后重新触发 skill。"
- **User says something else** → Ask again. Do NOT proceed until resolved.

**0e. After ALL `0`s are resolved** → Re-read `.supersearch-state`. Confirm no `0` remains. Then proceed to §1.

**0f. After resolving** → Output confirmation:
```
引擎配置状态：
- Tavily:    [已配置/已跳过]
- Exa:       [已配置/已跳过]
- Brave:     [已配置/已跳过]
共 X 个引擎已配置，可以开始搜索。
```

---

**STATE FILE NOT FOUND?** If `.supersearch-state` does not exist:
1. Create it with all engines set to `0`
2. Run Step 0d for all 3 engines
3. Then proceed

**CRITICAL RULES:**
- 🚫 NEVER search with an engine that has state `0` — it has no API key
- 🚫 NEVER skip this gate — even if the user's request seems urgent
- 🚫 NEVER assume an engine is available without checking the state file
- 🚫 NEVER proceed to §1 while any engine is `0`
- ✅ ALWAYS resolve every `0` before continuing

---

# SuperSearch — Unified Multi-Engine Search

## 1. Quick Decision: Broad vs Precise

**Before choosing a mode: Complete §4.1 Step 0 (runtime engine check). No search is valid without it.**

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

### 2.4 Output Language

- **Agent output language MUST match the user's input language**
- If user writes in Chinese → entire response in Chinese (including section headers, confidence labels, error messages)
- If user writes in English → entire response in English
- If user writes in another language → respond in that language
- NEVER switch language mid-response — pick one and stick with it

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

**STOP. DO NOT CALL ANY SEARCH TOOL UNTIL STEP 0 IS FULLY COMPLETE.**

0. **Runtime Engine Check — verify which configured engines are ACTUALLY usable right now**

   **Note:** The Configuration Gate (top of SKILL.md) already ensured no engine has state `0`. This step checks runtime availability.

   **0a. Check MCP tools** — Look at your available tool list RIGHT NOW:
   - `mcp__tavily__tavily_search` in your tools → Tavily = YES
   - `mcp__exa__web_search_exa` in your tools → Exa = YES
   - `mcp__brave__brave_web_search` in your tools → Brave = YES
   - Any tool NOT in your list → that engine = NO (even if state=1, MCP may not be loaded)
   - **Rule: tool NOT in list = engine unavailable. Do NOT use Bash echo, placeholder, or any substitute.**

   **0b. Check WebSearch geo-availability** — Run: `curl -s --max-time 3 "http://ip-api.com/json/?fields=countryCode" 2>/dev/null`
   - `"countryCode":"US"` → WebSearch = YES
   - ANYTHING ELSE (CN, non-US, timeout, error, curl unavailable) → WebSearch = **NO**
   - **CRITICAL: WebSearch in your tool list does NOT mean it works. If IP is not US, WebSearch = NO. Do NOT call it.**

   **0c. Output engine status table to user** (YOU MUST OUTPUT THIS):
   ```
   引擎可用性检查：
   - Tavily:    [可用/不可用] (MCP工具是否存在)
   - Exa:       [可用/不可用] (MCP工具是否存在)
   - Brave:     [可用/不可用] (MCP工具是否存在)
   - WebSearch: [可用/不可用] (IP检测结果)
   共 X 个引擎可用。
   ```

   **0d. Handle results:**
   - **0 engines available** → Tell user: "配置的引擎在当前环境不可用（MCP 未加载或 IP 限制）。请检查 MCP 服务器配置。" → STOP
   - **1+ engines available** → Proceed to Step 1

   **0e. Validate keys at runtime** — When calling an engine, if it returns 401/403:
   - Skip that engine for this search
   - Inform the user: "[Engine] API key 无效或已过期，跳过该引擎"
   - Continue with remaining engines

   **0f. Cross-validation rule** — With only 1 engine, mark ALL results as `(Single source)`. With 2+ engines, calculate confidence normally.

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

1. **Check tool availability FIRST** — Before selecting a tool, verify it exists in your tool list. If the selected tool is NOT available, pick the next best from the table. If NO tools are available, inform the user: "配置的引擎在当前环境不可用，请检查 MCP 服务器配置。"
2. Identify intent from user's request
3. Select the BEST single tool (only from available tools)
4. Apply localization: write the query in the appropriate language
5. Fire the tool with optimized query
6. If poor results → fall back to second choice → Broad Search (if ≥2 engines available)

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
- Output language MUST match the user's language — if the user writes in Chinese, respond in Chinese; if in English, respond in English. Do NOT switch languages mid-response.
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
- NEVER use Bash echo, placeholder text, or any substitute for MCP tool calls — if a tool is unavailable, skip it and inform the user
- NEVER call WebSearch when IP is not US — it WILL return 0 results. The tool being in your list does NOT mean it works.
- NEVER skip the Configuration Gate (top of SKILL.md) — you MUST read `.supersearch-state` and resolve all `0` engines before ANY search
- NEVER skip the runtime engine check (§4.1 Step 0) — you MUST output the availability summary before any search

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
