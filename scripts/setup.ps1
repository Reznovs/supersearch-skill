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
# 3-state: -1=user has no key (never ask)  0=undecided (will ask)  1=configured
Write-Info "Phase 2/5: Configuring API Keys..."
Write-Info "(Can be preset via environment variables: TAVILY_API_KEY / EXA_API_KEY / BRAVE_API_KEY)"

$KeysFile = Join-Path $SkillDir ".env"
$StateFile = Join-Path $SkillDir ".supersearch-state"

# Load existing .env if present (don't overwrite existing env vars)
if (Test-Path $KeysFile) {
    Get-Content $KeysFile | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.+)$') {
            $k = $Matches[1].Trim()
            $v = $Matches[2].Trim()
            if (-not [Environment]::GetEnvironmentVariable($k, "Process")) {
                [Environment]::SetEnvironmentVariable($k, $v, "Process")
            }
        }
    }
    Write-Info "Found existing .env file"
}

# Load state file: -1=skip forever, 0=ask, 1=configured
$state = @{ TAVILY = 0; EXA = 0; BRAVE = 0 }
if (Test-Path $StateFile) {
    Get-Content $StateFile | ForEach-Object {
        if ($_ -match '^([A-Z_]+)=(-?\d+)$') {
            $state[$Matches[1]] = [int]$Matches[2]
        }
    }
}

$needKeys = $false
$engineCount = 0

# Helper: validate engine key
function Test-EngineKey {
    param([string]$Engine, [string]$Key)
    try {
        switch ($Engine) {
            "TAVILY" {
                $body = @{ api_key = $Key; query = "test"; max_results = 1 } | ConvertTo-Json
                $r = Invoke-WebRequest -Uri "https://api.tavily.com/search" -Method Post -ContentType "application/json" -Body $body -TimeoutSec 5 -ErrorAction Stop
                return $r.StatusCode -in @(200, 201)
            }
            "EXA" {
                $body = @{ query = "test"; numResults = 1 } | ConvertTo-Json
                $r = Invoke-WebRequest -Uri "https://api.exa.ai/search" -Method Post -ContentType "application/json" -Headers @{"x-api-key" = $Key} -Body $body -TimeoutSec 5 -ErrorAction Stop
                return $r.StatusCode -in @(200, 201)
            }
            "BRAVE" {
                $r = Invoke-WebRequest -Uri "https://api.search.brave.com/res/v1/web/search?q=test&count=1" -Method Get -Headers @{"Accept" = "application/json"; "X-Subscription-Token" = $Key} -TimeoutSec 5 -ErrorAction Stop
                return $r.StatusCode -in @(200, 201)
            }
        }
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 401 -or $code -eq 403) { return $false }
        # Timeout/network errors → allow (don't block on transient failures)
        return $true
    }
    return $true
}

# Helper: ask for a single engine's key
function Ask-EngineKey {
    param(
        [string]$Engine,
        [string]$EnvVar,
        [string]$Url,
        [string]$Desc,
        [ref]$StateRef,
        [ref]$NeedKeysRef,
        [ref]$CountRef
    )
    $s = $StateRef.Value
    $currentVal = [Environment]::GetEnvironmentVariable($EnvVar, "Process")

    # Key exists → state = 1
    if ($currentVal) {
        $s[$Engine] = 1
        Write-Ok "$EnvVar configured"
        $CountRef.Value++
        return $currentVal
    }

    # State -1 → user said "no", skip forever
    if ($s[$Engine] -eq -1) {
        Write-Info "$EnvVar : marked as unavailable, skipping ($Desc disabled)"
        return $null
    }

    # State 0 → ask
    Write-Warn "$EnvVar not found"
    Write-Host "  Options:"
    Write-Host "    Enter API Key  → configure this engine"
    Write-Host "    Press Enter    → skip, will ask next time"
    Write-Host "    Type 'n'       → mark as unavailable, never ask again"
    $input = Read-Host "  Enter key (get from $Url)"

    if ($input -eq 'n' -or $input -eq 'N') {
        $confirm = Read-Host "  Confirm mark $Engine as unavailable? Won't ask again [y/N]"
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            $s[$Engine] = -1
            Write-Info "  Marked as unavailable"
        } else {
            $s[$Engine] = 0
            Write-Info "  Cancelled, skipping"
        }
        return $null
    } elseif ($input) {
        # Validate key
        if (Test-EngineKey -Engine $Engine -Key $input) {
            $s[$Engine] = 1
            $NeedKeysRef.Value = $true
            $CountRef.Value++
            return $input
        } else {
            Write-Warn "  Key validation failed (invalid or expired), skipping $Engine"
            $s[$Engine] = 0
            return $null
        }
    } else {
        $s[$Engine] = 0
        Write-Info "  Skipped, will ask next time"
        return $null
    }
}

$tavilyKey = Ask-EngineKey "TAVILY" "TAVILY_API_KEY" "https://app.tavily.com" "deep research" ([ref]$state) ([ref]$needKeys) ([ref]$engineCount)
$exaKey    = Ask-EngineKey "EXA"    "EXA_API_KEY"    "https://dashboard.exa.ai" "code/academic search" ([ref]$state) ([ref]$needKeys) ([ref]$engineCount)
$braveKey  = Ask-EngineKey "BRAVE"  "BRAVE_API_KEY"  "https://brave.com/search/api/" "news search" ([ref]$state) ([ref]$needKeys) ([ref]$engineCount)

# Save state file
@"
# SuperSearch engine state: -1=no(skip forever) 0=ask 1=configured
TAVILY=$($state['TAVILY'])
EXA=$($state['EXA'])
BRAVE=$($state['BRAVE'])
"@ | Set-Content -Path $StateFile -Encoding UTF8

if ($engineCount -eq 0) {
    if ($state['TAVILY'] -eq -1 -and $state['EXA'] -eq -1 -and $state['BRAVE'] -eq -1) {
        Write-Err "All engines marked as unavailable. Delete .supersearch-state and re-run to reconfigure."
    } else {
        Write-Err "No API Keys configured! At least one search engine is required."
    }
    exit 1
}

if ($needKeys) {
    @"
# SuperSearch API Keys — Do NOT commit to Git
# Leave blank to skip that engine
TAVILY_API_KEY=$tavilyKey
EXA_API_KEY=$exaKey
BRAVE_API_KEY=$braveKey
"@ | Set-Content -Path $KeysFile -Encoding UTF8

    Write-Ok "API Keys saved to $KeysFile ($engineCount engine(s) available)"
    Write-Info "This file is in .gitignore and will not be committed to GitHub"
}

# ── Phase 3: Deploy to Platforms ───────────────────────────
Write-Info "Phase 3/5: Installing Skill to platforms..."

$platformsInstalled = 0

# Helper: deploy skill to a target directory
function Deploy-Skill {
    param([string]$TargetPath, [string]$PlatformName)
    $parentDir = Split-Path -Parent $TargetPath
    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
    if (Test-Path $TargetPath) { Remove-Item -Recurse -Force $TargetPath }
    Copy-Item -Recurse -Force $SkillDir $TargetPath
    @(".git", ".gitignore", ".env", ".supersearch-state") | ForEach-Object {
        $p = Join-Path $TargetPath $_
        if (Test-Path $p) { Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue }
    }
    Write-Ok "${PlatformName}: $TargetPath"
    $script:platformsInstalled++
}

# Claude Code
$homePath = $env:USERPROFILE
$ccSwitch = Join-Path $homePath ".cc-switch\skills"
$claudeSkills = Join-Path $homePath ".claude\skills"

if (Test-Path $ccSwitch) {
    Deploy-Skill (Join-Path $ccSwitch $SkillName) "Claude Code"
} elseif (Test-Path $claudeSkills) {
    Deploy-Skill (Join-Path $claudeSkills $SkillName) "Claude Code"
} else {
    Deploy-Skill (Join-Path $claudeSkills $SkillName) "Claude Code"
}

# Codex
$codexDir = Join-Path $homePath ".codex"
if (Test-Path $codexDir) {
    Deploy-Skill (Join-Path $codexDir "skills\user\$SkillName") "Codex"
} else {
    Write-Info "Codex not installed, skipping"
}

# OpenCode
$ocDir = Join-Path $homePath ".config\opencode"
if (Test-Path $ocDir) {
    Deploy-Skill (Join-Path $ocDir "skills\$SkillName") "OpenCode"
} else {
    Write-Info "OpenCode not installed, skipping"
}

if ($platformsInstalled -eq 0) {
    Write-Err "No platforms found! Please install Claude Code / Codex / OpenCode first."
    exit 1
}

# ── Phase 4: MCP Server Registration ──────────────────────
Write-Info "Phase 4/5: Registering MCP servers..."

$claude = Get-Command claude -ErrorAction SilentlyContinue

function Register-MCPServer {
    param([string]$Name, [string]$Pkg, [string[]]$ExtraArgs = @())
    if (-not $claude) { return }
    & claude mcp get $Name 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$Name MCP already registered"
        return
    }
    Write-Info "Registering $Name MCP Server..."
    try {
        $args = @("mcp", "add", $Name, "--", "npx", "-y", $Pkg) + $ExtraArgs
        & claude @args
        Write-Ok "$Name MCP registered"
    } catch {
        Write-Warn "$Name MCP registration failed. Please run manually:"
        Write-Host "  claude mcp add $Name -- npx -y $Pkg $($ExtraArgs -join ' ')"
    }
}

if ($tavilyKey) { Register-MCPServer "tavily" "tavily-mcp@latest" }
if ($exaKey)    { Register-MCPServer "exa" "exa-mcp-server@latest" }
if ($braveKey)  { Register-MCPServer "brave-search" "@brave/brave-search-mcp-server" @("--brave-api-key", $braveKey) }

if (-not $claude) {
    Write-Warn "'claude' command not found, skipping MCP registration"
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
