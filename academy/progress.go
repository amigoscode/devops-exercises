package main

// Progress lives in my-journey/progress.json: the student's own folder, never
// touched by upstream syncs, so it is committed to their fork alongside their notes.

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

type SectionProgress struct {
	Started      bool     `json:"started,omitempty"`
	Passed       []string `json:"passed,omitempty"`
	Failed       []string `json:"failed,omitempty"`
	Drills       []string `json:"drills,omitempty"` // self-checked drills
	PassCount    int      `json:"passCount"`
	FailCount    int      `json:"failCount"`
	Completed    bool     `json:"completed,omitempty"`
	CompletedAt  string   `json:"completedAt,omitempty"`
	LastVerified string   `json:"lastVerified,omitempty"`
	LastOutput   string   `json:"lastOutput,omitempty"`
}

type Progress struct {
	Version  int                         `json:"version"`
	Last     string                      `json:"last,omitempty"` // last section opened
	Sections map[string]*SectionProgress `json:"sections"`
	path     string
}

func LoadProgress(repo string) *Progress {
	p := &Progress{Version: 1, Sections: map[string]*SectionProgress{}}
	p.path = filepath.Join(repo, "my-journey", "progress.json")
	if b, err := os.ReadFile(p.path); err == nil {
		_ = json.Unmarshal(b, p)
		if p.Sections == nil {
			p.Sections = map[string]*SectionProgress{}
		}
	}
	return p
}

func (p *Progress) Save() error {
	_ = os.MkdirAll(filepath.Dir(p.path), 0o755)
	b, _ := json.MarshalIndent(p, "", "  ")
	return os.WriteFile(p.path, append(b, '\n'), 0o644)
}

func (p *Progress) Get(key string) *SectionProgress {
	sp, ok := p.Sections[key]
	if !ok {
		sp = &SectionProgress{}
		p.Sections[key] = sp
	}
	return sp
}

func (p *Progress) Peek(key string) SectionProgress {
	if sp, ok := p.Sections[key]; ok {
		return *sp
	}
	return SectionProgress{}
}

func (sp *SectionProgress) HasDrill(id string) bool {
	for _, d := range sp.Drills {
		if d == id {
			return true
		}
	}
	return false
}

func (sp *SectionProgress) ToggleDrill(id string) {
	for i, d := range sp.Drills {
		if d == id {
			sp.Drills = append(sp.Drills[:i], sp.Drills[i+1:]...)
			return
		}
	}
	sp.Drills = append(sp.Drills, id)
	sort.Strings(sp.Drills)
}

// TaskState: 0 not attempted, 1 passed, -1 failed.
func (sp SectionProgress) TaskState(id string) int {
	for _, x := range sp.Passed {
		if x == id {
			return 1
		}
	}
	for _, x := range sp.Failed {
		if x == id {
			return -1
		}
	}
	return 0
}

type Status int

const (
	NotStarted Status = iota
	InProgress
	Done
)

func (sp SectionProgress) Status() Status {
	switch {
	case sp.Completed:
		return Done
	case sp.Started || sp.PassCount > 0 || sp.FailCount > 0 || len(sp.Drills) > 0:
		return InProgress
	}
	return NotStarted
}

// ---- grader output -------------------------------------------------------------

type Check struct {
	OK   bool
	ID   string
	Text string
}

type Result struct {
	Checks []Check
	Pass   int
	Fail   int
}

var (
	ansiRe  = regexp.MustCompile(`\x1b\[[0-9;?]*[A-Za-z]`)
	checkRe = regexp.MustCompile(`^\s*(✅|❌)\s*(?:(\d+(?:\.\d+)?)\.?\s+)?(.*)$`)
	scoreRe = regexp.MustCompile(`Score:\s*(\d+)\s*passed,\s*(\d+)\s*failed`)
)

func StripANSI(s string) string { return ansiRe.ReplaceAllString(s, "") }

// ParseResult reads the ✅ / ❌ lines every verify.sh prints.
func ParseResult(out string) Result {
	var r Result
	for _, line := range strings.Split(StripANSI(out), "\n") {
		if m := checkRe.FindStringSubmatch(line); m != nil {
			c := Check{OK: m[1] == "✅", ID: m[2], Text: m[3]}
			r.Checks = append(r.Checks, c)
			if c.OK {
				r.Pass++
			} else {
				r.Fail++
			}
		}
		if m := scoreRe.FindStringSubmatch(line); m != nil {
			r.Pass, _ = strconv.Atoi(m[1])
			r.Fail, _ = strconv.Atoi(m[2])
		}
	}
	return r
}

func (sp *SectionProgress) Apply(r Result, out string) (justCompleted bool) {
	sp.Started = true
	sp.LastOutput = strings.TrimSpace(StripANSI(out))
	sp.LastVerified = time.Now().Format(time.RFC3339)
	sp.PassCount, sp.FailCount = r.Pass, r.Fail
	sp.Passed, sp.Failed = nil, nil
	for _, c := range r.Checks {
		if c.ID == "" {
			continue
		}
		if c.OK {
			sp.Passed = append(sp.Passed, c.ID)
		} else {
			sp.Failed = append(sp.Failed, c.ID)
		}
	}
	if r.Pass > 0 && r.Fail == 0 {
		if !sp.Completed {
			justCompleted = true
			sp.CompletedAt = time.Now().Format("2006-01-02")
		}
		sp.Completed = true
	}
	return justCompleted
}
