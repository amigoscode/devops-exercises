# Solutions - File Permissions

> Try every exercise before reading. The *reasoning* matters more than the command.

All commands run from inside `sandbox/`.

## Tier 1

**1.1** Make `deploy.sh` executable by everyone:
```bash
chmod a+x deploy.sh      # or: chmod 755 deploy.sh
```
`a+x` adds execute for user, group, and others without touching read/write.

**1.2** `secret.env` owner-only read/write:
```bash
chmod 600 secret.env     # or: chmod u=rw,go= secret.env
```
Secrets should never be group/world readable - this is a real security habit.

**1.3** `notes.txt` read-only for everyone:
```bash
chmod 444 notes.txt      # or: chmod a=r notes.txt
```

## Tier 2

**2.1** `app/run.sh` → `rwxr-x---`:
```bash
chmod 750 app/run.sh
```
`rwx`=7, `r-x`=5, `---`=0 → **750**.

**2.2** Same perms, symbolic only:
```bash
chmod u=rwx,g=rx,o= app/config.yaml
```

**2.3** Lock down `app/logs/` - directory to `750`, the log files to `644`:
```bash
chmod 750 app/logs                       # dir needs x to be entered
chmod 644 app/logs/*.log                  # or list them: app1.log app2.log app3.log
```
The lesson from the folders video: a directory needs **execute** or you can't
`ls`/`cd` into it, even with read. Files don't need execute unless they're
scripts. (The pro one-liner `find app/logs -type f -exec chmod 644 {} +` does
the files in one shot - but `find` comes later in the track.)

## Tier 3 - Scenario

**3.1** `start.sh` won't run → owner needs execute, only owner writes:
```bash
chmod 744 service/start.sh   # or: chmod u+x,go-w service/start.sh (from 644)
```

**3.2** `app.conf` (mode 000) → readable by owner + group, no writes:
```bash
chmod 440 service/app.conf
```

**3.3** `app.log` owned by `root:root` → take ownership as `student`, owner rw:
```bash
sudo chown student:student service/app.log   # or just: sudo chown student service/app.log
chmod 644 service/app.log
```
The lesson: **ownership and permissions are two different controls** - `chmod`
can't fix a "wrong owner" problem, only `chown` can. Note you needed `sudo`
because only root could reassign a root-owned file.

---

### Mental model to keep

```
 -    rwx    r-x    r--
type  owner  group  others
       7      5      4     →  754
```
Octal = sum of read(4) + write(2) + execute(1) per column.
