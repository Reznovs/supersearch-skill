# Four-Tool Capability Matrix

## Overview

| Dimension | WebSearch* | Tavily | Exa | Brave Search |
|-----------|-----------|--------|-----|--------------|
| **Core capability** | General web search | Search+extract+crawl+map+deep research | Code search+academic search | Web+news+image+video+local |
| **Freshness** | Medium (depends on index refresh) | Medium-high | Medium | High (news index: minute-level) |
| **Coverage** | Google index | Self-built index | Self-built (GitHub+academic focus) | Self-built independent index |
| **Rate limits** | Unlimited (built-in tool) | Generous | Generous | Free tier: 1 QPS / 2000 req/month |
| **Cost** | Free (Claude Code built-in) | Free tier | Free tier | Free $5/month credit |
| **LLM optimized** | Yes (native integration) | Yes (purpose-built) | Yes | Yes |

> \* WebSearch is only available with a US IP (see SKILL.md §4.1 Step 0). Outside the US, this column is skipped and 3 engines (Tavily + Exa + Brave) are used.

## WebSearch (Built-in)

**Best for:**
- Quick fact lookups ("what is XXX")
- Broad coverage (any domain)
- No API key required

**Limitations:**
- Cannot deep-crawl
- Cannot extract specific page content
- No structured aggregation
- **Geo-restriction:** Only available with a US IP. Automatically skipped outside the US.

## Tavily

**5 capabilities:**

| Tool | Function | Best for |
|------|----------|----------|
| `tavily_search` | Web search | General search with depth/breadth params |
| `tavily_extract` | Page content extraction | Fetching raw content from specific URLs |
| `tavily_crawl` | Site crawling | Multi-level crawl from a starting URL |
| `tavily_map` | Site structure mapping | Understanding a site's URL structure |
| `tavily_research` | Deep research | Multi-source aggregation, auto-generated reports |

**When to prefer Tavily:**
- Deep research on a topic (→ research)
- Extracting content from specific sites (→ extract)
- Understanding site structure (→ map)
- Multi-page crawling (→ crawl)

**Limitations:**
- `tavily_research` is token-intensive
- Some dynamic sites may not extract correctly

## Exa

**2 core capabilities:**

| Tool | Function | Best for |
|------|----------|----------|
| `web_search_exa` | General search | Web search with academic/news filters |
| `get_code_context_exa` | Code search | GitHub + Stack Overflow + docs |

**When to prefer Exa:**
- Finding code examples, API usage, library patterns (→ get_code_context_exa)
- Academic papers and literature (→ web_search_exa with academic filter)
- Technical depth beyond blog posts
- "How do I use this function" / "Does this library support X" / "How to fix this error"

**Limitations:**
- Less coverage for non-technical content vs general search engines
- Less timely for news than Brave

## Brave Search

**5 core capabilities:**

| Tool | Function | Best for |
|------|----------|----------|
| `brave_web_search` | Web search | General search with image/video filters |
| `brave_news_search` | News search | Latest news, breaking events in real-time |
| `brave_image_search` | Image search | Finding image assets |
| `brave_video_search` | Video search | Finding video content |
| `brave_local_search` | Local search | Local business, POI information |

**When to prefer Brave:**
- Latest news/event coverage (→ news_search)
- High-freshness information verification
- Privacy-first search needs
- Multimedia content (images, videos)
- Local business/location information

**Limitations:**
- Free tier: 1 QPS, not suitable for batch concurrency
- Monthly quota: 2000 requests (free tier)
- Code search less specialized than Exa
- Deep research less comprehensive than Tavily

## Combination Strategy

| Goal | Primary tool | Secondary tool | Notes |
|------|-------------|----------------|-------|
| Technical research | Exa | Tavily (+ WebSearch if US IP) | Exa for code, Tavily for depth, WebSearch for breadth (US only) |
| News verification | Brave | Tavily | Brave for freshness, Tavily for cross-validation |
| Academic research | Exa | Tavily | Exa academic filter, Tavily crawl for citations |
| Industry research | Tavily | Brave + Exa | Tavily research aggregation, Brave for latest, Exa for technical |
| Quick Q&A | WebSearch (US IP) / Tavily | — | Fastest zero-latency query (US only); Tavily for non-US |
