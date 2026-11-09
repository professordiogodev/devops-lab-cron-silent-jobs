# LAB | Cron: Five Jobs That Never Ran

## The situation

Monday. Finance asks why the weekly report never arrived. Support asks why there are no backups from the last seven days. You check: five scheduled jobs on the Clipstr server, all "installed", and none of them has produced anything. Cron did not complain once. It never does.

Cron is the oldest scheduler on Linux and the quietest. When a job fails, nothing tells you. Your job is to learn how to make a silent system talk, by fixing five jobs that each fail for a **different** reason.

> **Your mission**
> - Find out why each of the five jobs does not run, with evidence
> - Understand how cron's environment differs from your own shell
> - Fix all five in one crontab file and make them **report their own failures**

**Time:** 45-60 min | **Cost:** free | **You need:** your Ubuntu environment with `sudo` and systemd. `sudo ./teardown.sh` removes the lab.

---

## Part 0 - Set the scene

Fork this repository, clone your fork, and run:

```bash
sudo ./setup.sh
```

It installs cron and five jobs in `/etc/cron.d/clipstr-lab`. A copy is in `clipstr-lab.cron` in this repo: **edit that file**, then install it with `sudo cp clipstr-lab.cron /etc/cron.d/clipstr-lab`. When a job succeeds it writes a line to `/var/log/clipstr-lab/<name>.ok`.

Wait one minute, then look in `/var/log/clipstr-lab/`.

---

## Part 1 - Recon

1. `ls -l /var/log/clipstr-lab/`. What is there? Is that what you expected after a minute of five jobs?
2. `cat clipstr-lab.cron`. Read each line. The six columns are minute, hour, day of month, month, day of week, **user**, then the command. (Files in `/etc/cron.d` have a user column, a personal `crontab -e` does not.)
3. Is cron itself running? `systemctl status cron`.
4. What does cron say about the jobs? `sudo journalctl -u cron --since "5 minutes ago"`. Does the log tell you whether any job **succeeded**?

> **Predict** The log shows the jobs were *started*. Does that mean they worked? Write down what you think the log can and cannot tell you.

---

## Part 2 - Investigate: five jobs, five reasons

For each job, **reproduce the failure by hand as the same user in cron's environment**. Cron runs your command with almost nothing set. This is how to imitate it:

```bash
sudo -u clipstr env -i HOME=/opt/clipstr-jobs SHELL=/bin/sh PATH=/usr/bin:/bin /bin/sh -c '<the command here>'
```

Run each command that way and read the error. Fill in a table: job, error message, root cause, fix.

| Job | Hints |
|-----|-------|
| 1 `report.sh` | Read the error carefully. What does `ls -l` say about the file? |
| 2 `backup-db` | Is the command found? What is cron's `PATH`? Where is the program (`ls /opt/clipstr-jobs/bin`)? |
| 3 the `echo "stamp ..."` job | Which character in the command does cron treat specially? Look in `man 5 crontab` for the word "percent". |
| 4 `greet.sh` | It needs a variable. Where do variables come from in your shell, and where in cron? |
| 5 `import.sh` | It reads `data.csv` without a path. In which directory does cron start jobs? |

> **Break it** Before you fix anything, run job 3 by hand in your own shell: it works. Run it through `env -i ... /bin/sh -c` exactly as written in the file: what happens? Explain why "it works on my machine" is the standard sentence about cron.

---

## Part 3 - Fix and make it loud

Edit `clipstr-lab.cron` so all five jobs work. You may use:

- A `PATH=` line and other variable lines at the top of the file
- `chmod`, or running the script through `bash`
- Escaping with a backslash, or moving the logic into a script
- `cd /somewhere &&` in front of a command
- `>> /var/log/clipstr-lab/<name>.log 2>&1` so output and errors end up somewhere you can read

Install it, wait for the next minute, and watch `/var/log/clipstr-lab/`:

```bash
sudo cp clipstr-lab.cron /etc/cron.d/clipstr-lab
watch -n 5 'ls -l --time-style=+%T /var/log/clipstr-lab/'
```

Rules: all five jobs stay scheduled every minute for this lab, they keep running as the `clipstr` user, and at least one captures its output with `2>&1`.

> **Think** What does `2>&1` mean, in order, one symbol at a time? What happens to a job's output when you leave it out (hint: `MAILTO`, and whether a mail server is installed)?

---

## Part 4 - Schedule like a professional

Answer these on paper (they go in your submission), then test your expressions with a calculator such as `crontab.guru`:

1. Every weekday at 02:30.
2. Every 15 minutes between 09:00 and 17:00 on weekdays.
3. At 03:00 on the first day of every month.
4. Why is `*/90 * * * *` not "every 90 minutes"?

---

## Part 5 - Prove it

```bash
sudo ./verify.sh
```

It waits up to two and a half minutes for cron to fire, then checks each job's marker.

---

## Level up (optional)

- **flock.** Wrap a job in `flock -n /tmp/job.lock ...`. Why do long jobs need this, and what happens without it when one run takes longer than a minute?
- **systemd timers.** Rewrite the report job as `report.service` plus `report.timer`. What do you gain (logs in journald, `Persistent=`, `OnCalendar` syntax)?
- **Dead man's switch.** Make a job `curl` a monitoring URL when it succeeds. Why is "alert when nothing arrives" better than "alert on errors"?

<!-- teardown:start (generated by labs.py, do not edit) -->
## Tear down (mandatory)

Resources left behind cost money, keep doors open and pollute the next lab. Removing what you created is part of the job, so it is part of the submission: **you must prove it is gone**.

Do this **last**, after you have pasted your `verify` output into `SUBMISSION.md` (once you tear down, the lab can no longer be verified).

1. Run `sudo ./teardown.sh`. It removes the five jobs, their scripts, the logs and the `clipstr` user.

Then run the proof:

```bash
sudo ./verify-teardown.sh
```

It prints a list of checks and must end with **TEARDOWN VERIFIED**. If it reports leftovers, remove them and run it again. Paste the full output in your submission.
<!-- teardown:end -->

<!-- submission:start (generated by labs.py, do not edit) -->
## Submission

Answer the questions in `SUBMISSION.md` in **your fork** (paste output in code blocks where asked), push, then submit the **URL of your fork**.

**Files to commit**

- `clipstr-lab.cron`: your fixed crontab file, committed to the repo

**Questions to answer**

1. For each of the five jobs: what was the reason it never ran, which tool showed you (log, `journalctl`, manual run) and what was the fix?
2. Why is cron's environment different from your shell's? Name three things that are different and which job taught you each.
3. Explain the five fields of `* * * * *` and write the expression for "every weekday at 02:30" and for "every 15 minutes between 09:00 and 17:00".
4. Why is `>> file 2>&1` important in a cron job? What happens to the output when you leave it out?
5. Paste the output of `sudo ./verify.sh`. It must end with **ALL CHECKS PASSED**.
6. **Tear down.** Paste the output of `sudo ./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.
<!-- submission:end -->
