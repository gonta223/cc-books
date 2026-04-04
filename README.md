# FlipBook UI

Your daily AI coding sessions, turned into a beautiful book you can flip through.

https://github.com/user-attachments/assets/placeholder-demo.gif

## What is this?

A [Claude Code](https://claude.ai/code) skill that reads your session logs and generates a page-flipping book in your browser.

- **Drag to flip** — grab pages with your mouse, stop mid-flip, release to complete or snap back
- **Paper sounds** — synthesized with Web Audio API (no audio files)
- **3D book feel** — CSS 3D transforms, spine shadow, page curl on hover
- **Touch support** — works on mobile
- **Zero dependencies** — single HTML file, no build, no libraries

## Setup (Claude Code users)

```bash
git clone https://github.com/gonta223/flipbook-ui.git
cp -r flipbook-ui/skill/ ~/.claude/skills/daily-flipbook/
```

Then in Claude Code:

```
/daily-flipbook
```

That's it. Claude reads your session logs, generates chapters, and opens the book in your browser.

### What gets generated

Claude Code scans today's session logs from:
- `~/.claude/projects/`
- `~/claude-data/projects/` (if `CLAUDE_CONFIG_DIR` is set)

Each session becomes a chapter: what you asked, what was built, what you learned. The output is a single HTML file at `/tmp/claude/daily-flipbook/YYYY-MM-DD.html`.

```
Your session logs (JSONL)
  → Claude extracts tasks & learnings
  → Generates chapters with code blocks, tips, quotes
  → Renders as a draggable flip-book
  → Opens in your browser
```

## Setup (without Claude Code)

Just open `index.html` in your browser. Edit the `pages` array to add your own content:

```javascript
const pages = [
  {
    front: `<div class="page-title">My Chapter</div>
            <div class="page-body"><p>Front side content</p></div>`,
    back:  `<div class="page-body"><p>Back side content</p></div>`,
    leftContent: `<p>Shown on left when flipped</p>`
  },
];
```

## Controls

| Action | Effect |
|--------|--------|
| Drag right half ← | Next page |
| Drag left half → | Previous page |
| Release past 50° | Complete flip |
| Release before 50° | Snap back |
| `←` `→` `Space` | Keyboard nav |
| Buttons | Nav buttons at bottom |

## Styling

Built-in CSS classes for book content:

| Class | What it does |
|-------|-------------|
| `.page-title` | Large chapter heading |
| `.chapter-label` | Small label like "第一章" |
| `.page-body` | Body text (add `.dropcap` to first `<p>` for drop cap) |
| `.code-block` | Dark code block (use `.comment` `.keyword` `.string` `.property` for syntax) |
| `.quote` | Blockquote with accent border |
| `.tip-box` | Highlighted tip box (`.tip-title` + `<ul>`) |
| `.comparison` | Side-by-side grid (`.col.good` / `.col.bad`) |
| `.divider` | Decorative separator |
| `.cover-front` | Book cover |

### Theming

```css
/* Cover color */
.cover-front { background: linear-gradient(145deg, #1a1520, #2a1f30); }

/* Accent color (chapter labels, tips, drop caps) */
.chapter-label, .tip-box .tip-title, .page-body .dropcap::first-letter { color: #D97B2F; }

/* Page background */
.page .front { background: linear-gradient(135deg, #fefcf7, #f5f0e8); }
```

### Sound

Adjust or disable in the `<script>`:

```javascript
g1.gain.setValueAtTime(0.4, ...);  // flip sound volume (0 = mute)
g.gain.value = 0.3;                // drag rustle volume (0 = mute)
```

## Project Structure

```
flipbook-ui/
├── index.html            # Standalone demo — open in browser, no setup needed
├── skill/
│   ├── SKILL.md          # Claude Code skill definition
│   ├── template.html     # HTML template with {{BOOK_TITLE}} / {{PAGES_DATA}} placeholders
│   └── generate.sh       # Session log collector (helper script)
├── LICENSE
└── README.md
```

## Browser Support

Chrome, Firefox, Safari, Edge (modern versions). Requires CSS 3D Transforms + Web Audio API.

## License

MIT
