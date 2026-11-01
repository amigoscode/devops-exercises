package main

// Ops runs the exercises. It mirrors what each course Makefile / runner.sh does,
// so `make start`, `./course.sh verify` and the academy are interchangeable and
// share the same containers.
//
// One difference for sandbox courses: the section folder is copied into the
// container with `docker cp` instead of bind-mounted. A copy works no matter where
// the academy runs (natively, or inside its own container on Windows), because the
// Docker client streams the files - no host path has to line up.

import (
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

func (o *Ops) ensureImage(c *Course) error {
	if _, err := docker("image", "inspect", c.Image); err == nil {
		return nil
	}
	o.say(fmt.Sprintf("Building the %s image - first time only, about a minute", c.Title))
	if out, err := docker("build", "-t", c.Image, c.Dir); err != nil {
		return fmt.Errorf("could not build the %s image:\n%s", c.Image, tail(out, 15))
	}
	return nil
}

// ensureContainer creates (or restarts) the section container and syncs the
// exercise files into it. Returns errNotStarted if create is false and it is missing.
func (o *Ops) ensureContainer(s *Section, create bool) error {
	c := s.Course
	name := c.Container(s)
	state, err := docker("inspect", "-f", "{{.State.Running}}", name)
	switch {
	case err != nil && !create:
		return errNotStarted
	case err != nil:
		o.say("Starting a fresh Ubuntu sandbox")
		if out, err := docker("run", "-dit", "--name", name, c.Image); err != nil {
			return fmt.Errorf("could not start the sandbox:\n%s", tail(out, 10))
		}
	case strings.TrimSpace(state) != "true":
		o.say("Waking your sandbox up")
		if out, err := docker("start", name); err != nil {
			return fmt.Errorf("could not restart the sandbox:\n%s", tail(out, 10))
		}
	}
	// Keep /exercise in step with the repo (fails harmlessly on a container made by
	// `make start`, where /exercise is a read-only bind mount that is already live).
	_, _ = docker("cp", s.Dir+string(filepath.Separator)+".", name+":/exercise")
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
	if out, err := docker("exec", c.Container(s), "bash", "-lc", c.SeedCmd); err != nil {
		return fmt.Errorf("seeding failed:\n%s", tail(out, 15))
	}
	return nil
}

// Shell is the interactive command the academy hands the terminal to.
func (o *Ops) Shell(s *Section) *exec.Cmd {
	c := s.Course
	banner := shellBanner(s)
	wrap := func(args ...string) *exec.Cmd {
		cmd := exec.Command("sh", append([]string{"-c", `printf '%s' "$ACADEMY_BANNER"; exec "$@"`, "sh"}, args...)...)
		cmd.Env = append(os.Environ(), "ACADEMY_BANNER="+banner)
		return cmd
	}
	if c.Kind == KindHost {
		sb := o.hostSandbox(s)
		_ = os.MkdirAll(sb, 0o755)
		sh := "bash"
		if !o.InDocker {
			if v := os.Getenv("SHELL"); v != "" {
				sh = v
			}
		}
		args := []string{sh}
		if o.InDocker {
			// A clean bash: Alpine's rc files would replace the Amigoscode prompt.
			args = append(args, "--noprofile", "--norc")
		}
		cmd := wrap(args...)
		cmd.Dir = sb
		cmd.Env = append(cmd.Env, "SB="+sb, "PS1=\\[\\e[38;2;167;139;250m\\]amigoscode\\[\\e[0m\\]:\\w \\$ ")
		return cmd
	}
	return wrap("docker", "exec", "-it", "-w", "/home/student/sandbox", c.Container(s), "bash")
}

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
	if err := o.ensureImage(c); err != nil {
		return err
	}
	if err := o.ensureContainer(s, true); err != nil {
		return err
	}
	o.say("Wiping ~/sandbox and re-seeding")
	for i, cmd := range c.ResetCmds {
		out, err := docker("exec", c.Container(s), "bash", "-lc", cmd)
		if err != nil && i == len(c.ResetCmds)-1 {
			return fmt.Errorf("reset failed:\n%s", tail(out, 15))
		}
	}
	return nil
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

func shellBanner(s *Section) string {
	v := "\x1b[38;2;167;139;250m"
	b := "\x1b[1m"
	d := "\x1b[38;2;143;136;168m"
	r := "\x1b[0m"
	where := "an Ubuntu sandbox - your work lives in ~/sandbox"
	if s.Course.Kind == KindHost {
		where = "your terminal, wired to your real Docker daemon"
	}
	return "\x1b[2J\x1b[H" +
		v + b + "  ▄▀█ █▀▄▀█ █ █▀▀ █▀█ █▀ █▀▀ █▀█ █▀▄ █▀▀" + r + "\n" +
		v + b + "  █▀█ █ ▀ █ █ █▄█ █▄█ ▄█ █▄▄ █▄█ █▄▀ ██▄" + r + d + "  Academy" + r + "\n\n" +
		"  " + b + s.Course.Title + " › " + s.Num + " " + s.Title + r + "\n" +
		"  " + d + "You are in " + where + "." + r + "\n" +
		"  " + d + "Type " + r + b + "exit" + r + d + " (or Ctrl+D) to go back - your work is graded automatically." + r + "\n\n"
}

func tail(s string, n int) string {
	lines := strings.Split(strings.TrimRight(StripANSI(s), "\n"), "\n")
	if len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	return strings.Join(lines, "\n")
}
