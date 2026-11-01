package main

// The catalog is read straight from the repo on every launch, so adding a course
// or a section is just adding a folder - the academy never needs to be edited.
//
//   NN-course/                 a course (Makefile => Ubuntu sandbox, runner.sh => host Docker)
//     README.md                "# Title - Hands-On Exercises"
//     NN-section/
//       README.md              tiers ("## Tier 1 - ...") and tasks ("**1.1 (graded)** ...")
//       seed.sh verify.sh solutions.md

import (
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type Kind int

const (
	KindSandbox Kind = iota // each section runs in its own Ubuntu container
	KindHost                // Docker course: the student drives their own Docker daemon
)

type Task struct {
	ID    string // "1.3", or "2" for numbered missions
	Kind  string // graded | drill | task
	Title string // first sentence, plain text
	Tier  int
}

type Tier struct {
	N     int
	Title string
}

type Section struct {
	Course    *Course
	Slug      string // 01-the-terminal
	Dir       string
	Num       string
	Title     string
	MapsTo    string
	Blurb     string
	Lesson    string // README with the make/launcher instructions removed
	Tasks     []Task
	Tiers     []Tier
	Verify    string // verify.sh, or "" when the section is reviewed by a human
	SelfCheck string // optional self-check.sh (capstones)
	Solutions string // solutions.md path, "" if none
}

func (s *Section) Key() string { return s.Course.Slug + "/" + s.Slug }

func (s *Section) Graded() bool { return s.Verify != "" }

type Course struct {
	Slug     string
	Dir      string
	Num      string
	Title    string
	Blurb    string
	Kind     Kind
	Sections []*Section

	// Sandbox courses: read from the course Makefile so `make` stays the source of truth.
	Image     string
	Prefix    string   // container name prefix, e.g. "lf-"
	SeedCmd   string   // runs inside the container on start
	ResetCmds []string // run inside the container on reset
}

func (c *Course) Container(s *Section) string { return c.Prefix + s.Slug }

var (
	numbered   = regexp.MustCompile(`^(\d{2})-[a-z0-9-]+$`)
	h1         = regexp.MustCompile(`(?m)^#\s+(.+)$`)
	tierRe     = regexp.MustCompile(`^##\s+Tier\s+(\d+)\s*[-–—:]\s*(.+)$`)
	taskRe     = regexp.MustCompile(`^\*\*(\d+\.\d+)\s*(?:\(([^)]*)\))?\*\*\s*(.*)$`)
	missionRe  = regexp.MustCompile(`^(\d+)\.\s+\*\*\(([^)]*)\)\*\*\s*(.*)$`)
	mdNoise    = regexp.MustCompile("\\*\\*|__|`|\\*|\\[|\\]\\([^)]*\\)")
	hintParens = regexp.MustCompile(`\s*\*\(.*\)\*\s*$`)
	makeVar    = regexp.MustCompile(`(?m)^(IMAGE|CONTAINER)\s*:?=\s*(\S+)`)
	bashLc     = regexp.MustCompile(`bash -lc '([^']*)'`)
)

func LoadCatalog(repo string) ([]*Course, error) {
	entries, err := os.ReadDir(repo)
	if err != nil {
		return nil, err
	}
	var courses []*Course
	for _, e := range entries {
		m := numbered.FindStringSubmatch(e.Name())
		if !e.IsDir() || m == nil {
			continue
		}
		c := &Course{Slug: e.Name(), Dir: filepath.Join(repo, e.Name()), Num: m[1]}
		switch {
		case exists(filepath.Join(c.Dir, "runner.sh")):
			c.Kind = KindHost
		case exists(filepath.Join(c.Dir, "Makefile")):
			c.Kind = KindSandbox
			parseMakefile(c)
		default:
			continue
		}
		readme := readFile(filepath.Join(c.Dir, "README.md"))
		c.Title = cleanTitle(firstH1(readme), e.Name())
		c.Blurb = firstParagraph(readme)
		if t, ok := taglines[c.Slug]; ok {
			c.Blurb = t
		}
		loadSections(c)
		if len(c.Sections) > 0 {
			courses = append(courses, c)
		}
	}
	sort.Slice(courses, func(i, j int) bool { return courses[i].Slug < courses[j].Slug })
	return courses, nil
}

// taglines are the one-line pitches shown on the dashboard. A course without an
// entry falls back to the first paragraph of its README.
var taglines = map[string]string{
	"01-linux-fundamentals":      "Get at home in the terminal: navigate the file system, manage files, users and permissions on a real Ubuntu box.",
	"02-vim":                     "Edit configs on any server with no GUI. Insert, navigate, search-and-replace and make Vim your own.",
	"03-linux-for-professionals": "The day-to-day of a DevOps engineer: pipes, environment variables, system admin, networking and SSH.",
	"04-shell-scripting":         "Automate the boring stuff. Write Bash scripts with conditions, loops, functions and proper error handling.",
	"05-git-github-fundamentals": "Version control from zero: commits, history, branches and remotes - then push a project end to end.",
	"06-docker":                  "Package, run and debug real containers on your own Docker, then ship multi-service apps with Compose.",
}

func loadSections(c *Course) {
	entries, _ := os.ReadDir(c.Dir)
	for _, e := range entries {
		m := numbered.FindStringSubmatch(e.Name())
		if !e.IsDir() || m == nil {
			continue
		}
		dir := filepath.Join(c.Dir, e.Name())
		readme := readFile(filepath.Join(dir, "README.md"))
		if readme == "" {
			continue
		}
		s := &Section{Course: c, Slug: e.Name(), Dir: dir, Num: m[1]}
		s.Title = cleanTitle(firstH1(readme), e.Name())
		s.MapsTo = mapsTo(readme)
		s.Blurb = firstParagraph(readme)
		s.Lesson = lessonBody(readme)
		s.Tasks, s.Tiers = parseTasks(readme)
		if p := filepath.Join(dir, "verify.sh"); exists(p) {
			s.Verify = p
		}
		if p := filepath.Join(dir, "self-check.sh"); exists(p) {
			s.SelfCheck = p
		}
		if p := filepath.Join(dir, "solutions.md"); exists(p) {
			s.Solutions = p
		}
		c.Sections = append(c.Sections, s)
	}
	sort.Slice(c.Sections, func(i, j int) bool { return c.Sections[i].Slug < c.Sections[j].Slug })
}

// parseMakefile pulls the image, container prefix and the seed/reset commands out
// of a course Makefile, falling back to the conventions every course follows.
func parseMakefile(c *Course) {
	mk := readFile(filepath.Join(c.Dir, "Makefile"))
	c.Image = c.Slug
	c.Prefix = c.Slug + "-"
	for _, m := range makeVar.FindAllStringSubmatch(mk, -1) {
		switch m[1] {
		case "IMAGE":
			c.Image = m[2]
		case "CONTAINER":
			c.Prefix = strings.TrimSuffix(m[2], "$(S)")
		}
	}
	c.SeedCmd = "test -d ~/sandbox || bash /exercise/seed.sh"
	if cmds := targetCmds(mk, "start"); len(cmds) > 0 {
		c.SeedCmd = cmds[0]
	}
	c.ResetCmds = []string{"rm -rf ~/sandbox", "bash /exercise/seed.sh"}
	if cmds := targetCmds(mk, "reset"); len(cmds) > 0 {
		c.ResetCmds = cmds
	}
}

// targetCmds returns the `bash -lc '...'` commands in one Makefile target's recipe.
func targetCmds(mk, target string) []string {
	var out []string
	in := false
	for _, line := range strings.Split(mk, "\n") {
		if strings.HasPrefix(line, target+":") {
			in = true
			continue
		}
		if in {
			if line != "" && !strings.HasPrefix(line, "\t") && !strings.HasPrefix(line, " ") {
				break
			}
			for _, m := range bashLc.FindAllStringSubmatch(line, -1) {
				out = append(out, m[1])
			}
		}
	}
	return out
}

func parseTasks(readme string) ([]Task, []Tier) {
	var tasks []Task
	var tiers []Tier
	tier := 0
	lines := strings.Split(readme, "\n")
	inCode := false
	for i, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "```") {
			inCode = !inCode
			continue
		}
		if inCode {
			continue
		}
		if m := tierRe.FindStringSubmatch(line); m != nil {
			tier++
			tiers = append(tiers, Tier{N: tier, Title: plain(hintParens.ReplaceAllString(m[2], ""))})
			continue
		}
		var id, kind, rest string
		if m := taskRe.FindStringSubmatch(line); m != nil {
			id, kind, rest = m[1], m[2], m[3]
		} else if m := missionRe.FindStringSubmatch(line); m != nil {
			id, kind, rest = m[1], m[2], m[3]
		} else {
			continue
		}
		// The task text often wraps - join the paragraph, then keep the first sentence.
		para := rest
		for j := i + 1; j < len(lines) && strings.TrimSpace(lines[j]) != "" && !strings.HasPrefix(lines[j], "```"); j++ {
			para += " " + strings.TrimSpace(lines[j])
		}
		tasks = append(tasks, Task{ID: id, Kind: normKind(kind), Title: firstSentence(plain(para)), Tier: tier})
	}
	return tasks, tiers
}

func normKind(k string) string {
	k = strings.ToLower(k)
	switch {
	case strings.Contains(k, "drill"), strings.Contains(k, "self"):
		return "drill"
	case strings.Contains(k, "graded"):
		return "graded"
	}
	return "task"
}

// lessonBody drops the "How to use this set" block: it explains make/launcher
// commands that the academy now runs for the student.
func lessonBody(readme string) string {
	lines := strings.Split(readme, "\n")
	var out []string
	skip := false
	for _, l := range lines {
		if strings.HasPrefix(l, "## ") {
			skip = strings.Contains(strings.ToLower(l), "how to use this set")
		}
		if skip && strings.TrimSpace(l) == "---" {
			skip = false
		}
		if !skip {
			out = append(out, l)
		}
	}
	body := strings.TrimSpace(strings.Join(out, "\n"))
	if strings.HasPrefix(body, "# ") {
		if i := strings.Index(body, "\n"); i > 0 {
			body = strings.TrimSpace(body[i:])
		}
	}
	return body
}

func firstH1(md string) string {
	if m := h1.FindStringSubmatch(md); m != nil {
		return m[1]
	}
	return ""
}

func cleanTitle(t, slug string) string {
	t = strings.TrimSpace(t)
	t = regexp.MustCompile(`^\d+\s*[-·.:]\s*`).ReplaceAllString(t, "")
	t = regexp.MustCompile(`\s+[-–]\s+Hands-On Exercises$`).ReplaceAllString(t, "")
	if t == "" {
		t = strings.ReplaceAll(numbered.ReplaceAllString(slug, ""), "-", " ")
	}
	return t
}

func mapsTo(md string) string {
	for _, l := range strings.Split(md, "\n") {
		if strings.HasPrefix(l, "> Maps to") {
			return plain(strings.TrimPrefix(strings.TrimPrefix(l, ">"), " "))
		}
	}
	return ""
}

// firstParagraph is the first plain prose paragraph after the title.
func firstParagraph(md string) string {
	var para []string
	for _, l := range strings.Split(md, "\n") {
		t := strings.TrimSpace(l)
		if t == "" {
			if len(para) > 0 {
				break
			}
			continue
		}
		if strings.HasPrefix(t, "#") || strings.HasPrefix(t, ">") || strings.HasPrefix(t, "-") ||
			strings.HasPrefix(t, "|") || strings.HasPrefix(t, "```") || strings.HasPrefix(t, "<") {
			if len(para) > 0 {
				break
			}
			continue
		}
		para = append(para, t)
	}
	return plain(strings.Join(para, " "))
}

func firstSentence(s string) string {
	for i := 0; i < len(s)-1; i++ {
		if (s[i] == '.' || s[i] == ':') && s[i+1] == ' ' && i > 12 {
			return s[:i+1]
		}
	}
	return s
}

func plain(s string) string {
	s = mdNoise.ReplaceAllString(s, "")
	return strings.Join(strings.Fields(s), " ")
}

func exists(p string) bool { _, err := os.Stat(p); return err == nil }

func readFile(p string) string {
	b, err := os.ReadFile(p)
	if err != nil {
		return ""
	}
	return strings.ReplaceAll(string(b), "\r\n", "\n")
}
