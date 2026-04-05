# CC Books

Claude Codeのセッションログを自動で「本」にしてくれるOSS。3D本棚 + ページめくりUI。


## これは何？

[Claude Code](https://claude.ai/code) のスキルとして動作し、今日のセッションログを読み取って、ブラウザで読めるページめくり本を自動生成します。

- **ドラッグでめくる** ── マウスで掴んで引っ張る。途中で止められる。離すと完了 or バネで戻る
- **紙の音** ── Web Audio APIで合成（音声ファイル不要）
- **3Dの質感** ── CSS 3D transform、背表紙の影、ページカール
- **スマホ対応** ── タッチ操作でもめくれる
- **依存ゼロ** ── HTMLファイル1つ。ビルドもライブラリも不要

## 使い方（Claude Codeユーザー）

```bash
git clone https://github.com/gonta223/cc-books.git
cp -r flipbook-ui/skill/ ~/.claude/skills/daily-flipbook/
```

Claude Codeで:

```
/daily-flipbook
```

これだけ。Claudeが今日のセッションログを読み取り、章立てして本を生成し、ブラウザで開きます。

### 生成の流れ

```
セッションログ (JSONL)
  → Claudeがタスク・学びを抽出
  → コードブロック、引用、ティップス付きで章を生成
  → ドラッグでめくれるFlipBookとしてレンダリング
  → ブラウザで開く
```

ログの読み取り先:
- `~/.claude/projects/`（デフォルト）
- `~/claude-data/projects/`（`CLAUDE_CONFIG_DIR` 設定時）

出力先: `/tmp/claude/daily-flipbook/YYYY-MM-DD.html`

## 使い方（Claude Codeなし）

`index.html` をブラウザで開くだけでデモが見れます。コンテンツを変えたい場合は `pages` 配列を編集:

```javascript
const pages = [
  {
    front: `<div class="page-title">章タイトル</div>
            <div class="page-body"><p>表面のコンテンツ</p></div>`,
    back:  `<div class="page-body"><p>裏面のコンテンツ</p></div>`,
    leftContent: `<p>めくった後に左ページに表示される内容</p>`
  },
];
```

## 操作方法

| 操作 | 動作 |
|------|------|
| 右半分を左にドラッグ | 次のページ |
| 左半分を右にドラッグ | 前のページ |
| 50度以上めくって離す | めくり完了 |
| 50度未満で離す | バネで戻る |
| `←` `→` `Space` | キーボード操作 |
| ボタン | 下部のナビボタン |

## CSSクラス一覧

| クラス | 用途 |
|--------|------|
| `.page-title` | 章見出し（大） |
| `.chapter-label` | 章ラベル（「第一章」など） |
| `.page-body` | 本文（`.dropcap` でドロップキャップ） |
| `.code-block` | コードブロック（`.comment` `.keyword` `.string` `.property`） |
| `.quote` | 引用ブロック |
| `.tip-box` | ティップスボックス（`.tip-title` + `<ul>`） |
| `.comparison` | 2カラム比較（`.col.good` / `.col.bad`） |
| `.divider` | 装飾区切り線 |
| `.cover-front` | 表紙デザイン |

## カスタマイズ

### テーマカラー

```css
/* 表紙 */
.cover-front { background: linear-gradient(145deg, #1a1520, #2a1f30); }

/* アクセントカラー（章ラベル、ティップス、ドロップキャップ） */
.chapter-label, .tip-box .tip-title, .page-body .dropcap::first-letter { color: #D97B2F; }

/* ページ背景 */
.page .front { background: linear-gradient(135deg, #fefcf7, #f5f0e8); }
```

### 音量

```javascript
g1.gain.setValueAtTime(0.4, ...);  // めくり音（0でミュート）
g.gain.value = 0.3;                // ドラッグ時の擦れ音（0でミュート）
```

## プロジェクト構成

```
flipbook-ui/
├── index.html            # スタンドアロンデモ（そのまま開ける）
├── skill/
│   ├── SKILL.md          # Claude Codeスキル定義
│   ├── template.html     # HTMLテンプレート（プレースホルダ付き）
│   └── generate.sh       # セッションログ収集スクリプト
├── LICENSE
└── README.md
```

## ブラウザ対応

Chrome, Firefox, Safari, Edge（モダンブラウザ）。CSS 3D Transforms + Web Audio API が必要。

## ライセンス

MIT

---

# CC Books (English)

Your daily AI coding sessions, turned into a beautiful book you can flip through.

## What is this?

A [Claude Code](https://claude.ai/code) skill that reads your session logs and generates a page-flipping book in your browser.

- **Drag to flip** — grab pages with your mouse, stop mid-flip, release to complete or snap back
- **Paper sounds** — synthesized with Web Audio API (no audio files)
- **3D book feel** — CSS 3D transforms, spine shadow, page curl on hover
- **Touch support** — works on mobile
- **Zero dependencies** — single HTML file, no build, no libraries

## Setup (Claude Code users)

```bash
git clone https://github.com/gonta223/cc-books.git
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

## License

MIT
