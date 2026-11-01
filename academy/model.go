package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type screen int

const (
	scrHome screen = iota
	scrCourse
	scrSection
)

type tabID int

const (
	tabLesson tabID = iota
	tabTasks
	tabResults
	tabSolution
)

var tabNames = map[tabID]string{tabLesson: "Lesson", tabTasks: "Tasks", tabResults: "Results", tabSolution: "Solution"}

type (
	dockerMsg struct {
		ver string
		err error
	}
	statesMsg    map[string]string
	statusMsg    string
	flashDoneMsg int
	opDoneMsg    struct {
		op  string
		sec *Section
		out string
		err error
	}
	shellDoneMsg struct{ sec *Section }
)

type confirmBox struct {
	title, body, op string
}

type model struct {
	ops     *Ops
	courses []*Course
	prog    *Progress
	w, h    int

	scr       screen
	courseIx  int
	sectionIx int
	sec       *Section

	tab        tabID
	focusTasks bool
	taskIx     int
	vp         viewport.Model
	vpKey      string
	unlocked   map[string]bool
	lastErr    map[string]string

	busy      bool
	spin      spinner.Model
	status    string
	flash     string
	flashBad  bool
	flashSeq  int
	states    map[string]string
	dockerVer string
	dockerErr string
	confirm   *confirmBox
	help      bool
}

func newModel(ops *Ops, courses []*Course, prog *Progress) *model {
	sp := spinner.New()
	sp.Spinner = spinner.Spinner{Frames: []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}, FPS: time.Second / 12}
	sp.Style = sBrand
	vp := viewport.New(80, 20)
	vp.MouseWheelEnabled = true
	vp.KeyMap.Left = key.NewBinding(key.WithDisabled())
	vp.KeyMap.Right = key.NewBinding(key.WithDisabled())
	vp.KeyMap.PageDown = key.NewBinding(key.WithKeys("pgdown", "f"))
	m := &model{
		ops: ops, courses: courses, prog: prog, spin: sp, vp: vp,
		unlocked: map[string]bool{}, lastErr: map[string]string{}, states: map[string]string{},
	}
	// Land the cursor on the course you were last working in.
	if s := m.continueTarget(); s != nil {
		for i, c := range courses {
			if c == s.Course {
				m.courseIx = i
			}
		}
	}
	return m
}

func (m *model) Init() tea.Cmd {
	return tea.Batch(m.spin.Tick, checkDocker(m.ops), refreshStates(m.ops))
}

// ---- commands -------------------------------------------------------------------

func checkDocker(o *Ops) tea.Cmd {
	return func() tea.Msg { v, err := o.DockerVersion(); return dockerMsg{v, err} }
}

func refreshStates(o *Ops) tea.Cmd {
	return func() tea.Msg { return statesMsg(o.States()) }
}

func (m *model) setFlash(msg string, bad bool) tea.Cmd {
	m.flash, m.flashBad = msg, bad
	m.flashSeq++
	seq := m.flashSeq
	return tea.Tick(6*time.Second, func(time.Time) tea.Msg { return flashDoneMsg(seq) })
}

func (m *model) run(op string, s *Section, status string, fn func() (string, error)) tea.Cmd {
	if m.busy {
		return nil
	}
	if m.dockerErr != "" {
		if v, err := m.ops.DockerVersion(); err != nil {
			return m.setFlash(err.Error(), true)
		} else {
			m.dockerVer, m.dockerErr = v, ""
		}
	}
	m.busy, m.status = true, status
	return func() tea.Msg {
		out, err := fn()
		return opDoneMsg{op: op, sec: s, out: out, err: err}
	}
}

func (m *model) openSandbox(s *Section) tea.Cmd {
	return m.run("prepare", s, "Getting your sandbox ready", func() (string, error) { return "", m.ops.Prepare(s) })
}

func (m *model) verify(s *Section) tea.Cmd {
	return m.run("verify", s, "Grading your work", func() (string, error) { return m.ops.Verify(s) })
}

// ---- update ---------------------------------------------------------------------

func (m *model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.w, m.h = msg.Width, msg.Height
		m.vpKey = ""
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(msg)
		return m, cmd

	case dockerMsg:
		if msg.err != nil {
			m.dockerErr = msg.err.Error()
		} else {
			m.dockerVer, m.dockerErr = msg.ver, ""
		}
		return m, nil

	case statesMsg:
		m.states = msg
		return m, nil

	case statusMsg:
		m.status = string(msg)
		return m, nil

	case flashDoneMsg:
		if int(msg) == m.flashSeq {
			m.flash = ""
		}
		return m, nil

	case opDoneMsg:
		return m, m.onOpDone(msg)

	case shellDoneMsg:
		m.vpKey = ""
		return m, tea.Batch(m.verify(msg.sec), tea.EnableMouseCellMotion)

	case tea.MouseMsg:
		if m.scr == scrSection && !m.focusTasks {
			var cmd tea.Cmd
			m.vp, cmd = m.vp.Update(msg)
			return m, cmd
		}
		return m, nil

	case tea.KeyMsg:
		return m, m.onKey(msg)
	}
	return m, nil
}

func (m *model) onOpDone(msg opDoneMsg) tea.Cmd {
	m.busy, m.status = false, ""
	s := msg.sec
	cmds := []tea.Cmd{refreshStates(m.ops)}
	if msg.err != nil && msg.err != errNotStarted {
		m.lastErr[s.Key()] = msg.err.Error()
		if m.sec == s {
			m.tab, m.vpKey = tabResults, ""
		}
		first := strings.SplitN(msg.err.Error(), "\n", 2)[0]
		return tea.Batch(append(cmds, m.setFlash("✘ "+first+" - details in Results", true))...)
	}
	delete(m.lastErr, s.Key())

	switch msg.op {
	case "prepare":
		sp := m.prog.Get(s.Key())
		sp.Started = true
		m.prog.Last = s.Key()
		_ = m.prog.Save()
		cmds = append(cmds, tea.ExecProcess(m.ops.Shell(s), func(error) tea.Msg { return shellDoneMsg{sec: s} }))

	case "verify":
		if msg.err == errNotStarted {
			cmds = append(cmds, m.setFlash("Open the sandbox first - press enter", true))
			break
		}
		sp := m.prog.Get(s.Key())
		res := ParseResult(msg.out)
		just := sp.Apply(res, msg.out)
		m.prog.Last = s.Key()
		_ = m.prog.Save()
		if m.sec == s {
			m.tab, m.vpKey = tabResults, ""
		}
		switch {
		case just && m.courseDone(s.Course):
			cmds = append(cmds, m.setFlash("★ Course complete: "+s.Course.Title+"! You're levelling up fast.", false))
		case just:
			cmds = append(cmds, m.setFlash("★ Section complete! Press n for the next one.", false))
		case res.Fail == 0 && res.Pass > 0:
			cmds = append(cmds, m.setFlash("✔ Still all green.", false))
		case res.Pass+res.Fail > 0:
			cmds = append(cmds, m.setFlash(fmt.Sprintf("%d of %d checks passing - the ✘ lines tell you what's missing", res.Pass, res.Pass+res.Fail), false))
		default:
			cmds = append(cmds, m.setFlash("Grader finished - see Results", false))
		}

	case "reset":
		cmds = append(cmds, m.setFlash("Fresh sandbox ready. Press enter to dive back in.", false))

	case "stop":
		cmds = append(cmds, m.setFlash("Sandbox removed. Your progress is kept.", false))
	}
	return tea.Batch(cmds...)
}

func (m *model) onKey(k tea.KeyMsg) tea.Cmd {
	key := k.String()
	if key == "ctrl+c" {
		return tea.Quit
	}
	if m.help {
		m.help = false
		return nil
	}
	if m.confirm != nil {
		c := m.confirm
		switch key {
		case "y", "Y", "enter":
			m.confirm = nil
			return m.doConfirmed(c.op)
		case "n", "N", "esc", "q":
			m.confirm = nil
		}
		return nil
	}
	if key == "?" {
		m.help = true
		return nil
	}

	switch m.scr {
	case scrHome:
		switch key {
		case "q", "esc":
			return tea.Quit
		case "up", "k":
			m.courseIx = (m.courseIx - 1 + len(m.courses)) % len(m.courses)
		case "down", "j":
			m.courseIx = (m.courseIx + 1) % len(m.courses)
		case "enter", "right", "l":
			m.scr = scrCourse
			m.sectionIx = m.firstOpenSection(m.courses[m.courseIx])
			return refreshStates(m.ops)
		case "c":
			if s := m.continueTarget(); s != nil {
				m.openSection(s)
				return refreshStates(m.ops)
			}
		}

	case scrCourse:
		c := m.courses[m.courseIx]
		switch key {
		case "q":
			return tea.Quit
		case "esc", "left", "h", "backspace":
			m.scr = scrHome
		case "up", "k":
			m.sectionIx = (m.sectionIx - 1 + len(c.Sections)) % len(c.Sections)
		case "down", "j":
			m.sectionIx = (m.sectionIx + 1) % len(c.Sections)
		case "enter", "right", "l":
			m.openSection(c.Sections[m.sectionIx])
		}

	case scrSection:
		return m.sectionKey(key, k)
	}
	return nil
}

func (m *model) sectionKey(key string, k tea.KeyMsg) tea.Cmd {
	s := m.sec
	tabs := m.tabs()
	switch key {
	case "q":
		return tea.Quit
	case "esc", "backspace":
		m.scr = scrCourse
		m.focusTasks = false
		return nil
	case "enter":
		if !m.busy {
			return m.openSandbox(s)
		}
	case "v":
		return m.verify(s)
	case "r":
		m.confirm = &confirmBox{"Reset this section?", "Your ~/sandbox is wiped and the scenario is seeded again.\nYour progress record is kept.", "reset"}
	case "x":
		m.confirm = &confirmBox{"Remove the sandbox?", "Deletes the container (and anything this section created).\nYour progress record is kept.", "stop"}
	case "s":
		m.showSolution()
	case "n":
		m.step(+1)
	case "p":
		m.step(-1)
	case "tab", "shift+tab":
		i := 0
		for j, t := range tabs {
			if t == m.tab {
				i = j
			}
		}
		if key == "tab" {
			i = (i + 1) % len(tabs)
		} else {
			i = (i - 1 + len(tabs)) % len(tabs)
		}
		m.setTab(tabs[i])
	case "1", "2", "3", "4":
		i := int(key[0] - '1')
		if i < len(tabs) {
			m.setTab(tabs[i])
		}
	case "right":
		if m.wide() {
			m.focusTasks = true
		}
	case "left":
		if m.wide() {
			m.focusTasks = false
		}
	default:
		if m.tasksActive() {
			switch key {
			case "up", "k":
				if m.taskIx > 0 {
					m.taskIx--
				}
				m.vpKey = ""
			case "down", "j":
				if m.taskIx < len(m.visibleTasks())-1 {
					m.taskIx++
				}
				m.vpKey = ""
			case " ", "space":
				ts := m.visibleTasks()
				if m.taskIx < len(ts) && ts[m.taskIx].Kind == "drill" {
					sp := m.prog.Get(s.Key())
					sp.ToggleDrill(ts[m.taskIx].ID)
					_ = m.prog.Save()
					m.vpKey = ""
				} else {
					return m.setFlash("Graded tasks tick themselves when you press v", false)
				}
			}
			return nil
		}
		var cmd tea.Cmd
		m.vp, cmd = m.vp.Update(k)
		return cmd
	}
	return nil
}

func (m *model) doConfirmed(op string) tea.Cmd {
	s := m.sec
	switch op {
	case "reset":
		return m.run("reset", s, "Resetting", func() (string, error) { return "", m.ops.Reset(s) })
	case "stop":
		return m.run("stop", s, "Cleaning up", func() (string, error) { return "", m.ops.Stop(s) })
	case "solution":
		m.unlocked[s.Key()] = true
		m.setTab(tabSolution)
	}
	return nil
}

func (m *model) showSolution() {
	s := m.sec
	if s.Solutions == "" {
		return
	}
	if m.unlocked[s.Key()] {
		m.setTab(tabSolution)
		return
	}
	m.confirm = &confirmBox{"Peek at the solution?", "Struggling is where the learning happens.\nGive it one more honest try first - then come back if you're stuck.", "solution"}
}

func (m *model) setTab(t tabID) {
	if t == tabSolution && !m.unlocked[m.sec.Key()] {
		m.showSolution()
		return
	}
	m.tab, m.vpKey = t, ""
	m.vp.GotoTop()
}

func (m *model) openSection(s *Section) {
	for i, c := range m.courses {
		if c == s.Course {
			m.courseIx = i
			for j, x := range c.Sections {
				if x == s {
					m.sectionIx = j
				}
			}
		}
	}
	m.sec, m.scr = s, scrSection
	m.tab, m.focusTasks, m.taskIx, m.vpKey = tabLesson, false, 0, ""
	m.prog.Last = s.Key()
	_ = m.prog.Save()
}

func (m *model) step(d int) {
	c := m.sec.Course
	for i, s := range c.Sections {
		if s == m.sec {
			j := i + d
			switch {
			case j >= 0 && j < len(c.Sections):
				m.openSection(c.Sections[j])
			case j >= len(c.Sections) && m.courseIx+1 < len(m.courses):
				m.openSection(m.courses[m.courseIx+1].Sections[0])
			case j < 0 && m.courseIx > 0:
				prev := m.courses[m.courseIx-1]
				m.openSection(prev.Sections[len(prev.Sections)-1])
			}
			return
		}
	}
}

// ---- derived state --------------------------------------------------------------

func (m *model) wide() bool { return m.w >= 104 }

func (m *model) tabs() []tabID {
	t := []tabID{tabLesson}
	if !m.wide() {
		t = append(t, tabTasks)
	}
	t = append(t, tabResults)
	if m.sec != nil && m.sec.Solutions != "" {
		t = append(t, tabSolution)
	}
	return t
}

func (m *model) tasksActive() bool {
	return (m.wide() && m.focusTasks) || (!m.wide() && m.tab == tabTasks)
}

func (m *model) courseDone(c *Course) bool {
	for _, s := range c.Sections {
		if m.prog.Peek(s.Key()).Status() != Done {
			return false
		}
	}
	return true
}

func (m *model) courseCounts(c *Course) (done, total int) {
	for _, s := range c.Sections {
		if m.prog.Peek(s.Key()).Status() == Done {
			done++
		}
	}
	return done, len(c.Sections)
}

func (m *model) firstOpenSection(c *Course) int {
	for i, s := range c.Sections {
		if m.prog.Peek(s.Key()).Status() != Done {
			return i
		}
	}
	return 0
}

// continueTarget: the section you were last in if unfinished, else the first unfinished one.
func (m *model) continueTarget() *Section {
	var first *Section
	for _, c := range m.courses {
		for _, s := range c.Sections {
			st := m.prog.Peek(s.Key()).Status()
			if s.Key() == m.prog.Last && st != Done {
				return s
			}
			if first == nil && st != Done {
				first = s
			}
		}
	}
	return first
}

// visibleTasks is the README task list, or - for sections without numbered tasks -
// whatever the grader last reported.
func (m *model) visibleTasks() []Task {
	if len(m.sec.Tasks) > 0 {
		return m.sec.Tasks
	}
	var ts []Task
	for _, c := range ParseResult(m.prog.Peek(m.sec.Key()).LastOutput).Checks {
		ts = append(ts, Task{ID: c.ID, Kind: "graded", Title: c.Text})
	}
	return ts
}

func (m *model) containerState(s *Section) string {
	if s.Course.Kind == KindHost {
		if exists(m.ops.hostSandbox(s)) {
			return "seeded"
		}
		return ""
	}
	return m.states[s.Course.Container(s)]
}

func init() {
	// Make lipgloss render for a dark canvas even if the terminal can't tell us.
	lipgloss.SetHasDarkBackground(true)
	_ = os.Setenv("GLAMOUR_STYLE", "dark")
}
