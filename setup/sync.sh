#!/usr/bin/env bash
# ============================================================
# Ghostty + Cmux + Zed source sync script
# Fetches the latest repo snapshot, then runs bootstrap from it.
# ============================================================

set -euo pipefail

ARCHIVE_URL="${GHOSTTY_CMUX_ARCHIVE_URL:-https://github.com/madlouse/ghostty-optimization/archive/refs/heads/main.tar.gz}"
TARGET_ROOT="${GHOSTTY_CMUX_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/ghostty-cmux}"
DOWNLOAD_DIR="$TARGET_ROOT/downloads"
SOURCE_BASE_DIR="$TARGET_ROOT/source"
SOURCE_DIR="$SOURCE_BASE_DIR/current"
METADATA_FILE="$SOURCE_BASE_DIR/metadata.env"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1" >&2; }
step()  { echo -e "\n${CYAN}==>${NC} $1"; }

DRY_RUN=false
SYNC_ONLY=false
BOOTSTRAP_ARGS=()

usage() {
  cat <<'EOF'
用法: bash setup/sync.sh [options] [bootstrap args...]

选项:
  --dry-run             只预览同步和 bootstrap 行为
  --force               透传给 bootstrap.sh
  --sync-only           仅同步最新源码，不执行 bootstrap
  --archive-url <url>   覆盖默认源码归档地址
  --target-root <path>  覆盖默认 managed source 根目录
  --help                显示帮助

环境变量:
  GHOSTTY_CMUX_ARCHIVE_URL
  GHOSTTY_CMUX_ROOT
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      BOOTSTRAP_ARGS+=("$1")
      shift
      ;;
    --force)
      BOOTSTRAP_ARGS+=("$1")
      shift
      ;;
    --sync-only)
      SYNC_ONLY=true
      shift
      ;;
    --archive-url)
      ARCHIVE_URL="${2:?missing value for --archive-url}"
      shift 2
      ;;
    --archive-url=*)
      ARCHIVE_URL="${1#*=}"
      shift
      ;;
    --target-root)
      TARGET_ROOT="${2:?missing value for --target-root}"
      DOWNLOAD_DIR="$TARGET_ROOT/downloads"
      SOURCE_BASE_DIR="$TARGET_ROOT/source"
      SOURCE_DIR="$SOURCE_BASE_DIR/current"
      METADATA_FILE="$SOURCE_BASE_DIR/metadata.env"
      shift 2
      ;;
    --target-root=*)
      TARGET_ROOT="${1#*=}"
      DOWNLOAD_DIR="$TARGET_ROOT/downloads"
      SOURCE_BASE_DIR="$TARGET_ROOT/source"
      SOURCE_DIR="$SOURCE_BASE_DIR/current"
      METADATA_FILE="$SOURCE_BASE_DIR/metadata.env"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      BOOTSTRAP_ARGS+=("$1")
      shift
      ;;
  esac
done

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    error "missing required command: $cmd"
    exit 1
  fi
}

write_metadata() {
  local source_path="$1"
  local synced_at="$2"

  mkdir -p "$SOURCE_BASE_DIR"
  cat > "$METADATA_FILE" <<EOF
ARCHIVE_URL='$ARCHIVE_URL'
SYNCED_AT='$synced_at'
SOURCE_DIR='$source_path'
EOF
}

sync_source() {
  local archive_path="$DOWNLOAD_DIR/source.tar.gz"
  local tmp_extract_dir extracted_root incoming_dir synced_at

  step "同步最新配置源码"
  echo "  Archive: $ARCHIVE_URL"
  echo "  Target:  $SOURCE_DIR"

  if $DRY_RUN; then
    warn "[dry-run] 将下载并替换 managed source"
    return 0
  fi

  mkdir -p "$DOWNLOAD_DIR" "$SOURCE_BASE_DIR"
  curl -fsSL "$ARCHIVE_URL" -o "$archive_path"

  tmp_extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/ghostty-cmux-sync.XXXXXX")"
  trap 'if [[ -n "${tmp_extract_dir:-}" ]]; then rm -rf "${tmp_extract_dir}"; fi' RETURN

  tar -xzf "$archive_path" -C "$tmp_extract_dir"
  extracted_root="$(find "$tmp_extract_dir" -mindepth 1 -maxdepth 1 -type d -print -quit)"
  if [[ -z "$extracted_root" ]]; then
    error "archive did not contain a top-level source directory"
    exit 1
  fi

  incoming_dir="$SOURCE_BASE_DIR/.incoming.$$"
  rm -rf "$incoming_dir"
  mv "$extracted_root" "$incoming_dir"
  rm -rf "$SOURCE_DIR"
  mv "$incoming_dir" "$SOURCE_DIR"

  synced_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  write_metadata "$SOURCE_DIR" "$synced_at"
  info "最新源码已同步到 $SOURCE_DIR"
}

run_bootstrap() {
  local bootstrap_script="$SOURCE_DIR/setup/bootstrap.sh"

  if $SYNC_ONLY; then
    info "sync-only 模式，跳过 bootstrap"
    return 0
  fi

  step "执行最新 bootstrap"
  echo "  Script: $bootstrap_script"

  if $DRY_RUN; then
    warn "[dry-run] 将执行: bash $bootstrap_script ${BOOTSTRAP_ARGS[*]}"
    return 0
  fi

  if [[ ! -x "$bootstrap_script" ]]; then
    error "bootstrap script not found or not executable: $bootstrap_script"
    exit 1
  fi

  bash "$bootstrap_script" "${BOOTSTRAP_ARGS[@]}"
}

main() {
  require_command curl
  require_command tar
  require_command bash
  sync_source
  run_bootstrap
}

main "$@"
