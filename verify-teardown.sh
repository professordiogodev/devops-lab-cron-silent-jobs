#!/usr/bin/env bash
# Proves the lab environment is gone. Run with: sudo ./verify-teardown.sh
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify-teardown.sh" >&2; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
no_user() { ! id "$1" >/dev/null 2>&1; }
no_group() { ! getent group "$1" >/dev/null 2>&1; }
no_path() { [ ! -e "$1" ]; }
no_proc() { ! pgrep -f "$1" >/dev/null 2>&1; }
no_listener() { ! ss -ltn 2>/dev/null | grep -qE ":$1\\b"; }

check "/etc/cron.d/clippy-lab is gone" no_path /etc/cron.d/clippy-lab
check "/opt/clippy-jobs is gone" no_path /opt/clippy-jobs
check "/var/log/clippy-lab is gone" no_path /var/log/clippy-lab
check "user clippy is gone" no_user clippy

echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass)"; else echo "NOT CLEAN: $failn leftover(s). Finish the tear down steps and run this again."; fi
exit "$failn"
