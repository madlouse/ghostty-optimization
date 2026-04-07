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

cmux_settings_file() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/cmux/settings.json"
}

read_cmux_socket_mode() {
    local settings_file
    settings_file="$(cmux_settings_file)"
    SETTINGS_FILE="$settings_file" python3 <<'PY'
import json
import os
import pathlib
import sys

path = pathlib.Path(os.environ["SETTINGS_FILE"])
if not path.exists():
    sys.exit(1)

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

raw = path.read_text(encoding="utf-8")
data = json.loads(strip_trailing_commas(strip_comments(raw)))
print(data.get("automation", {}).get("socketControlMode", ""))
PY
}

cmux_workspace_refs() {
    cmux list-workspaces 2>/dev/null | grep -oE 'workspace:[0-9]+' || true
}

cmux_runtime_smoke() {
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
        cmux close-workspace --workspace "$new_ref" >/dev/null 2>&1 || true
    fi

    return 0
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

# ── 4. Cmux Helpers ──────────────────────────────
echo ""
echo "【4. Cmux Helpers】"
if [[ -f "$HOME/.zshrc" ]]; then
    if grep -q "cmux shell zsh" "$HOME/.zshrc"; then
        check ".zshrc 仍引用已移除的 cmux shell 子命令" "FAIL"
    else
        check ".zshrc 不再依赖 cmux shell init" "PASS"
    fi

    if grep -q "new-workspace --name" "$HOME/.zshrc"; then
        check "cw 仍使用已移除的 --name 参数" "FAIL"
    else
        check "cw 使用 current cmux CLI（--cwd）" "PASS"
    fi

    if grep -qE "^[[:space:]]*cw\(\)" "$HOME/.zshrc"; then
        check "cw helper 已部署" "PASS"
    else
        check "cw helper 缺失" "FAIL"
    fi

    if grep -qE "^[[:space:]]*cc\(\)" "$HOME/.zshrc"; then
        check "cc helper 已部署" "PASS"
    else
        check "cc helper 缺失" "FAIL"
    fi

    if grep -qE "^[[:space:]]*cb\(\)" "$HOME/.zshrc"; then
        check "cb helper 已部署" "PASS"
    else
        check "cb helper 缺失" "FAIL"
    fi
else
    check ".zshrc 不存在（无法检查 Cmux helpers）" "FAIL"
fi

# ── 5. Cmux Automation ───────────────────────────
echo ""
echo "【5. Cmux Automation】"
if [[ -f "$(cmux_settings_file)" ]]; then
    if [[ "$(read_cmux_socket_mode 2>/dev/null || true)" == "automation" ]]; then
        check "settings.json 中 automation.socketControlMode = automation" "PASS"
    else
        check "settings.json 未将 socketControlMode 设为 automation" "FAIL"
    fi
else
    check "Cmux settings.json 未创建" "FAIL"
fi

if command -v cmux &>/dev/null; then
    if cmux ping &>/dev/null; then
        check "cmux ping 可用" "PASS"
    else
        check "cmux ping 失败（socket automation 未就绪）" "FAIL"
    fi

    if cmux_runtime_smoke &>/dev/null; then
        check "外部 shell 可执行 cmux new-workspace" "PASS"
    else
        check "外部 shell 无法执行 cmux new-workspace" "FAIL"
    fi
else
    check "cmux CLI 缺失（无法检查 automation）" "FAIL"
fi

# ── 6. 应用安装状态 ──────────────────────────────
echo ""
echo "【6. 应用程序】"
for app in Ghostty Zed Cmux; do
    ls "/Applications/${app}.app" &>/dev/null \
        && check "$app — 已安装" "PASS" \
        || check "$app — 未安装" "FAIL"
done

# ── 7. 幂等标记（确认 bootstrap 成功） ───────────
echo ""
echo "【7. 部署状态】"
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
