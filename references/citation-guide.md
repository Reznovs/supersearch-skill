# Citation Guide

## Design Philosophy

Traditional academic citations (marking [1][2] after every sentence) cause two problems in AI output:
1. **Poor readability** — excessive markers interrupt reading flow
2. **Over-fragmentation** — consecutive sentences usually come from the same few sources

SuperSearch uses **paragraph-level citations**: after a logical paragraph ends, cite all sources and confidence score together.

## Confidence Scoring

| Condition | Score | Meaning |
|-----------|-------|---------|
| 4+ sources highly consistent, all authoritative | 100% | Near certain |
| 3 sources highly consistent, authoritative | 95% | Highly reliable |
| 2-3 sources mostly consistent | 80-90% | Reliable |
| 2-3 sources consistent but some non-authoritative | 70-80% | Fairly reliable |
| 2 sources consistent, some details模糊 | 60-70% | Use as reference |
| Sources partially consistent with different emphasis | 50-60% | Use with caution |
| Sources clearly contradict | "Conflicting" | State both sides |
| Only 1 source | "Single source" | Cannot cross-verify |
| Single source + low credibility | "Single source, low credibility" | Cite cautiously |

## Handling Source Conflicts

Do not use percentages. Explicitly list the disagreement:

```
The casualty figures for this event remain uncertain.
[1][2] (Conflicting)
  Source 1 (Reuters): Reports 12 deaths
  Source 2 (AFP): Reports 8 deaths
```

## Paragraph Splitting Guide

A good citation paragraph = one independent topic sub-unit, containing 2-5 related sentences.

**Correct — one complete topic paragraph:**
```
DeepSeek V4 was released as Preview on April 24. It launched two versions:
V4-Pro (1.6T) and V4-Flash (284B), both supporting 1M token context with
MIT license. API pricing is extremely low.
[1][2][3] (Confidence: 100%)
```

**Wrong — over-split, breaks reading flow:**
```
DeepSeek V4 was released on April 24. [1][2]  ← Don't break here
It launched Pro and Flash versions. [1][3]     ← Don't break here
Supports 1M context. [2][3]                    ← Don't break here
```

## When to Start a New Paragraph

- Topic switch (from "release timeline" to "performance comparison")
- Source set changes (previous paragraph cites [1][2], now cites [3][4])
- Confidence score differs significantly (previous 95%, now 60%)
- Need to flag a conflict

## Numbering Rules

- Number sources sequentially across the entire response; reuse the same number for the same source
- Start from [1], no gaps
- Do not include unnumbered sources in the final source list

## Complete Output Example

```
## Search Results: DeepSeek V4 Release Information

### Key Takeaways
DeepSeek officially released V4 Preview on April 24, 2026. It launched two
versions: V4-Pro (1.6T) and V4-Flash (284B), both supporting 1M token
context under MIT license. Flash API pricing is only 2 yuan per million tokens.
[1][2][3][4] (Confidence: 100%)

### Detailed Findings

**Release Timeline**: Originally expected in February, delayed to March,
and finally landed on April 24. The founder's internal communication confirmed
the late-April target was met.
[1][2][3] (Confidence: 100%)

**Architecture Innovation**: Uses CSA + HCA hybrid attention and DSA sparse
attention. Significantly reduces compute and memory costs for 1M token
long-context scenarios.
[4][5] (Confidence: 80%)

**Domestic Chip Compatibility**: Huawei Ascend confirmed support for V4.
However, the actual proportion of Huawei chips used in training remains disputed
across different analyses.
[6][7] (Confidence: 50%)

---

### Sources
[1] DeepSeek API Docs — https://api-docs.deepseek.com/news/news260424
[2] Fortune — https://fortune.com/2026/04/24/deepseek-v4
[3] CNBC — https://www.cnbc.com/2026/04/24/deepseek-v4
[4] Simon Willison — https://simonwillison.net/2026/Apr/24/deepseek-v4/
[5] MIT Tech Review — https://www.technologyreview.com/2026/04/24/1136422/
[6] Sohu Tech — https://www.sohu.com/a/1013995823_121448078
[7] Bloomberg — https://www.bloomberg.com/news/articles/2026-04-24/deepseek
```
