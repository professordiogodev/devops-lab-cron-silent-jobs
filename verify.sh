#!/usr/bin/env bash
# Run with: sudo ./verify.sh   (waits up to ~2.5 minutes for cron to fire)
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify.sh" >&2; exit 1; }
[ -d /opt/clippy-jobs ] || { echo "Run sudo ./setup.sh first"; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }

echo "== Your crontab =="
check "clippy-lab.cron is what cron really runs (identical to /etc/cron.d/clippy-lab)" cmp -s clippy-lab.cron /etc/cron.d/clippy-lab
check "cron is running"                                        bash -c "pgrep -x cron >/dev/null"
check "all five jobs are still in the file"                    bash -c "[ \$(grep -cE '^[^#].*(report|backup|stamp|greet|import)' clippy-lab.cron) -ge 5 ]"
check "jobs still run as the clippy user, not root"           bash -c "! grep -E '^[^#]*[0-9*] +root ' clippy-lab.cron"
check "at least one job captures its output (>> file 2>&1)"    grep -q '2>&1' clippy-lab.cron

echo "== Did the jobs run? (waiting up to 150 seconds) =="
start=$(date +%s); deadline=$((start + 150))
fresh() { f=/var/log/clippy-lab/$1.ok; [ -f "$f" ] && [ $(( $(date +%s) - $(stat -c %Y "$f") )) -lt 75 ]; }
while [ "$(date +%s)" -lt "$deadline" ]; do
  all=1; for j in report backup stamp greet data; do fresh $j || all=0; done
  [ $all = 1 ] && break; sleep 5
done
for j in report backup stamp greet data; do check "job '$j' ran in the last minute" fresh $j; done
check "the stamp job wrote a real date (the % trap is fixed)"  bash -c "tail -1 /var/log/clippy-lab/stamp.ok | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'"

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
