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
error() { echo -e "${RED}[✗]${NC} $1"; }
step()  { echo -e "\n${CYAN}==>${NC} $1"; }
skip()  { echo -e "${GREEN}[→]${NC} $1 (已一致，跳过)"; }

DRY_RUN=false
FORCE=false
BREWFILE_INSTALL_STATUS="pending"
VERIFY_STATUS="pending"
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true; warn "预览模式，不会实际修改" && echo "" ;;
        --force)   FORCE=true ;;
    esac
done

emit_summary() {
    local status="$1" stage="$2" message="$3"

    echo ""
    echo "BOOTSTRAP_SUMMARY_BEGIN"
    printf 'status=%s\n' "$status"
    printf 'stage=%s\n' "$stage"
    printf 'dry_run=%s\n' "$DRY_RUN"
    printf 'force=%s\n' "$FORCE"
    printf 'brewfile_status=%s\n' "$BREWFILE_INSTALL_STATUS"
    printf 'verify_status=%s\n' "$VERIFY_STATUS"
    printf 'message=%q\n' "$message"
    echo "BOOTSTRAP_SUMMARY_END"
}

cmux_settings_file() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/cmux/settings.json"
}

update_cmux_settings_file() {
    local settings_file
    settings_file="$(cmux_settings_file)"
    SETTINGS_FILE="$settings_file" python3 <<'PY'
import json
import os
import pathlib
import sys

path = pathlib.Path(os.environ["SETTINGS_FILE"])
path.parent.mkdir(parents=True, exist_ok=True)

def strip_comments(text: str) -> str:
    result = []
    in_string = False
    escape = False
    line_comment = False
    block_comment = False
    i = 0
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if line_comment:
            if ch == "\n":
                line_comment = False
                result.append(ch)
            i += 1
            continue

        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
                continue
            i += 1
            continue

        if in_string:
            result.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue

        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue

        result.append(ch)
        if ch == '"':
            in_string = True
        i += 1

    return "".join(result)

def strip_trailing_commas(text: str) -> str:
    result = []
    in_string = False
    escape = False
    i = 0
    while i < len(text):
        ch = text[i]

        if in_string:
            result.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            result.append(ch)
            i += 1
            continue

        if ch == ",":
            j = i + 1
            while j < len(text) and text[j] in " \t\r\n":
                j += 1
            if j < len(text) and text[j] in "}]":
                i += 1
                continue

        result.append(ch)
        i += 1

    return "".join(result)

data = {}
if path.exists():
    raw = path.read_text(encoding="utf-8")
    normalized = strip_trailing_commas(strip_comments(raw)).strip()
    if normalized:
        try:
            data = json.loads(normalized)
        except json.JSONDecodeError as exc:
            sys.stderr.write(
                f"cmux settings file is not mergeable JSON/JSONC: {path} ({exc})\n"
            )
            sys.exit(1)

if not isinstance(data, dict):
    sys.stderr.write(f"cmux settings file root must be an object: {path}\n")
    sys.exit(1)

data.setdefault(
    "$schema",
    "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux-settings.schema.json",
)
data.setdefault("schemaVersion", 1)
automation = data.setdefault("automation", {})
if not isinstance(automation, dict):
    sys.stderr.write(f"cmux automation settings must be an object: {path}\n")
    sys.exit(1)
automation["socketControlMode"] = "automation"

path.write_text(json.dumps(data, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
PY
}

cmux_workspace_refs() {
    cmux list-workspaces 2>/dev/null | grep -oE 'workspace:[0-9]+' || true
}

smoke_test_cmux_workspace_creation() {
    local before_refs after_refs create_output new_ref smoke_cwd

    smoke_cwd="${TMPDIR:-/tmp}"
    before_refs="$(cmux_workspace_refs | sort -u)"
    create_output="$(cmux new-workspace --cwd "$smoke_cwd" 2>&1)" || {
        printf '%s\n' "$create_output" >&2
        return 1
    }

    after_refs="$(cmux_workspace_refs | sort -u)"
    new_ref="$(printf '%s\n' "$create_output" | grep -oE 'workspace:[0-9]+' | tail -n 1 || true)"
    if [[ -z "$new_ref" ]]; then
        new_ref="$(comm -13 <(printf '%s\n' "$before_refs") <(printf '%s\n' "$after_refs") | head -n 1 || true)"
    fi

    if [[ -n "$new_ref" ]]; then
        cmux close-workspace --workspace "$new_ref" >/dev/null 2>&1 || warn "未能自动关闭 smoke workspace: $new_ref"
    fi

    info "cmux new-workspace ✓"
}

ensure_cmux_socket_ready() {
    local attempt

    if cmux ping >/dev/null 2>&1; then
        info "cmux ping ✓"
        return 0
    fi

    if command -v open &>/dev/null; then
        open -a Cmux >/dev/null 2>&1 || true
    fi

    for attempt in 1 2 3 4 5 6 7 8 9 10; do
        if cmux ping >/dev/null 2>&1; then
            info "cmux ping ✓"
            return 0
        fi
        sleep 1
    done

    return 1
}

configure_cmux_automation() {
    step "配置 Cmux automation mode"
    local settings_file
    settings_file="$(cmux_settings_file)"

    if $DRY_RUN; then
        warn "[dry-run] 将确保 $settings_file 中 automation.socketControlMode=automation"
        return 0
    fi

    if ! command -v python3 &>/dev/null; then
        error "缺少 python3，无法写入 $settings_file"
        return 1
    fi

    if ! update_cmux_settings_file; then
        error "无法更新 Cmux settings: $settings_file"
        return 1
    fi
    info "Cmux automation mode 已写入 $settings_file"

    if ! command -v cmux &>/dev/null; then
        error "cmux CLI 未找到，无法验证 automation mode"
        return 1
    fi

    if ! ensure_cmux_socket_ready; then
        error "cmux ping 失败；请确认 Cmux 已启动并读取新的 automation 配置"
        return 1
    fi

    if ! smoke_test_cmux_workspace_creation; then
        error "cmux workspace 创建 smoke test 失败"
        return 1
    fi
}

# ============================================================
# 1. 前置检查
# ============================================================
check_prerequisites() {
    step "检查前置条件"

    if [[ "$(uname)" != "Darwin" ]]; then
        error "此脚本仅支持 macOS"
        return 1
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
        return 1
    fi
    if [[ ! -f "$BACKUP_DIR/ghostty-config" ]]; then
        error "ghostty-config 不存在: $BACKUP_DIR/ghostty-config"
        return 1
    fi
}

# ============================================================
# 2. 安装工具 (通过 Brewfile)
# ============================================================
install_via_brewfile() {
    step "安装工具 (通过 Brewfile)"

    if $DRY_RUN; then
        BREWFILE_INSTALL_STATUS="skipped"
        warn "[dry-run] 将安装: brew bundle install --file=$BACKUP_DIR/Brewfile"
        return
    fi

    # Tap Cmux（幂等：重复 tap 无害）
    if ! brew tap | grep -q "manaflow-ai/cmux"; then
        brew tap manaflow-ai/cmux
    fi

    # 保留完整日志；若安装失败则中止后续部署，避免制造“伪成功”。
    if ! brew bundle install --file="$BACKUP_DIR/Brewfile"; then
        BREWFILE_INSTALL_STATUS="failed"
        error "Brewfile 安装失败，停止后续部署"
        return 1
    fi

    BREWFILE_INSTALL_STATUS="installed"
    info "Brewfile 安装完成"
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
# 返回 0=成功（无论跳过还是已部署）
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
    return 0
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
    local cmux_mode=""
    local settings_file
    settings_file="$(cmux_settings_file)"
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

    if [[ -f "$settings_file" ]]; then
        cmux_mode="$(SETTINGS_FILE="$settings_file" python3 <<'PY'
import json
import os
import pathlib

path = pathlib.Path(os.environ["SETTINGS_FILE"])
data = json.loads(path.read_text(encoding="utf-8"))
print(data.get("automation", {}).get("socketControlMode", ""))
PY
)" || cmux_mode=""
        if [[ "$cmux_mode" == "automation" ]]; then
            info "Cmux automation mode ✓"
        else
            warn "Cmux automation mode 未设置为 automation"
            all_ok=false
        fi
    else
        warn "Cmux settings.json 未创建: $settings_file"
        all_ok=false
    fi

    if command -v cmux &>/dev/null && cmux ping >/dev/null 2>&1; then
        info "cmux ping ✓"
    else
        warn "cmux ping 失败"
        all_ok=false
    fi

    echo ""
    if $all_ok; then
        VERIFY_STATUS="pass"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        info "全部就绪！重启终端后开始使用"
        echo ""
        echo "  exec zsh"
        echo ""
        echo "  多 Agent 模式:"
        echo "    open -a Cmux"
        echo "    cw .             # 为当前目录新建 Workspace"
        echo "    cc               # 在当前 Cmux workspace 中分屏启动 Claude Code"
        echo "    zed .            # 编辑文件"
        echo ""
        echo "  轻量独立模式:"
        echo "    open -a Ghostty"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        VERIFY_STATUS="warn"
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

    if ! check_prerequisites; then
        emit_summary "failed" "check_prerequisites" "前置条件检查失败"
        return 1
    fi

    if ! install_via_brewfile; then
        emit_summary "failed" "brewfile_install" "Brewfile 安装失败"
        return 1
    fi

    if ! deploy_all; then
        emit_summary "failed" "deploy" "配置部署失败"
        return 1
    fi

    if ! configure_cmux_automation; then
        emit_summary "failed" "cmux_automation" "Cmux automation mode 配置失败"
        return 1
    fi

    if ! check_compatibility; then
        emit_summary "failed" "compatibility" "兼容性检查失败"
        return 1
    fi

    if ! verify; then
        emit_summary "failed" "verify" "安装验证失败"
        return 1
    fi

    if [[ "$VERIFY_STATUS" == "pass" ]]; then
        emit_summary "success" "completed" "Bootstrap 完成"
    else
        emit_summary "warning" "completed" "Bootstrap 完成，但存在验证警告"
    fi
}

# Only invoke main when executed directly (not when sourced for unit tests)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
