#!/usr/bin/env bash
# ============================================================
# Ghostty + Cmux + Zed 环境初始化脚本
# 部署当前机器的真实配置到新环境
# 适用于: macOS
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backup"
CONFIG_DIR="$SCRIPT_DIR/configs"
BACKUP_USER="$HOME/.config-backup/ghostty-opt-$(date +%Y%m%d-%H%M%S)"

# 幂等性标记：部署过 .zshrc 后写入此标记，再次运行时跳过
MARKER_FILE="$HOME/.config/.ghostty-opt-deployed"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1" || true; }
step()  { echo -e "\n${CYAN}==>${NC} $1"; }
skip()  { echo -e "${GREEN}[→]${NC} $1 (已一致，跳过)"; }

DRY_RUN=false
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true; warn "预览模式，不会实际修改" && echo "" ;;
        --force)   FORCE=true ;;
    esac
done

# ============================================================
# 1. 前置检查
# ============================================================
check_prerequisites() {
    step "检查前置条件"

    if [[ "$(uname)" != "Darwin" ]]; then
        error "此脚本仅支持 macOS"
        exit 1
    fi

    if ! command -v brew &>/dev/null; then
        if $DRY_RUN; then
            warn "[dry-run] 将安装 Homebrew"
        else
            warn "安装 Homebrew ..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Apple Silicon / Intel 自动适配
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            else
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
    else
        info "Homebrew ✓ ($(brew --version | head -1))"
    fi

    # 检查备份文件是否存在
    if [[ ! -f "$BACKUP_DIR/Brewfile" ]]; then
        error "Brewfile 不存在: $BACKUP_DIR/Brewfile"
        exit 1
    fi
    if [[ ! -f "$BACKUP_DIR/ghostty-config" ]]; then
        error "ghostty-config 不存在: $BACKUP_DIR/ghostty-config"
        exit 1
    fi
}

# ============================================================
# 2. 安装工具 (通过 Brewfile)
# ============================================================
install_via_brewfile() {
    step "安装工具 (通过 Brewfile)"

    if $DRY_RUN; then
        warn "[dry-run] 将安装: brew bundle install --file=$BACKUP_DIR/Brewfile"
        return
    fi

    # Tap Cmux（幂等：重复 tap 无害）
    if ! brew tap | grep -q "manaflow-ai/cmux"; then
        brew tap manaflow-ai/cmux
    fi

    # brew bundle install 本身幂等：已装过的包跳过
    if brew bundle install --file="$BACKUP_DIR/Brewfile" --no-lock 2>&1 | tail -20; then
        info "Brewfile 安装完成"
    else
        warn "部分包安装失败，继续部署配置..."
    fi
}

# ============================================================
# 3. 部署配置
# ============================================================
backup_if_exists() {
    local src="$1" name="$2"
    if [[ -f "$src" ]]; then
        mkdir -p "$BACKUP_USER"
        cp "$src" "$BACKUP_USER/$name"
        warn "已备份: $src → $BACKUP_USER/$name"
    fi
}

# 幂等部署：仅在文件内容不一致时才覆盖
# 返回 0=一致（跳过），1=不一致（已部署），2=不存在（已部署）
deploy_file() {
    local src="$1" dst="$2" label="$3"
    if [[ -f "$dst" ]] && diff -q "$src" "$dst" &>/dev/null; then
        $DRY_RUN && warn "[dry-run] $label 已一致，跳过" || skip "$label"
        return 0
    fi
    if $DRY_RUN; then
        warn "[dry-run] 将部署 $label"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    info "$label 已部署 ✓"
    return 1
}

deploy_all() {
    step "部署全部配置"

    # --- Ghostty / Cmux 配置 ---
    deploy_file "$BACKUP_DIR/ghostty-config" \
        "$HOME/.config/ghostty/config" "Ghostty 配置"

    # --- Starship 配置 ---
    deploy_file "$BACKUP_DIR/starship.toml" \
        "$HOME/.config/starship.toml" "Starship 配置"

    # --- .zprofile ---
    deploy_file "$BACKUP_DIR/zprofile" \
        "$HOME/.zprofile" ".zprofile"

    # --- Zed 配置 ---
    deploy_file "$BACKUP_DIR/zed/settings.json" \
        "$HOME/.config/zed/settings.json" "Zed 配置"

    # --- Zsh Completions ---
    if [[ -f "$BACKUP_DIR/zsh-completions/_opencli" ]]; then
        deploy_file "$BACKUP_DIR/zsh-completions/_opencli" \
            "$HOME/.zsh/completions/_opencli" "Zsh Completions"
    fi

    # --- Claude Code Hooks ---
    if [[ -f "$BACKUP_DIR/claude-hooks/cmux-notify-hook.sh" ]]; then
        deploy_file "$BACKUP_DIR/claude-hooks/cmux-notify-hook.sh" \
            "$HOME/.claude/hooks/cmux-notify-hook.sh" "Claude Code Hooks"
        chmod +x "$HOME/.claude/hooks/cmux-notify-hook.sh" 2>/dev/null || true
    fi

    # --- .zshrc（幂等：标记文件存在则跳过）---
    deploy_zshrc

    # --- .env.local（secrets 模板，仅首次创建）---
    if [[ ! -f "$HOME/.env.local" ]]; then
        if $DRY_RUN; then
            warn "[dry-run] 将创建 ~/.env.local"
        else
            cp "$BACKUP_DIR/env.local.example" "$HOME/.env.local"
            warn "已创建 ~/.env.local — 请编辑填入你的 API keys"
        fi
    else
        info "~/.env.local 已存在，跳过"
    fi

    # --- .zshrc.local（本机专属配置模板，仅首次创建）---
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        if $DRY_RUN; then
            warn "[dry-run] 将创建 ~/.zshrc.local"
        else
            cp "$BACKUP_DIR/zshrc.local.example" "$HOME/.zshrc.local"
            warn "已创建 ~/.zshrc.local — 请编辑填入本机专属配置"
        fi
    else
        info "~/.zshrc.local 已存在，跳过"
    fi
}

deploy_zshrc() {
    local zshrc="$HOME/.zshrc"
    local marker_dir="$(dirname "$MARKER_FILE")"

    # 如果有标记文件且非 --force，且 .zshrc 已与备份一致 → 跳过
    if [[ -f "$MARKER_FILE" ]] && ! $FORCE; then
        if [[ -f "$zshrc" ]] && diff -q "$BACKUP_DIR/zshrc" "$zshrc" &>/dev/null; then
            skip ".zshrc（已标记为已部署，内容一致）"
            return 0
        fi
    fi

    if $DRY_RUN; then
        warn "[dry-run] 将部署完整可移植 .zshrc（备份旧版）"
        return
    fi

    backup_if_exists "$zshrc" "zshrc.bak"
    cp "$BACKUP_DIR/zshrc" "$zshrc"
    # 写入幂等标记
    mkdir -p "$marker_dir"
    echo "$(date -r "$BACKUP_DIR/zshrc" +%Y-%m-%dT%H:%M:%S) $SCRIPT_DIR" > "$MARKER_FILE"
    info ".zshrc 已部署 ✓"
}

# ============================================================
# 4. Cmux Socket 配置
# ============================================================
configure_cmux_socket() {
    step "配置 Cmux Socket"

    # 检查 cmux 是否已安装
    if [[ ! -d "/Applications/cmux.app" ]]; then
        skip "cmux 未安装，跳过 socket 配置"
        return 0
    fi

    # 当前 socket mode
    # bash 3.2 + set -u: "local var" (no initializer) leaves var truly unset,
    # causing "unbound variable" even on ${var:-} — fix: initialize to ""
    # bash 3.2 + set -u: "${var:-}" does NOT trigger (falls back safely),
    # but bare $var in [[ ]] does — use ${var:-} in all conditionals.
    local current_mode=""
    if command -v defaults &>/dev/null; then
        set +u
        current_mode=$(defaults read com.cmuxterm.app socketControlMode 2>/dev/null || echo "")
        set -u
    fi
    if [[ "${current_mode:-}" == "automation" ]]; then
        info "cmux socketControlMode = automation ✓"
    else
        if [[ -n "${current_mode:-}" ]]; then
            warn "cmux socketControlMode = ${current_mode:-}（应为 automation）"
        else
            warn "cmux socketControlMode 未设置"
        fi
        echo "   设置 socketControlMode = automation..."

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "   [dry-run] 跳过写入 defaults"
        else
            if defaults write com.cmuxterm.app socketControlMode -string automation 2>/dev/null; then
                info "socketControlMode 已设为 automation"
            else
                error "写入 socketControlMode 失败"
                return 1
            fi
        fi
    fi

    # 冒烟测试：尝试 cmux ping（仅当非 dry-run 且 cmux CLI 存在时）
    if [[ "$DRY_RUN" != "true" ]] && command -v cmux &>/dev/null; then
        echo "   执行冒烟测试..."
        if cmux ping 2>/dev/null; then
            info "cmux ping 成功 ✓"
        else
            warn "cmux ping 失败（app 可能需要重启）"
            echo "   请手动重启 Cmux："
            echo "     osascript -e 'quit app \"cmux\"' && open -a cmux"
        fi
    fi
    return 0
}

# ============================================================
# 5. 兼容性检查
# ============================================================
check_compatibility() {
    step "兼容性检查"

    local ghostty_cfg="$HOME/.config/ghostty/config"
    if [[ -f "$ghostty_cfg" ]]; then
        if grep -q "copy-on-select = clipboard" "$ghostty_cfg"; then
            warn "Ghostty: copy-on-select = clipboard 与 Cmux 可能冲突"
            echo "   运行以下命令修复:"
            echo "   sed -i '' 's/copy-on-select = clipboard/copy-on-select = false/' $ghostty_cfg"
        else
            info "Ghostty copy-on-select 兼容 ✓"
        fi
    fi
}

# ============================================================
# 5. 验证
# ============================================================
verify() {
    step "验证安装"

    local all_ok=true
    for app in "cmux:Cmux" "ghostty:Ghostty" "zed:Zed"; do
        local cmd="${app%%:*}" name="${app##*:}"
        if ls "/Applications/${name}.app" &>/dev/null 2>&1 || command -v "$cmd" &>/dev/null; then
            info "$name ✓"
        else
            warn "$name 未安装"
            all_ok=false
        fi
    done

    for tool in starship fastfetch btop; do
        if command -v "$tool" &>/dev/null; then
            info "$tool ✓"
        else
            warn "$tool 未安装"
            all_ok=false
        fi
    done

    echo ""
    if $all_ok; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        info "全部就绪！重启终端后开始使用"
        echo ""
        echo "  exec zsh"
        echo ""
        echo "  多 Agent 模式:"
        echo "    open -a Cmux"
        echo "    cw myproject     # 新建 Workspace"
        echo "    cc               # 启动 Claude Code"
        echo "    zed .            # 编辑文件"
        echo ""
        echo "  轻量独立模式:"
        echo "    open -a Ghostty"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
}

# ============================================================
# 主流程
# ============================================================
main() {
    echo "╔══════════════════════════════════════════════╗"
    echo "║  Ghostty + Cmux + Zed 环境初始化            ║"
    echo "║  幂等安装：内容一致时自动跳过                 ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    echo "用法: bash bootstrap.sh [--dry-run] [--force]"
    echo "  --dry-run  预览将要执行的操作（不实际修改）"
    echo "  --force    强制重新部署所有文件（忽略一致性检查）"
    echo ""

    check_prerequisites
    install_via_brewfile
    deploy_all
    configure_cmux_socket
    check_compatibility
    verify
}

# Only invoke main when executed directly (not when sourced for unit tests)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
