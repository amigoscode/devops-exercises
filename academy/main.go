// Amigoscode Academy - a terminal UI for the devops-exercises repo.
//
// Students run ./academy.sh (or academy.cmd on Windows). That builds and runs this
// program inside a small container, so Docker stays the only thing to install.
// Maintainers can also run it natively:  cd academy && go run .
package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"

	tea "github.com/charmbracelet/bubbletea"
)

var program *tea.Program

func main() {
	repo, err := findRepo()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	courses, err := LoadCatalog(repo)
	if err != nil || len(courses) == 0 {
		fmt.Fprintln(os.Stderr, "No courses found in", repo)
		os.Exit(1)
	}
	if len(os.Args) > 1 && os.Args[1] == "--list" {
		printCatalog(courses)
		return
	}

	ops := &Ops{Repo: repo, InDocker: os.Getenv("ACADEMY_IN_DOCKER") == "1"}
	ops.Status = func(s string) {
		if program != nil {
			program.Send(statusMsg(s))
		}
	}
	defer ops.Cleanup()
	m := newModel(ops, courses, LoadProgress(repo))

	// Paint the whole terminal in the Amigoscode navy (OSC 11) and restore it on exit
	// (OSC 111). Terminals that don't support it simply keep their own dark/light bg.
	fmt.Print("\x1b]11;" + bgHex + "\x07")
	defer fmt.Print("\x1b]111\x07")

	program = tea.NewProgram(m, tea.WithAltScreen(), tea.WithMouseCellMotion())
	if _, err := program.Run(); err != nil {
		fmt.Print("\x1b]111\x07")
		fmt.Fprintln(os.Stderr, "academy:", err)
		os.Exit(1)
	}
	fmt.Println("See you next session. Progress saved to my-journey/progress.json")
}

// findRepo: $ACADEMY_REPO, else walk up from the working directory.
func findRepo() (string, error) {
	if r := os.Getenv("ACADEMY_REPO"); r != "" {
		return r, nil
	}
	dir, _ := os.Getwd()
	for {
		if exists(filepath.Join(dir, "academy", "go.mod")) {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", errors.New("run this from inside the devops-exercises repo (or set ACADEMY_REPO)")
		}
		dir = parent
	}
}

func printCatalog(courses []*Course) {
	for _, c := range courses {
		kind := "sandbox image=" + c.Image()
		if c.Kind == KindHost {
			kind = "host"
		}
		fmt.Printf("%s  %s  [%s]\n", c.Num, c.Title, kind)
		for _, s := range c.Sections {
			graded, drills := 0, 0
			for _, t := range s.Tasks {
				if t.Kind == "drill" {
					drills++
				} else {
					graded++
				}
			}
			fmt.Printf("    %s %-34s tiers=%d tasks=%d drills=%d verify=%v\n", s.Num, s.Title, len(s.Tiers), graded, drills, s.Verify != "")
		}
	}
}
