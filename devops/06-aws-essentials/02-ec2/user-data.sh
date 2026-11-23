#!/bin/bash
# User data for amigos-web: paste all of it into EC2 → Launch instances →
# Advanced details → User data. It runs once, as root, at the first boot.
# It only prepares the website: it writes the home page to /srv/www.
# Installing Docker and running nginx is your job (Tier 2).
mkdir -p /srv/www

# Ask the instance metadata service (IMDSv2) who and where this server is.
IMDS=http://169.254.169.254/latest
TOKEN=$(curl -s -X PUT "$IMDS/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
meta() {
  curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$IMDS/meta-data/$1"
}

cat > /srv/www/index.html <<PAGE
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>amigos-web</title>
<style>
  body { margin: 0; min-height: 100vh; display: grid;
         place-items: center; font-family: system-ui, sans-serif;
         background: #0f172a; color: #e2e8f0; }
  main { max-width: 36rem; padding: 2rem; }
  h1   { font-size: 2.2rem; margin: 0 0 .5rem; }
  span, a { color: #a78bfa; }
  code { background: #1e293b; padding: .1rem .35rem; }
</style>
</head>
<body>
<main>
  <h1>Hello from <span>amigos-web</span> 👋</h1>
  <p>nginx in a Docker container, on an EC2 server you launched.</p>
  <p>Instance <code>$(meta instance-id)</code>,
     type <code>$(meta instance-type)</code>,
     in <code>$(meta placement/availability-zone)</code>.</p>
  <p>This page was written by user data, at the server's first boot.</p>
</main>
</body>
</html>
PAGE

chmod -R a+rX /srv/www
