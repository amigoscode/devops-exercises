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
	if m.scr == scrBrowse {
		v = m.viewBrowse()
	} else {
		v = m.viewExercise()
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
	return truncateANSI(margin+strings.Join(hints, "   "), m.w)
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

// box draws a rounded panel with a label in its top border. Focused panels are violet.
func box(content, label string, w, h int, focused bool) string {
	st, edge := sPanel, cBorder
	if focused {
		st, edge = sPanelFocus, cViolet5
	}
	inner := clip(content, w-4, h-2)
	b := st.Width(w - 2).Height(h - 2).MaxHeight(h).Render(inner)
	if label != "" {
		b = labelBorder(b, label, edge, focused)
	}
	return b
}

// ---- browse ---------------------------------------------------------------------

func (m *model) viewBrowse() string {
	W, H := m.w, m.h
	var top []string
	logo := strings.Split(Logo(), "\n")
	top = append(top, "", spread(margin+logo[0], m.dockerBadge()+margin, W))
	top = append(top, margin+logo[1]+"  "+sBold.Render("Academy"))
	top = append(top, margin+sMuted.Render("Hands-on, auto-graded exercises · Linux, Git, Docker and SQL, in real sandboxes"), "")

	// progress + continue
	done, total := 0, 0
	for _, c := range m.courses {
		d, t := m.courseCounts(c)
		done, total = done+d, total+t
	}
	cardW := min(W-4, 120)
	pct := 0
	if total > 0 {
		pct = done * 100 / total
	}
	stat := sBold.Render(fmt.Sprintf("%d/%d", done, total)) + sMuted.Render(" sections done  ") + sBrand.Render(fmt.Sprintf("%d%%", pct))
	line1 := Bar(done, total, cardW-8-lipgloss.Width(stat)) + "  " + stat
	line2 := sGreen.Render("★ Every section complete. Time to build something real.")
	if s := m.continueTarget(); s != nil {
		label := "Start here"
		if done > 0 || m.anyProgress() {
			label = "Continue"
		}
		line2 = spread(sBrand.Render("▶ "+label)+"  "+sText.Render(s.Course.Title)+sFaint.Render(" › ")+sBold.Render(s.Num+" "+s.Title),
			keyHint("c", "jump in"), cardW-4)
	}
	top = append(top, indent(box(line1+"\n"+line2, "Your progress", cardW, 4, false), margin), "")

	// how-it-works strip, only when there is room
	var strip []string
	if H >= 34 {
		step := func(n, txt string) string { return sPill.Render(n) + " " + sText.Render(txt) }
		arrow := sFaint.Render("  ─▶  ")
		strip = []string{"", margin + step("1", "Pick a section") + arrow + step("2", "Read the questions") + arrow +
			step("3", "enter: do them in a real sandbox") + arrow + step("4", "exit: checked instantly")}
	}

	// columns
	topLines := strings.Count(strings.Join(top, "\n"), "\n") + 1
	colH := max(H-topLines-len(strip)-2, 6)
	c := m.courses[m.courseIx]
	var cols string
	if W >= 96 {
		// wide enough for the longest course name (marker, number, count, borders),
		// but leaving the section list most of the screen
		need := 0
		for _, c := range m.courses {
			need = max(need, lipgloss.Width(c.Title)+18)
		}
		cw := min(max(cardW/3+4, need), cardW*2/5+4)
		sw := cardW - cw - 1
		cols = lipgloss.JoinHorizontal(lipgloss.Top,
			box(m.courseList(cw-4), "Courses", cw, colH, m.col == 0), " ",
			box(m.sectionList(c, sw-4, colH-2), c.Title, sw, colH, m.col == 1))
	} else if m.col == 0 {
		cols = box(m.courseList(cardW-4), "Courses", cardW, colH, true)
	} else {
		cols = box(m.sectionList(c, cardW-4, colH-2), c.Title, cardW, colH, true)
	}

	body := strings.Join(top, "\n") + "\n" + indent(cols, margin) + strings.Join(strip, "\n")
	var idle string
	var hints []string
	if m.col == 0 {
		idle = sMuted.Render("Choose a course, then press ") + sBold.Render("→") + sMuted.Render(" to see its sections.")
		hints = []string{keyHint("↑↓", "choose course"), keyHint("→ / enter", "see sections"), keyHint("c", "continue"), keyHint("?", "help"), keyHint("q", "quit")}
	} else {
		s := c.Sections[m.sectionIx]
		idle = sMuted.Render("Press ") + sBold.Render("enter") + sMuted.Render(" to start ") + sText.Render(s.Num+" "+s.Title)
		hints = []string{keyHint("↑↓", "choose section"), keyHint("enter", "start"), keyHint("← / esc", "courses"), keyHint("c", "continue"), keyHint("?", "help"), keyHint("q", "quit")}
	}
	return stick(body, m.statusLine(idle)+"\n"+m.footer(hints...), H)
}

func (m *model) courseList(w int) string {
	var rows []string
	for i, c := range m.courses {
		d, t := m.courseCounts(c)
		sel := i == m.courseIx
		marker, num, title := "  ", sFaint.Render(c.Num), sText.Render(c.Title)
		if sel {
			marker, num, title = sBrand.Render("▶ "), sBrand.Render(c.Num), sBold.Render(c.Title)
		}
		count := sMuted.Render(fmt.Sprintf("%d/%d", d, t))
		if d == t {
			count = sGreen.Render("✔ done")
		}
		left := marker + num + "  " + title
		rows = append(rows, spread(truncateANSI(left, w-lipgloss.Width(count)-2), count, w))
	}
	return strings.Join(rows, "\n")
}

func (m *model) sectionList(c *Course, w, h int) string {
	var rows []string
	for i, s := range c.Sections {
		sp := m.prog.Peek(s.Key())
		sel := i == m.sectionIx
		marker, title := "  ", sText.Render(s.Title)
		if sel {
			marker, title = "  ", sBold.Render(s.Title)
			if m.col == 1 {
				marker = sBrand.Render("▶ ")
			}
		}
		right := ""
		d, t := m.questionCounts(s)
		switch {
		case !s.Graded():
			right = sAmber.Render("reviewed")
		case sp.Status() == Done:
			right = sGreen.Render("✔ done")
		case t > 0:
			right = sMuted.Render(fmt.Sprintf("%d/%d", d, t))
		}
		if st := m.containerState(s); st == "running" {
			right = sGreen.Render("● ") + right
		}
		left := marker + statusIcon(sp.Status()) + " " + sFaint.Render(s.Num) + "  " + title
		rows = append(rows, spread(truncateANSI(left, w-12), right, w))
	}

	// preview of the highlighted section underneath
	s := c.Sections[m.sectionIx]
	env := sCyan.Render("◆ Ubuntu sandbox")
	if c.PSQL {
		env = sCyan.Render("◆ PostgreSQL sandbox")
	}
	if c.Kind == KindHost {
		env = sCyan.Render("◆ Your own Docker")
	}
	graded, drills := 0, 0
	for _, t := range s.Tasks {
		if t.Kind == "drill" {
			drills++
		} else {
			graded++
		}
	}
	facts := fmt.Sprintf("%d questions", graded)
	if drills > 0 {
		facts += fmt.Sprintf(" · %d drills", drills)
	}
	if !s.Graded() {
		facts = "open-ended · reviewed by a human"
	}
	preview := []string{"", sFaint.Render(strings.Repeat("─", w)), sBold.Render(s.Num+" · "+s.Title) + "  " + sMuted.Render(facts) + "  " + env}
	room := h - len(rows) - len(preview)
	if room > 0 {
		blurb := lipgloss.NewStyle().Foreground(cMuted).Width(w).Render(s.Blurb)
		bl := strings.Split(blurb, "\n")
		if len(bl) > room {
			bl = bl[:room]
			bl[room-1] = truncateANSI(bl[room-1]+" …", w)
		}
		preview = append(preview, bl...)
	}
	return strings.Join(append(rows, preview...), "\n")
}

// ---- exercise -------------------------------------------------------------------

func (m *model) viewExercise() string {
	s := m.sec
	W, H := m.w, m.h
	sp := m.prog.Peek(s.Key())
	qs := m.questions()
	d, t := m.questionCounts(s)

	// title row
	pill := sPillDim.Render("not started")
	switch {
	case !s.Graded():
		pill = lipgloss.NewStyle().Foreground(lipgloss.Color("#2A1A00")).Background(cAmber).Bold(true).Padding(0, 1).Render("reviewed by a human")
	case sp.Status() == Done:
		pill = lipgloss.NewStyle().Foreground(lipgloss.Color("#06281C")).Background(cGreen).Bold(true).Padding(0, 1).Render("✔ complete")
	case sp.Started || d > 0:
		pill = lipgloss.NewStyle().Foreground(cText).Background(cRaised).Padding(0, 1).Render("in progress")
	}
	sandbox := ""
	switch m.containerState(s) {
	case "running":
		sandbox = sGreen.Render("● sandbox ready") + "  "
	case "exited":
		sandbox = sAmber.Render("● sandbox paused") + "  "
	}
	progress := ""
	if t > 0 {
		progress = Bar(d, t, 14) + " " + sBold.Render(fmt.Sprintf("%d/%d", d, t)) + sMuted.Render(" done") + "   "
	}
	title := margin + sPill.Render(s.Num) + " " + sBold.Render(s.Title)
	right := sandbox + progress + pill + margin
	if s.MapsTo != "" {
		room := W - lipgloss.Width(title) - lipgloss.Width(right) - 4
		if room > 20 {
			title += "  " + sFaint.Render(truncate(s.MapsTo, room))
		}
	}
	titleRow := spread(title, right, W)

	// question list on top
	boxW := W - 4
	inner := boxW - 4
	rows, selRow := m.questionRows(qs, inner)
	avail := H - 6 // topbar, gap, title, status, footer, + 1 spare
	maxQ := max(3, avail*45/100)
	qh := min(len(rows), maxQ)
	if qh < 1 {
		qh = 1
	}
	start := 0
	if selRow >= qh {
		start = selRow - qh + 1
	}
	if start+qh > len(rows) {
		start = max(len(rows)-qh, 0)
	}
	visible := rows[start:min(start+qh, len(rows))]
	qLabel := fmt.Sprintf("Questions  %d/%d", d, t)
	if len(rows) > qh {
		qLabel += fmt.Sprintf("  ·  %d-%d of %d lines", start+1, start+len(visible), len(rows))
	}
	if t == 0 {
		qLabel = "Questions"
	}
	qBox := box(strings.Join(visible, "\n"), qLabel, boxW, qh+2, true)

	// the selected question (or lesson / solution) underneath
	detailH := avail - (qh + 2)
	m.syncViewport(inner, detailH-2)
	label := m.paneLabel(qs)
	if m.vp.TotalLineCount() > m.vp.Height {
		label += fmt.Sprintf("  ·  %d%%  PgUp/PgDn", int(m.vp.ScrollPercent()*100))
	}
	dBox := box(m.vp.View(), label, boxW, detailH, false)

	return strings.Join([]string{
		m.topBar(s.Course.Title, s.Num+" "+s.Title),
		"",
		titleRow,
		indent(qBox, margin),
		indent(dBox, margin),
		m.statusLine(m.exerciseIdle(sp)),
		m.footer(m.exerciseHints(qs)...),
	}, "\n")
}

// questionRows renders the list with tier headings and returns the selected row index.
func (m *model) questionRows(qs []Task, w int) ([]string, int) {
	s := m.sec
	sp := m.prog.Peek(s.Key())
	var rows []string
	sel := 0
	if len(qs) == 0 {
		msg := "Open-ended capstone - there is no checklist. Read the brief below, build it, and submit it in the Academy."
		if s.Graded() {
			msg = "The questions for this section are in the lesson below. Press v after you've worked through it."
		}
		return []string{lipgloss.NewStyle().Foreground(cMuted).Width(w).Render(msg)}, 0
	}
	tier := -1
	for i, q := range qs {
		if q.Tier != tier && q.Tier > 0 {
			tier = q.Tier
			rows = append(rows, tierLabel(s, tier))
		}
		if i == m.q {
			sel = len(rows)
		}
		rows = append(rows, questionLine(q, sp, w, i == m.q))
	}
	return rows, sel
}

func questionLine(q Task, sp SectionProgress, w int, sel bool) string {
	icon := sFaint.Render("○")
	if q.Kind == "drill" {
		icon = sFaint.Render("◇")
		if sp.HasDrill(q.ID) {
			icon = sViolet.Render("◆")
		}
	} else {
		switch sp.TaskState(q.ID) {
		case 1:
			icon = sGreen.Render("✔")
		case -1:
			icon = sRed.Render("✘")
		}
	}
	marker := "  "
	id := sFaint.Render(padRight(q.ID, 4))
	text := sText.Render(q.Text)
	if sel {
		marker = sBrand.Render("▶ ")
		id = sBrand.Render(padRight(q.ID, 4))
		text = sBold.Render(q.Text)
	}
	tag := ""
	if q.Kind == "drill" {
		tag = sFaint.Render("  drill")
	}
	return marker + icon + " " + id + " " + truncateANSI(text, w-9-lipgloss.Width(tag)) + tag
}

func tierLabel(s *Section, n int) string {
	for _, t := range s.Tiers {
		if t.N == n {
			return sBrand.Render(fmt.Sprintf("TIER %d", n)) + sMuted.Render(" · "+t.Title)
		}
	}
	return sBrand.Render(fmt.Sprintf("TIER %d", n))
}

func (m *model) paneLabel(qs []Task) string {
	switch {
	case m.pane == paneLesson || len(qs) == 0:
		return "Full lesson"
	case m.pane == paneSolution:
		return "Solution"
	}
	q := qs[min(m.q, len(qs)-1)]
	kind := "auto-checked"
	if q.Kind == "drill" {
		kind = "drill · self-checked"
	}
	return "Question " + q.ID + "  ·  " + kind
}

func (m *model) exerciseIdle(sp SectionProgress) string {
	switch {
	case !m.sec.Graded():
		return sMuted.Render("Build it, then submit it in the Academy for review.")
	case sp.Status() == Done:
		return sGreen.Render("✔ Section complete. ") + sMuted.Render("Press ") + sBold.Render("n") + sMuted.Render(" for the next one.")
	case sp.Started:
		return sMuted.Render("Press ") + sBold.Render("enter") + sMuted.Render(" to go back into your sandbox. Type ") + sBold.Render("exit") + sMuted.Render(" there and your work is checked.")
	}
	return sBrand.Render("▶ ") + sMuted.Render("Read the questions, then press ") + sBold.Render("enter") + sMuted.Render(" to open your sandbox - they're printed there too.")
}

func (m *model) exerciseHints(qs []Task) []string {
	h := []string{keyHint("↑↓", "question"), keyHint("enter", "open sandbox"), keyHint("v", "check")}
	if m.q < len(qs) && qs[m.q].Kind == "drill" && m.pane == paneQuestion {
		h = append(h, keyHint("space", "tick drill"))
	}
	if m.pane == paneLesson {
		h = append(h, keyHint("l", "back to question"))
	} else {
		h = append(h, keyHint("l", "full lesson"))
	}
	if m.sec.Solutions != "" {
		h = append(h, keyHint("s", "solution"))
	}
	return append(h, keyHint("esc", "back"), keyHint("?", "more"))
}

func (m *model) syncViewport(w, h int) {
	w, h = max(w, 10), max(h, 1)
	sp := m.prog.Peek(m.sec.Key())
	key := fmt.Sprintf("%s|%d|%d|%d|%d|%s|%v|%s", m.sec.Key(), m.pane, w, h, m.q, sp.LastVerified, sp.Drills, m.lastErr[m.sec.Key()])
	m.vp.Width, m.vp.Height = w, h
	if key == m.vpKey {
		return
	}
	m.vpKey = key
	qs := m.questions()
	var content string
	switch {
	case m.pane == paneSolution:
		content = RenderMarkdown(m.sec.Key()+"#solution", readFile(m.sec.Solutions), w)
	case m.pane == paneLesson || len(qs) == 0:
		content = RenderMarkdown(m.sec.Key()+"#lesson", m.sec.Lesson, w)
	default:
		content = m.questionDetail(qs[min(m.q, len(qs)-1)], w)
	}
	if e := m.lastErr[m.sec.Key()]; e != "" {
		content = sRed.Render("✘ Something went wrong") + "\n" + lipgloss.NewStyle().Foreground(cMuted).Width(w).Render(e) +
			"\n" + sFaint.Render("Is Docker running? Try again, or press r to start the section over.") + "\n\n" + content
	}
	m.vp.SetContent(content)
}

// questionDetail: where you stand on this question, then the question itself.
func (m *model) questionDetail(q Task, w int) string {
	s := m.sec
	sp := m.prog.Peek(s.Key())
	wrap := lipgloss.NewStyle().Width(w - 4)
	var out []string
	rw := w

	if q.Kind == "drill" {
		if sp.HasDrill(q.ID) {
			out = append(out, " "+sViolet.Render("◆ Practised")+sMuted.Render(" - nice. Press space to untick."))
		} else {
			out = append(out, " "+sFaint.Render("◇ Drill - nothing to grade. Practise it in your sandbox, then press space to tick it off."))
		}
	} else if c, ok := m.check(q.ID); ok {
		if c.OK {
			out = append(out, " "+sGreen.Render("✔ Done")+sMuted.Render(" - "+c.Text))
		} else {
			out = append(out, " "+sRed.Render("✘ Not done yet"), indent(wrap.Foreground(cViolet1).Render(c.Text), "   "))
		}
	} else {
		out = append(out, " "+sFaint.Render("○ Not checked yet - do it in your sandbox, then type exit (or press v)."))
	}

	for _, t := range s.Tiers {
		if t.N == q.Tier && t.Intro != "" {
			out = append(out, "", trimBlank(RenderMarkdown(fmt.Sprintf("%s#tier%d", s.Key(), t.N), t.Intro, rw)))
		}
	}
	out = append(out, "", trimBlank(RenderMarkdown(s.Key()+"#q"+q.ID, q.Detail, rw)))
	return strings.Join(out, "\n")
}

// shellBanner is printed when the sandbox opens (and by `questions` inside it).
func (m *model) shellBanner(s *Section) string {
	sp := m.prog.Peek(s.Key())
	w := min(max(m.w-6, 50), 100)
	var b []string
	logo := strings.Split(Logo(), "\n")
	b = append(b, "", margin+logo[0], margin+logo[1]+"  "+sBold.Render("Academy"), "",
		margin+sBold.Render(s.Course.Title+" › "+s.Num+" "+s.Title))
	where := "an Ubuntu sandbox - your work lives in ~/sandbox"
	if s.Course.PSQL {
		where = "psql, connected to this section's database. Save a query with \\w 1.1.sql"
	}
	if s.Course.Kind == KindHost {
		where = "a terminal wired to your real Docker"
	}
	b = append(b, margin+sMuted.Render("You are in "+where+"."), "")
	if len(s.Tasks) > 0 {
		b = append(b, margin+sBrand.Render("YOUR QUESTIONS"))
		tier := -1
		for _, q := range s.Tasks {
			if q.Tier != tier && q.Tier > 0 {
				tier = q.Tier
				b = append(b, "", margin+tierLabel(s, tier))
				for _, t := range s.Tiers {
					if t.N == tier && t.Intro != "" {
						b = append(b, indent(lipgloss.NewStyle().Foreground(cMuted).Width(w-4).Render(strings.Trim(plain(unquote(t.Intro)), "_")), margin+"  "))
					}
				}
			}
			icon := "○"
			switch {
			case q.Kind == "drill" && sp.HasDrill(q.ID):
				icon = sViolet.Render("◆")
			case q.Kind == "drill":
				icon = "◇"
			case sp.TaskState(q.ID) == 1:
				icon = sGreen.Render("✔")
			}
			var lines []string
			for i, part := range detailParts(q.Detail) {
				if part.code {
					for _, cl := range strings.Split(part.text, "\n") {
						lines = append(lines, sCyan.Render("  "+cl))
					}
					continue
				}
				text := part.text
				if i == 0 && q.Kind == "drill" {
					text += " (drill)"
				}
				lines = append(lines, strings.Split(lipgloss.NewStyle().Foreground(cText).Width(w-10).Render(text), "\n")...)
			}
			for i := range lines {
				if i == 0 {
					lines[i] = margin + "  " + icon + " " + sBrand.Render(padRight(q.ID, 4)) + " " + lines[i]
				} else {
					lines[i] = margin + "         " + lines[i]
				}
			}
			b = append(b, lines...)
		}
		b = append(b, "")
	}
	qCmd, cCmd := "questions", "check"
	if s.Course.PSQL {
		qCmd, cCmd = ":questions", ":check"
	}
	b = append(b, margin+sFaint.Render(strings.Repeat("─", w)),
		margin+sMuted.Render("Type ")+sBold.Render(qCmd)+sMuted.Render(" to see these again  ·  ")+
			sBold.Render(cCmd)+sMuted.Render(" to check your work  ·  ")+
			sBold.Render("exit")+sMuted.Render(" to go back (progress is saved)"), "", "")
	return "\x1b[2J\x1b[H" + strings.Join(b, "\n")
}

type part struct {
	text string
	code bool
}

// detailParts turns a question's markdown into plain paragraphs and code blocks,
// for printing in the sandbox where markdown isn't rendered.
func detailParts(md string) []part {
	var out []part
	var buf []string
	inCode := false
	flush := func(code bool) {
		t := strings.Join(buf, "\n")
		if !code {
			t = plain(unquote(t))
		}
		if strings.TrimSpace(t) != "" {
			out = append(out, part{t, code})
		}
		buf = nil
	}
	for _, l := range strings.Split(md, "\n") {
		if strings.HasPrefix(strings.TrimSpace(l), "```") {
			flush(inCode)
			inCode = !inCode
			continue
		}
		if !inCode && strings.TrimSpace(l) == "" {
			flush(false)
			continue
		}
		buf = append(buf, l)
	}
	flush(inCode)
	return out
}

// trimBlank drops leading/trailing lines that are empty or only padding.
func trimBlank(s string) string {
	lines := strings.Split(s, "\n")
	for len(lines) > 0 && strings.TrimSpace(StripANSI(lines[0])) == "" {
		lines = lines[1:]
	}
	for len(lines) > 0 && strings.TrimSpace(StripANSI(lines[len(lines)-1])) == "" {
		lines = lines[:len(lines)-1]
	}
	return strings.Join(lines, "\n")
}

func unquote(md string) string {
	lines := strings.Split(md, "\n")
	for i, l := range lines {
		lines[i] = strings.TrimPrefix(strings.TrimPrefix(l, ">"), " ")
	}
	return strings.Join(lines, "\n")
}

// ---- modals ---------------------------------------------------------------------

func (m *model) confirmView() string {
	c := m.confirm
	body := sBrand.Render(c.title) + "\n\n" + sMuted.Render(c.body) + "\n\n" + keyHint("y", "yes") + "   " + keyHint("n", "no")
	return modal.Render(body)
}

func (m *model) helpBox() string {
	section := func(t string) string { return "\n" + sBrand.Render(t) }
	row := func(k, d string) string { return sKey.Render(padRight(k, 11)) + "  " + sText.Render(d) }
	lines := []string{
		gradient("AMIGOSCODE", true) + sMuted.Render(" Academy · how to get around"),
		section("EVERYWHERE"),
		row("↑ ↓", "move"),
		row("→ / enter", "go in"),
		row("← / esc", "go back"),
		row("q", "quit - progress is saved to my-journey/progress.json"),
		section("BROWSING"),
		row("c", "continue where you left off"),
		section("IN AN EXERCISE"),
		row("↑ ↓", "pick a question - its details show underneath"),
		row("enter", "open your sandbox (the questions are printed there too)"),
		row("check", "(inside the sandbox) check your work without leaving"),
		row("exit", "(inside the sandbox) go back - your work is checked and saved"),
		row("v", "check your work again"),
		row("space", "tick off a drill you've practised"),
		row("l", "show the full lesson"),
		row("s", "show the solution (try first!)"),
		row("PgUp PgDn", "scroll the panel underneath (or use the mouse)"),
		row("n / p", "next / previous section"),
		row("r / x", "start over / remove the sandbox"),
		"", sFaint.Render("press any key"),
	}
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

// labelBorder writes a label into a box's top border: ╭─ Questions ──────╮
func labelBorder(b, label string, edge lipgloss.TerminalColor, focused bool) string {
	lines := strings.SplitN(b, "\n", 2)
	if len(lines) < 2 {
		return b
	}
	w := lipgloss.Width(lines[0])
	lab := " " + truncate(label, w-6) + " "
	e := lipgloss.NewStyle().Foreground(edge)
	ls := sMuted
	if focused {
		ls = sBrand
	}
	top := e.Render("╭─") + ls.Render(lab) + e.Render(strings.Repeat("─", max(w-3-lipgloss.Width(lab), 0))+"╮")
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
