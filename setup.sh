#!/usr/bin/env bash
# Installs cron and five broken jobs. Run with: sudo ./setup.sh (safe to re-run)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./setup.sh" >&2; exit 1; }
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq cron >/dev/null
./teardown.sh >/dev/null 2>&1 || true
state="$(systemctl is-system-running 2>/dev/null || true)"
{ [ -n "$state" ] && [ "$state" != offline ]; } && systemctl enable --now cron >/dev/null 2>&1 || service cron start >/dev/null 2>&1 || true

id clippy >/dev/null 2>&1 || useradd --system --home /opt/clippy-jobs --shell /usr/sbin/nologin clippy
mkdir -p /opt/clippy-jobs/bin /var/log/clippy-lab
chown clippy /var/log/clippy-lab; chmod 755 /var/log/clippy-lab

ok() { echo "echo \"\$(date +%T) $1 ran\" >> /var/log/clippy-lab/$1.ok"; }
# 1: report.sh is not executable
printf '#!/bin/bash\n%s\n' "$(ok report)" > /opt/clippy-jobs/report.sh; chmod 644 /opt/clippy-jobs/report.sh
# 2: backup-db is not in cron's PATH
printf '#!/bin/bash\n%s\n' "$(ok backup)" > /opt/clippy-jobs/bin/backup-db; chmod 755 /opt/clippy-jobs/bin/backup-db
# 4: greet.sh needs an environment variable
printf '#!/bin/bash\nset -u\n: "$CLIPPY_ENV"\n%s\n' "$(ok greet)" > /opt/clippy-jobs/greet.sh; chmod 755 /opt/clippy-jobs/greet.sh
# 5: import.sh uses a relative path
printf 'id,url\n1,https://ironhack.com\n' > /opt/clippy-jobs/data.csv
printf '#!/bin/bash\nset -e\nwc -l data.csv >/dev/null\n%s\n' "$(ok data)" > /opt/clippy-jobs/import.sh; chmod 755 /opt/clippy-jobs/import.sh
chmod -R a+rX /opt/clippy-jobs

cat > clippy-lab.cron <<'C'
# m h dom mon dow user command
* * * * * clippy /opt/clippy-jobs/report.sh
* * * * * clippy backup-db
* * * * * clippy echo "stamp $(date +%T) on $(date +%F)" >> /var/log/clippy-lab/stamp.ok
* * * * * clippy /opt/clippy-jobs/greet.sh
* * * * * clippy /opt/clippy-jobs/import.sh
C
cp clippy-lab.cron /etc/cron.d/clippy-lab; chmod 644 /etc/cron.d/clippy-lab
echo "Five jobs are installed in /etc/cron.d/clippy-lab (a copy is in clippy-lab.cron). Wait a minute, then look in /var/log/clippy-lab/."
