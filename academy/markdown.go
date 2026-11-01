package main

import (
	"strconv"

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
	s.Code.Prefix = " "
	s.Code.Suffix = " "
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
		glamour.WithWordWrap(max(width-2, 20)),
		glamour.WithEmoji(),
	)
	if err != nil {
		return md
	}
	out, err := r.Render(md)
	if err != nil {
		return md
	}
	mdMemo[id] = mdCache{key: key, out: out}
	return out
}
