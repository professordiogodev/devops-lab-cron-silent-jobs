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

id clipstr >/dev/null 2>&1 || useradd --system --home /opt/clipstr-jobs --shell /usr/sbin/nologin clipstr
mkdir -p /opt/clipstr-jobs/bin /var/log/clipstr-lab
chown clipstr /var/log/clipstr-lab; chmod 755 /var/log/clipstr-lab

ok() { echo "echo \"\$(date +%T) $1 ran\" >> /var/log/clipstr-lab/$1.ok"; }
# 1: report.sh is not executable
printf '#!/bin/bash\n%s\n' "$(ok report)" > /opt/clipstr-jobs/report.sh; chmod 644 /opt/clipstr-jobs/report.sh
# 2: backup-db is not in cron's PATH
printf '#!/bin/bash\n%s\n' "$(ok backup)" > /opt/clipstr-jobs/bin/backup-db; chmod 755 /opt/clipstr-jobs/bin/backup-db
# 4: greet.sh needs an environment variable
printf '#!/bin/bash\nset -u\n: "$CLIPSTR_ENV"\n%s\n' "$(ok greet)" > /opt/clipstr-jobs/greet.sh; chmod 755 /opt/clipstr-jobs/greet.sh
# 5: import.sh uses a relative path
printf 'id,url\n1,https://ironhack.com\n' > /opt/clipstr-jobs/data.csv
printf '#!/bin/bash\nset -e\nwc -l data.csv >/dev/null\n%s\n' "$(ok data)" > /opt/clipstr-jobs/import.sh; chmod 755 /opt/clipstr-jobs/import.sh
chmod -R a+rX /opt/clipstr-jobs

cat > clipstr-lab.cron <<'C'
# m h dom mon dow user command
* * * * * clipstr /opt/clipstr-jobs/report.sh
* * * * * clipstr backup-db
* * * * * clipstr echo "stamp $(date +%T) on $(date +%F)" >> /var/log/clipstr-lab/stamp.ok
* * * * * clipstr /opt/clipstr-jobs/greet.sh
* * * * * clipstr /opt/clipstr-jobs/import.sh
C
cp clipstr-lab.cron /etc/cron.d/clipstr-lab; chmod 644 /etc/cron.d/clipstr-lab
echo "Five jobs are installed in /etc/cron.d/clipstr-lab (a copy is in clipstr-lab.cron). Wait a minute, then look in /var/log/clipstr-lab/."
