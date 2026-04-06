---
name: daily-flipbook
description: 今日のAIコーディングエージェント（Claude Code / Codex / Copilot）のセッションログから振り返り本（FlipBook）を自動生成して開く
---

# Daily FlipBook Generator

今日のAIコーディングエージェントのセッションログを読み取り、1日の振り返りをページめくりできる「本」として生成するスキル。

**対応エージェント:**
- Claude Code
- OpenAI Codex CLI
- GitHub Copilot CLI

## トリガー

- `/daily-flipbook` で起動
- 「今日の振り返り本作って」「日記本生成して」等

## 処理フロー

### Step 1: セッションログの収集

以下の全パスからセッションログを収集する:

#### Claude Code
```bash
# パス1: デフォルト
~/.claude/projects/

# パス2: CLAUDE_CONFIG_DIR指定
~/claude-data/projects/
```

#### OpenAI Codex CLI
```bash
# デフォルト（CODEX_HOMEで変更可能）
~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl
```

#### GitHub Copilot CLI
```bash
# セッション状態ディレクトリ
~/.copilot/session-state/{session-id}/events.jsonl
```

**必ず全てのパスを検索すること。一部だけで「見つからない」は禁止。**

ログファイルはいずれもJSONL形式。以下のコマンドで今日のセッションを見つける:

```bash
# 日付マーカーの作成
touch -t $(date +%Y%m%d)0000 /tmp/today_marker

# Claude Code
find ~/.claude/projects/ -name "*.jsonl" -newer /tmp/today_marker -not -path "*/subagents/*" 2>/dev/null
find ~/claude-data/projects/ -name "*.jsonl" -newer /tmp/today_marker -not -path "*/subagents/*" 2>/dev/null

# Codex CLI（日付でディレクトリ分けされている）
ls ~/.codex/sessions/$(date +%Y)/$(date +%m)/$(date +%d)/rollout-*.jsonl 2>/dev/null

# Copilot CLI
find ~/.copilot/session-state/ -name "events.jsonl" -newer /tmp/today_marker 2>/dev/null
```

### Step 2: ログの解析

各エージェントのJSONLファイルから以下を抽出:

#### Claude Code のログ形式
1. **ユーザーのメッセージ** (`type: "user"`) → 何を依頼したか
2. **アシスタントの応答** (`type: "assistant"`) → 何を実行したか
3. **ツール使用** (`tool_use`) → Write, Edit, Bash等の実行内容

#### Codex CLI のログ形式
1. **ユーザーのメッセージ** (`item.type: "event_msg"`, `item.payload.type: "user_message"`) → `.message`
2. **コマンド実行** (`item.payload.type: "exec_command_begin"`) → `.command`
3. **関数呼び出し** (`item.type: "response_item"`, `item.type: "function_call"`) → `.name`, `.arguments`

#### Copilot CLI のログ形式
1. **ユーザーのメッセージ** (`role: "user"` or `type: "user"`) → `.content` or `.message`
2. **ツール呼び出し** (`type: "tool_call"` or `type: "call_tool"`) → `.name`, `.arguments`

これらを時系列で整理し、以下の構造にまとめる:

```
- セッション1: [プロジェクト名] [エージェント名]
  - やったこと: [概要]
  - 成果物: [ファイル、コミット等]
  - 学び: [気づき、発見]

- セッション2: ...
```

### Step 3: 本の構成を決定

収集した情報から本の構成を自動生成:

| ページ | 内容 |
|--------|------|
| 表紙 | 日付 + タイトル（「YYYY年MM月DD日の記録」） |
| はじめに | 今日のサマリー（セッション数、使用エージェント、主な成果） |
| 各章 | セッションごとの詳細（やったこと、コード、学び） |
| 最終ページ | 今日の振り返り + 明日へのアクション |

**構成ルール:**
- 1セッションにつき1見開き（2ページ）
- 最大6章（12ページ）まで。それ以上は重要度で選別
- コードブロック、引用、ティップスボックスを適宜使用
- 各章にどのエージェントを使ったかを明記する

### Step 4: FlipBook HTMLを生成

テンプレート（`index.html`）をベースに、`pages` 配列を差し替えたHTMLを生成する。

出力先: `/tmp/claude/daily-flipbook/YYYY-MM-DD.html`

使用可能なCSSクラス:
- `.page-title` — 大見出し
- `.chapter-label` — 章番号
- `.page-body` — 本文
- `.code-block` — コード（`.comment`, `.keyword`, `.string`, `.property` でハイライト）
- `.quote` — 引用ブロック
- `.tip-box` — ティップス（`.tip-title` + `<ul>`）
- `.comparison` — 2カラム比較（`.col.good` / `.col.bad`）
- `.divider` — 装飾区切り線
- `.dropcap` — ドロップキャップ（`<p class="dropcap">`）

### Step 5: ブラウザで開く

```bash
open /tmp/claude/daily-flipbook/YYYY-MM-DD.html    # macOS
xdg-open /tmp/claude/daily-flipbook/YYYY-MM-DD.html # Linux
```

## 出力例

表紙:
```
2026年4月5日の記録
── Today I Learned ──
3 agents / 12 sessions
```

章の例:
```
第一章: FlipBook UIを作った [Claude Code]

「本のページめくるUI作れる？」から始まって、
CSS 3D transformsとWeb Audio APIで
ドラッグでめくれる本のUIを作った。
```

```
第三章: APIリファクタリング [Codex CLI]

古いREST APIをOpenAPI仕様に沿って
リファクタリング。Codexがテストも
自動生成してくれた。
```

## 注意事項

- セッションログが見つからない場合は「今日はまだセッションがありません」と伝える
- 個人情報（APIキー、パスワード等）がログに含まれている場合は除外する
- 生成したHTMLにも個人情報を含めない
- ログの解析にはBashツール（jq）を使用する
