#!/usr/bin/env bash
# Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
rm -f /etc/cron.d/clippy-lab; rm -rf /opt/clippy-jobs /var/log/clippy-lab
userdel -f clippy 2>/dev/null
echo "Lab environment removed."
