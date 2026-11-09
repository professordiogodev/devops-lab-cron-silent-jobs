#!/usr/bin/env bash
# Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
rm -f /etc/cron.d/clipstr-lab; rm -rf /opt/clipstr-jobs /var/log/clipstr-lab
echo "Lab environment removed."
