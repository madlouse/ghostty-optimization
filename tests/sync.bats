#!/usr/bin/env bats
# tests/sync.bats — sync.sh unit tests
# Run: bats tests/sync.bats

bats_require_minimum_version 1.5.0

load 'test_helper'

setup() {
  setup_isolated_home
}

teardown() {
  teardown_isolated_home
}

@test "sync: dry-run prints intended source update without writing files" {
  local fixture_root archive_path managed_root

  fixture_root="$(create_sync_fixture_tree)"
  archive_path="$(create_sync_archive_fixture "$fixture_root")"
  managed_root="$BATS_TEST_TMPDIR/managed"

  run bash "$REPO_ROOT/setup/sync.sh" \
    --dry-run \
    --sync-only \
    --archive-url "file://$archive_path" \
    --target-root "$managed_root"

  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  [ ! -d "$managed_root/source/current" ]
}

@test "sync: sync-only downloads and installs latest source tree" {
  local fixture_root archive_path managed_root

  fixture_root="$(create_sync_fixture_tree)"
  archive_path="$(create_sync_archive_fixture "$fixture_root")"
  managed_root="$BATS_TEST_TMPDIR/managed"

  run bash "$REPO_ROOT/setup/sync.sh" \
    --sync-only \
    --archive-url "file://$archive_path" \
    --target-root "$managed_root"

  [ "$status" -eq 0 ]
  [ -x "$managed_root/source/current/setup/bootstrap.sh" ]
  [ -f "$managed_root/source/metadata.env" ]
}

@test "sync: bootstrap runs from synced source and receives passthrough flags" {
  local fixture_root archive_path managed_root bootstrap_log

  fixture_root="$(create_sync_fixture_tree)"
  archive_path="$(create_sync_archive_fixture "$fixture_root")"
  managed_root="$BATS_TEST_TMPDIR/managed"
  bootstrap_log="$BATS_TEST_TMPDIR/bootstrap.log"
  export GHOSTTY_CMUX_BOOTSTRAP_LOG="$bootstrap_log"

  run bash "$REPO_ROOT/setup/sync.sh" \
    --archive-url "file://$archive_path" \
    --target-root "$managed_root" \
    --force

  [ "$status" -eq 0 ]
  [ -f "$bootstrap_log" ]
  run cat "$bootstrap_log"
  [[ "$output" == *"$managed_root/source/current/setup/bootstrap.sh --force"* ]]
}
