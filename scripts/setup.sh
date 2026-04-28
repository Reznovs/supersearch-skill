#!/usr/bin/env bash
# SuperSearch Skill — 一键安装脚本
# 兼容: Claude Code / Codex / OpenCode
# 设计: 幂等、交互式、容错
set -euo pipefail

# ── 颜色输出 ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR ]${NC} $*"; }

echo "╔══════════════════════════════════════════════╗"
echo "║     SuperSearch Skill — 一键安装            ║"
echo "║     4引擎统一搜索 + 交叉验证引用            ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Phase 1: 环境检测 ─────────────────────────────────────
info "Phase 1/5: 检测运行环境..."

failures=0

if ! command -v node &>/dev/null; then
    err "未找到 Node.js（需要 18+）。请先安装: https://nodejs.org"
    failures=$((failures + 1))
else
    node_ver=$(node -v | sed 's/v//' | cut -d. -f1)
    ok "Node.js $(node -v) ✓"
fi

if ! command -v npx &>/dev/null; then
    err "未找到 npx（通常随 Node.js 安装）"
    failures=$((failures + 1))
else
    ok "npx ✓"
fi

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_NAME="supersearch"
ok "Skill 源目录: $SKILL_DIR"

if (( failures > 0 )); then
    err "请修复以上 $failures 个环境问题后重新运行。"
    exit 1
fi

# ── Phase 2: 收集 API Keys ─────────────────────────────────
info "Phase 2/5: 配置 API Keys..."
info "（可从环境变量预设: TAVILY_API_KEY / EXA_API_KEY / BRAVE_API_KEY）"

KEYS_FILE="$SKILL_DIR/.env"

# 读取已有值
if [[ -f "$KEYS_FILE" ]]; then
    source "$KEYS_FILE" 2>/dev/null || true
    info "已检测到现有 .env 文件"
fi

need_keys=false

# Tavily
if [[ -z "${TAVILY_API_KEY:-}" ]]; then
    warn "未检测到 TAVILY_API_KEY"
    echo -n "  请输入 Tavily API Key（从 https://app.tavily.com 获取）: "
    read -r TAVILY_API_KEY
    need_keys=true
else
    ok "TAVILY_API_KEY 已配置 ✓"
fi

# Exa
if [[ -z "${EXA_API_KEY:-}" ]]; then
    warn "未检测到 EXA_API_KEY"
    echo -n "  请输入 Exa API Key（从 https://dashboard.exa.ai 获取）: "
    read -r EXA_API_KEY
    need_keys=true
else
    ok "EXA_API_KEY 已配置 ✓"
fi

# Brave
if [[ -z "${BRAVE_API_KEY:-}" ]]; then
    warn "未检测到 BRAVE_API_KEY"
    echo -n "  请输入 Brave Search API Key（从 https://brave.com/search/api/ 获取）: "
    read -r BRAVE_API_KEY
    need_keys=true
else
    ok "BRAVE_API_KEY 已配置 ✓"
fi

if $need_keys; then
    # 写入 .env（不会被 git 追踪，已在 .gitignore 中）
    cat > "$KEYS_FILE" <<EOF
# SuperSearch API Keys — 不要提交到 Git
TAVILY_API_KEY=$TAVILY_API_KEY
EXA_API_KEY=$EXA_API_KEY
BRAVE_API_KEY=$BRAVE_API_KEY
EOF
    ok "API Keys 已保存到 $KEYS_FILE"
    info "此文件已在 .gitignore 中，不会被提交到 GitHub"
fi

# ── Phase 3: 安装到各平台 ──────────────────────────────────
info "Phase 3/5: 安装 Skill 文件到各平台..."

PLATFORMS_INSTALLED=0

# Claude Code
install_to_claude() {
    local target
    if [[ -d "$HOME/.cc-switch/skills" ]]; then
        target="$HOME/.cc-switch/skills/$SKILL_NAME"
    elif [[ -d "$HOME/.claude/skills" ]]; then
        target="$HOME/.claude/skills/$SKILL_NAME"
    else
        target="$HOME/.claude/skills/$SKILL_NAME"
    fi

    mkdir -p "$(dirname "$target")"
    rm -rf "$target"
    cp -r "$SKILL_DIR" "$target"
    rm -rf "$target/.git" "$target/.gitignore" "$target/.env" 2>/dev/null || true
    ok "Claude Code: $target ✓"
    PLATFORMS_INSTALLED=$((PLATFORMS_INSTALLED + 1))
}

# Codex
install_to_codex() {
    local target="$HOME/.codex/skills/user/$SKILL_NAME"
    if [[ -d "$HOME/.codex" ]]; then
        mkdir -p "$(dirname "$target")"
        rm -rf "$target"
        cp -r "$SKILL_DIR" "$target"
        rm -rf "$target/.git" "$target/.gitignore" "$target/.env" 2>/dev/null || true
        ok "Codex: $target ✓"
        PLATFORMS_INSTALLED=$((PLATFORMS_INSTALLED + 1))
    else
        info "Codex 未安装，跳过"
    fi
}

# OpenCode
install_to_opencode() {
    local target="$HOME/.config/opencode/skills/$SKILL_NAME"
    if [[ -d "$HOME/.config/opencode" ]]; then
        mkdir -p "$(dirname "$target")"
        rm -rf "$target"
        cp -r "$SKILL_DIR" "$target"
        rm -rf "$target/.git" "$target/.gitignore" "$target/.env" 2>/dev/null || true
        ok "OpenCode: $target ✓"
        PLATFORMS_INSTALLED=$((PLATFORMS_INSTALLED + 1))
    else
        info "OpenCode 未安装，跳过"
    fi
}

install_to_claude
install_to_codex
install_to_opencode

if (( PLATFORMS_INSTALLED == 0 )); then
    err "未安装到任何平台！请检查 Claude Code / Codex / OpenCode 是否已安装。"
    exit 1
fi

# ── Phase 4: 注册 MCP 服务器 ────────────────────────────────
info "Phase 4/5: 检查 MCP 服务器配置..."

# 检测 claude 命令是否可用
if command -v claude &>/dev/null; then
    # Brave Search MCP
    if claude mcp get brave-search &>/dev/null 2>&1; then
        ok "Brave Search MCP 已注册 ✓"
    else
        info "正在注册 Brave Search MCP Server..."
        if claude mcp add brave-search -- npx -y @brave/brave-search-mcp-server --brave-api-key "$BRAVE_API_KEY" 2>&1; then
            ok "Brave Search MCP 注册成功 ✓"
        else
            warn "Brave Search MCP 注册失败，请手动执行:"
            echo "  claude mcp add brave-search -- npx -y @brave/brave-search-mcp-server --brave-api-key <your_key>"
        fi
    fi

    # 检查 Tavily
    if claude mcp get tavily &>/dev/null 2>&1; then
        ok "Tavily MCP 已注册 ✓"
    else
        warn "Tavily MCP 未找到。请确认已注册 Tavily MCP Server。"
    fi

    # 检查 Exa
    if claude mcp get exa &>/dev/null 2>&1; then
        ok "Exa MCP 已注册 ✓"
    else
        warn "Exa MCP 未找到。请确认已注册 Exa MCP Server。"
    fi
else
    warn "未检测到 'claude' 命令，跳过 MCP 检查"
    info "请确保你的 Agent 平台已配置对应的搜索工具。"
fi

# ── Phase 5: 安装总结 ──────────────────────────────────────
info "Phase 5/5: 安装完成！"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         SuperSearch 安装完成！              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  已安装平台数: $PLATFORMS_INSTALLED"
echo "  Skill 路径:   $SKILL_DIR"
echo ""
echo "  ── 下一步 ──"
echo "  1. 在 Claude Code 中添加工具权限（如尚未添加）："
echo "     编辑 ~/.claude/settings.local.json 添加:"
echo ""
echo '     "permissions": {'
echo '       "allow": ['
echo '         "mcp__tavily__tavily_search",'
echo '         "mcp__tavily__tavily_extract",'
echo '         "mcp__tavily__tavily_crawl",'
echo '         "mcp__tavily__tavily_map",'
echo '         "mcp__tavily__tavily_research",'
echo '         "mcp__exa__web_search_exa",'
echo '         "mcp__exa__get_code_context_exa",'
echo '         "mcp__brave__brave_web_search",'
echo '         "mcp__brave__brave_news_search",'
echo '         "WebSearch(*)"'
echo '       ]'
echo '     }'
echo ""
echo "  2. 验证安装（重启 Claude Code 后）:"
echo "     \"用 supersearch 大范围搜索 'AI安全最新进展'\""
echo ""
echo "  3. 使用 Broad Search:"
echo "     \"supersearch，帮我全面调查 XXX\""
echo ""
echo "  4. 使用 Precise Search:"
echo "     \"supersearch，帮我找 XXX 的代码示例\""
echo ""

# 输出当前状态
if command -v claude &>/dev/null; then
    echo "  ── 当前 MCP 服务器状态 ──"
    claude mcp list 2>/dev/null || true
fi

echo ""
echo "  更多信息: 查看 $SKILL_DIR/README_CN.md"
echo ""
