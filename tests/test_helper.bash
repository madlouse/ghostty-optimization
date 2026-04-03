#!/usr/bin/env bash
# tests/test_helper.bash — 公共 mock / setup / teardown

# ---- 路径 ----
export REPO_ROOT
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SETUP_DIR="$REPO_ROOT/setup"
export BACKUP_DIR="$SETUP_DIR/backup"

# ---- 隔离 HOME ----
setup_isolated_home() {
  export REAL_HOME="$HOME"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/.config/ghostty"
  mkdir -p "$HOME/.config/zed"
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.zsh/completions"
  mkdir -p "$HOME/.claude/hooks"
}

teardown_isolated_home() {
  export HOME="$REAL_HOME"
}

# ---- Mock brew ----
# mock_brew_installed 通过在 bash -c 命令字符串中注入 `export PATH`
# 来使子进程找到 mock（_source helper 已在命令内 export PATH）
# 此函数只需确保 mock 可执行文件存在
mock_brew_installed() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/brew" << 'MOCKBREW'
#!/usr/bin/env bash
case "$1" in
  --version) echo "Homebrew 4.0.0" ;;
  tap)        echo "manaflow-ai/cmux" ;;
  bundle)     exit 0 ;;
  *)          exit 0 ;;
esac
MOCKBREW
  chmod +x "$BATS_TEST_TMPDIR/bin/brew"
}

mock_brew_not_installed() {
  # 从 PATH 中移除真实 brew
  mkdir -p "$BATS_TEST_TMPDIR/no-brew/bin"
  export PATH="$BATS_TEST_TMPDIR/no-brew/bin:$(echo "$PATH" | tr ':' '\n' | grep -v homebrew | tr '\n' ':' | sed 's/:$//')"
}

# ---- Mock 外部命令 ----
mock_command() {
  local name="$1"; shift
  local body="${1:-exit 0}"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  printf '#!/usr/bin/env bash\n%s\n' "$body" > "$BATS_TEST_TMPDIR/bin/$name"
  chmod +x "$BATS_TEST_TMPDIR/bin/$name"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

mock_command_missing() {
  local name="$1"
  # 创建一个会 fail 的 wrapper，模拟 command not found
  mkdir -p "$BATS_TEST_TMPDIR/no-bin"
  # 确保 no-bin 在 PATH 中没有该命令
  : # 什么都不创建，command -v 会找不到
}

# ---- 创建最小 fixture ----
setup_fixtures() {
  # 确保 backup/ 里的必要文件存在（测试用临时副本）
  export BACKUP_DIR="$BATS_TEST_TMPDIR/backup"
  mkdir -p "$BACKUP_DIR/zed" "$BACKUP_DIR/zsh-completions" "$BACKUP_DIR/claude-hooks"

  cp "$REPO_ROOT/setup/backup/ghostty-config"       "$BACKUP_DIR/ghostty-config"
  cp "$REPO_ROOT/setup/backup/starship.toml"         "$BACKUP_DIR/starship.toml"
  cp "$REPO_ROOT/setup/backup/zprofile"              "$BACKUP_DIR/zprofile"
  cp "$REPO_ROOT/setup/backup/Brewfile"              "$BACKUP_DIR/Brewfile"
  cp "$REPO_ROOT/setup/backup/zshrc"                 "$BACKUP_DIR/zshrc"
  cp "$REPO_ROOT/setup/backup/env.local.example"     "$BACKUP_DIR/env.local.example"
  cp "$REPO_ROOT/setup/backup/zshrc.local.example"   "$BACKUP_DIR/zshrc.local.example"

  # Zed settings (可能不存在，创建空的)
  echo '{}' > "$BACKUP_DIR/zed/settings.json"
  echo '#_opencli' > "$BACKUP_DIR/zsh-completions/_opencli"
  echo '#!/usr/bin/env bash' > "$BACKUP_DIR/claude-hooks/cmux-notify-hook.sh"
}

# ---- run_bootstrap_fn: 在隔离环境中 source bootstrap 并调用指定函数 ----
# 关键：PATH 必须在 bash -c 命令内 export，否则子进程找不到 mock brew
# 方案：把 PATH 拼接好放在 bash -c "export PATH=...; ..." 字符串里
run_bootstrap_fn() {
  local fn_name="$1"; shift
  local _brew_path="PATH=$BATS_TEST_TMPDIR/bin:\$PATH"
  # shellcheck disable=SC2086
  BACKUP_DIR="$BATS_TEST_TMPDIR/backup" \
  BACKUP_USER="$BATS_TEST_TMPDIR/backup-user" \
  DRY_RUN=false \
    bash -c "$_brew_path; source '$REPO_ROOT/setup/bootstrap.sh'; $fn_name $*" 2>&1
}

run_bootstrap_fn_dry() {
  local fn_name="$1"; shift
  local _brew_path="PATH=$BATS_TEST_TMPDIR/bin:\$PATH"
  # shellcheck disable=SC2086
  BACKUP_DIR="$BATS_TEST_TMPDIR/backup" \
  BACKUP_USER="$BATS_TEST_TMPDIR/backup-user" \
  DRY_RUN=true \
    bash -c "$_brew_path; source '$REPO_ROOT/setup/bootstrap.sh'; $fn_name $*" 2>&1
}
