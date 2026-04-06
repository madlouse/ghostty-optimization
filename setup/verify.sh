#!/usr/bin/env bash
# ============================================================
# Ghostty + Cmux + Zed 安装验证脚本
# Canonical checklist — 所有 Agent 的统一验证入口
# 用法: bash setup/verify.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backup"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0 FAIL=0 SKIP=0

check() {
    local label="$1" result="$2"
    if [[ "$result" == "PASS" ]]; then
        echo -e "  ${GREEN}[✓]${NC} $label"
        PASS=$((PASS+1))
    elif [[ "$result" == "FAIL" ]]; then
        echo -e "  ${RED}[✗]${NC} $label"
        FAIL=$((FAIL+1))
    else
        echo -e "  ${YELLOW}[→]${NC} $label"
        SKIP=$((SKIP+1))
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Ghostty + Cmux + Zed 安装验证"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. 配置文件部署 ─────────────────────────────
echo "【1. 配置文件】"

if [[ -f "$HOME/.config/ghostty/config" ]]; then
    if diff -q "$BACKUP_DIR/ghostty-config" "$HOME/.config/ghostty/config" &>/dev/null; then
        check "ghostty config — 内容一致" "PASS"
    else
        check "ghostty config — 内容不一致（需同步）" "FAIL"
    fi
else
    check "ghostty config — 未部署" "FAIL"
fi

if [[ -f "$HOME/.config/starship.toml" ]]; then
    if diff -q "$BACKUP_DIR/starship.toml" "$HOME/.config/starship.toml" &>/dev/null; then
        check "starship config — 内容一致" "PASS"
    else
        check "starship config — 内容不一致（需同步）" "FAIL"
    fi
else
    check "starship config — 未部署" "FAIL"
fi

if [[ -f "$HOME/.config/zed/settings.json" ]]; then
    if diff -q "$BACKUP_DIR/zed/settings.json" "$HOME/.config/zed/settings.json" &>/dev/null; then
        check "zed settings — 内容一致" "PASS"
    else
        check "zed settings — 内容不一致（需同步）" "FAIL"
    fi
else
    check "zed settings — 未部署" "FAIL"
fi

if [[ -f "$HOME/.zprofile" ]]; then
    if diff -q "$BACKUP_DIR/zprofile" "$HOME/.zprofile" &>/dev/null; then
        check ".zprofile — 内容一致" "PASS"
    else
        check ".zprofile — 内容不一致（需同步）" "FAIL"
    fi
else
    check ".zprofile — 未部署" "FAIL"
fi

if [[ -f "$HOME/.zshrc" ]]; then
    if diff -q "$BACKUP_DIR/zshrc" "$HOME/.zshrc" &>/dev/null; then
        check ".zshrc — 内容一致" "PASS"
    else
        check ".zshrc — 内容不一致（需同步）" "FAIL"
    fi
else
    check ".zshrc — 未部署" "FAIL"
fi

[[ -f "$HOME/.env.local" ]]     && check ".env.local — 已创建" "PASS" \
                                || check ".env.local — 未创建（需填写 API keys）" "SKIP"
[[ -f "$HOME/.zshrc.local" ]]  && check ".zshrc.local — 已创建" "PASS" \
                                || check ".zshrc.local — 未创建（可选）" "SKIP"

# ── 2. Ghostty 关键配置项 ────────────────────────
echo ""
echo "【2. Ghostty 关键配置】"
GHOSTTY_CFG="$HOME/.config/ghostty/config"
[[ -f "$GHOSTTY_CFG" ]] || check "Ghostty config 存在（无法检查）" "SKIP"

if [[ -f "$GHOSTTY_CFG" ]]; then
    grep -q "font-size = 16"       "$GHOSTTY_CFG" && check "font-size = 16"   "PASS" \
                                        || check "font-size ≠ 16"           "FAIL"
    grep -q "Catppuccin"           "$GHOSTTY_CFG" && check "theme = Catppuccin" "PASS" \
                                        || check "theme ≠ Catppuccin"       "FAIL"
    grep -q "copy-on-select = false" "$GHOSTTY_CFG" && check "copy-on-select = false（兼容 Cmux）" "PASS" \
                                        || check "copy-on-select 可能与 Cmux 冲突" "FAIL"
    grep -q "adjust-cell-height"   "$GHOSTTY_CFG" && check "adjust-cell-height（行高）" "PASS" \
                                        || check "adjust-cell-height 未设置" "SKIP"
fi

# ── 3. CLI 工具可用性 ─────────────────────────────
echo ""
echo "【3. CLI 工具】"
for tool in starship fastfetch btop; do
    command -v "$tool" &>/dev/null \
        && check "$tool — 已安装" "PASS" \
        || check "$tool — 未安装" "FAIL"
done

# ── 4. 应用安装状态 ──────────────────────────────
echo ""
echo "【4. 应用程序】"
for app in Ghostty Zed Cmux; do
    # Cmux: check /Applications bundle first, fall back to binary on PATH
    # (supports HOMEBREW_CASK_OPTS=--appdir installs)
    if [[ "$app" == "Cmux" ]]; then
        if ls "/Applications/cmux.app" &>/dev/null || command -v cmux &>/dev/null; then
            check "$app — 已安装" "PASS"
        else
            check "$app — 未安装" "FAIL"
        fi
    else
        ls "/Applications/${app}.app" &>/dev/null \
            && check "$app — 已安装" "PASS" \
            || check "$app — 未安装" "FAIL"
    fi
done

# ── 4b. Cmux Socket Mode ─────────────────────────
echo ""
echo "【4b. Cmux Socket】"
# Check both: binary on PATH (e.g. custom appdir) and app bundle at default location.
# If either is present, we can read socketControlMode from defaults.
if command -v cmux &>/dev/null || [[ -d "/Applications/cmux.app" ]]; then
    socket_mode=$(defaults read com.cmuxterm.app socketControlMode 2>/dev/null || echo "")
    if [[ "$socket_mode" == "automation" ]]; then
        check "socketControlMode = automation" "PASS"
    elif [[ -z "$socket_mode" ]]; then
        check "socketControlMode 未设置（应为 automation）" "FAIL"
    else
        check "socketControlMode = $socket_mode（应为 automation）" "FAIL"
    fi
else
    check "cmux 未安装（跳过 socket 检查）" "SKIP"
fi

# ── 5. 幂等标记（确认 bootstrap 成功） ───────────
echo ""
echo "【5. 部署状态】"
MARKER="$HOME/.config/.ghostty-opt-deployed"
if [[ -f "$MARKER" ]]; then
    check "bootstrap 已标记完成（最后部署：$(cat "$MARKER")）" "PASS"
else
    check "bootstrap 未标记（从未运行，或 --dry-run）" "SKIP"
fi

# ── 汇总 ────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  结果: ${GREEN}%d 通过${NC}  ${RED}%d 失败${NC}  ${YELLOW}%d 跳过/警告${NC}\n" "$PASS" "$FAIL" "$SKIP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "运行以下命令重新部署:"
    echo "  cd ~/dev/ghostty-optimization && bash setup/bootstrap.sh --force"
    exit 1
fi
if [[ $SKIP -gt 0 ]]; then
    echo ""
    echo "部分项目跳过或未配置，请确认是否符合预期。"
fi
exit 0
