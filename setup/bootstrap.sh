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

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
step()  { echo -e "\n${CYAN}==>${NC} $1"; }

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true && warn "预览模式，不会实际修改" && echo ""

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
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        info "Homebrew ✓"
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

    # Tap Cmux
    if ! brew tap | grep -q "manaflow-ai/cmux"; then
        brew tap manaflow-ai/cmux
    fi

    # 安装全部包
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

deploy_all() {
    step "部署全部配置"

    # --- Ghostty / Cmux 配置 ---
    local ghostty_target="$HOME/.config/ghostty/config"
    if [[ -f "$ghostty_target" ]]; then
        backup_if_exists "$ghostty_target" "ghostty-config.bak"
    fi
    if $DRY_RUN; then
        warn "[dry-run] 将部署 Ghostty 配置"
    else
        mkdir -p "$(dirname "$ghostty_target")"
        cp "$BACKUP_DIR/ghostty-config" "$ghostty_target"
        info "Ghostty 配置已部署 ✓"
    fi

    # --- Starship 配置 ---
    local starship_target="$HOME/.config/starship.toml"
    if [[ -f "$starship_target" ]]; then
        backup_if_exists "$starship_target" "starship.toml.bak"
    fi
    if $DRY_RUN; then
        warn "[dry-run] 将部署 Starship 配置"
    else
        mkdir -p "$(dirname "$starship_target")"
        cp "$BACKUP_DIR/starship.toml" "$starship_target"
        info "Starship 配置已部署 ✓"
    fi

    # --- .zprofile ---
    if [[ -f "$HOME/.zprofile" ]]; then
        backup_if_exists "$HOME/.zprofile" "zprofile.bak"
    fi
    if $DRY_RUN; then
        warn "[dry-run] 将部署 .zprofile"
    else
        cp "$BACKUP_DIR/zprofile" "$HOME/.zprofile"
        info ".zprofile 已部署 ✓"
    fi

    # --- Zed 配置 ---
    local zed_target="$HOME/.config/zed/settings.json"
    if [[ -f "$zed_target" ]]; then
        backup_if_exists "$zed_target" "zed-settings.json.bak"
    fi
    if $DRY_RUN; then
        warn "[dry-run] 将部署 Zed 配置"
    else
        mkdir -p "$(dirname "$zed_target")"
        cp "$BACKUP_DIR/zed/settings.json" "$zed_target"
        info "Zed 配置已部署 ✓"
    fi

    # --- Zsh Completions ---
    if $DRY_RUN; then
        warn "[dry-run] 将部署 Zsh Completions"
    else
        mkdir -p "$HOME/.zsh/completions"
        cp "$BACKUP_DIR/zsh-completions/_opencli" "$HOME/.zsh/completions/"
        info "Zsh Completions 已部署 ✓"
    fi

    # --- Claude Code Hooks ---
    if $DRY_RUN; then
        warn "[dry-run] 将部署 Claude Code Hooks"
    else
        mkdir -p "$HOME/.claude/hooks"
        cp "$BACKUP_DIR/claude-hooks/cmux-notify-hook.sh" "$HOME/.claude/hooks/"
        chmod +x "$HOME/.claude/hooks/cmux-notify-hook.sh"
        info "Claude Code Hooks 已部署 ✓"
    fi

    # --- Shell 集成 (.zshrc) ---
    deploy_shell_integration
}

deploy_shell_integration() {
    local zshrc="$HOME/.zshrc"
    local marker="# >>> ghostty-cmux-zed setup >>>"

    if [[ -f "$zshrc" ]] && grep -q "$marker" "$zshrc"; then
        info ".zshrc 集成已存在，跳过"
        return
    fi

    if $DRY_RUN; then
        warn "[dry-run] 将追加 Shell 集成到 .zshrc"
        return
    fi

    backup_if_exists "$zshrc" "zshrc.bak"
    cat "$BACKUP_DIR/zshrc-append" >> "$zshrc"
    info "Shell 集成已追加到 .zshrc ✓"
}

# ============================================================
# 4. 兼容性检查
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
    echo "║  部署真实配置 · 快速进入工作                 ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    check_prerequisites
    install_via_brewfile
    deploy_all
    check_compatibility
    verify
}

main "$@"
