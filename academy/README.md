# Amigoscode Academy (TUI)

The terminal app students launch with `./academy.sh` / `academy.cmd` from the repo
root. Built with Go and [Charm](https://charm.sh) (Bubble Tea, Lip Gloss, Glamour).

## How it fits the repo

The Academy has **no exercise content of its own**. On every launch it reads the repo:

| It reads | To get |
|----------|--------|
| `track/` folders (`devops/`, `git/`, `sql/`) + `README.md` H1 | the groups in the course list and their names |
| `track/NN-course/` folders + `README.md` H1 | the courses in each group and their titles |
| `NN-course/Dockerfile` | marks an Ubuntu-sandbox course (DevOps 01-04, Git); the image every section runs in |
| `NN-course/runner.sh` | marks a host-Docker course (DevOps 05 Docker); start/verify/reset/stop are delegated to it |
| `NN-course/start-postgres.sh` | marks an SQL course (the `sql/` track): the sandbox opens straight in `psql`, connected to the database the section's `seed.sh` exports as `PGDATABASE` in `~/.bashrc`; `:check` and `:questions` work inside psql |
| `NN-section/wake.sh` (optional) | run when a stopped sandbox is started again (Docker or the machine restarted), to bring back background services the seed started |
| `NN-section/README.md` | the lesson, `## Tier N - ...` headings, `**1.2 (graded)**` / `(drill)` tasks |
| `verify.sh` output | `✅ 1.2 ...` / `❌ 1.2 ...` lines, mapped back onto the tasks |
| `solutions.md`, `self-check.sh` | the Solution tab and capstone self-checks |

So **adding a track, course or section is just adding a folder** in the usual shape. Keep task headings
as `**N.N (graded)**` and print the task id at the start of each ✅/❌ line, and the
checklist lights up automatically. `./academy.sh --list` prints what was parsed.

Sandbox courses need no configuration: the image is `amigoscode-academy/<track>-<course>`
(rebuilt automatically when the course Dockerfile changes) and each section gets a
container `academy_<track>-<course>_<section>`. Starting a section runs its `seed.sh` once;
"start over" (`r`) throws the container away and makes a new one, so everything the
student changed is reset. The section folder is copied into the container with
`docker cp` (instead of a bind mount) so it works identically when the Academy itself
runs in a container - including on Windows, where host paths don't line up.

Progress is written to `my-journey/progress.json` in the student's fork, keyed by
`track/course/section`. Progress saved before the courses moved into tracks is carried
over automatically (`movedCourses` in `progress.go`).

## Develop

```bash
cd academy
go run .            # runs natively against the repo (needs Go 1.23+ and Docker)
go run . --list     # print the parsed catalog
go vet ./...
```

`../academy.sh` fingerprints `go.mod go.sum Dockerfile *.go` and rebuilds the
`amigoscode/academy:local` image only when they change.

| File | What's in it |
|------|--------------|
| `catalog.go` | discovers courses/sections, parses READMEs into tiers and questions |
| `ops.go` | Docker operations: prepare, shell, verify, reset, stop |
| `progress.go` | progress file + grader-output parsing |
| `model.go` | Bubble Tea state and key handling |
| `view.go` | rendering: dashboard, course, section workspace, modals |
| `theme.go`, `markdown.go` | Amigoscode dark palette, wordmark, Glamour style |
