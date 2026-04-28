# Platform Tool Name Mapping

SuperSearch follows the agentskills.io open standard and is compatible with multiple Agent platforms. This file lists the exact tool names per platform for reference when calling tools.

## Claude Code

| Capability | Claude Code Tool Name |
|-----------|----------------------|
| General web search | `WebSearch` (US IP only, see SKILL.md §4.1 Step 0) |
| Tavily search | `mcp__tavily__tavily_search` |
| Tavily extract | `mcp__tavily__tavily_extract` |
| Tavily crawl | `mcp__tavily__tavily_crawl` |
| Tavily map | `mcp__tavily__tavily_map` |
| Tavily research | `mcp__tavily__tavily_research` |
| Exa web search | `mcp__exa__web_search_exa` |
| Exa code search | `mcp__exa__get_code_context_exa` |
| Brave web search | `mcp__brave__brave_web_search` |
| Brave news search | `mcp__brave__brave_news_search` |

## Codex

| Capability | Codex Tool Name |
|-----------|----------------|
| General web search | `web_search` (US IP only) |
| Tavily search | MCP tool names same as Claude Code |
| Exa search | MCP tool names same as Claude Code |
| Brave search | MCP tool names same as Claude Code |

> Codex supports the same MCP tools through its MCP integration. Tool names follow the `mcp__<server>__<tool>` pattern.

## OpenCode

| Capability | OpenCode Tool Name |
|-----------|-------------------|
| General web search | Depends on configured search backend |
| Tavily/Exa/Brave | Via MCP integration, similar tool name pattern |

> OpenCode's MCP support depends on its specific version configuration. Check OpenCode docs for the latest MCP tool naming conventions.

## Generic Capability Descriptions

In SKILL.md, we use generic capability descriptions rather than specific tool names. Each platform's Agent should use this mapping table to select the appropriate tool:

| SKILL.md Description | Actual Capability |
|---------------------|-------------------|
| "web search" | General web search (US IP only) |
| "Tavily search / crawl / extract / map / research" | Tavily's 5 MCP tools |
| "Exa code search / web search" | Exa's 2 MCP tools |
| "Brave web search / news search" | Brave's 2 MCP tools |

## Adding a New Platform

To use SuperSearch on a new platform:
1. Confirm the platform's search tool names
2. Add a new platform section to this file
3. Test that SKILL.md's generic instructions correctly map to the tools

No changes to SKILL.md itself are needed.
