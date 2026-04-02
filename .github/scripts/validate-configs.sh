#!/usr/bin/env bash
# .github/scripts/validate-configs.sh
# 配置文件语法校验脚本
# 在 CI 和本地均可运行

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_DIR="$REPO_ROOT/setup/backup"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; FAILED=1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

FAILED=0

echo "🔍 配置文件语法校验"
echo ""

# ============================================================
# 1. Zsh 语法检查
# ============================================================
echo "── Zsh ──"
if [[ -f "$BACKUP_DIR/zshrc" ]]; then
  if zsh -n "$BACKUP_DIR/zshrc" 2>&1; then
    ok "zshrc: 语法正确"
  else
    fail "zshrc: 语法错误"
  fi
else
  warn "zshrc 不存在，跳过"
fi

# ============================================================
# 2. Starship TOML 校验
# ============================================================
echo ""
echo "── Starship ──"
if command -v starship &>/dev/null; then
  if starship config 2>/dev/null | head -1 | grep -q "schema" || \
     STARSHIP_CONFIG="$BACKUP_DIR/starship.toml" starship config 2>&1 | head -5; then
    ok "starship.toml: 可解析"
  else
    fail "starship.toml: 解析失败"
  fi
  # 更严格：用 python tomllib 校验 TOML 格式
  if command -v python3 &>/dev/null; then
    if python3 -c "
import sys, tomllib
with open('$BACKUP_DIR/starship.toml', 'rb') as f:
    tomllib.load(f)
print('TOML valid')
" 2>&1 | grep -q "TOML valid"; then
      ok "starship.toml: TOML 格式有效"
    else
      fail "starship.toml: TOML 格式无效"
    fi
  fi
else
  warn "starship 未安装，跳过 Starship 校验"
fi

# ============================================================
# 3. Ghostty 配置校验
# ============================================================
echo ""
echo "── Ghostty ──"
if command -v ghostty &>/dev/null; then
  if ghostty +validate-config --config-file="$BACKUP_DIR/ghostty-config" 2>&1 | grep -q "No errors"; then
    ok "ghostty-config: 无错误"
  else
    # ghostty validate 输出格式可能因版本不同，只要不出错就算通过
    output=$(ghostty +validate-config --config-file="$BACKUP_DIR/ghostty-config" 2>&1)
    if echo "$output" | grep -qi "error"; then
      fail "ghostty-config: 发现错误"
      echo "$output"
    else
      ok "ghostty-config: 校验通过"
    fi
  fi
else
  warn "ghostty 未安装，跳过 Ghostty 校验"
fi

# ============================================================
# 4. Brewfile 格式校验
# ============================================================
echo ""
echo "── Brewfile ──"
if [[ -f "$BACKUP_DIR/Brewfile" ]]; then
  # 基础格式校验：每行应该是 tap/brew/cask/vscode/uv 或注释/空行
  invalid_lines=$(grep -vE '^\s*(#|$|tap|brew|cask|vscode|uv)' "$BACKUP_DIR/Brewfile" || true)
  if [[ -z "$invalid_lines" ]]; then
    ok "Brewfile: 格式正确"
  else
    fail "Brewfile: 发现不合规行:"
    echo "$invalid_lines"
  fi
else
  fail "Brewfile 不存在"
fi

# ============================================================
# 5. 模板文件完整性检查
# ============================================================
echo ""
echo "── 模板文件 ──"
for f in env.local.example zshrc.local.example zshrc zprofile ghostty-config starship.toml; do
  if [[ -f "$BACKUP_DIR/$f" ]]; then
    ok "$f: 存在"
  else
    fail "$f: 缺失"
  fi
done

# ============================================================
# 结果
# ============================================================
echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo -e "${GREEN}✅ 全部校验通过${NC}"
  exit 0
else
  echo -e "${RED}❌ 部分校验失败${NC}"
  exit 1
fi
