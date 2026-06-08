# Solutions - Working with Directories

## Tier 1

**1.1**
```bash
mkdir ~/sandbox/builds
mkdir -p ~/sandbox/app/src/main     # -p makes app, src and main as needed
```

**1.2**
```bash
rmdir ~/sandbox/old-empty           # works: it's empty
rmdir ~/sandbox/has-stuff           # fails: "Directory not empty" - leave it
```

## Tier 2

**2.1**
```bash
rm -rf ~/sandbox/temp-build         # -r recurse, -f force
```

**2.2** The `/*` targets the *contents*, leaving the folder:
```bash
rm -rf ~/sandbox/cache/*
```

**2.3** The command to know and never run:
```bash
echo 'sudo rm -rf /' > ~/sandbox/danger.txt
```
`rm -r -f /` recursively force-deletes everything from the filesystem root - bin,
etc, home, the lot - with no prompt and no undo. We can write it safely; running
it on a real host ends the machine. (Here, the container is disposable.)

## Tier 3

**3.1**
```bash
mkdir -p ~/sandbox/release/v2/bin ~/sandbox/release/v2/config ~/sandbox/release/v2/logs
echo "2.0" > ~/sandbox/release/v2/VERSION
```

**3.2**
```bash
cd ~/sandbox
zip -r release-v2.zip release       # -r walks the whole tree
```

**3.3** Quote or escape the space:
```bash
mv ~/sandbox/"old releases" ~/sandbox/archived-releases
# or: mv ~/sandbox/old\ releases ~/sandbox/archived-releases
```

### Answers to the self-check

1. `rmdir` removes an **empty** directory only; `rm -rf` removes a directory **and
   everything inside it**.
2. `mkdir -p` creates **all missing parent directories** in the path (and doesn't
   error if they already exist).
3. `rm -rf /` recursively deletes the entire filesystem with no recovery. Here a
   disposable container protects you - `make reset` rebuilds the sandbox.
4. Wrap it in quotes (`"old releases"`) or escape the space with a backslash
   (`old\ releases`).

---

## Quick reference

| Goal | Command |
|------|---------|
| Make a dir | `mkdir name` |
| Make nested dirs | `mkdir -p a/b/c` |
| Remove empty dir | `rmdir name` |
| Remove dir + contents | `rm -rf name` |
| Empty a dir, keep it | `rm -rf name/*` |
| Zip a folder | `zip -r out.zip folder` |
| Space in a name | `'my folder'` or `my\ folder` |
| ☠️ NEVER | `sudo rm -rf /` |
