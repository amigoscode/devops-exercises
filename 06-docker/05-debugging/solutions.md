# Solutions - Debugging

Run these from the `06-docker/` folder so the relative paths match.

## Tier 1
**1.1** Read the logs and grab the error line:
```bash
docker logs buggy                                   # see everything it printed
docker logs buggy 2>&1 | grep ERROR > sandbox/05-debugging/error.txt
```

**1.2** Follow live:
```bash
docker logs -f buggy        # Ctrl+C stops following, not the container
```

## Tier 2
**2.1** Read the environment from inside the container:
```bash
docker exec buggy env                               # all variables
docker exec buggy env | grep APP_ENV > sandbox/05-debugging/env.txt
```

**2.2** Run a command inside the running container:
```bash
docker exec buggy touch /tmp/fixed
docker exec buggy ls -l /tmp/fixed                  # confirm
# open a full shell to poke around:  docker exec -it buggy sh
```

## Tier 3
**3.1** Pull one field out of the metadata with a Go-template:
```bash
docker inspect -f '{{index .Config.Labels "version"}}' buggy > sandbox/05-debugging/version.txt
```

### Answers
1. `docker logs -f` **follows** (tails) the logs, streaming new lines as they arrive;
   plain `docker logs` prints what exists so far and returns.
2. No. Ctrl+C only detaches your terminal from the log stream. The container keeps
   running in the background.
3. `docker exec` runs a command **inside an already-running** container (great for
   debugging). `docker run` **creates a new** container from an image.
4. Its full config: environment variables, mounts, networks/IP, labels, restart
   policy, the exact command/entrypoint - none of which appear in the app's logs.
5. `docker exec -it <container> sh` (or `bash` if the image has it) gives you an
   interactive shell inside it.
