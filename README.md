# CC Books

AIコーディングエージェントのセッションログを自動で「本」にしてくれるOSS。3D本棚 + ページめくりUI。

**対応エージェント:** Claude Code / OpenAI Codex CLI / GitHub Copilot CLI


## これは何？

AIコーディングエージェント（Claude Code, Codex, Copilot）のセッションログを読み取って、ブラウザで読めるページめくり本を自動生成します。

- **マルチエージェント対応** ── Claude Code, Codex CLI, Copilot CLI のログを統合
- **ドラッグでめくる** ── マウスで掴んで引っ張る。途中で止められる。離すと完了 or バネで戻る
- **紙の音** ── Web Audio APIで合成（音声ファイル不要）
- **3Dの質感** ── CSS 3D transform、背表紙の影、ページカール
- **スマホ対応** ── タッチ操作でもめくれる
- **依存ゼロ** ── HTMLファイル1つ。ビルドもライブラリも不要

## 対応エージェントとログの場所

| エージェント | ログの場所 | 形式 |
|-------------|-----------|------|
| Claude Code | `~/.claude/projects/**/*.jsonl` | JSONL |
| Claude Code | `~/claude-data/projects/**/*.jsonl`（`CLAUDE_CONFIG_DIR`設定時） | JSONL |
| Codex CLI | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | JSONL |
| Copilot CLI | `~/.copilot/session-state/{id}/events.jsonl` | JSONL |

## 使い方（Claude Codeユーザー）

```bash
git clone https://github.com/hatyibei/cc-books.git
cp -r cc-books/skill/ ~/.claude/skills/daily-flipbook/
```

Claude Codeで:

```
/daily-flipbook
```

これだけ。全エージェントのセッションログを読み取り、章立てして本を生成し、ブラウザで開きます。

## 使い方（Codex CLIユーザー）

```bash
git clone https://github.com/hatyibei/cc-books.git
cd cc-books
./skill/generate.sh           # 今日のログを収集
```

収集されたログをCodexに渡して本を生成:
```bash
codex "$(cat /tmp/flipbook_sessions_$(date +%Y-%m-%d).txt) を読んで、skill/template.html をベースにFlipBook HTMLを生成して /tmp/claude/daily-flipbook/$(date +%Y-%m-%d).html に出力して"
```

## 使い方（Copilot CLIユーザー）

```bash
git clone https://github.com/hatyibei/cc-books.git
cd cc-books
./skill/generate.sh           # 今日のログを収集
```

収集されたログをCopilotに渡して本を生成:
```bash
copilot "Read /tmp/flipbook_sessions_$(date +%Y-%m-%d).txt and generate a FlipBook HTML based on skill/template.html. Output to /tmp/claude/daily-flipbook/$(date +%Y-%m-%d).html"
```

### 生成の流れ

```
セッションログ (JSONL)
  ├─ Claude Code (~/.claude/projects/)
  ├─ Codex CLI   (~/.codex/sessions/)
  └─ Copilot CLI (~/.copilot/session-state/)
        ↓
  AIがタスク・学びを抽出
        ↓
  コードブロック、引用、ティップス付きで章を生成
        ↓
  ドラッグでめくれるFlipBookとしてレンダリング
        ↓
  ブラウザで開く
```

出力先: `/tmp/claude/daily-flipbook/YYYY-MM-DD.html`

### 自動生成（毎日勝手に貯まる）

毎日23:55に自動でその日の本を生成するcronを設定できます:

```bash
# macOS (launchd)
cp skill/com.cc-books.daily.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.cc-books.daily.plist

# Linux (cron)
crontab -e
# 55 23 * * * /path/to/cc-books/skill/daily-cron.sh
```

セッションがあった日だけ本が生成されます。既に生成済みの日はスキップ。
Claude Code, Codex, Copilot のいずれかのCLIがインストールされていれば自動生成されます。

## 使い方（AIエージェントなし）

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
cc-books/
├── index.html            # スタンドアロンデモ（そのまま開ける）
├── bookshelf.html        # 3D本棚UI
├── books.json            # 本の一覧データ
├── skill/
│   ├── SKILL.md          # スキル定義（Claude Code / Codex / Copilot対応）
│   ├── template.html     # HTMLテンプレート（プレースホルダ付き）
│   ├── generate.sh       # セッションログ収集スクリプト（全エージェント対応）
│   ├── daily-cron.sh     # 自動生成用cronスクリプト
│   └── com.cc-books.daily.plist  # macOS launchd設定
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

**Supported agents:** Claude Code / OpenAI Codex CLI / GitHub Copilot CLI

## What is this?

Reads session logs from AI coding agents (Claude Code, Codex, Copilot) and generates a page-flipping book in your browser.

- **Multi-agent support** — aggregates logs from Claude Code, Codex CLI, and Copilot CLI
- **Drag to flip** — grab pages with your mouse, stop mid-flip, release to complete or snap back
- **Paper sounds** — synthesized with Web Audio API (no audio files)
- **3D book feel** — CSS 3D transforms, spine shadow, page curl on hover
- **Touch support** — works on mobile
- **Zero dependencies** — single HTML file, no build, no libraries

## Supported Agents & Log Locations

| Agent | Log Location | Format |
|-------|-------------|--------|
| Claude Code | `~/.claude/projects/**/*.jsonl` | JSONL |
| Codex CLI | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | JSONL |
| Copilot CLI | `~/.copilot/session-state/{id}/events.jsonl` | JSONL |

## Setup (Claude Code)

```bash
git clone https://github.com/hatyibei/cc-books.git
cp -r cc-books/skill/ ~/.claude/skills/daily-flipbook/
```

Then in Claude Code:

```
/daily-flipbook
```

That's it. It reads session logs from all installed agents, generates chapters, and opens the book in your browser.

## Setup (Codex CLI / Copilot CLI)

```bash
git clone https://github.com/hatyibei/cc-books.git
cd cc-books
./skill/generate.sh    # Collect today's logs from all agents
```

Then pass the collected data to your preferred agent for FlipBook generation.

### What gets generated

The tool scans today's session logs from all configured agents:
- `~/.claude/projects/` (Claude Code)
- `~/.codex/sessions/YYYY/MM/DD/` (Codex CLI)
- `~/.copilot/session-state/` (Copilot CLI)

Each session becomes a chapter: what you asked, what was built, what you learned. The output is a single HTML file at `/tmp/claude/daily-flipbook/YYYY-MM-DD.html`.

```
Session logs (JSONL)
  ├─ Claude Code
  ├─ Codex CLI
  └─ Copilot CLI
        ↓
  AI extracts tasks & learnings
        ↓
  Generates chapters with code blocks, tips, quotes
        ↓
  Renders as a draggable flip-book
        ↓
  Opens in your browser
```

## Setup (without any AI agent)

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
| Drag right half left | Next page |
| Drag left half right | Previous page |
| Release past 50 deg | Complete flip |
| Release before 50 deg | Snap back |
| Arrow keys / Space | Keyboard nav |
| Buttons | Nav buttons at bottom |

## Project Structure

```
cc-books/
├── index.html            # Standalone demo
├── bookshelf.html        # 3D bookshelf UI
├── books.json            # Book catalog data
├── skill/
│   ├── SKILL.md          # Skill definition (Claude Code / Codex / Copilot)
│   ├── template.html     # HTML template with {{BOOK_TITLE}} / {{PAGES_DATA}} placeholders
│   ├── generate.sh       # Session log collector (all agents)
│   ├── daily-cron.sh     # Auto-generation cron script
│   └── com.cc-books.daily.plist  # macOS launchd config
├── LICENSE
└── README.md
```

## License

MIT
