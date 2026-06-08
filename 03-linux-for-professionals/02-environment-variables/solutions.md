# Solutions - Environment Variables

The key idea: **persist** in `~/.bashrc`, then `source` it (or open a new shell).

## Tier 1
```bash
echo 'export GREETING="hello world"' >> ~/.bashrc   # 1.1
echo 'export APP_ENV=production'      >> ~/.bashrc   # 1.2
source ~/.bashrc
echo $GREETING $APP_ENV                              # hello world production
```

## Tier 2
```bash
echo "alias ll='ls -lah'" >> ~/.bashrc              # 2.1
mkdir -p ~/bin                                       # 2.2
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Tier 3
```bash
cat > ~/bin/greet <<'EOF'                            # 3.1
#!/usr/bin/env bash
echo "ready to deploy"
EOF
chmod +x ~/bin/greet
greet                                                # ready to deploy
```

### Answers
1. `export FOO=bar` only affects the **current** session. To persist, add the
   `export` line to `~/.bashrc` (sourced by every new shell).
2. `PATH` is a colon-separated list of directories the shell searches, in order, to
   find the executable for a command you type.
3. Either `~/bin` isn't on `PATH` (re-check the export + `source`), or the script
   isn't executable (`chmod +x ~/bin/greet`).
