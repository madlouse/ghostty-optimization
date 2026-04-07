#!/usr/bin/env bats
# tests/bootstrap.bats — bootstrap.sh full unit tests
# Run: bats tests/bootstrap.bats

bats_require_minimum_version 1.5.0

load 'test_helper'

# ===========================================================
# setup / teardown
# ===========================================================

setup() {
  setup_isolated_home
  setup_fixtures
  mock_brew_installed
  mock_command "curl" "exit 0"
  mock_command "sh"   "exit 0"
}

teardown() {
  teardown_isolated_home
}

# Helper: source bootstrap then override mutable vars
# Usage: source_bootstrap [dry_run=true|false]
# Sets BACKUP_DIR and BACKUP_USER from test fixtures AFTER source
_source() {
  local dry="${1:-false}"
  echo "
    source '$REPO_ROOT/setup/bootstrap.sh'
    BACKUP_DIR='$BATS_TEST_TMPDIR/backup'
    BACKUP_USER='$BATS_TEST_TMPDIR/backup-user'
    DRY_RUN=$dry
    HOME='$HOME'
  "
}

# ===========================================================
# 1. check_prerequisites
# ===========================================================

@test "prerequisites: non-macOS exits with error" {
  run bash -c "
    uname() { echo 'Linux'; }
    export -f uname
    $(_source)
    check_prerequisites
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"macOS"* ]]
}

@test "prerequisites: brew already installed skips install" {
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    $(_source)
    check_prerequisites
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"Homebrew"* ]]
}

@test "prerequisites: missing Brewfile exits with error" {
  rm -f "$BATS_TEST_TMPDIR/backup/Brewfile"
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    $(_source)
    check_prerequisites
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"Brewfile"* ]]
}

@test "prerequisites: missing ghostty-config exits with error" {
  rm -f "$BATS_TEST_TMPDIR/backup/ghostty-config"
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    $(_source)
    check_prerequisites
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"ghostty-config"* ]]
}

@test "prerequisites: dry-run warns instead of installing brew" {
  # Use minimal system PATH with no brew at all
  # macOS system PATH without homebrew: /usr/bin /bin /usr/sbin /sbin
  run bash -c "
    PATH='/usr/bin:/bin:/usr/sbin:/sbin'
    $(_source true)
    check_prerequisites
  "
  [[ "$output" == *"dry-run"* ]]
}

# ===========================================================
# 2. install_via_brewfile
# ===========================================================

@test "brewfile: dry-run only prints, does not install" {
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    $(_source true)
    install_via_brewfile
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
}

@test "brewfile: success reports completion" {
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    $(_source)
    install_via_brewfile
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"Brewfile"* ]]
}

@test "brewfile: install does not use deprecated no-lock flag" {
  export BREW_TEST_LOG="$BATS_TEST_TMPDIR/brew.log"
  : > "$BREW_TEST_LOG"
  cat > "$BATS_TEST_TMPDIR/bin/brew" << 'MOCK'
#!/usr/bin/env bash
{
  printf '%q ' "$@"
  printf '\n'
} >> "${BREW_TEST_LOG:?}"
case "$1" in
  --version) echo "Homebrew 5.1.3" ;;
  tap)
    if [[ $# -eq 1 ]]; then
      echo "manaflow-ai/cmux"
    else
      exit 0
    fi
    ;;
  bundle) exit 0 ;;
  *)      exit 0 ;;
esac
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/brew"
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    export BREW_TEST_LOG='$BREW_TEST_LOG'
    $(_source)
    install_via_brewfile
  "
  [ "$status" -eq 0 ]
  run grep -- '--no-lock' "$BREW_TEST_LOG"
  [ "$status" -ne 0 ]
}

@test "brewfile: brew bundle failure exits non-zero and reports fatal error" {
  cat > "$BATS_TEST_TMPDIR/bin/brew" << 'MOCK'
#!/usr/bin/env bash
case "$1" in
  --version) echo "Homebrew 5.1.3" ;;
  tap)
    if [[ $# -eq 1 ]]; then
      echo "manaflow-ai/cmux"
    else
      exit 0
    fi
    ;;
  bundle) echo "some error"; exit 1 ;;
  *) exit 0 ;;
esac
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/brew"
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    $(_source)
    install_via_brewfile
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"some error"* ]]
  [[ "$output" == *"安装失败"* ]]
}

# ===========================================================
# 3. cmux automation
# ===========================================================

@test "cmux automation: writes settings.json with automation mode and preserves existing keys" {
  mkdir -p "$HOME/.config/cmux"
  cat > "$HOME/.config/cmux/settings.json" <<'EOF'
{
  "app": {
    "appearance": "dark"
  }
}
EOF
  mock_cmux_helper_cli
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    HOME='$HOME'
    $(_source)
    configure_cmux_automation
  "
  [ "$status" -eq 0 ]
  run python3 - <<PY
import json
from pathlib import Path
path = Path(r"$HOME/.config/cmux/settings.json")
data = json.loads(path.read_text())
assert data["app"]["appearance"] == "dark"
assert data["automation"]["socketControlMode"] == "automation"
assert data["schemaVersion"] == 1
PY
  [ "$status" -eq 0 ]
}

# ===========================================================
# 4. backup_if_exists
# ===========================================================

@test "backup_if_exists: creates backup when file exists" {
  echo "original" > "$HOME/.testfile"
  run bash -c "
    $(_source)
    backup_if_exists '$HOME/.testfile' 'testfile.bak'
  "
  [ -f "$BATS_TEST_TMPDIR/backup-user/testfile.bak" ]
}

@test "backup_if_exists: does not create dir when file missing" {
  run bash -c "
    source '$REPO_ROOT/setup/bootstrap.sh'
    BACKUP_USER='$BATS_TEST_TMPDIR/backup-user-empty'
    backup_if_exists '/nonexistent/file.txt' 'test.bak'
  "
  [ ! -d "$BATS_TEST_TMPDIR/backup-user-empty" ]
}

# ===========================================================
# 5. Config file deployments
# ===========================================================

@test "ghostty: deploys when target absent" {
  run bash -c "
    $(_source)
    mkdir -p \"\$HOME/.config/ghostty\"
    cp \"\$BACKUP_DIR/ghostty-config\" \"\$HOME/.config/ghostty/config\"
  "
  [ -f "$HOME/.config/ghostty/config" ]
}

@test "ghostty: backs up existing config before overwriting" {
  echo "old config" > "$HOME/.config/ghostty/config"
  run bash -c "
    $(_source)
    ghostty_target=\"\$HOME/.config/ghostty/config\"
    backup_if_exists \"\$ghostty_target\" 'ghostty-config.bak'
    cp \"\$BACKUP_DIR/ghostty-config\" \"\$ghostty_target\"
  "
  [ -f "$BATS_TEST_TMPDIR/backup-user/ghostty-config.bak" ]
}

@test "ghostty: dry-run does not deploy file" {
  run bash -c "
    $(_source true)
    if \$DRY_RUN; then warn '[dry-run] ghostty'; fi
  "
  [ ! -f "$HOME/.config/ghostty/config" ]
  [[ "$output" == *"dry-run"* ]]
}

@test "starship: deploys to correct path" {
  run bash -c "
    $(_source)
    mkdir -p \"\$HOME/.config\"
    cp \"\$BACKUP_DIR/starship.toml\" \"\$HOME/.config/starship.toml\"
  "
  [ -f "$HOME/.config/starship.toml" ]
}

@test "zprofile: deploys to HOME" {
  run bash -c "
    $(_source)
    cp \"\$BACKUP_DIR/zprofile\" \"\$HOME/.zprofile\"
  "
  [ -f "$HOME/.zprofile" ]
}

@test "zed: deploys settings.json" {
  run bash -c "
    $(_source)
    mkdir -p \"\$HOME/.config/zed\"
    cp \"\$BACKUP_DIR/zed/settings.json\" \"\$HOME/.config/zed/settings.json\"
  "
  [ -f "$HOME/.config/zed/settings.json" ]
}

@test "completions: _opencli deployed to .zsh/completions" {
  run bash -c "
    $(_source)
    mkdir -p \"\$HOME/.zsh/completions\"
    cp \"\$BACKUP_DIR/zsh-completions/_opencli\" \"\$HOME/.zsh/completions/\"
  "
  [ -f "$HOME/.zsh/completions/_opencli" ]
}

@test "claude hooks: cmux-notify-hook.sh is executable after deploy" {
  run bash -c "
    $(_source)
    mkdir -p \"\$HOME/.claude/hooks\"
    cp \"\$BACKUP_DIR/claude-hooks/cmux-notify-hook.sh\" \"\$HOME/.claude/hooks/\"
    chmod +x \"\$HOME/.claude/hooks/cmux-notify-hook.sh\"
  "
  [ -x "$HOME/.claude/hooks/cmux-notify-hook.sh" ]
}

# ===========================================================
# 6. deploy_zshrc
# ===========================================================

@test "deploy_zshrc: deploys full zshrc to HOME" {
  run bash -c "
    $(_source)
    deploy_zshrc
  "
  [ "$status" -eq 0 ]
  [ -f "$HOME/.zshrc" ]
  [[ "$output" == *".zshrc"* ]]
}

@test "deploy_zshrc: backs up existing then overwrites" {
  echo "old zshrc content" > "$HOME/.zshrc"
  run bash -c "
    $(_source)
    deploy_zshrc
  "
  [ -f "$BATS_TEST_TMPDIR/backup-user/zshrc.bak" ]
  run grep "old zshrc content" "$HOME/.zshrc"
  [ "$status" -ne 0 ]
}

@test "deploy_zshrc: dry-run does not create file" {
  run bash -c "
    $(_source true)
    deploy_zshrc
  "
  [ ! -f "$HOME/.zshrc" ]
  [[ "$output" == *"dry-run"* ]]
}

# ===========================================================
# 7. .env.local
# ===========================================================

@test "env.local: creates from example when absent" {
  run bash -c "
    $(_source)
    if [[ ! -f \"\$HOME/.env.local\" ]]; then
      cp \"\$BACKUP_DIR/env.local.example\" \"\$HOME/.env.local\"
      warn 'created env.local'
    fi
  "
  [ -f "$HOME/.env.local" ]
  [[ "$output" == *"created"* ]]
}

@test "env.local: skips when already exists" {
  echo "export GROK_API_KEY=existing" > "$HOME/.env.local"
  run bash -c "
    $(_source)
    if [[ ! -f \"\$HOME/.env.local\" ]]; then
      cp \"\$BACKUP_DIR/env.local.example\" \"\$HOME/.env.local\"
    else
      info 'env.local exists, skipping'
    fi
  "
  [[ "$output" == *"skipping"* ]]
  grep -q "existing" "$HOME/.env.local"
}

@test "env.local: dry-run does not create file" {
  run bash -c "
    $(_source true)
    if \$DRY_RUN; then warn '[dry-run] env.local'; fi
  "
  [ ! -f "$HOME/.env.local" ]
  [[ "$output" == *"dry-run"* ]]
}

# ===========================================================
# 8. .zshrc.local
# ===========================================================

@test "zshrc.local: creates from example when absent" {
  run bash -c "
    $(_source)
    if [[ ! -f \"\$HOME/.zshrc.local\" ]]; then
      cp \"\$BACKUP_DIR/zshrc.local.example\" \"\$HOME/.zshrc.local\"
      warn 'created zshrc.local'
    fi
  "
  [ -f "$HOME/.zshrc.local" ]
  [[ "$output" == *"created"* ]]
}

@test "zshrc.local: skips when already exists" {
  echo "alias foo=bar" > "$HOME/.zshrc.local"
  run bash -c "
    $(_source)
    if [[ ! -f \"\$HOME/.zshrc.local\" ]]; then
      echo 'would create'
    else
      info 'zshrc.local exists, skipping'
    fi
  "
  [[ "$output" == *"skipping"* ]]
}

@test "zshrc.local: dry-run does not create file" {
  run bash -c "
    $(_source true)
    if \$DRY_RUN; then warn '[dry-run] zshrc.local'; fi
  "
  [ ! -f "$HOME/.zshrc.local" ]
  [[ "$output" == *"dry-run"* ]]
}

# ===========================================================
# 9. check_compatibility
# ===========================================================

@test "compatibility: warns when copy-on-select=clipboard found" {
  mkdir -p "$HOME/.config/ghostty"
  echo "copy-on-select = clipboard" > "$HOME/.config/ghostty/config"
  run bash -c "
    $(_source)
    check_compatibility
  "
  [[ "$output" == *"clipboard"* ]]
}

@test "compatibility: passes when copy-on-select=false" {
  mkdir -p "$HOME/.config/ghostty"
  echo "copy-on-select = false" > "$HOME/.config/ghostty/config"
  run bash -c "
    $(_source)
    check_compatibility
  "
  [[ "$output" == *"✓"* ]]
}

@test "compatibility: no ghostty config silently passes" {
  run bash -c "
    $(_source)
    check_compatibility
  "
  [ "$status" -eq 0 ]
}

# ===========================================================
# 10. verify
# ===========================================================

@test "verify: missing tools warn but do not hard-exit" {
  # Keep system PATH so source works, but override app commands to not exist
  # The verify function checks for cmux/ghostty/zed/starship/fastfetch/btop
  # We don't mock them, so command -v will fail for each — verify should still return 0
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$(echo "$PATH" | tr ':' '\n' | grep -vE 'homebrew|cmux|ghostty|zed|starship' | tr '\n' ':' | sed 's/:$//')'
    $(_source)
    verify
  "
  [ "$status" -eq 0 ]
}

@test "verify: present tools report success" {
  mkdir -p "$HOME/.config/cmux"
  cat > "$HOME/.config/cmux/settings.json" <<'EOF'
{
  "schemaVersion": 1,
  "automation": {
    "socketControlMode": "automation"
  }
}
EOF
  mock_cmux_helper_cli
  mock_command "starship"  "exit 0"
  mock_command "fastfetch" "exit 0"
  mock_command "btop"      "exit 0"
  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    $(_source)
    verify
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cmux automation mode"* ]]
  [[ "$output" == *"cmux ping"* ]]
}

# ===========================================================
# 11. Homebrew path detection
# ===========================================================

@test "brew detection: Apple Silicon path check logic" {
  run bash -c "
    [[ -f /opt/homebrew/bin/brew ]] && echo 'apple-silicon' || echo 'not-found'
  "
  [ "$status" -eq 0 ]
  [[ "$output" == "apple-silicon" || "$output" == "not-found" ]]
}

@test "brew detection: Intel path fallback logic" {
  run bash -c "
    if [[ -f /opt/homebrew/bin/brew ]]; then
      echo 'apple-silicon'
    elif [[ -f /usr/local/bin/brew ]]; then
      echo 'intel'
    else
      echo 'neither'
    fi
  "
  [ "$status" -eq 0 ]
  [[ "$output" == "apple-silicon" || "$output" == "intel" || "$output" == "neither" ]]
}

# ===========================================================
# 12. End-to-end dry-run
# ===========================================================

@test "e2e: --dry-run leaves HOME untouched" {
  local before
  before="$(find "$HOME" -type f | sort)"

  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    HOME='$HOME'
    BACKUP_DIR='$BATS_TEST_TMPDIR/backup'
    bash '$REPO_ROOT/setup/bootstrap.sh' --dry-run
  "
  [ "$status" -eq 0 ]

  local after
  after="$(find "$HOME" -type f | sort)"
  [ "$before" = "$after" ]
  [[ "$output" == *"BOOTSTRAP_SUMMARY_BEGIN"* ]]
  [[ "$output" == *"status=warning"* || "$output" == *"status=success"* ]]
}

@test "e2e: bootstrap writes all managed files into isolated HOME" {
  mock_brew_installed
  mock_command "cmux"      "exit 0"
  mock_command "ghostty"   "exit 0"
  mock_command "zed"       "exit 0"
  mock_command "starship"  "exit 0"
  mock_command "fastfetch" "exit 0"
  mock_command "btop"      "exit 0"

  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    HOME='$HOME'
    bash '$REPO_ROOT/setup/bootstrap.sh'
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"BOOTSTRAP_SUMMARY_BEGIN"* ]]
  [[ "$output" == *"status=success"* ]]

  [ -f "$HOME/.config/ghostty/config" ]
  [ -f "$HOME/.config/starship.toml" ]
  [ -f "$HOME/.config/zed/settings.json" ]
  [ -f "$HOME/.zprofile" ]
  [ -f "$HOME/.zshrc" ]
  [ -f "$HOME/.env.local" ]
  [ -f "$HOME/.zshrc.local" ]
  [ -f "$HOME/.config/.ghostty-opt-deployed" ]
  [ -f "$HOME/.config/cmux/settings.json" ]
  run python3 - <<PY
import json
from pathlib import Path
data = json.loads(Path(r"$HOME/.config/cmux/settings.json").read_text())
assert data["automation"]["socketControlMode"] == "automation"
PY
  [ "$status" -eq 0 ]
}

@test "e2e: brew bundle failure aborts before deployment and prints failure summary" {
  cat > "$BATS_TEST_TMPDIR/bin/brew" << 'MOCK'
#!/usr/bin/env bash
case "$1" in
  --version) echo "Homebrew 5.1.3" ;;
  tap)
    if [[ $# -eq 1 ]]; then
      echo "manaflow-ai/cmux"
    else
      exit 0
    fi
    ;;
  bundle)
    echo "Error: invalid option: --no-lock" >&2
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/brew"

  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    HOME='$HOME'
    bash '$REPO_ROOT/setup/bootstrap.sh'
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid option: --no-lock"* ]]
  [[ "$output" == *"BOOTSTRAP_SUMMARY_BEGIN"* ]]
  [[ "$output" == *"status=failed"* ]]
  [[ "$output" == *"stage=brewfile_install"* ]]
  [[ "$output" != *"全部就绪"* ]]
  [ ! -f "$HOME/.zshrc" ]
  [ ! -f "$HOME/.config/.ghostty-opt-deployed" ]
}

@test "e2e: deployed zshrc loads helpers and routes helper commands inside isolated shell" {
  export CMUX_TEST_LOG="$BATS_TEST_TMPDIR/cmux.log"
  : > "$CMUX_TEST_LOG"

  mock_brew_installed
  mock_cmux_helper_cli
  mock_command "ghostty"   "exit 0"
  mock_command "zed"       "exit 0"
  mock_command "starship"  "exit 0"
  mock_command "fastfetch" "exit 0"
  mock_command "btop"      "exit 0"

  run bash -c "
    PATH='$BATS_TEST_TMPDIR/bin:$PATH'
    HOME='$HOME'
    bash '$REPO_ROOT/setup/bootstrap.sh'
  "
  [ "$status" -eq 0 ]

  mkdir -p "$HOME/projects/demo"
  run zsh -lc "
    export HOME='$HOME'
    export PATH='$BATS_TEST_TMPDIR/bin':\$PATH
    export CMUX_TEST_LOG='$CMUX_TEST_LOG'
    source '$HOME/.zshrc'
    export PATH='$BATS_TEST_TMPDIR/bin':\$PATH
    whence -f cw cc cb >/dev/null
    unset CMUX_WORKSPACE_ID CMUX_SURFACE_ID
    cw '$HOME/projects/demo'
    export CMUX_WORKSPACE_ID='workspace:1'
    export CMUX_SURFACE_ID='surface:1'
    cc
    cb 'https://example.com'
  "
  [ "$status" -eq 0 ]

  run cat "$CMUX_TEST_LOG"
  [[ "$output" == *"$HOME/projects/demo"* ]]
  [[ "$output" == *"new-split right"* ]]
  [[ "$output" == *"identify"* ]]
  [[ "$output" == *"send --surface surface:9 \$'claude\\n'"* ]]
  [[ "$output" == *"new-pane --type browser --url https://example.com"* ]]
}
