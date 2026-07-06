# 09 - Capstone: Ship a Real App (Open-Ended, Reviewed)

> The final Docker capstone - and a different kind of challenge. There is **no
> auto-grader** here. You take a real, non-trivial application and make the whole
> thing run with Docker Compose, then **submit it for review in the Academy**, exactly
> like handing a running environment to a teammate.

Everything so far gave you an app that was already wired up. Real DevOps work is the
opposite: someone hands you a codebase and says *"get this running, reproducibly, for
the whole team."* That is this capstone.

## The application

**Smart Lead Qualification** - a Spring Boot service that qualifies sales leads from
incoming messages.

- Repository: **https://github.com/ricardopissarra/smart-lead**
- What it does: a message comes in over a REST API, gets published to a **queue**, a
  listener picks it up and runs it through an **AI analyzer**, and if it looks like a
  real lead it is saved to a **database** and linked back to the message.

It has real moving parts a DevOps engineer has to stand up:

| Part | What it is |
|---|---|
| **App** | a Spring Boot (Java 21, Maven) service exposing a REST API on port 8080 |
| **Database** | PostgreSQL (the app runs Flyway migrations on startup) |
| **Queue** | AWS SQS, emulated locally by **LocalStack** |
| **AI** | HuggingFace (external) - with a built-in **fake stub** so it runs with no API key |

Read the project's own README first. Notice what is already there (a
`docker-compose.yml` that starts *only* the infrastructure) and what is missing.

## Your mission

Make the **entire system** come up with Docker Compose - app included - on a machine
that has nothing but Docker installed. No locally installed Java, no Maven, no manual
steps. A reviewer should be able to clone your work and run **one command**, then hit
the API and watch a message flow all the way through to a saved lead.

This is deliberately open-ended. Part of the job is figuring out *what* is necessary
and *how* to wire it together. That is the skill being assessed.

## What "done" looks like (acceptance criteria)

Your submission must satisfy all of these:

1. **One command brings up everything.** `docker compose up` (optionally with
   `--build`) starts the app, the database, and the queue - no host Java/Maven needed.
2. **The app is containerized by you.** There is a `Dockerfile` for the Spring Boot
   app that builds it from source (the running machine does not have Maven).
3. **The services find each other.** The app talks to the database and the queue by
   their Compose **service names**, not `localhost`. (The app currently defaults to
   `localhost` - you have to change that without editing hard-coded values you should
   not need to. Hint below.)
4. **Correct startup.** The app does not crash because the database or queue "was not
   ready yet." Ordering/health is handled.
5. **The queue exists.** The SQS queue the app expects is present when the app starts.
6. **Data persists.** Restarting the stack does not wipe the database.
7. **No secrets required to run.** It comes up with **no** real API keys (use the
   provided AI stub). If you support a real key, it is passed in safely, not committed.
8. **It actually works end to end.** You can `POST` a message and then `GET` a lead
   that was created from it.

Prove #8 with something like:
```bash
# submit a message
curl -X POST localhost:8080/api/v1/messages \
  -H 'Content-Type: application/json' \
  -d '{"content":"How much does the pro plan cost?"}'

# a few seconds later, a lead should exist
curl localhost:8080/api/v1/leads
```

## Things you will have to figure out

These are the real decisions - work them out, do not expect them spelled out:

- **Building the app image.** Maven build inside the image, or a pre-built jar? Keep
  the final image lean (multi-stage is worth learning here).
- **Pointing the app at the containers.** The app reads its config from
  `application.properties`. Spring lets you **override any property with an environment
  variable** - look at every `localhost`/queue/database value in that file and think
  about which ones must change when the app runs *inside* Compose next to `db` and
  `localstack`.
- **Startup ordering.** `depends_on` alone waits for *start*, not for *ready*. How do
  you make the app wait until Postgres and LocalStack are actually accepting work?
- **Creating the queue.** The repo already has a LocalStack init hook - make sure it
  runs and the app uses the same queue name.
- **The AI call.** You have no HuggingFace key. The app ships a stub you can switch on
  so analysis runs locally. Find it (the project README and the `dev` profile are good
  places to look) and turn it on for this environment.
- **Persistence.** Which volume keeps the database's data across `down`/`up`?

### Heads-up: the shipped infra may not "just run"

The repo's existing `docker-compose.yml` starts the infrastructure, but do not assume
it comes up cleanly on *your* machine with no accounts or tokens. Part of real DevOps
work is making someone else's environment reproducible for everyone. Two things worth
checking early (there are more):

- **LocalStack licensing.** The `latest` LocalStack image expects a paid auth token and
  will quit without one. The SQS you need is available in the free community edition -
  make the queue run with **no token required**.
- **Postgres image version.** Newer Postgres major versions changed where the data
  directory is mounted. A volume that "worked" on an older tag can make the container
  refuse to start. Make sure your database comes up from cold *and* keeps its data.

Getting the infrastructure to start reliably for an outsider is part of the grade.

## Stretch goals (optional, impress the reviewer)

- A healthcheck on the **app** itself (not just the dependencies).
- A multi-stage build that produces a small runtime image, and a `.dockerignore`.
- Run the app as a **non-root** user in the container.
- A `Makefile` or short script wrapping the common commands.
- A clean way to switch the real HuggingFace key on via an env var / `.env`.
- Scale the app or add a reverse proxy in front of it.

## How to submit

1. **Fork** the smart-lead repo (or start a fresh repo that contains it) so your work
   lives somewhere you control.
2. Add your `Dockerfile`, your Compose changes, and anything else you needed.
3. Fill in [`SUBMISSION.md`](SUBMISSION.md) (copy it into your project) - it asks how to
   run your solution and to explain the key decisions you made and why.
4. Push it, and **submit the repository link in the Academy for review.**

You will be assessed against [`RUBRIC.md`](RUBRIC.md) - read it before you start so you
know what "great" looks like. Do not just aim for "it runs" - aim for something you
would be happy to hand a teammate.

---

## Self-check before you submit (optional)

Copy [`self-check.sh`](self-check.sh) into the root of your solution and run it after
`docker compose up`. It exercises the full flow (starts nothing itself - just probes)
and tells you whether an outsider can bring your stack up and get a lead. It is a
sanity check, **not** the official grade - a human still reviews your design.

## Self-reflection questions (answer in your SUBMISSION.md)

1. Which `application.properties` values did you override, and why those exactly?
2. How did you guarantee the app does not start before the database and queue are
   ready - and how is that different from a plain `depends_on`?
3. Where does the database data live, and how did you prove it survives a restart?
4. How would you switch this environment from the AI stub to a real HuggingFace key
   without changing the image or committing a secret?
5. What did you do to keep the final image small and safe, and what would you improve
   with more time?
