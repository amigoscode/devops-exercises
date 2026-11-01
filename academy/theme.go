package main

// Amigoscode dark theme: deep navy-violet canvas, violet brand ramp, cyan accent.

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

var (
	cBg       = lipgloss.Color("#0D0B1A")
	cSurface  = lipgloss.Color("#16122A")
	cRaised   = lipgloss.Color("#211A3D")
	cBorder   = lipgloss.Color("#2E2650")
	cViolet9  = lipgloss.Color("#5B21B6")
	cViolet   = lipgloss.Color("#7C3AED")
	cViolet5  = lipgloss.Color("#8B5CF6")
	cViolet3  = lipgloss.Color("#A78BFA")
	cViolet1  = lipgloss.Color("#DDD6FE")
	cCyan     = lipgloss.Color("#22D3EE")
	cPink     = lipgloss.Color("#E879F9")
	cGreen    = lipgloss.Color("#34D399")
	cRed      = lipgloss.Color("#F87171")
	cAmber    = lipgloss.Color("#FBBF24")
	cText     = lipgloss.Color("#ECE8F7")
	cMuted    = lipgloss.Color("#9A93B5")
	cFaint    = lipgloss.Color("#5E577A")
	bgHex     = "#0D0B1A"
	gradStops = []string{"#C4B5FD", "#A78BFA", "#8B5CF6", "#7C3AED", "#A855F7", "#E879F9"}
)

var (
	sText   = lipgloss.NewStyle().Foreground(cText)
	sMuted  = lipgloss.NewStyle().Foreground(cMuted)
	sFaint  = lipgloss.NewStyle().Foreground(cFaint)
	sBold   = lipgloss.NewStyle().Foreground(cText).Bold(true)
	sViolet = lipgloss.NewStyle().Foreground(cViolet3)
	sBrand  = lipgloss.NewStyle().Foreground(cViolet5).Bold(true)
	sCyan   = lipgloss.NewStyle().Foreground(cCyan)
	sGreen  = lipgloss.NewStyle().Foreground(cGreen)
	sRed    = lipgloss.NewStyle().Foreground(cRed)
	sAmber  = lipgloss.NewStyle().Foreground(cAmber)

	sPanel = lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(cBorder).
		Padding(0, 1)
	sPanelFocus = sPanel.BorderForeground(cViolet5)

	sPill = lipgloss.NewStyle().
		Foreground(lipgloss.Color("#FFFFFF")).
		Background(cViolet).
		Bold(true).
		Padding(0, 1)
	sPillDim = lipgloss.NewStyle().
			Foreground(cMuted).
			Background(cRaised).
			Padding(0, 1)
	sKey = lipgloss.NewStyle().
		Foreground(cViolet1).
		Background(cRaised).
		Bold(true).
		Padding(0, 1)
	sSelected = lipgloss.NewStyle().Background(cSurface)
)

var logoLines = []string{
	"▄▀█ █▀▄▀█ █ █▀▀ █▀█ █▀ █▀▀ █▀█ █▀▄ █▀▀",
	"█▀█ █ ▀ █ █ █▄█ █▄█ ▄█ █▄▄ █▄█ █▄▀ ██▄",
}

// Logo renders the wordmark with a left-to-right violet gradient.
func Logo() string {
	var out []string
	for _, line := range logoLines {
		out = append(out, gradient(line, true))
	}
	return strings.Join(out, "\n")
}

func gradient(s string, bold bool) string {
	runes := []rune(s)
	var b strings.Builder
	n := len(runes)
	for i, r := range runes {
		if r == ' ' {
			b.WriteRune(r)
			continue
		}
		stop := gradStops[i*(len(gradStops)-1)/max(n-1, 1)]
		st := lipgloss.NewStyle().Foreground(lipgloss.Color(stop))
		if bold {
			st = st.Bold(true)
		}
		b.WriteString(st.Render(string(r)))
	}
	return b.String()
}

// Bar is a progress bar: violet fill, faint track.
func Bar(done, total, width int) string {
	if width < 1 {
		return ""
	}
	filled := 0
	if total > 0 {
		filled = done * width / total
	}
	if done > 0 && filled == 0 {
		filled = 1
	}
	fill := ""
	for i := 0; i < filled; i++ {
		stop := gradStops[1+i*(len(gradStops)-2)/max(width-1, 1)]
		fill += lipgloss.NewStyle().Foreground(lipgloss.Color(stop)).Render("━")
	}
	if total > 0 && done == total {
		fill = sGreen.Render(strings.Repeat("━", width))
		filled = width
	}
	return fill + lipgloss.NewStyle().Foreground(cBorder).Render(strings.Repeat("━", width-filled))
}

func statusIcon(st Status) string {
	switch st {
	case Done:
		return sGreen.Render("✔")
	case InProgress:
		return sAmber.Render("◐")
	}
	return sFaint.Render("○")
}

func keyHint(k, label string) string {
	return sKey.Render(k) + " " + sMuted.Render(label)
}

func truncate(s string, w int) string {
	if w <= 1 {
		return ""
	}
	if lipgloss.Width(s) <= w {
		return s
	}
	r := []rune(s)
	for len(r) > 0 && lipgloss.Width(string(r))+1 > w {
		r = r[:len(r)-1]
	}
	return string(r) + "…"
}

func padRight(s string, w int) string {
	if gap := w - lipgloss.Width(s); gap > 0 {
		return s + strings.Repeat(" ", gap)
	}
	return s
}
