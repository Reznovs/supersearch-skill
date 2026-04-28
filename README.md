# SuperSearch

> 3-4 engine unified search with academic-style citation markers. Make AI accountable for every sentence.

## Overview

SuperSearch is an Agent Skill that orchestrates 3-4 search engines (Tavily, Exa, Brave Search + WebSearch when US IP detected) to solve three core AI search problems: narrow coverage, shallow depth, and hallucination.

Each factual claim is tagged with a citation marker:
- **[✅N]** Verified — confirmed by ≥2 independent sources
- **[⚠️N]** Conflicting — sources disagree
- **[❓N]** Unverified — single source only

Every response ends with a complete source list with URLs.

## Quick Start

```bash
git clone https://github.com/<your-org>/supersearch-skill.git
cd supersearch-skill
bash scripts/setup.sh
```

## Features

- 3-4 engines: Tavily + Exa + Brave + WebSearch (auto-detected by IP region)
- Two modes: Broad Search (parallel + cross-validation) and Precise Search (intent-based tool selection)
- Academic-style citation markers on every factual claim
- Cross-platform: Claude Code, Codex, OpenCode (agentskills.io standard)
- One-command install

## Requirements

- Node.js 18+
- Claude Code / Codex / OpenCode
- 3 API keys: [Tavily](https://app.tavily.com), [Exa](https://dashboard.exa.ai), [Brave](https://brave.com/search/api/)

## License

MIT — see [LICENSE](LICENSE).
