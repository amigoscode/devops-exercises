# Review Rubric - Smart Lead Capstone

This is how your submission is assessed in the Academy. It is also your checklist:
read it before you start. A reviewer will clone your repository and try to run it on a
clean machine that has **only Docker installed**.

## How grading works

Each area below is scored. The **Must-pass** items are gates: if any of them fails,
the submission is sent back with feedback before the finer points are scored. The rest
separates "it works" from "I would trust this person with a production stack."

---

## Must-pass gates (the environment actually works)

| # | Gate | How the reviewer checks it |
|---|------|----------------------------|
| G1 | Comes up in one command | `docker compose up --build` with nothing but Docker installed - no host Java/Maven, no manual steps |
| G2 | App is containerized from source | there is a `Dockerfile` that builds the Spring Boot app; the reviewer did not run Maven themselves |
| G3 | Services talk by name | app reaches Postgres and LocalStack via Compose service names, not `localhost` |
| G4 | Boots reliably | app does not crash-loop waiting for the DB/queue; a cold `up` on a fresh machine works |
| G5 | End to end works | `POST /api/v1/messages` then, shortly after, `GET /api/v1/leads` returns a lead created from it |
| G6 | No secrets needed | it runs with no real API key (AI stub enabled); no secret is committed to the repo |

## Scored dimensions

### 1. Correctness & completeness (35%)
- All acceptance criteria in the brief are met.
- The queue exists before the app needs it; Flyway migrations run cleanly.
- Database data **persists** across `docker compose down` / `up` (a named volume).
- Configuration is passed in (env vars), not hacked into source files that should not
  change.

### 2. Compose & image quality (30%)
- Startup ordering uses **healthchecks** with `depends_on: condition: service_healthy`,
  not a bare `depends_on` or `sleep`.
- The app `Dockerfile` is a sensible **multi-stage** build producing a lean runtime
  image (JRE, not a full JDK + Maven).
- A `.dockerignore` keeps build context small; no `target/`, `.git`, etc. copied in.
- Ports, volumes and networks are declared cleanly; no leftover/unused config.

### 3. Security & configuration hygiene (15%)
- App container runs as a **non-root** user (stretch, but rewarded).
- Secrets (a real HuggingFace key, DB password) are injected via env/`.env`, never
  committed; `.env` is git-ignored and an `.env.example` documents the variables.
- Base images are pinned to a tag, not floating `latest` where it matters.

### 4. Documentation & reproducibility (15%)
- `SUBMISSION.md` is filled in: exact run commands, the decisions made and **why**, and
  answers to the reflection questions.
- A fresh reader can go from clone to working stack using only the docs.
- Trade-offs and known limitations are stated honestly.

### 5. Stretch & polish (5%, bonus)
- App-level healthcheck, `Makefile`/scripts, reverse proxy, horizontal scaling, real
  key switch-over, CI that builds the image, etc. Anything that shows craft beyond the
  minimum.

---

## Rough banding

- **Needs work** - one or more must-pass gates fail.
- **Solid** - all gates pass; config via env; data persists; readable Compose.
- **Strong** - healthcheck-based ordering, clean multi-stage image, `.dockerignore`,
  good `SUBMISSION.md`.
- **Excellent** - all of the above plus non-root, safe secret handling, and one or more
  stretch goals done well. Something you would genuinely hand to a team.

## Reviewer notes

- Run it twice: once `--build` from cold, once after a `down`/`up` to confirm
  persistence and that a warm start still works.
- Skim the git history and `.dockerignore`; check that no secret or `target/` blob was
  committed.
- Favor sound reasoning in `SUBMISSION.md` over a perfect setup - understanding the
  *why* matters more than copying a config.
