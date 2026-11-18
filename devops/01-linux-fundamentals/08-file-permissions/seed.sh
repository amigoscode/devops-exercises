#!/usr/bin/env bash
# Runs INSIDE the Ubuntu container. Builds a fresh ~/sandbox for the exercises.
set -euo pipefail
SB="$HOME/sandbox"

rm -rf "$SB"
mkdir -p "$SB/app/logs" "$SB/service"

# --- Tier 1 ---
printf '#!/usr/bin/env bash\necho deploying\n' > "$SB/deploy.sh"
echo 'API_KEY=changeme'        > "$SB/secret.env"
echo 'remember to rotate keys' > "$SB/notes.txt"
chmod 644 "$SB/deploy.sh" "$SB/secret.env" "$SB/notes.txt"

# --- Tier 2 ---
echo 'echo run' > "$SB/app/run.sh"
echo 'env: prod' > "$SB/app/config.yaml"
for i in 1 2 3; do echo "log line $i" > "$SB/app/logs/app$i.log"; done
find "$SB/app" -type f -exec chmod 666 {} +
find "$SB/app" -type d -exec chmod 755 {} +

# --- Tier 3 (real scenario) ---
printf '#!/usr/bin/env bash\necho started\n' > "$SB/service/start.sh"
echo 'port: 8080' > "$SB/service/app.conf"
echo 'boot ok'    > "$SB/service/app.log"
chmod 644 "$SB/service/start.sh"   # missing execute -> "permission denied"
chmod 000 "$SB/service/app.conf"   # unreadable
# Genuinely root-owned - only possible because we're in a container.
sudo chown root:root "$SB/service/app.log"

echo "Sandbox ready at ~/sandbox"
