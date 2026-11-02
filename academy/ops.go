package main

// Ops runs the exercises.
//
// Sandbox courses (01-05): one image per course, built from its Dockerfile, and one
// container per section. The section folder is copied into the container with
// `docker cp` (not bind-mounted), which works no matter where the academy runs -
// natively, or inside its own container on Windows - because the Docker client
// streams the files and no host path has to line up.
//
// Host courses (06 Docker): start/verify/reset/stop are delegated to the course's
// own runner.sh, so `./course.sh` and the academy stay interchangeable.

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var errNotStarted = errors.New("not started")

type Ops struct {
	Repo     string
	InDocker bool // the academy itself runs inside a container (academy.sh / academy.cmd)
	Status   func(string)
	tmpDir   string // private (0700) scratch dir, created on first use
}

// scratch returns a private directory for the files handed to shells. It is created
// with os.MkdirTemp (mode 0700), never a fixed name in the shared temp dir, so no
// other local user can plant or swap the rc file bash is told to run.
func (o *Ops) scratch() (string, error) {
	if o.tmpDir == "" {
		d, err := os.MkdirTemp("", "academy-*")
		if err != nil {
			return "", err
		}
		o.tmpDir = d
	}
	return o.tmpDir, nil
}

// Cleanup removes the private scratch dir. Called when the academy exits.
func (o *Ops) Cleanup() {
	if o.tmpDir != "" {
		_ = os.RemoveAll(o.tmpDir)
	}
}

// writeScratch writes name inside the private dir and returns its path.
func (o *Ops) writeScratch(name, content string) (string, error) {
	dir, err := o.scratch()
	if err != nil {
		return "", err
	}
	p := filepath.Join(dir, name)
	// 0644 inside a 0700 dir: private on this machine, yet still readable by the
	// sandbox's student user after `docker cp` hands the file over as root.
	return p, os.WriteFile(p, []byte(content), 0o644)
}

func (o *Ops) say(msg string) {
	if o.Status != nil {
		o.Status(msg)
	}
}

func run(dir string, env []string, name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	cmd.Env = append(os.Environ(), env...)
	out, err := cmd.CombinedOutput()
	return string(out), err
}

func docker(args ...string) (string, error) { return run("", nil, "docker", args...) }

func (o *Ops) DockerVersion() (string, error) {
	if _, err := exec.LookPath("docker"); err != nil {
		return "", errors.New("Docker is not installed")
	}
	out, err := docker("version", "--format", "{{.Server.Version}}")
	if err != nil {
		return "", errors.New("Docker is not running - start Docker Desktop")
	}
	return strings.TrimSpace(out), nil
}

// States maps container name -> state (running, exited, ...).
func (o *Ops) States() map[string]string {
	out, err := docker("ps", "-a", "--format", "{{.Names}}\t{{.State}}")
	m := map[string]string{}
	if err != nil {
		return m
	}
	for _, l := range strings.Split(strings.TrimSpace(out), "\n") {
		if name, state, ok := strings.Cut(l, "\t"); ok {
			m[name] = state
		}
	}
	return m
}

func (o *Ops) runner(c *Course, args ...string) (string, error) {
	env := []string{"COURSE_LAUNCHER=academy"}
	return run(c.Dir, env, "bash", append([]string{filepath.Join(c.Dir, "runner.sh")}, args...)...)
}

func (o *Ops) hostSandbox(s *Section) string {
	return filepath.Join(s.Course.Dir, "sandbox", s.Slug)
}

// ---- sandbox (Ubuntu container) plumbing ---------------------------------------

// ensureImage builds the course image, and rebuilds it whenever the course
// Dockerfile changes (its hash is stored as an image label).
func (o *Ops) ensureImage(c *Course) error {
	sum := sha256.Sum256([]byte(readFile(filepath.Join(c.Dir, "Dockerfile"))))
	want := hex.EncodeToString(sum[:8])
	have, err := docker("image", "inspect", "-f", `{{ index .Config.Labels "academy.dockerfile" }}`, c.Image())
	if err == nil && strings.TrimSpace(have) == want {
		return nil
	}
	o.say(fmt.Sprintf("Building the %s image - first time only, about a minute", c.Title))
	if out, err := docker("build", "--label", "academy.dockerfile="+want, "-t", c.Image(), c.Dir); err != nil {
		return fmt.Errorf("could not build the %s image:\n%s", c.Title, tail(out, 15))
	}
	return nil
}

// ensureContainer creates (or restarts) the section container and syncs the
// exercise files into it. Returns errNotStarted if create is false and it is missing.
func (o *Ops) ensureContainer(s *Section, create bool) error {
	c := s.Course
	name := c.Container(s)
	state, err := docker("inspect", "-f", "{{.State.Running}}", name)
	woke := false
	switch {
	case err != nil && !create:
		return errNotStarted
	case err != nil:
		o.say("Starting a fresh Ubuntu sandbox")
		if out, err := docker("run", "-dit", "--name", name, c.Image()); err != nil {
			return fmt.Errorf("could not start the sandbox:\n%s", tail(out, 10))
		}
	case strings.TrimSpace(state) != "true":
		o.say("Waking your sandbox up")
		if out, err := docker("start", name); err != nil {
			return fmt.Errorf("could not restart the sandbox:\n%s", tail(out, 10))
		}
		woke = true
	}
	// Keep /exercise in step with the repo.
	if out, err := docker("cp", s.Dir+string(filepath.Separator)+".", name+":/exercise"); err != nil {
		return fmt.Errorf("could not copy the exercise into the sandbox:\n%s", tail(out, 10))
	}
	// A restart (Docker or the machine rebooted) kills background processes the seed
	// started, like a local web service. A section's optional wake.sh brings them back.
	if woke {
		_, _ = docker("exec", name, "bash", "-lc", "test -f /exercise/wake.sh && test -d ~/sandbox && bash /exercise/wake.sh; true")
	}
	return nil
}

// Prepare gets a section ready to work in: image, container, seeded scenario.
func (o *Ops) Prepare(s *Section) error {
	c := s.Course
	if c.Kind == KindHost {
		if exists(o.hostSandbox(s)) {
			return nil
		}
		o.say("Setting up the scenario on your Docker daemon (pulling images)")
		if out, err := o.runner(c, "start", s.Slug); err != nil {
			return fmt.Errorf("seeding failed:\n%s", tail(out, 15))
		}
		return os.MkdirAll(o.hostSandbox(s), 0o755)
	}
	if err := o.ensureImage(c); err != nil {
		return err
	}
	if err := o.ensureContainer(s, true); err != nil {
		return err
	}
	o.say("Seeding the scenario")
	if out, err := docker("exec", c.Container(s), "bash", "-lc", "test -d ~/sandbox || bash /exercise/seed.sh"); err != nil {
		return fmt.Errorf("seeding failed:\n%s", tail(out, 15))
	}
	return nil
}

// Shell is the interactive command the academy hands the terminal to. banner is
// printed first (the section's questions); inside bash a `questions` command prints
// it again, so the questions are never more than one word away.
func (o *Ops) Shell(s *Section, banner string) *exec.Cmd {
	c := s.Course
	wrap := func(args ...string) *exec.Cmd {
		cmd := exec.Command("sh", append([]string{"-c", `printf '%s' "$ACADEMY_BANNER"; exec "$@"`, "sh"}, args...)...)
		cmd.Env = append(os.Environ(), "ACADEMY_BANNER="+banner)
		return cmd
	}
	qFile, qErr := o.writeScratch("questions.txt", banner)

	if c.Kind == KindHost {
		// Docker course: a clean bash with our own rc (Alpine's rc files would
		// replace the prompt). `check` runs the same grader as the app.
		sb := o.hostSandbox(s)
		_ = os.MkdirAll(sb, 0o755)
		rcText := "[ -f ~/.bashrc ] && [ -z \"$ACADEMY_IN_DOCKER\" ] && . ~/.bashrc\n" +
			"PS1='\\[\\e[38;2;167;139;250m\\]amigoscode\\[\\e[0m\\]:\\W \\$ '\n"
		if qErr == nil {
			rcText += "questions() { cat " + shq(qFile) + "; }\n"
		}
		if o.InDocker {
			// This shell lives in the academy container, where localhost is the
			// container itself. Send curl's localhost to the student's machine, so
			// `curl localhost:8080` reaches the ports their containers publish.
			rcText += "curl() { command curl --connect-to localhost::host.docker.internal: --connect-to 127.0.0.1::host.docker.internal: \"$@\"; }\n"
		}
		switch {
		case s.Verify != "":
			rcText += "check() { COURSE_LAUNCHER=academy bash " + shq(filepath.Join(c.Dir, "runner.sh")) + " verify " + shq(s.Slug) + "; " + checkFooter + "; }\n"
		case s.SelfCheck != "":
			base := ""
			if o.InDocker {
				base = "BASE_URL=http://host.docker.internal:8080 "
			}
			rcText += "check() { " + base + "bash " + shq(s.SelfCheck) + "; }\n"
		default:
			rcText += "check() { echo 'This capstone has no auto-check - a human reviews it in the Academy.'; }\n"
		}
		cmd := wrap("bash", "--noprofile", "--norc", "-i")
		if rc, err := o.writeScratch("host.rc", rcText); err == nil {
			cmd = wrap("bash", "--noprofile", "--rcfile", rc, "-i")
		}
		// The lessons are written from the course folder (`cd sandbox/03-volumes/site`).
		cmd.Dir = c.Dir
		cmd.Env = append(cmd.Env, "SB="+sb)
		return cmd
	}

	// Ubuntu sandbox: drop the questions and a tiny rc file into the container. The rc
	// sources the student's own ~/.bashrc first, so the shell behaves exactly as
	// a plain `bash` would - it just also knows `questions` and `check`. If anything
	// fails, fall back to a plain shell rather than pointing bash at a file we didn't write.
	name := c.Container(s)
	plainShell := wrap("docker", "exec", "-it", "-w", "/home/student/sandbox", name, "bash")
	funcs := "questions() { cat /tmp/academy-questions.txt; }\n" +
		"check() { ( cd ~/sandbox && bash /exercise/verify.sh ); " + checkFooter + "; }\n"
	rc, err := o.writeScratch("sandbox.rc", "[ -f ~/.bashrc ] && . ~/.bashrc\n"+funcs)
	if err != nil || qErr != nil {
		return plainShell
	}
	if _, err := docker("cp", qFile, name+":/tmp/academy-questions.txt"); err != nil {
		return plainShell
	}
	if _, err := docker("cp", rc, name+":/tmp/academy.rc"); err != nil {
		return plainShell
	}
	if c.PSQL {
		if cmd := o.psqlShell(name, wrap); cmd != nil {
			return cmd
		}
		return plainShell
	}
	// Students who switched their login shell (chsh -s /bin/zsh) get that shell, with
	// the same two commands: zsh reads $ZDOTDIR/.zshrc, which sources their ~/.zshrc.
	if zrc, err := o.writeScratch("sandbox.zshrc", "unset ZDOTDIR\n[ -f ~/.zshrc ] && . ~/.zshrc\n"+funcs); err == nil {
		if _, err := docker("exec", name, "mkdir", "-p", "/tmp/academy-zsh"); err == nil {
			_, _ = docker("cp", zrc, name+":/tmp/academy-zsh/.zshrc")
		}
	}
	const login = `sh="$(getent passwd "$(id -un)" | cut -d: -f7)"
case "$sh" in */zsh) [ -f /tmp/academy-zsh/.zshrc ] && ZDOTDIR=/tmp/academy-zsh exec "$sh" -i ;; esac
exec bash --rcfile /tmp/academy.rc -i`
	return wrap("docker", "exec", "-it", "-w", "/home/student/sandbox", name, "bash", "-c", login)
}

// psqlShell opens an SQL course's sandbox straight in psql, connected to the
// section's database (the PGDATABASE its seed.sh exported). Inside psql, :check
// grades the work and :questions prints the questions; exit goes back. Returns nil
// if the helper files can't be put in place, so the caller falls back to bash.
func (o *Ops) psqlShell(name string, wrap func(...string) *exec.Cmd) *exec.Cmd {
	files := map[string]string{
		"/tmp/academy-check": "cd ~/sandbox && bash /exercise/verify.sh\n" + checkFooter + "\n",
		"/tmp/academy.psqlrc": `\set QUIET on
\set check '\\! bash /tmp/academy-check'
\set questions '\\! cat /tmp/academy-questions.txt'
\setenv PSQL_EDITOR nano
\set academy_rc ` + "`test -f ~/.psqlrc && echo 1 || echo 0`" + `
\if :academy_rc
  \i ~/.psqlrc
\endif
\unset academy_rc
\set QUIET off
`,
	}
	for dst, text := range files {
		f, err := o.writeScratch(filepath.Base(dst), text)
		if err != nil {
			return nil
		}
		if _, err := docker("cp", f, name+":"+dst); err != nil {
			return nil
		}
	}
	const launch = `eval "$(grep -h '^export PG' ~/.bashrc 2>/dev/null)"
pg_isready -q || sudo service postgresql start >/dev/null 2>&1
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done
export PSQLRC=/tmp/academy.psqlrc
psql
if [ $? = 2 ]; then
  printf '\nCould not open the %s database - connecting to your own database instead.\nPress r in the Academy to start this section over.\n\n' "${PGDATABASE:-student}"
  PGDATABASE=student exec psql
fi`
	return wrap("docker", "exec", "-it", "-w", "/home/student/sandbox", name, "bash", "-c", launch)
}

// checkFooter is printed after `check` inside a sandbox.
const checkFooter = `printf '\n  \033[2mKeep going - type exit when you are done and your progress is saved.\033[0m\n'`

// shq single-quotes s for bash.
func shq(s string) string { return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'" }

func (o *Ops) Verify(s *Section) (string, error) {
	c := s.Course
	if c.Kind == KindHost {
		if s.Verify == "" {
			if s.SelfCheck == "" {
				return "", errors.New("this section is reviewed by a human in the Academy - no auto-grader")
			}
			env := []string{}
			if o.InDocker {
				env = append(env, "BASE_URL=http://host.docker.internal:8080")
			}
			return run(o.hostSandbox(s), env, "bash", s.SelfCheck)
		}
		out, _ := o.runner(c, "verify", s.Slug)
		return out, nil
	}
	if err := o.ensureContainer(s, false); err != nil {
		return "", err
	}
	out, err := docker("exec", "-w", "/home/student/sandbox", c.Container(s), "bash", "/exercise/verify.sh")
	if err != nil && !strings.ContainsAny(out, "✅❌") {
		return out, fmt.Errorf("the grader could not run:\n%s", tail(out, 10))
	}
	return out, nil
}

func (o *Ops) Reset(s *Section) error {
	c := s.Course
	if c.Kind == KindHost {
		o.say("Removing this section's containers and re-seeding")
		if out, err := o.runner(c, "reset", s.Slug); err != nil {
			return fmt.Errorf("reset failed:\n%s", tail(out, 15))
		}
		return nil
	}
	// Start over = a brand-new container. That resets everything the student
	// changed, not just ~/sandbox: git config, users they added, their shell, history.
	o.say("Throwing the old sandbox away")
	_, _ = docker("rm", "-f", c.Container(s))
	return o.Prepare(s)
}

func (o *Ops) Stop(s *Section) error {
	c := s.Course
	if c.Kind == KindHost {
		o.say("Cleaning up everything this section created")
		_, err := o.runner(c, "stop", s.Slug)
		return err
	}
	o.say("Removing the sandbox container")
	_, _ = docker("rm", "-f", c.Container(s))
	return nil
}

func tail(s string, n int) string {
	lines := strings.Split(strings.TrimRight(StripANSI(s), "\n"), "\n")
	if len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	return strings.Join(lines, "\n")
}
