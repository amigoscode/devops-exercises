# Solutions - System Admin & Maintenance

## Tier 1
```bash
df -h > ~/sandbox/disk.txt                       # 1.1
du -sh ~/sandbox/data > ~/sandbox/data-size.txt  # 1.2
```

## Tier 2
```bash
ps aux > ~/sandbox/processes.txt                 # 2.1
# 2.2 - find the runaway and record its PID:
ps aux | grep sleep                              # read the PID (ignore the grep line)
echo <PID> > ~/sandbox/runaway-pid.txt           # write the PID you found
```

## Tier 3
```bash
jq -r '.service.name'    ~/sandbox/services.json > ~/sandbox/name.txt      # 3.1 -> checkout-api
jq -r '.service.version' ~/sandbox/services.json > ~/sandbox/version.txt   # 3.2 -> 2.3.1
jq '.replicas'           ~/sandbox/services.json > ~/sandbox/replicas.txt  # 3.3 -> 3
```

### Answers
1. `df` shows usage of whole **filesystems** (how full each mount is); `du` shows
   how much space **files/directories** take up.
2. Use `top`/`htop` (live) or `ps aux | grep name` to locate the process and read
   its **PID** - the number you'd act on.
3. `jq -r '.a.b'` reaches into the JSON and prints the nested field `b`. `-r` gives
   **raw** output (no surrounding quotes), so it's clean text for piping.
