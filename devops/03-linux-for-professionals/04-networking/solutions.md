# Solutions - Networking

## Tier 1
```bash
ss -a > ~/sandbox/sockets.txt             # 1.1  (-a = all sockets, incl. the listening :8000)
```

## Tier 2
```bash
curl -s http://localhost:8000/hello.txt -o ~/sandbox/fetched.txt   # 2.1
curl -sI http://localhost:8000/ > ~/sandbox/headers.txt            # 2.2  (-I = headers only)
```

## Tier 3
```bash
curl -s http://localhost:8000/services.json | jq -r '.service.name' > ~/sandbox/svc.txt  # 3.1
```

### Answers
1. `ss -a` lists **all** open sockets - including listening ones, so you can see
   what's accepting connections (e.g. is my service actually up on 8000?).
2. `-o` saves the response **body** to a file; `-I` fetches only the **headers**
   (status code, content-type, etc.) - great for a quick "is it up / what does it
   return" check.
3. APIs and tools emit JSON; `curl` fetches it and `jq` extracts exactly the field
   you need - the bread-and-butter of scripting against services.
