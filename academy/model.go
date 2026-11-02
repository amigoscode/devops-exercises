package main

// Two screens, one set of keys:
//
//   Browse    courses │ sections        ↑↓ move · → / enter go in · ← / esc go back
//   Exercise  questions on top, the selected question underneath
//             ↑↓ pick a question · enter open the sandbox · v check · esc back

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
	scrBrowse screen = iota
	scrExercise
)

// What the panel under the questions shows.
type pane int

const (
	paneQuestion pane = iota
	paneLesson
	paneSolution
)

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
	col       int // browse: 0 = courses, 1 = sections
	courseIx  int
	sectionIx int
	sec       *Section

	pane     pane
	q        int // selected question
	vp       viewport.Model
	vpKey    string
	unlocked map[string]bool
	lastErr  map[string]string

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

	// ↑↓ belong to the question list; the detail panel scrolls with PgUp/PgDn,
	// ctrl+u/ctrl+d, shift+↑↓ or the mouse wheel.
	vp := viewport.New(80, 20)
	vp.MouseWheelEnabled = true
	vp.KeyMap = viewport.KeyMap{
		PageDown:     key.NewBinding(key.WithKeys("pgdown")),
		PageUp:       key.NewBinding(key.WithKeys("pgup")),
		HalfPageDown: key.NewBinding(key.WithKeys("ctrl+d")),
		HalfPageUp:   key.NewBinding(key.WithKeys("ctrl+u")),
		Down:         key.NewBinding(key.WithKeys("shift+down")),
		Up:           key.NewBinding(key.WithKeys("shift+up")),
		Left:         key.NewBinding(key.WithDisabled()),
		Right:        key.NewBinding(key.WithDisabled()),
	}
	m := &model{
		ops: ops, courses: courses, prog: prog, spin: sp, vp: vp,
		unlocked: map[string]bool{}, lastErr: map[string]string{}, states: map[string]string{},
	}
	// Land on the section you were last working in.
	if s := m.continueTarget(); s != nil {
		m.selectSection(s)
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
	return tea.Tick(7*time.Second, func(time.Time) tea.Msg { return flashDoneMsg(seq) })
}

func (m *model) run(op string, s *Section, status string, fn func() (string, error)) tea.Cmd {
	if m.busy {
		return nil
	}
	if m.dockerErr != "" {
		v, err := m.ops.DockerVersion()
		if err != nil {
			return m.setFlash(err.Error(), true)
		}
		m.dockerVer, m.dockerErr = v, ""
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
	return m.run("verify", s, "Checking your work", func() (string, error) { return m.ops.Verify(s) })
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
		if m.scr == scrExercise {
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
		m.pane, m.vpKey = paneQuestion, ""
		first := strings.SplitN(msg.err.Error(), "\n", 2)[0]
		return tea.Batch(append(cmds, m.setFlash("✘ "+first, true))...)
	}
	delete(m.lastErr, s.Key())

	switch msg.op {
	case "prepare":
		sp := m.prog.Get(s.Key())
		sp.Started = true
		m.prog.Last = s.Key()
		_ = m.prog.Save()
		cmds = append(cmds, tea.ExecProcess(m.ops.Shell(s, m.shellBanner(s)), func(error) tea.Msg { return shellDoneMsg{sec: s} }))

	case "verify":
		if msg.err == errNotStarted {
			cmds = append(cmds, m.setFlash("Nothing to check yet - press enter to open your sandbox first", true))
			break
		}
		sp := m.prog.Get(s.Key())
		res := ParseResult(msg.out)
		just := sp.Apply(res, msg.out)
		m.prog.Last = s.Key()
		_ = m.prog.Save()
		if m.sec == s {
			m.pane, m.vpKey = paneQuestion, ""
			m.q = m.firstOpenQuestion() // jump straight to what still needs doing
		}
		switch {
		case just && m.courseDone(s.Course):
			cmds = append(cmds, m.setFlash("★ Course complete: "+s.Course.Title+"! You're levelling up fast.", false))
		case just:
			cmds = append(cmds, m.setFlash("★ Section complete! Press n for the next one.", false))
		case res.Fail == 0 && res.Pass > 0:
			cmds = append(cmds, m.setFlash("✔ All checks still passing.", false))
		case res.Pass+res.Fail > 0:
			cmds = append(cmds, m.setFlash(fmt.Sprintf("%d of %d done - the question with ✘ shows what's missing", res.Pass, res.Pass+res.Fail), false))
		default:
			cmds = append(cmds, m.setFlash("Check finished", false))
		}

	case "reset":
		cmds = append(cmds, m.setFlash("Fresh sandbox ready. Press enter to dive back in.", false))

	case "stop":
		cmds = append(cmds, m.setFlash("Sandbox removed. Your progress is kept.", false))
	}
	return tea.Batch(cmds...)
}

// ---- keys -----------------------------------------------------------------------

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
	switch key {
	case "?":
		m.help = true
		return nil
	case "q":
		return tea.Quit
	}
	if m.scr == scrBrowse {
		return m.browseKey(key)
	}
	return m.exerciseKey(key, k)
}

func (m *model) browseKey(key string) tea.Cmd {
	c := m.courses[m.courseIx]
	switch key {
	case "up", "k":
		if m.col == 0 {
			m.courseIx = (m.courseIx - 1 + len(m.courses)) % len(m.courses)
			m.sectionIx = m.firstOpenSection(m.courses[m.courseIx])
		} else {
			m.sectionIx = (m.sectionIx - 1 + len(c.Sections)) % len(c.Sections)
		}
	case "down", "j":
		if m.col == 0 {
			m.courseIx = (m.courseIx + 1) % len(m.courses)
			m.sectionIx = m.firstOpenSection(m.courses[m.courseIx])
		} else {
			m.sectionIx = (m.sectionIx + 1) % len(c.Sections)
		}
	case "right", "l", "enter", " ":
		if m.col == 0 {
			m.col = 1
			return nil
		}
		m.openSection(c.Sections[m.sectionIx])
		return refreshStates(m.ops)
	case "left", "h", "esc", "backspace":
		m.col = 0
	case "c":
		if s := m.continueTarget(); s != nil {
			m.openSection(s)
			return refreshStates(m.ops)
		}
	}
	return nil
}

func (m *model) exerciseKey(key string, k tea.KeyMsg) tea.Cmd {
	s := m.sec
	qs := m.questions()
	switch key {
	case "esc", "backspace", "left", "h":
		if m.pane != paneQuestion {
			m.setPane(paneQuestion)
			return nil
		}
		m.scr, m.col = scrBrowse, 1
		m.selectSection(s)
	case "up", "k":
		if m.q > 0 {
			m.q--
		}
		m.setPane(paneQuestion)
	case "down", "j":
		if m.q < len(qs)-1 {
			m.q++
		}
		m.setPane(paneQuestion)
	case "enter", "right":
		if !m.busy {
			return m.openSandbox(s)
		}
	case "v":
		return m.verify(s)
	case " ", "space":
		if m.q < len(qs) && qs[m.q].Kind == "drill" {
			sp := m.prog.Get(s.Key())
			sp.ToggleDrill(qs[m.q].ID)
			_ = m.prog.Save()
			m.vpKey = ""
			return nil
		}
		return m.setFlash("Graded questions tick themselves - press v to check", false)
	case "l":
		if m.pane == paneLesson {
			m.setPane(paneQuestion)
		} else {
			m.setPane(paneLesson)
		}
	case "s":
		m.showSolution()
	case "r":
		m.confirm = &confirmBox{"Start this section over?", "Your ~/sandbox is wiped and the scenario is set up again.\nYour progress record is kept.", "reset"}
	case "x":
		m.confirm = &confirmBox{"Remove the sandbox?", "Deletes the container (and anything this section created).\nYour progress record is kept.", "stop"}
	case "n":
		m.step(+1)
	case "p":
		m.step(-1)
	default:
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
		return m.run("reset", s, "Starting over", func() (string, error) { return "", m.ops.Reset(s) })
	case "stop":
		return m.run("stop", s, "Cleaning up", func() (string, error) { return "", m.ops.Stop(s) })
	case "solution":
		m.unlocked[s.Key()] = true
		m.setPane(paneSolution)
	}
	return nil
}

func (m *model) showSolution() {
	s := m.sec
	if s.Solutions == "" {
		return
	}
	if m.pane == paneSolution {
		m.setPane(paneQuestion)
		return
	}
	if m.unlocked[s.Key()] {
		m.setPane(paneSolution)
		return
	}
	m.confirm = &confirmBox{"Peek at the solution?", "Struggling is where the learning happens.\nGive it one more honest try first - then come back if you're stuck.", "solution"}
}

func (m *model) setPane(p pane) {
	if p != m.pane {
		m.vp.GotoTop()
	}
	m.pane, m.vpKey = p, ""
}

// ---- navigation -----------------------------------------------------------------

func (m *model) selectSection(s *Section) {
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
}

func (m *model) openSection(s *Section) {
	m.selectSection(s)
	m.sec, m.scr = s, scrExercise
	m.pane, m.vpKey = paneQuestion, ""
	m.q = m.firstOpenQuestion()
	m.vp.GotoTop()
	m.prog.Last = s.Key()
	_ = m.prog.Save()
}

func (m *model) step(d int) {
	var all []*Section
	for _, c := range m.courses {
		all = append(all, c.Sections...)
	}
	for i, s := range all {
		if s == m.sec && i+d >= 0 && i+d < len(all) {
			m.openSection(all[i+d])
			return
		}
	}
}

// ---- derived state --------------------------------------------------------------

// questions is the README's task list, or - for sections without numbered tasks -
// whatever the grader last reported.
func (m *model) questions() []Task {
	if len(m.sec.Tasks) > 0 {
		return m.sec.Tasks
	}
	var ts []Task
	for _, c := range ParseResult(m.prog.Peek(m.sec.Key()).LastOutput).Checks {
		ts = append(ts, Task{ID: c.ID, Kind: "graded", Title: c.Text, Text: c.Text})
	}
	return ts
}

// firstOpenQuestion is the first graded question not yet passing (else 0).
func (m *model) firstOpenQuestion() int {
	sp := m.prog.Peek(m.sec.Key())
	for i, t := range m.questions() {
		if t.Kind != "drill" && sp.TaskState(t.ID) != 1 {
			return i
		}
	}
	return 0
}

// check returns the grader's last line about a question, if any.
func (m *model) check(id string) (Check, bool) {
	for _, c := range ParseResult(m.prog.Peek(m.sec.Key()).LastOutput).Checks {
		if c.ID == id {
			return c, true
		}
	}
	return Check{}, false
}

func (m *model) questionCounts(s *Section) (done, total int) {
	sp := m.prog.Peek(s.Key())
	for _, t := range s.Tasks {
		if t.Kind == "drill" {
			continue
		}
		total++
		if sp.TaskState(t.ID) == 1 {
			done++
		}
	}
	return done, total
}

func (m *model) courseDone(c *Course) bool {
	d, t := m.courseCounts(c)
	return d == t
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

func (m *model) anyProgress() bool {
	for _, sp := range m.prog.Sections {
		if sp.Status() != NotStarted {
			return true
		}
	}
	return false
}

func (m *model) containerState(s *Section) string {
	if s.Course.Kind == KindHost {
		if exists(m.ops.hostSandbox(s)) {
			return "running"
		}
		return ""
	}
	return m.states[s.Course.Container(s)]
}

func init() {
	// Render for a dark canvas even if the terminal can't tell us.
	lipgloss.SetHasDarkBackground(true)
	_ = os.Setenv("GLAMOUR_STYLE", "dark")
}
