# SuperSearch Skill — One-Click Install (PowerShell)
# Compatible: Claude Code / Codex / OpenCode
# Platform: Windows (PowerShell 5.1+ / PowerShell Core 7+)
# Design: Idempotent, interactive, fault-tolerant

$ErrorActionPreference = "Stop"

# ── Color output ──────────────────────────────────────────
function Write-Info  { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[ERR ] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "========================================" -ForegroundColor Blue
Write-Host "  SuperSearch Skill — One-Click Install" -ForegroundColor Blue
Write-Host "  3-4 Engine Unified Search" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

# ── Phase 1: Environment Check ────────────────────────────
Write-Info "Phase 1/5: Checking environment..."

$failures = 0

# Check Node.js
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Err "Node.js not found (requires 18+). Install from: https://nodejs.org"
    $failures++
} else {
    $nodeVersion = (node -v) -replace 'v','' -split '\.' | Select-Object -First 1
    Write-Ok "Node.js $(node -v)"
}

# Check npx
$npx = Get-Command npx -ErrorAction SilentlyContinue
if (-not $npx) {
    Write-Err "npx not found (usually comes with Node.js)"
    $failures++
} else {
    Write-Ok "npx"
}

# Skill source directory
$SkillDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SkillName = "supersearch"
Write-Ok "Skill source: $SkillDir"

if ($failures -gt 0) {
    Write-Err "Please fix the above $failures issue(s) and re-run."
    exit 1
}

# ── Phase 2: API Keys ─────────────────────────────────────
Write-Info "Phase 2/5: Configuring API Keys..."
Write-Info "(Can be preset via environment variables: TAVILY_API_KEY / EXA_API_KEY / BRAVE_API_KEY)"

$KeysFile = Join-Path $SkillDir ".env"

# Load existing .env if present
if (Test-Path $KeysFile) {
    Get-Content $KeysFile | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.+)$') {
            [Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
        }
    }
    Write-Info "Found existing .env file"
}

$needKeys = $false

# Tavily
$tavilyKey = [Environment]::GetEnvironmentVariable("TAVILY_API_KEY", "Process")
if (-not $tavilyKey) {
    Write-Warn "TAVILY_API_KEY not found"
    $tavilyKey = Read-Host "  Enter Tavily API Key (get from https://app.tavily.com)"
    $needKeys = $true
} else {
    Write-Ok "TAVILY_API_KEY configured"
}

# Exa
$exaKey = [Environment]::GetEnvironmentVariable("EXA_API_KEY", "Process")
if (-not $exaKey) {
    Write-Warn "EXA_API_KEY not found"
    $exaKey = Read-Host "  Enter Exa API Key (get from https://dashboard.exa.ai)"
    $needKeys = $true
} else {
    Write-Ok "EXA_API_KEY configured"
}

# Brave
$braveKey = [Environment]::GetEnvironmentVariable("BRAVE_API_KEY", "Process")
if (-not $braveKey) {
    Write-Warn "BRAVE_API_KEY not found"
    $braveKey = Read-Host "  Enter Brave Search API Key (get from https://brave.com/search/api/)"
    $needKeys = $true
} else {
    Write-Ok "BRAVE_API_KEY configured"
}

if ($needKeys) {
    @"
# SuperSearch API Keys — Do NOT commit to Git
TAVILY_API_KEY=$tavilyKey
EXA_API_KEY=$exaKey
BRAVE_API_KEY=$braveKey
"@ | Set-Content -Path $KeysFile -Encoding UTF8

    Write-Ok "API Keys saved to $KeysFile"
    Write-Info "This file is in .gitignore and will not be committed to GitHub"
}

# ── Phase 3: Deploy to Platforms ───────────────────────────
Write-Info "Phase 3/5: Installing Skill to platforms..."

$platformsInstalled = 0

# Claude Code
function Install-ToClaude {
    $homePath = $env:USERPROFILE
    $ccSwitch = Join-Path $homePath ".cc-switch\skills"
    $claudeSkills = Join-Path $homePath ".claude\skills"

    if (Test-Path $ccSwitch) {
        $target = Join-Path $ccSwitch $using:SkillName
    } elseif (Test-Path $claudeSkills) {
        $target = Join-Path $claudeSkills $using:SkillName
    } else {
        $target = Join-Path $claudeSkills $using:SkillName
    }

    $parentDir = Split-Path -Parent $target
    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }

    # Copy excluding .git, .gitignore, .env
    Copy-Item -Recurse -Force $using:SkillDir $target
    @(".git", ".gitignore", ".env") | ForEach-Object {
        $p = Join-Path $target $_
        if (Test-Path $p) { Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue }
    }

    Write-Ok "Claude Code: $target"
    $using:platformsInstalled++
}

# Codex
function Install-ToCodex {
    $homePath = $env:USERPROFILE
    $codexDir = Join-Path $homePath ".codex"

    if (Test-Path $codexDir) {
        $target = Join-Path $codexDir "skills\user\$using:SkillName"
        $parentDir = Split-Path -Parent $target
        if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        if (Test-Path $target) { Remove-Item -Recurse -Force $target }

        Copy-Item -Recurse -Force $using:SkillDir $target
        @(".git", ".gitignore", ".env") | ForEach-Object {
            $p = Join-Path $target $_
            if (Test-Path $p) { Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue }
        }

        Write-Ok "Codex: $target"
        $using:platformsInstalled++
    } else {
        Write-Info "Codex not installed, skipping"
    }
}

# OpenCode
function Install-ToOpenCode {
    $homePath = $env:USERPROFILE
    $ocDir = Join-Path $homePath ".config\opencode"

    if (Test-Path $ocDir) {
        $target = Join-Path $ocDir "skills\$using:SkillName"
        $parentDir = Split-Path -Parent $target
        if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        if (Test-Path $target) { Remove-Item -Recurse -Force $target }

        Copy-Item -Recurse -Force $using:SkillDir $target
        @(".git", ".gitignore", ".env") | ForEach-Object {
            $p = Join-Path $target $_
            if (Test-Path $p) { Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue }
        }

        Write-Ok "OpenCode: $target"
        $using:platformsInstalled++
    } else {
        Write-Info "OpenCode not installed, skipping"
    }
}

Install-ToClaude
Install-ToCodex
Install-ToOpenCode

if ($platformsInstalled -eq 0) {
    Write-Err "No platforms found! Please install Claude Code / Codex / OpenCode first."
    exit 1
}

# ── Phase 4: MCP Server Registration ──────────────────────
Write-Info "Phase 4/5: Checking MCP server configuration..."

$claude = Get-Command claude -ErrorAction SilentlyContinue
if ($claude) {
    # Brave Search MCP
    $braveRegistered = & claude mcp get brave-search 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Brave Search MCP registered"
    } else {
        Write-Info "Registering Brave Search MCP Server..."
        try {
            & claude mcp add brave-search -- npx -y "@brave/brave-search-mcp-server" --brave-api-key $braveKey
            Write-Ok "Brave Search MCP registered"
        } catch {
            Write-Warn "Brave Search MCP registration failed. Please run manually:"
            Write-Host "  claude mcp add brave-search -- npx -y @brave/brave-search-mcp-server --brave-api-key <your_key>"
        }
    }

    # Check Tavily
    & claude mcp get tavily 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Tavily MCP registered"
    } else {
        Write-Warn "Tavily MCP not found. Please register Tavily MCP Server."
    }

    # Check Exa
    & claude mcp get exa 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Exa MCP registered"
    } else {
        Write-Warn "Exa MCP not found. Please register Exa MCP Server."
    }
} else {
    Write-Warn "'claude' command not found, skipping MCP check"
    Write-Info "Please configure search MCP servers in your Agent platform."
}

# ── Phase 5: Summary ──────────────────────────────────────
Write-Info "Phase 5/5: Installation complete!"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  SuperSearch Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Platforms installed: $platformsInstalled"
Write-Host "  Skill path: $SkillDir"
Write-Host ""
Write-Host "  ── Next Steps ──"
Write-Host "  1. Add tool permissions in Claude Code (if not already):"
Write-Host "     Edit ~/.claude/settings.local.json, add:"
Write-Host ""
Write-Host '     "permissions": {'
Write-Host '       "allow": ['
Write-Host '         "mcp__tavily__tavily_search",'
Write-Host '         "mcp__tavily__tavily_extract",'
Write-Host '         "mcp__tavily__tavily_crawl",'
Write-Host '         "mcp__tavily__tavily_map",'
Write-Host '         "mcp__tavily__tavily_research",'
Write-Host '         "mcp__exa__web_search_exa",'
Write-Host '         "mcp__exa__get_code_context_exa",'
Write-Host '         "mcp__brave__brave_web_search",'
Write-Host '         "mcp__brave__brave_news_search",'
Write-Host '         "WebSearch(*)"'
Write-Host '       ]'
Write-Host '     }'
Write-Host ""
Write-Host "  2. Verify installation (restart Claude Code first):"
Write-Host '     "Use supersearch to search AI safety latest progress"'
Write-Host ""
Write-Host "  3. Broad Search:"
Write-Host '     "supersearch, help me investigate XXX"'
Write-Host ""
Write-Host "  4. Precise Search:"
Write-Host '     "supersearch, find code examples for XXX"'
Write-Host ""

if ($claude) {
    Write-Host "  ── Current MCP Server Status ──"
    & claude mcp list 2>$null
}

Write-Host ""
Write-Host "  More info: $SkillDir\README.md"
Write-Host ""
