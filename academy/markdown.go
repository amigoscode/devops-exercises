package main

import (
	"regexp"
	"strconv"
	"strings"

	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/glamour/ansi"
	"github.com/charmbracelet/glamour/styles"
)

func sp(s string) *string { return &s }
func bp(b bool) *bool     { return &b }
func up(u uint) *uint     { return &u }

// brandStyle is glamour's dark style re-coloured for Amigoscode.
func brandStyle() ansi.StyleConfig {
	s := styles.DarkStyleConfig
	s.Document.Margin = up(1)
	s.Document.Color = sp("#ECE8F7")
	s.Document.BlockPrefix = ""
	s.Document.BlockSuffix = ""

	s.Heading.Color = sp("#A78BFA")
	s.Heading.Bold = bp(true)
	s.H1.Prefix = " "
	s.H1.Suffix = " "
	s.H1.Color = sp("#FFFFFF")
	s.H1.BackgroundColor = sp("#7C3AED")
	s.H1.Bold = bp(true)
	s.H2.Prefix = "▌ "
	s.H2.Color = sp("#C4B5FD")
	s.H3.Prefix = "› "
	s.H3.Color = sp("#A78BFA")
	s.H4.Prefix = "› "

	s.Strong.Color = sp("#FFFFFF")
	s.Strong.Bold = bp(true)
	s.Emph.Color = sp("#DDD6FE")
	s.Link.Color = sp("#22D3EE")
	s.LinkText.Color = sp("#22D3EE")
	s.HorizontalRule.Color = sp("#2E2650")
	s.HorizontalRule.Format = "\n────────────────────────────────────────\n"
	s.Item.BlockPrefix = "• "
	s.BlockQuote.Color = sp("#9A93B5")
	s.BlockQuote.Indent = up(1)
	s.BlockQuote.IndentToken = sp("┃ ")

	s.Code.Color = sp("#22D3EE")
	s.Code.BackgroundColor = sp("#211A3D")
	s.CodeBlock.Margin = up(1)
	if s.CodeBlock.Chroma != nil {
		ch := *s.CodeBlock.Chroma
		ch.Text.Color = sp("#ECE8F7")
		ch.Comment.Color = sp("#6B6488")
		ch.Keyword.Color = sp("#C084FC")
		ch.NameBuiltin.Color = sp("#22D3EE")
		ch.LiteralString.Color = sp("#86EFAC")
		ch.LiteralNumber.Color = sp("#FBBF24")
		ch.Background.BackgroundColor = sp("#16122A")
		s.CodeBlock.Chroma = &ch
	}
	s.Table.Color = sp("#ECE8F7")
	return s
}

type mdCache struct {
	key string
	out string
}

var mdMemo = map[string]mdCache{}

// RenderMarkdown renders md at the given width, caching per (id, width).
func RenderMarkdown(id, md string, width int) string {
	key := id + "@" + strconv.Itoa(width)
	if c, ok := mdMemo[id]; ok && c.key == key {
		return c.out
	}
	r, err := glamour.NewTermRenderer(
		glamour.WithStyles(brandStyle()),
		// leave slack for the margin and blockquote bars so no line ever exceeds the
		// panel (the panel would re-wrap it and leave a ragged break)
		glamour.WithWordWrap(max(width-6, 20)),
		glamour.WithEmoji(),
	)
	if err != nil {
		return md
	}
	out, err := r.Render(reflow(md))
	if err != nil {
		return md
	}
	mdMemo[id] = mdCache{key: key, out: out}
	return out
}

var blockStart = regexp.MustCompile(`^\s*([-*+]\s|\d+[.)]\s|#|\||>|` + "```" + `)`)

// reflow joins the hard-wrapped lines of each paragraph (and blockquote) so the
// renderer can wrap them to the panel width without leaving ragged breaks.
func reflow(md string) string {
	lines := strings.Split(md, "\n")
	var out []string
	inCode := false
	for _, l := range lines {
		t := strings.TrimSpace(l)
		if strings.HasPrefix(t, "```") {
			inCode = !inCode
			out = append(out, l)
			continue
		}
		if inCode || len(out) == 0 || t == "" {
			out = append(out, l)
			continue
		}
		prev := out[len(out)-1]
		pt := strings.TrimSpace(prev)
		switch {
		case pt == "" || strings.HasPrefix(pt, "```") || strings.HasPrefix(pt, "#") || strings.HasPrefix(pt, "|") ||
			strings.HasSuffix(prev, "  ") || pt == "---":
			out = append(out, l)
		case strings.HasPrefix(t, ">") && strings.HasPrefix(pt, ">"):
			out[len(out)-1] = prev + " " + strings.TrimSpace(strings.TrimPrefix(t, ">"))
		case blockStart.MatchString(l):
			out = append(out, l)
		case strings.HasPrefix(pt, ">"):
			out = append(out, l)
		default:
			out[len(out)-1] = prev + " " + t
		}
	}
	return strings.Join(out, "\n")
}
