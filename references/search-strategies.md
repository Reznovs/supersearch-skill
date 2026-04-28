# Search Strategies

## Search Localization — Language & Region Strategy

Different topics have different geographic/cultural origins. Adjust the query language distribution (Chinese/English/local language) accordingly.

### Topic Classification

#### China-topic → Chinese 70-80%, English 20-30%

Triggers: Chinese brands/companies (Huawei, Xiaomi, OPPO, ByteDance, Tencent, Alibaba, BYD), Chinese policy/events (Two Sessions, domestic regulations), Chinese market (A-shares, real estate), domestic substitution (local chips, IT localization)

4-engine allocation (US IP): WebSearch CN, Tavily CN, Exa EN, Brave CN
3-engine allocation (non-US): Tavily CN, Brave CN, Exa EN

#### Country-specific → Target language 70%, English 30%

Triggers: Events, policies, or companies clearly tied to a specific country. E.g., "France pension reform" → French, "Bank of Japan rate" → Japanese

4-engine allocation (US IP): WebSearch target-lang, Tavily target-lang, Exa EN, Brave target-lang
3-engine allocation (non-US): Tavily target-lang, Brave target-lang, Exa EN

#### Global/Universal → Chinese 50%, English 50%

Triggers: Global brands (iPhone, PlayStation), universal tech (Python, AI/ML), global markets (US stocks, oil), international entertainment (Hollywood movies)

4-engine allocation (US IP): WebSearch CN, Tavily CN, Exa EN, Brave EN
3-engine allocation (non-US): Tavily CN, Brave EN, Exa EN

### Language Allocation Matrix

| Topic Type | WebSearch* | Tavily | Exa | Brave |
|-----------|-----------|--------|-----|-------|
| China-topic | CN | CN | EN | CN |
| Global | CN | CN | EN | EN |
| Country-specific | target-lang | target-lang | EN | target-lang |

> \* WebSearch is only available with a US IP (see SKILL.md §4.1 Step 0). Outside the US, skip this column and use 3 engines (Tavily + Exa + Brave).

## Intent Recognition Rules

### Broad Search Triggers

**Chinese**: 全面搜索、交叉验证、多方对比、广泛调研、大范围、帮我全面查、核实一下
**English**: comprehensive, verify, fact check, cross-reference, multiple sources, broad search
**Implicit**: claims involving numbers/statistics/prices/dates, potentially controversial events, high-risk topics (medical/financial/legal)

### Precise Search Triggers

| Intent | Keywords | Tool |
|--------|----------|------|
| Code/programming | "找代码"、"查API"、"示例" | Exa |
| Latest news | "最新"、"今天"、"刚刚" | Brave |
| Deep research | "深入"、"全面了解"、"报告" | Tavily |
| Academic | "论文"、"学术"、"文献" | Exa |
| Website extraction | "爬取"、"抓取"、"提取内容" | Tavily |
| Quick lookup | "搜一下"、"什么是" | WebSearch (US IP only) / Tavily (non-US) |

## Query Rewriting Examples

### China-topic: "OPPO Find X9 release date"

Chinese queries (WebSearch* / Tavily / Brave; *US IP only):
```
OPPO Find X9 发布日期 2026 官方消息
```

English query (Exa):
```
OPPO Find X9 release date 2026 announcement
```

### Global topic: "Avengers Secret Wars"

Chinese queries (WebSearch* / Tavily; *US IP only):
```
复仇者联盟 秘密战争 上映日期 2026 漫威
```

English queries (Exa / Brave):
```
Avengers Secret Wars release date 2026 cast Marvel
```

## Parallel vs Sequential

| Scenario | Strategy | Reason |
|----------|----------|--------|
| Broad Search | 3-4 parallel (per IP check) | Multi-angle coverage |
| Precise Search | Primary tool → fallback if insufficient | Efficiency first |
| Quota constrained | Tavily first (no geo-restriction) → add more if needed | Save API quota |
| Nested research | Tavily map first → then crawl | Needs previous step's results |

## Result Synthesis

### Deduplication
1. Title similarity > 80% → treat as same result
2. Same domain + same topic → merge
3. Same content, different wording → independent source (加分)

### Sorting
1. High confidence (≥80%) first
2. Medium confidence (50-79%) middle
3. Conflicting and single-source last
