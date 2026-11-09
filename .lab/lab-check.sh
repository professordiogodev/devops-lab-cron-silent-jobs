#!/usr/bin/env bash
rc=0
[ -s clipstr-lab.cron ] && [ "$(grep -cE '^[^#]*(report|backup|stamp|greet|import)' clipstr-lab.cron)" -ge 5 ] && echo "- ✅ clipstr-lab.cron has the five jobs" || { echo "- ❌ clipstr-lab.cron is missing or lacks the five jobs"; rc=1; }
grep -q '2>&1' clipstr-lab.cron 2>/dev/null && echo "- ✅ a job captures stdout and stderr" || { echo "- ❌ at least one job must redirect with >> file 2>&1"; rc=1; }
grep -q '\\%' clipstr-lab.cron 2>/dev/null && echo "- ✅ the % characters are escaped" || { echo "- ⚠️ no escaped \\% found: did you solve the stamp job another way?"; }
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
