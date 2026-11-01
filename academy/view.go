package main

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/lipgloss"
	xansi "github.com/charmbracelet/x/ansi"
)

const margin = "  "

func (m *model) View() string {
	if m.w == 0 || m.h == 0 {
		return ""
	}
	if m.w < 60 || m.h < 18 {
		return lipgloss.Place(m.w, m.h, lipgloss.Center, lipgloss.Center,
			sBrand.Render("AMIGOSCODE")+"\n"+sMuted.Render("Make the terminal a little bigger (60×18+)"))
	}
	var v string
	switch m.scr {
	case scrHome:
		v = m.viewHome()
	case scrCourse:
		v = m.viewCourse()
	case scrSection:
		v = m.viewSection()
	}
	v = fit(v, m.w, m.h)
	if m.help {
		v = overlay(v, m.helpBox(), m.w, m.h)
	}
	if m.confirm != nil {
		v = overlay(v, m.confirmView(), m.w, m.h)
	}
	return v
}

// ---- shared chrome --------------------------------------------------------------

func (m *model) dockerBadge() string {
	switch {
	case m.dockerErr != "":
		return sRed.Render("● " + m.dockerErr)
	case m.dockerVer != "":
		return sGreen.Render("●") + sMuted.Render(" Docker "+m.dockerVer)
	}
	return sFaint.Render("● checking Docker…")
}

func (m *model) topBar(crumbs ...string) string {
	left := margin + gradient("AMIGOSCODE", true) + sMuted.Render(" Academy")
	for _, c := range crumbs {
		left += sFaint.Render("  ›  ") + sText.Render(c)
	}
	return spread(left, m.dockerBadge()+margin, m.w)
}

func (m *model) footer(hints ...string) string {
	line := margin + strings.Join(hints, "   ")
	return truncateANSI(line, m.w)
}

func (m *model) statusLine(idle string) string {
	switch {
	case m.busy:
		return margin + m.spin.View() + " " + sViolet.Render(m.status+"…")
	case m.flash != "" && m.flashBad:
		return margin + sRed.Render(m.flash)
	case m.flash != "":
		return margin + sGreen.Render(m.flash)
	}
	return margin + idle
}

// ---- home -----------------------------------------------------------------------

func (m *model) viewHome() string {
	var b []string
	W := m.w
	b = append(b, "")
	logo := strings.Split(Logo(), "\n")
	b = append(b, spread(margin+logo[0], m.dockerBadge()+margin, W))
	b = append(b, margin+logo[1]+"  "+sBold.Render("Academy"))
	b = append(b, margin+sMuted.Render("Hands-on, auto-graded exercises · from your first command to shipping containers"))
	b = append(b, "")

	// Progress card
	done, total := 0, 0
	for _, c := range m.courses {
		d, t := m.courseCounts(c)
		done, total = done+d, total+t
	}
	cardW := min(W-4, 112)
	inner := cardW - 4
	pct := 0
	if total > 0 {
		pct = done * 100 / total
	}
	stat := sBold.Render(fmt.Sprintf("%d/%d", done, total)) + sMuted.Render(" sections  ") + sBrand.Render(fmt.Sprintf("%d%%", pct))
	barW := inner - lipgloss.Width(stat) - 2
	card := []string{
		sFaint.Render("YOUR PROGRESS"),
		Bar(done, total, barW) + "  " + stat,
	}
	if s := m.continueTarget(); s != nil {
		label := "Start here"
		if m.prog.Peek(s.Key()).Status() != NotStarted || done > 0 {
			label = "Continue"
		}
		card = append(card, spread(sBrand.Render("▶ "+label)+"  "+sText.Render(s.Course.Title)+sFaint.Render(" › ")+sBold.Render(s.Num+" "+s.Title), keyHint("c", "jump in"), inner))
	} else {
		card = append(card, sGreen.Render("★ Every section complete. You did it - time to build something real."))
	}
	b = append(b, indent(sPanel.Width(cardW-2).Render(strings.Join(card, "\n")), margin))
	b = append(b, "")

	// Courses list (+ detail on wide screens)
	listW := cardW
	showDetail := W >= 104
	if showDetail {
		listW = min(62, cardW/2+6)
	}
	var rows []string
	rows = append(rows, sFaint.Render("COURSES"))
	for i, c := range m.courses {
		d, t := m.courseCounts(c)
		sel := i == m.courseIx
		marker := "  "
		title := sText.Render(c.Title)
		num := sFaint.Render(c.Num)
		if sel {
			marker = sBrand.Render("▌ ")
			title = sBold.Render(c.Title)
			num = sBrand.Render(c.Num)
		}
		count := sMuted.Render(fmt.Sprintf("%d/%d", d, t))
		if d == t {
			count = sGreen.Render(fmt.Sprintf("%d/%d ✔", d, t))
		}
		nameW := listW - 4 - 4 - 14 - 8
		row := marker + num + "  " + padRight(truncate(title, nameW), nameW) + " " + Bar(d, t, 12) + "  " + count
		rows = append(rows, row)
	}
	list := strings.Join(rows, "\n")

	if showDetail {
		detW := cardW - listW - 2
		detail := m.courseDetail(m.courses[m.courseIx], detW-4)
		box := sPanelFocus.Width(detW - 2).Render(detail)
		list = lipgloss.JoinHorizontal(lipgloss.Top, lipgloss.NewStyle().Width(listW).Render(list), "  ", box)
	}
	b = append(b, indent(list, margin))
	if m.h >= 36 {
		step := func(n, txt string) string { return sPill.Render(n) + " " + sText.Render(txt) }
		arrow := sFaint.Render("  ──▶  ")
		b = append(b, "", margin+sFaint.Render("HOW IT WORKS"),
			margin+step("1", "Read the lesson")+arrow+step("2", "enter opens a real sandbox")+arrow+step("3", "Do the tasks")+arrow+step("4", "exit · graded instantly"))
	}

	body := strings.Join(b, "\n")
	foot := []string{
		m.statusLine(sMuted.Render("Pick a course, or press ") + sBold.Render("c") + sMuted.Render(" to carry on where you left off.")),
		m.footer(keyHint("↑↓", "move"), keyHint("enter", "open"), keyHint("c", "continue"), keyHint("?", "help"), keyHint("q", "quit")),
	}
	return stick(body, strings.Join(foot, "\n"), m.h)
}

func (m *model) courseDetail(c *Course, w int) string {
	env := sCyan.Render("◆ Runs in a disposable Ubuntu sandbox")
	if c.Kind == KindHost {
		env = sCyan.Render("◆ Runs on your own Docker - real containers")
	}
	d, t := m.courseCounts(c)
	lines := []string{
		sBold.Render(c.Title),
		env,
		"",
		lipgloss.NewStyle().Foreground(cMuted).Width(w).Render(truncate(c.Blurb, w*3)),
		"",
		sFaint.Render(fmt.Sprintf("SECTIONS  %d/%d", d, t)),
	}
	for _, s := range c.Sections {
		st := m.prog.Peek(s.Key()).Status()
		lines = append(lines, statusIcon(st)+" "+sFaint.Render(s.Num)+" "+truncate(sText.Render(s.Title), w-6))
	}
	return strings.Join(lines, "\n")
}

// ---- course ---------------------------------------------------------------------

func (m *model) viewCourse() string {
	c := m.courses[m.courseIx]
	W := m.w
	var b []string
	b = append(b, m.topBar(c.Title), "")
	d, t := m.courseCounts(c)
	stat := sBold.Render(fmt.Sprintf("%d/%d", d, t)) + sMuted.Render(" sections complete")
	b = append(b, margin+sPill.Render(c.Num)+" "+sBold.Render(c.Title)+"   "+Bar(d, t, 24)+"  "+stat, "")

	listW := min(W-4, 54)
	wide := W >= 100
	var rows []string
	for i, s := range c.Sections {
		sp := m.prog.Peek(s.Key())
		sel := i == m.sectionIx
		marker := "  "
		title := sText.Render(s.Title)
		if sel {
			marker = sBrand.Render("▌ ")
			title = sBold.Render(s.Title)
		}
		score := ""
		if sp.PassCount+sp.FailCount > 0 {
			score = fmt.Sprintf("%d/%d", sp.PassCount, sp.PassCount+sp.FailCount)
		}
		if !s.Graded() {
			score = "review"
		}
		live := " "
		if st := m.containerState(s); st == "running" || st == "seeded" {
			live = sGreen.Render("•")
		}
		nameW := listW - 4 - 3 - 3 - 9
		rows = append(rows, marker+statusIcon(sp.Status())+" "+sFaint.Render(s.Num)+" "+padRight(truncate(title, nameW), nameW)+live+" "+sMuted.Render(fmt.Sprintf("%6s", score)))
	}
	listBox := sPanel.Width(listW - 2).Render(sFaint.Render("SECTIONS") + "\n" + strings.Join(rows, "\n"))
	content := listBox
	if wide {
		detW := min(W-listW-6, 76)
		content = lipgloss.JoinHorizontal(lipgloss.Top, listBox, "  ", sPanelFocus.Width(detW-2).Render(m.sectionPreview(c.Sections[m.sectionIx], detW-4)))
	}
	b = append(b, indent(content, margin))

	s := c.Sections[m.sectionIx]
	idle := sMuted.Render("Press ") + sBold.Render("enter") + sMuted.Render(" to open ") + sText.Render(s.Num+" "+s.Title)
	foot := []string{
		m.statusLine(idle),
		m.footer(keyHint("↑↓", "move"), keyHint("enter", "open"), keyHint("esc", "back"), keyHint("?", "help"), keyHint("q", "quit")),
	}
	return stick(strings.Join(b, "\n"), strings.Join(foot, "\n"), m.h)
}

func (m *model) sectionPreview(s *Section, w int) string {
	sp := m.prog.Peek(s.Key())
	lines := []string{sBold.Render(s.Num + " · " + s.Title)}
	if s.MapsTo != "" {
		lines = append(lines, sFaint.Render(truncate(s.MapsTo, w)))
	}
	lines = append(lines, "", lipgloss.NewStyle().Foreground(cMuted).Width(w).Render(truncate(s.Blurb, w*3)), "")
	if !s.Graded() {
		lines = append(lines, sAmber.Render("◆ Open-ended capstone - reviewed by a human in the Academy"), "")
	}
	tier := -1
	for _, t := range s.Tasks {
		if t.Tier != tier {
			tier = t.Tier
			lines = append(lines, tierLabel(s, tier))
		}
		lines = append(lines, taskLine(t, sp, w, false))
	}
	if sp.LastVerified != "" {
		lines = append(lines, "", sFaint.Render("last checked "+ago(sp.LastVerified)))
	}
	return strings.Join(lines, "\n")
}

// ---- section --------------------------------------------------------------------

func (m *model) viewSection() string {
	s := m.sec
	W, H := m.w, m.h
	sp := m.prog.Peek(s.Key())

	// title row
	pill := sPillDim.Render("not started")
	switch {
	case sp.Status() == Done:
		pill = lipgloss.NewStyle().Foreground(lipgloss.Color("#06281C")).Background(cGreen).Bold(true).Padding(0, 1).Render("✔ complete")
	case sp.PassCount+sp.FailCount > 0:
		pill = lipgloss.NewStyle().Foreground(lipgloss.Color("#2A1A00")).Background(cAmber).Bold(true).Padding(0, 1).Render(fmt.Sprintf("%d/%d passing", sp.PassCount, sp.PassCount+sp.FailCount))
	case sp.Started:
		pill = lipgloss.NewStyle().Foreground(cText).Background(cRaised).Padding(0, 1).Render("in progress")
	}
	sandbox := ""
	switch m.containerState(s) {
	case "running", "seeded":
		sandbox = sGreen.Render("● sandbox up")
	case "exited":
		sandbox = sAmber.Render("● sandbox paused")
	}
	title := margin + sPill.Render(s.Num) + " " + sBold.Render(s.Title)
	if s.MapsTo != "" && W > 110 {
		title += "  " + sFaint.Render(truncate(s.MapsTo, W-60-lipgloss.Width(s.Title)))
	}
	titleRow := spread(title, sandbox+"  "+pill+margin, W)

	// tabs
	var tabs []string
	for i, t := range m.tabs() {
		name := fmt.Sprintf("%d %s", i+1, tabNames[t])
		if t == tabSolution && !m.unlocked[s.Key()] {
			name += " ·locked"
		}
		if t == tabResults && sp.LastOutput == "" && m.lastErr[s.Key()] == "" {
			name += " ·none yet"
		}
		if t == m.tab {
			tabs = append(tabs, sPill.Render(name))
		} else {
			tabs = append(tabs, sPillDim.Render(name))
		}
	}
	tabRow := margin + strings.Join(tabs, " ")

	// panels
	panelH := H - 8
	taskW := 0
	if m.wide() {
		taskW = min(50, W/3)
	}
	leftW := W - 4 - taskW
	if taskW > 0 {
		leftW -= 1
	}
	m.syncViewport(leftW-4, panelH-2)

	left := sPanel
	if !m.focusTasks || !m.wide() {
		left = sPanelFocus
	}
	scroll := ""
	if m.vp.TotalLineCount() > m.vp.Height {
		scroll = fmt.Sprintf(" %d%%", int(m.vp.ScrollPercent()*100))
	}
	leftBox := left.Width(leftW - 2).Height(panelH - 2).MaxHeight(panelH).Render(clip(m.vp.View(), m.vp.Width, m.vp.Height))
	edge := cBorder
	if !m.focusTasks || !m.wide() {
		edge = cViolet5
	}
	leftBox = labelBorder(leftBox, tabNames[m.tab]+scroll, edge)
	panels := leftBox
	if taskW > 0 {
		box := sPanel
		if m.focusTasks {
			box = sPanelFocus
		}
		tb := box.Width(taskW - 2).Height(panelH - 2).MaxHeight(panelH).Render(clip(m.taskPanel(taskW-4, panelH-2, m.focusTasks), taskW-4, panelH-2))
		panels = lipgloss.JoinHorizontal(lipgloss.Top, leftBox, " ", tb)
	}

	idle := m.sectionIdle(sp)
	hints := []string{keyHint("enter", "open sandbox"), keyHint("v", "check"), keyHint("tab", "switch view")}
	if m.wide() {
		hints = append(hints, keyHint("→", "tasks"))
	}
	hints = append(hints, keyHint("s", "solution"), keyHint("r", "reset"), keyHint("n/p", "next/prev"), keyHint("esc", "back"), keyHint("?", "more"))
	return strings.Join([]string{
		m.topBar(s.Course.Title, s.Num+" "+s.Title),
		"",
		titleRow,
		tabRow,
		indent(panels, margin),
		m.statusLine(idle),
		m.footer(hints...),
	}, "\n")
}

func (m *model) sectionIdle(sp SectionProgress) string {
	switch {
	case !m.sec.Graded():
		return sMuted.Render("Open-ended capstone: read the brief, build it, then submit it in the Academy for review.")
	case sp.Status() == Done:
		return sGreen.Render("✔ Section complete. ") + sMuted.Render("Press ") + sBold.Render("n") + sMuted.Render(" for the next one.")
	case sp.Started:
		return sMuted.Render("Press ") + sBold.Render("enter") + sMuted.Render(" to jump back into your sandbox - you're graded automatically when you exit.")
	}
	return sBrand.Render("▶ ") + sMuted.Render("Read the lesson, then press ") + sBold.Render("enter") + sMuted.Render(" to open your sandbox and start.")
}

func (m *model) syncViewport(w, h int) {
	w, h = max(w, 10), max(h, 3)
	key := fmt.Sprintf("%s|%d|%d|%d|%d|%v", m.sec.Key(), m.tab, w, h, m.taskIx, m.prog.Peek(m.sec.Key()).LastVerified)
	m.vp.Width, m.vp.Height = w, h
	if key == m.vpKey {
		return
	}
	keepY := m.vp.YOffset
	sameDoc := strings.HasPrefix(m.vpKey, fmt.Sprintf("%s|%d|", m.sec.Key(), m.tab))
	m.vpKey = key
	var content string
	switch m.tab {
	case tabLesson:
		content = RenderMarkdown(m.sec.Key()+"#lesson", m.sec.Lesson, w)
	case tabSolution:
		content = RenderMarkdown(m.sec.Key()+"#solution", readFile(m.sec.Solutions), w)
	case tabResults:
		content = m.resultsView(w)
	case tabTasks:
		content = m.taskPanel(w, 1000, true)
	}
	m.vp.SetContent(content)
	if sameDoc {
		m.vp.SetYOffset(keepY)
	}
}

func (m *model) resultsView(w int) string {
	s := m.sec
	if e := m.lastErr[s.Key()]; e != "" {
		return sRed.Render("Something went wrong") + "\n\n" + lipgloss.NewStyle().Foreground(cMuted).Width(w).Render(e) +
			"\n\n" + sMuted.Render("Is Docker running? Try again, or press r to reset the section.")
	}
	sp := m.prog.Peek(s.Key())
	if sp.LastOutput == "" {
		return "\n" + sBold.Render("No check yet.") + "\n\n" +
			sMuted.Render("Do the tasks in your sandbox, then press ") + sBold.Render("v") + sMuted.Render(" - or just exit the sandbox,\nit's checked automatically.")
	}
	res := ParseResult(sp.LastOutput)
	var head string
	if res.Fail == 0 && res.Pass > 0 {
		head = sGreen.Render("✔ All checks passing") + sMuted.Render(" - nice work.")
	} else {
		head = sBold.Render(fmt.Sprintf("%d of %d checks passing", res.Pass, res.Pass+res.Fail)) + sMuted.Render(" - fix the ✘ lines and press v again.")
	}
	lines := []string{head, Bar(res.Pass, res.Pass+res.Fail, min(w, 60)), sFaint.Render("checked " + ago(sp.LastVerified)), ""}
	wrap := lipgloss.NewStyle().Width(w - 4)
	for _, raw := range strings.Split(StripANSI(sp.LastOutput), "\n") {
		t := strings.TrimSpace(raw)
		switch {
		case t == "":
			lines = append(lines, "")
		case strings.HasPrefix(t, "✅"):
			lines = append(lines, hang(sGreen.Render("✔ "), wrap.Foreground(cText).Render(strings.TrimSpace(strings.TrimPrefix(t, "✅")))))
		case strings.HasPrefix(t, "❌"):
			lines = append(lines, hang(sRed.Render("✘ "), wrap.Foreground(cViolet1).Render(strings.TrimSpace(strings.TrimPrefix(t, "❌")))))
		case strings.HasPrefix(t, "Tier"), strings.HasPrefix(t, "Mission"):
			lines = append(lines, sBrand.Render(t))
		case strings.HasPrefix(t, "Score:"):
			lines = append(lines, sBold.Render(t))
		default:
			lines = append(lines, wrap.Foreground(cMuted).Render(t))
		}
	}
	return strings.Join(lines, "\n")
}

func (m *model) taskPanel(w, h int, focused bool) string {
	s := m.sec
	sp := m.prog.Peek(s.Key())
	tasks := m.visibleTasks()
	graded, passed := 0, 0
	for _, t := range tasks {
		if t.Kind == "drill" {
			continue
		}
		graded++
		if sp.TaskState(t.ID) == 1 {
			passed++
		}
	}
	head := spread(sFaint.Render("TASKS"), sMuted.Render(fmt.Sprintf("%d/%d", passed, graded)), w)
	lines := []string{head, Bar(passed, graded, w), ""}
	if !s.Graded() {
		lines = append(lines, lipgloss.NewStyle().Foreground(cAmber).Width(w).Render("Open-ended capstone - a human reviews your design in the Academy."), "")
		if s.SelfCheck != "" {
			lines = append(lines, lipgloss.NewStyle().Foreground(cMuted).Width(w).Render("Press v to run the optional self-check against your running stack."), "")
		}
	}
	if len(tasks) == 0 && s.Graded() {
		lines = append(lines, sMuted.Render("Press v to see the checks."))
	}
	tier := -1
	for i, t := range tasks {
		if t.Tier != tier && t.Tier > 0 {
			tier = t.Tier
			if i > 0 {
				lines = append(lines, "")
			}
			lines = append(lines, tierLabel(s, tier))
		}
		sel := focused && i == m.taskIx
		lines = append(lines, taskLine(t, sp, w, sel))
		if sel {
			if t.Kind == "drill" {
				lines = append(lines, indent(sFaint.Render("space: mark as practised"), "    "))
			}
		}
	}
	if len(lines) > h {
		lines = append(lines[:h-1], sFaint.Render("…"))
	}
	return strings.Join(lines, "\n")
}

func tierLabel(s *Section, n int) string {
	for _, t := range s.Tiers {
		if t.N == n {
			return sBrand.Render(fmt.Sprintf("TIER %d", n)) + sMuted.Render(" · "+t.Title)
		}
	}
	return sBrand.Render(fmt.Sprintf("TIER %d", n))
}

func taskLine(t Task, sp SectionProgress, w int, sel bool) string {
	icon := sFaint.Render("○")
	if t.Kind == "drill" {
		icon = sFaint.Render("◇")
		if sp.HasDrill(t.ID) {
			icon = sViolet.Render("◆")
		}
	} else {
		switch sp.TaskState(t.ID) {
		case 1:
			icon = sGreen.Render("✔")
		case -1:
			icon = sRed.Render("✘")
		}
	}
	id := sFaint.Render(padRight(t.ID, 4))
	tag := ""
	if t.Kind == "drill" {
		tag = sFaint.Render(" drill")
	}
	marker := " "
	text := sText.Render(t.Title)
	if sel {
		marker = sBrand.Render("›")
		text = sBold.Render(t.Title)
		id = sBrand.Render(padRight(t.ID, 4))
	}
	room := w - 2 - 2 - 5 - lipgloss.Width(tag)
	if sel {
		// the selected task expands to its full text
		body := lipgloss.NewStyle().Foreground(cText).Bold(true).Width(w - 8).Render(t.Title)
		rows := strings.Split(body, "\n")
		rows[0] = marker + icon + " " + id + " " + rows[0]
		for i := 1; i < len(rows); i++ {
			rows[i] = strings.Repeat(" ", 8) + rows[i]
		}
		rows[len(rows)-1] += tag
		return strings.Join(rows, "\n")
	}
	return marker + icon + " " + id + " " + truncateANSI(text, room) + tag
}

// ---- modals ---------------------------------------------------------------------

func (m *model) confirmView() string {
	c := m.confirm
	body := sBrand.Render(c.title) + "\n\n" + sMuted.Render(c.body) + "\n\n" + keyHint("y", "yes") + "   " + keyHint("n", "no")
	return modal.Render(body)
}

func (m *model) helpBox() string {
	rows := [][2]string{
		{"↑ ↓ / j k", "move, or scroll the lesson"},
		{"enter", "open (a course, a section, your sandbox)"},
		{"c", "continue where you left off (home)"},
		{"v", "check your work (also runs when you exit the sandbox)"},
		{"tab / 1-4", "switch Lesson · Tasks · Results · Solution"},
		{"→ ←", "focus the task list / the lesson (wide screens)"},
		{"space", "tick a self-checked drill"},
		{"s", "show the solution (try first!)"},
		{"r", "reset the section - fresh scenario"},
		{"x", "remove the section's sandbox"},
		{"n / p", "next / previous section"},
		{"esc", "back"},
		{"q", "quit - progress is saved in my-journey/progress.json"},
	}
	lines := []string{gradient("AMIGOSCODE", true) + sMuted.Render(" Academy · keys"), ""}
	for _, r := range rows {
		lines = append(lines, sKey.Render(padRight(r[0], 10))+"  "+sText.Render(r[1]))
	}
	lines = append(lines, "", sFaint.Render("How it works: read the lesson → enter opens a real sandbox →"),
		sFaint.Render("do the tasks → exit → you're graded instantly. Repeat."), "", sFaint.Render("press any key"))
	return modal.Render(strings.Join(lines, "\n"))
}

var modal = lipgloss.NewStyle().
	Border(lipgloss.RoundedBorder()).
	BorderForeground(cViolet5).
	Background(cBg).
	Padding(1, 3)

// ---- layout helpers -------------------------------------------------------------

// spread puts left and right on one line of width w.
func spread(left, right string, w int) string {
	gap := w - lipgloss.Width(left) - lipgloss.Width(right)
	if gap < 1 {
		return truncateANSI(left, w)
	}
	return left + strings.Repeat(" ", gap) + right
}

func indent(s, pre string) string {
	lines := strings.Split(s, "\n")
	for i := range lines {
		lines[i] = pre + lines[i]
	}
	return strings.Join(lines, "\n")
}

// hang prefixes the first line and aligns the rest under it.
func hang(prefix, body string) string {
	pad := strings.Repeat(" ", lipgloss.Width(prefix))
	lines := strings.Split(body, "\n")
	for i := range lines {
		if i == 0 {
			lines[i] = margin + prefix + lines[i]
		} else {
			lines[i] = margin + pad + lines[i]
		}
	}
	return strings.Join(lines, "\n")
}

// stick pins foot to the bottom of an h-line screen.
func stick(body, foot string, h int) string {
	bl := strings.Count(body, "\n") + 1
	fl := strings.Count(foot, "\n") + 1
	if gap := h - bl - fl; gap > 0 {
		body += strings.Repeat("\n", gap)
	}
	return body + "\n" + foot
}

// fit clips the frame to the terminal so nothing scrolls.
func fit(s string, w, h int) string {
	lines := strings.Split(s, "\n")
	if len(lines) > h {
		lines = lines[:h]
	}
	for i, l := range lines {
		if lipgloss.Width(l) > w {
			lines[i] = truncateANSI(l, w)
		}
	}
	return strings.Join(lines, "\n")
}

// clip hard-limits a block to w columns and h rows so a long code line can never
// wrap inside a panel and push the layout off screen.
func clip(s string, w, h int) string {
	lines := strings.Split(s, "\n")
	if len(lines) > h {
		lines = lines[:h]
	}
	for i, l := range lines {
		lines[i] = truncateANSI(l, w)
	}
	return strings.Join(lines, "\n")
}

func truncateANSI(s string, w int) string {
	if w <= 0 {
		return ""
	}
	if lipgloss.Width(s) <= w {
		return s
	}
	return xansi.Truncate(s, w, "…")
}

// overlay draws box centred over base.
func overlay(base, box string, w, h int) string {
	bl := strings.Split(base, "\n")
	for len(bl) < h {
		bl = append(bl, "")
	}
	ol := strings.Split(box, "\n")
	bw := lipgloss.Width(box)
	x := max((w-bw)/2, 0)
	y := max((h-len(ol))/2, 0)
	for i, line := range ol {
		row := y + i
		if row >= len(bl) {
			break
		}
		under := padRight(bl[row], w)
		left := xansi.Truncate(under, x, "")
		right := xansi.TruncateLeft(under, x+bw, "")
		bl[row] = left + "\x1b[0m" + line + "\x1b[0m" + right
	}
	return strings.Join(bl, "\n")
}

// labelBorder writes a label into a box's top border: ╭─ Lesson ──────╮
func labelBorder(box, label string, edge lipgloss.TerminalColor) string {
	lines := strings.SplitN(box, "\n", 2)
	if len(lines) < 2 {
		return box
	}
	w := lipgloss.Width(lines[0])
	lab := " " + label + " "
	if lipgloss.Width(lab)+4 > w {
		return box
	}
	e := lipgloss.NewStyle().Foreground(edge)
	top := e.Render("╭─") + sBrand.Render(lab) + e.Render(strings.Repeat("─", w-3-lipgloss.Width(lab))+"╮")
	return top + "\n" + lines[1]
}

func ago(ts string) string {
	t, err := time.Parse(time.RFC3339, ts)
	if err != nil {
		return ""
	}
	d := time.Since(t)
	switch {
	case d < time.Minute:
		return "just now"
	case d < time.Hour:
		return fmt.Sprintf("%dm ago", int(d.Minutes()))
	case d < 24*time.Hour:
		return fmt.Sprintf("%dh ago", int(d.Hours()))
	}
	return t.Format("2 Jan")
}
