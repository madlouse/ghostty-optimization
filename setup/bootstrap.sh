#!/usr/bin/env bash
# ============================================================
# Ghostty + Cmux + Zed 环境初始化脚本
# AI 编程终端栈一键部署
# 适用于: macOS
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/configs"
BACKUP_DIR="$HOME/.config-backup/ghostty-opt-$(date +%Y%m%d-%H%M%S)"

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
        error "此脚本仅支持 macOS（Cmux 为 macOS 原生应用）"
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
}

# ============================================================
# 2. 安装工具
# ============================================================
install_packages() {
    step "安装核心工具"

    # --- Cmux ---
    if command -v cmux &>/dev/null || ls /Applications/cmux.app &>/dev/null 2>&1; then
        info "Cmux ✓"
    else
        if $DRY_RUN; then
            warn "[dry-run] 将安装 Cmux"
        else
            warn "安装 Cmux ..."
            brew tap manaflow-ai/cmux 2>/dev/null || true
            brew install --cask cmux
            info "Cmux 安装完成"
        fi
    fi

    # --- Zed ---
    if command -v zed &>/dev/null || ls /Applications/Zed.app &>/dev/null 2>&1; then
        info "Zed ✓"
    else
        if $DRY_RUN; then
            warn "[dry-run] 将安装 Zed"
        else
            warn "安装 Zed ..."
            brew install --cask zed
            info "Zed 安装完成"
        fi
    fi

    # --- 辅助工具 ---
    local formulae=(starship fastfetch btop zsh-syntax-highlighting zsh-autosuggestions)
    for pkg in "${formulae[@]}"; do
        if brew list "$pkg" &>/dev/null 2>&1; then
            info "$pkg ✓"
        else
            if $DRY_RUN; then
                warn "[dry-run] 将安装 $pkg"
            else
                brew install "$pkg"
                info "$pkg ✓"
            fi
        fi
    done

    # --- Nerd Font ---
    if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd" || ls ~/Library/Fonts/*JetBrainsMono*Nerd* &>/dev/null 2>&1; then
        info "JetBrainsMono Nerd Font ✓"
    else
        if $DRY_RUN; then
            warn "[dry-run] 将安装 font-jetbrains-mono-nerd-font"
        else
            brew install --cask font-jetbrains-mono-nerd-font
            info "JetBrainsMono Nerd Font ✓"
        fi
    fi
}

# ============================================================
# 3. 部署配置
# ============================================================
backup_if_exists() {
    local src="$1" name="$2"
    if [[ -f "$src" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$src" "$BACKUP_DIR/$name"
        warn "已备份: $src → $BACKUP_DIR/$name"
    fi
}

deploy_ghostty_config() {
    step "Ghostty 配置 (Cmux 共用)"
    local target="$HOME/.config/ghostty/config"

    if [[ -f "$target" ]]; then
        info "Ghostty 配置已存在，保留不覆盖"
        # 检查 Cmux 兼容性
        if grep -q "copy-on-select = clipboard" "$target"; then
            warn "建议: copy-on-select 改为 false（避免与 Cmux 选择冲突）"
        fi
    else
        if $DRY_RUN; then
            warn "[dry-run] 将部署 Ghostty 配置"
        else
            mkdir -p "$(dirname "$target")"
            cp "$CONFIG_DIR/ghostty-config" "$target"
            info "Ghostty 配置已部署"
        fi
    fi
}

deploy_zed_config() {
    step "Zed 编辑器配置"
    local target="$HOME/.config/zed/settings.json"

    if [[ -f "$target" ]]; then
        info "Zed 配置已存在，保留不覆盖"
    else
        if $DRY_RUN; then
            warn "[dry-run] 将部署 Zed 基础配置"
        else
            mkdir -p "$(dirname "$target")"
            cp "$CONFIG_DIR/zed-settings.json" "$target"
            info "Zed 配置已部署"
        fi
    fi
}

deploy_cmux_hooks() {
    step "Cmux Claude Code Hooks"
    local hooks_dir="$HOME/.claude/hooks"

    if [[ -d "$hooks_dir" ]] && ls "$hooks_dir"/*cmux* &>/dev/null 2>&1; then
        info "Cmux hooks 已存在，跳过"
    else
        if $DRY_RUN; then
            warn "[dry-run] 将部署 Cmux notification hooks"
        else
            mkdir -p "$hooks_dir"
            cp "$CONFIG_DIR/cmux-notify-hook.sh" "$hooks_dir/"
            chmod +x "$hooks_dir/cmux-notify-hook.sh"
            info "Cmux hooks 已部署"
            warn "需在 Claude Code settings.json 中配置 hook 触发"
        fi
    fi
}

deploy_shell_integration() {
    step "Shell 集成 (Cmux + Zed)"
    local zshrc="$HOME/.zshrc"
    local marker="# >>> ghostty-cmux-zed setup >>>"

    if [[ -f "$zshrc" ]] && grep -q "$marker" "$zshrc"; then
        info "Shell 集成已存在，跳过"
    else
        if $DRY_RUN; then
            warn "[dry-run] 将追加 Cmux/Zed 集成到 .zshrc"
        else
            backup_if_exists "$zshrc" "zshrc.bak"
            cat "$CONFIG_DIR/zshrc-append" >> "$zshrc"
            info "Shell 集成已追加到 .zshrc"
        fi
    fi
}

deploy_configs() {
    deploy_ghostty_config
    deploy_zed_config
    deploy_cmux_hooks
    deploy_shell_integration
}

# ============================================================
# 4. 验证
# ============================================================
verify() {
    step "验证安装结果"

    local all_ok=true

    for app in "cmux:Cmux" "zed:Zed"; do
        local cmd="${app%%:*}" name="${app##*:}"
        if command -v "$cmd" &>/dev/null || ls "/Applications/${name}.app" &>/dev/null 2>&1; then
            info "$name ✓"
        else
            error "$name 未找到"
            all_ok=false
        fi
    done

    for cmd in starship fastfetch btop; do
        if command -v "$cmd" &>/dev/null; then
            info "$cmd ✓"
        else
            error "$cmd 未找到"
            all_ok=false
        fi
    done

    echo ""
    if [[ -f "$HOME/.config/ghostty/config" ]]; then
        info "Ghostty 配置 ✓ (Cmux 共用)"
    else
        error "Ghostty 配置缺失"
        all_ok=false
    fi

    if $all_ok; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        info "全部就绪！"
        echo ""
        echo "  快速开始:"
        echo "    1. 打开 Cmux.app"
        echo "    2. 新建 Workspace → 命名项目"
        echo "    3. 启动 Claude Code: claude"
        echo "    4. 分屏: cmux new-split right"
        echo "    5. 需要编辑文件时: zed ."
        echo ""
        echo "  常用 Cmux CLI:"
        echo "    cmux list-workspaces       # 列出工作区"
        echo "    cmux new-split right       # 右侧分屏"
        echo "    cmux new-split down        # 下方分屏"
        echo "    cmux notify --title X      # 发送通知"
        echo "    cmux new-pane --type browser --url URL"
        echo ""
        echo "  Zed 快捷操作:"
        echo "    zed .                      # 打开当前目录"
        echo "    zed file.py                # 打开文件"
        echo "    Cmd+Shift+A                # Agent Panel"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        warn "部分组件未就绪，请检查上述信息。"
    fi
}

# ============================================================
# 主流程
# ============================================================
main() {
    echo "╔══════════════════════════════════════════════╗"
    echo "║  Ghostty + Cmux + Zed 环境初始化            ║"
    echo "║  AI 编程终端栈 · 兼容模式                   ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    check_prerequisites
    install_packages
    deploy_configs
    verify
}

main "$@"
