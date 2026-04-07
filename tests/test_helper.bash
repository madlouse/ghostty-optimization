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
mock_brew_installed() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/brew" << 'MOCK'
#!/usr/bin/env bash
case "$1" in
  --version) echo "Homebrew 4.0.0" ;;
  tap)        echo "manaflow-ai/cmux" ;;
  bundle)     exit 0 ;;
  *)          exit 0 ;;
esac
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/brew"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
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

mock_cmux_helper_cli() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/cmux" << 'MOCK'
#!/usr/bin/env bash
set -euo pipefail

log_file="${CMUX_TEST_LOG:-}"
if [[ -n "$log_file" && $# -gt 0 ]]; then
  {
    printf '%q ' "$@"
    printf '\n'
  } >> "$log_file"
fi

case "${1:-}" in
  ping)
    echo "PONG"
    ;;
  list-workspaces)
    cat <<'EOF'
* workspace:1  demo
EOF
    ;;
  new-workspace)
    echo "workspace:99"
    ;;
  close-workspace)
    ;;
  identify)
    cat <<'EOF'
{
  "focused" : {
    "workspace_ref" : "workspace:1",
    "surface_ref" : "surface:9"
  },
  "caller" : {
    "workspace_ref" : "workspace:1",
    "surface_ref" : "surface:1"
  }
}
EOF
    ;;
  *)
    ;;
esac
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/cmux"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
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
run_bootstrap_fn() {
  local fn_name="$1"; shift
  # 覆盖 BACKUP_DIR 指向 fixture
  BACKUP_DIR="$BATS_TEST_TMPDIR/backup" \
  BACKUP_USER="$BATS_TEST_TMPDIR/backup-user" \
  DRY_RUN=false \
    bash -c "
      source '$REPO_ROOT/setup/bootstrap.sh'
      $fn_name $*
    " 2>&1
}

run_bootstrap_fn_dry() {
  local fn_name="$1"; shift
  BACKUP_DIR="$BATS_TEST_TMPDIR/backup" \
  BACKUP_USER="$BATS_TEST_TMPDIR/backup-user" \
  DRY_RUN=true \
    bash -c "
      source '$REPO_ROOT/setup/bootstrap.sh'
      $fn_name $*
    " 2>&1
}

create_sync_fixture_tree() {
  local fixture_root="$BATS_TEST_TMPDIR/sync-fixture"

  rm -rf "$fixture_root"
  mkdir -p "$fixture_root/setup"

  cat > "$fixture_root/setup/bootstrap.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "$0" "$*" > "${GHOSTTY_CMUX_BOOTSTRAP_LOG:?}"
EOF
  chmod +x "$fixture_root/setup/bootstrap.sh"

  echo "$fixture_root"
}

create_sync_archive_fixture() {
  local fixture_root="$1"
  local staging_root="$BATS_TEST_TMPDIR/sync-archive-root"
  local archive_path="$BATS_TEST_TMPDIR/ghostty-optimization-main.tar.gz"

  rm -rf "$staging_root"
  mkdir -p "$staging_root/ghostty-optimization-main"
  cp -R "$fixture_root"/. "$staging_root/ghostty-optimization-main/"
  tar -czf "$archive_path" -C "$staging_root" ghostty-optimization-main

  echo "$archive_path"
}
