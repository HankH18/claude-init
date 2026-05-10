# claude-init

> Opinionated, idempotent project scaffolding for [Claude Code](https://code.claude.com/). One command, full setup: project memory, hooks, sub-agents, slash commands, and an MCP reference doc — with configurable model assignments per sub-agent.

---

## Install (one line)

```bash
curl -fsSL https://raw.githubusercontent.com/HankH18/claude-init/main/install.sh | bash
```

> Replace `HankH18` with the GitHub user or org that hosts this repo. If you forked it, that's you.

The installer drops the `claude-init` binary into `~/.local/bin/`. If that's not on your `PATH`, the installer tells you exactly what to add to your shell rc.

**Prerequisites:** `bash` 4+, `curl`, `jq` (`brew install jq` on macOS, `apt install jq` on Debian/Ubuntu), and the [Claude Code CLI](https://code.claude.com/docs/en/install) (`npm install -g @anthropic-ai/claude-code`).

## Quick start

```bash
# 1. (Optional) set global model defaults — interactive, 4 questions
claude-init --configure

# 2. Initialize any project
cd ~/projects/my-thing
claude-init

# 3. Start coding
claude
```

That's it. `claude-init` is idempotent — re-run it anytime; it only writes files that don't already exist (use `--force` to refresh).

---

## What it sets up

```
your-project/
├── CLAUDE.md                          ← project memory (under 200 lines, opinionated)
├── .gitignore                         ← Claude-related entries appended
└── .claude/
    ├── settings.json                  ← hooks config
    ├── hooks/
    │   ├── format.sh                  ← polyglot post-edit formatter
    │   ├── danger-guard.sh            ← pre-bash safety net
    │   └── test-on-stop.sh            ← block stop until tests pass
    ├── agents/
    │   ├── planner.md                 ← plan-before-code sub-agent
    │   ├── code-reviewer.md           ← read-only review sub-agent
    │   ├── test-runner.md             ← test execution sub-agent
    │   └── debugger.md                ← reproduce-isolate-fix sub-agent
    ├── commands/
    │   ├── plan.md                    ← /plan slash command
    │   ├── review.md                  ← /review slash command
    │   └── ship.md                    ← /ship slash command
    └── MCP_SETUP.md                   ← curated MCP server reference (60+ servers, 10 categories)
```

Stack auto-detection works out of the box for: Node/TypeScript, Python, Rust, Go, Ruby, PHP, JVM, Terraform, Serverless Framework, Docker. Build/test/lint/dev commands get pre-filled in `CLAUDE.md` from `package.json`, `pyproject.toml`, `Cargo.toml`, etc.

---

## Configuring sub-agent models

`claude-init` ships with four sub-agents. Each can run on a different Claude model — `opus` for high-stakes reasoning, `sonnet` for everyday work, `haiku` for cheap-and-fast utility roles.

### Defaults (the `balanced` preset)

| Sub-agent       | Default model | When to call it                                                |
|-----------------|---------------|----------------------------------------------------------------|
| `planner`       | **Opus**      | BEFORE coding any feature touching >2 files                    |
| `code-reviewer` | **Opus**      | AFTER a feature, before commit                                 |
| `test-runner`   | **Sonnet**    | Run tests cheaply without bloating the main context            |
| `debugger`      | **Opus**      | When tests fail or behavior is unexpected — root-cause analysis |

### Presets

A preset configures all four sub-agents at once. Five are built in:

| Preset          | planner | code-reviewer | test-runner | debugger | Best for                                            |
|-----------------|---------|---------------|-------------|----------|-----------------------------------------------------|
| `opus-heavy`    | Opus    | Opus          | Opus        | Opus     | Maximum quality, you have Max tier and don't care   |
| `balanced` ★    | Opus    | Opus          | Sonnet      | Opus     | The default — production-grade, sensible quota use  |
| `thrifty`       | Opus    | Sonnet        | Sonnet      | Sonnet   | Pro tier, want decent quality without burning quota |
| `minimal`       | Sonnet  | Sonnet        | Sonnet      | Sonnet   | Smoke-testing, low-stakes scripting                 |
| `haiku-runner`  | Opus    | Opus          | Haiku       | Opus     | High-frequency test runs, willing to trade reliability for speed |

Apply a preset:

```bash
claude-init --preset=opus-heavy
claude-init --preset=thrifty
```

### Per-agent flags

Override one or more sub-agents:

```bash
claude-init --planner=opus
claude-init --reviewer=sonnet --debugger=opus
claude-init --test-runner=haiku
```

You can mix presets and overrides — overrides win:

```bash
# opus-heavy preset, but knock test-runner down to sonnet
claude-init --preset=opus-heavy --test-runner=sonnet
```

### Configuration sources (highest priority wins)

```
1. CLI flags          --planner=opus, --preset=balanced, etc.
2. Environment vars   CLAUDE_INIT_PLANNER_MODEL=opus, etc.
3. Config file        ~/.config/claude-init/config
4. Built-in defaults  the 'balanced' preset
```

### Setting global defaults

The easiest way is the interactive walk-through:

```bash
claude-init --configure
```

It asks four questions and writes `~/.config/claude-init/config`. Subsequent `claude-init` runs will use these defaults unless you override per-project.

You can also write the file by hand:

```bash
mkdir -p ~/.config/claude-init
cat > ~/.config/claude-init/config <<'EOF'
# claude-init global config
# Valid values: opus, sonnet, haiku
planner=opus
reviewer=opus
test-runner=sonnet
debugger=opus
EOF
```

### Environment variables (handy for CI or per-shell overrides)

```bash
export CLAUDE_INIT_PLANNER_MODEL=opus
export CLAUDE_INIT_REVIEWER_MODEL=opus
export CLAUDE_INIT_TESTRUNNER_MODEL=sonnet
export CLAUDE_INIT_DEBUGGER_MODEL=opus
```

### Inspecting the resolved config

```bash
claude-init --show-config
```

Prints the final model assignments and which config sources contributed. Useful when you're not sure why a particular model is being applied.

> **Note on model resolution:** When `claude-init` writes `model: opus` into a sub-agent file, Claude Code resolves that to whatever the latest available Opus is on your subscription (currently Opus 4.7). You don't need to pin specific versions — your config will track upgrades automatically.

---

## The four sub-agents in detail

### `planner`
Read-only. Tools: `Read`, `Grep`, `Glob`, `WebSearch`, `WebFetch`. Produces a numbered, screen-sized plan with explicit risks and open questions. Stops without writing any code.

**When to invoke:** Any feature touching more than 2 files, anything with non-obvious architectural implications. Use the `/plan` slash command for the lazy invocation.

### `code-reviewer`
Read-only. Tools: `Read`, `Grep`, `Glob`, `Bash`. Reviews uncommitted changes (default) or a specified target for correctness, security, conventions, tests, performance, and API stability. Outputs `BLOCKING` / `SUGGESTIONS` / `LGTM` — never edits files.

**When to invoke:** After implementing a feature, before commit. Use `/review`.

### `test-runner`
Tools: `Bash`, `Read`, `Grep`. Detects framework, runs tests, returns terse failure summaries with `path:line — test name — assertion`. Designed to keep the main session's context window clean.

**When to invoke:** Whenever you want test feedback without dumping a 500-line stack trace into the main thread. Auto-invoked by `/ship`.

### `debugger`
Tools: `Read`, `Grep`, `Glob`, `Bash`, `Edit`. Reproduces the bug, isolates with hypothesis-driven bisection, applies the smallest possible fix, adds a regression test, verifies.

**When to invoke:** When a test is red, an error is firing, or behavior is unexpected. Hard rule: one bug per session — finds a second bug, it's noted, not fixed.

---

## Hooks in detail

All hooks live in `.claude/hooks/`. They're declared in `.claude/settings.json` so Claude Code picks them up automatically.

### `format.sh` — PostToolUse: `Write|Edit|MultiEdit`
Polyglot post-edit formatter. Best-effort — never blocks. Detects file type and runs whatever's installed:

| File type   | Formatter (in priority order)                |
|-------------|----------------------------------------------|
| `.ts/.js/.json/.md/.yml/.css/.html` | Biome → Prettier |
| `.py`       | Ruff format + Ruff check --fix → Black       |
| `.go`       | gofmt + goimports                            |
| `.rs`       | rustfmt                                      |
| `.tf/.tfvars` | terraform fmt                              |
| `.sh/.bash` | shfmt                                        |
| `.rb`       | rubocop -A                                   |

If none of those tools are installed for a given file type, the hook silently no-ops.

### `danger-guard.sh` — PreToolUse: `Bash`
Pre-execution safety net. Returns exit 2 (blocks) on:

- `rm -rf /` and similar destructive recursive deletes
- `mkfs`, `dd if=... of=/dev/...`, fork bombs
- `chmod -R 777 /`, `chown -R ... /`
- AWS destructive ops: `s3 rb --force`, `s3 rm --recursive`, `iam delete-*`, `lambda delete-function`, `rds delete-db-*`
- SQL: `DROP DATABASE`, `DROP SCHEMA`, `TRUNCATE TABLE`
- Git: force-push to `main`/`master`/`production`, hard reset to those branches
- Pipe-to-shell installers: `curl ... | bash`, `wget ... | sh`

To temporarily bypass (e.g., you intentionally need a force push), run the command yourself in a shell, or edit `.claude/hooks/danger-guard.sh` to remove patterns you find too aggressive.

### `test-on-stop.sh` — Stop
When Claude tries to end the session, this runs the project's test suite (auto-detected: `npm test`, `pytest`, `cargo test`, `go test`). Returns exit 2 if tests fail, which forces Claude to keep working until they pass.

Smart skips:

- If no source files have changed (`git status --porcelain` is empty), tests are skipped to save quota.
- If the stop hook has already fired once this turn (`stop_hook_active`), it doesn't recurse.

**Bypass:** `touch .claude/SKIP_TESTS` to disable for the next session — useful when you're explicitly debugging the tests themselves.

---

## Slash commands

Defined in `.claude/commands/`. Type `/` in Claude Code to see them.

| Command            | What it does                                                                              |
|--------------------|-------------------------------------------------------------------------------------------|
| `/plan <feature>`  | Invokes `planner` sub-agent. Shows the plan and waits for your approval before any code.  |
| `/review [target]` | Invokes `code-reviewer` against uncommitted changes (or specified branch/file).           |
| `/ship [message]`  | Runs `test-runner`, runs project linters, then `git commit` if green. Never pushes.       |

---

## CLAUDE.md philosophy

`claude-init` generates a `CLAUDE.md` template designed to be **kept under 200 lines**. Frontier reasoning models reliably follow ~150–200 instructions. Beyond that, recall degrades — and "Claude ignores my rules" is almost always a too-long `CLAUDE.md` problem.

**What to put in it:**

- **Project topology** — where things live (`src/`, `tests/`, `.claude/`, etc.)
- **Build/test/lint commands** — auto-filled from your manifest, but verify them
- **Conventions** — match-existing-patterns rules that aren't enforceable by linters
- **Guardrails** — never-do-X items: no secrets, no direct push to main, no rewriting migrations, etc.
- **Failure modes** — the most valuable section over time. When Claude makes a mistake, document it here. "The `users` table has soft deletes; always filter `deleted_at IS NULL` unless told otherwise." This is the equivalent of a domain-knowledge sidecar that keeps growing as you work.

**What NOT to put in it:**

- Style guides — Claude is an in-context learner, not a linter. Convert style rules into a Stop hook that runs your formatter and feeds errors back. The `format.sh` hook handles most of this for free.
- Massive instructions about how to write code — Claude already knows how to write code. Tell it about *your* code.

**Subdirectory CLAUDE.md files** are pulled in automatically when Claude works on files there. Put domain-specific context where it lives:

- `services/dispatch/CLAUDE.md` — VRPTW solver context
- `infra/CLAUDE.md` — AWS Lambda/Redshift conventions
- `shopify-integration/CLAUDE.md` — your Shopify-specific gotchas

---

## MCP server reference

The generated `.claude/MCP_SETUP.md` is a comprehensive reference covering 60+ MCP servers, organized by purpose:

1. **Core** — GitHub, Context7, Git
2. **Databases & Data Stores** — Postgres/Redshift, MySQL, SQLite, Mongo, Redis, Snowflake, BigQuery
3. **Cloud & Infrastructure** — AWS, Cloudflare, Vercel, Supabase, Firebase, Docker, K8s, Terraform
4. **Browser, Web, & Scraping** — Playwright, Puppeteer, Fetch, Firecrawl, Brave/Tavily/Perplexity
5. **Observability & Monitoring** — Sentry, Datadog, Grafana, Honeycomb
6. **Communication & PM** — Slack, Linear, Jira, Notion, Asana, Discord, Gmail/Google Workspace
7. **Commerce & Payments** — Stripe, Shopify, PayPal, Square
8. **Marketing & Analytics** — Klaviyo, Google Ads, Meta Ads, HubSpot, Salesforce, PostHog
9. **AI / ML / Search** — HuggingFace, Vectara, Pinecone, Qdrant, Sequential Thinking
10. **Specialty / Niche** — Filesystem, Memory, Time, Apple, Zapier, n8n

Each entry includes the exact install command, when to use it (vs. alternatives), and gotchas. Plus stack-archetype "kits" (web SaaS, e-commerce, mobile+backend, data/ML, infra/DevOps), discipline guidance, and a debugging cheat sheet.

You don't need to install any of them — just read what's relevant when you need it.

---

## Idempotency and safety

`claude-init` follows three rules religiously:

1. **Identical content → silent skip.** Re-runs that produce the same files just log `=  unchanged`.
2. **Differing content (no `--force`) → keep yours.** Logged as `=  exists, differs; --force to overwrite`.
3. **Differing content (`--force`) → back up, then overwrite.** Original goes to `path.bak.YYYYMMDD-HHMMSS`.

This means you can safely re-run `claude-init` to:

- Add new files after the script has been updated
- Refresh hook scripts without losing your customized `CLAUDE.md` (run `--force`, the old one gets backed up)
- Pull a new MCP_SETUP.md without disturbing your local edits (similar)

### Preview mode

```bash
claude-init --dry-run
```

Shows everything that *would* happen, writes nothing. Useful before `--force` runs.

```bash
claude-init --dry-run --force
```

Shows which existing files would be backed up and overwritten.

---

## Updating

Just re-run the installer. It always pulls the latest version from the configured branch (default `main`).

```bash
curl -fsSL https://raw.githubusercontent.com/HankH18/claude-init/main/install.sh | bash
```

Pin to a specific tag if you want stability:

```bash
CLAUDE_INIT_BRANCH=v1.3.0 curl -fsSL .../install.sh | bash
```

After updating, run `claude-init --force` in your projects to refresh hook scripts and sub-agent definitions. Your `CLAUDE.md` will be backed up so customizations aren't lost.

---

## Uninstalling

```bash
rm ~/.local/bin/claude-init                 # remove the binary
rm -rf ~/.config/claude-init                # remove the global config (optional)
```

To remove `claude-init`'s output from a project:

```bash
rm -rf .claude/ CLAUDE.md
# Then manually clean .gitignore entries if you want.
```

---

## For teams

Two patterns work well for sharing across a company:

**1. Pinned company config in `~/.config/claude-init/config`.** Document the company's preferred model assignments, distribute via your dotfiles repo or onboarding doc.

**2. Project-level `.claude/` checked into git.** Once `claude-init` initializes a project, commit `.claude/` to the repo. New teammates clone, run `claude` and inherit the team's hooks/agents/commands without running `claude-init` themselves.

For an internal-only fork:

```bash
# Fork or mirror this repo to your company GitHub
# Update install.sh's CLAUDE_INIT_REPO default to your fork
# Distribute the install one-liner internally
curl -fsSL https://raw.githubusercontent.com/acme-corp/claude-init/main/install.sh | bash
```

---

## Customizing for your fork

This repo is meant to be forked. After forking:

1. **Run the one-liner setup script** — it replaces all placeholders in `install.sh`, `README.md`, `LICENSE`, and `CHANGELOG.md` in a single pass:

   ```bash
   ./setup-fork.sh YOUR_GITHUB_USERNAME "Your Name"
   ```

   The "Your Name" argument is for the LICENSE copyright line and is optional (defaults to the username if omitted). Re-running is safe — it detects already-substituted repos and exits cleanly.

2. **(Optional) Edit `bin/claude-init`** — change the default sub-agent model assignments, add company-specific guardrails to `danger-guard.sh`, add custom slash commands, swap MCP server recommendations.

3. **Tag a release** — `git tag v1.0.0 && git push --tags` so users can pin via `CLAUDE_INIT_BRANCH=v1.0.0`.

The script is plain bash, ~1400 lines, with clear section headers. Greppable and easy to fork.

---

## Troubleshooting

**`claude-init: command not found` after install** — `~/.local/bin` isn't on your `PATH`. Add `export PATH="$HOME/.local/bin:$PATH"` to your shell rc (`~/.zshrc` or `~/.bashrc`), then `source` it.

**Installer says "claude CLI not found"** — install Claude Code first: `npm install -g @anthropic-ai/claude-code`.

**Installer says "jq not found"** — `brew install jq` (macOS) or `apt install jq` (Debian/Ubuntu).

**The hooks don't fire** — check `.claude/settings.json` exists and is valid JSON: `jq . .claude/settings.json`. Inside Claude Code, run `/hooks` to see what's registered.

**A sub-agent isn't being invoked** — Claude Code chooses sub-agents based on their `description` field. If `planner` isn't getting picked up for architectural questions, add a more specific use-case to its description. You can also force it: "Use the planner sub-agent for this."

**`format.sh` is changing files I don't want changed** — edit `.claude/hooks/format.sh` and remove the formatter for that file extension, or wrap it in a `if [[ "$FILE" != *vendor/* ]]` guard.

**`danger-guard.sh` is too aggressive** — open it and remove patterns. It's a single regex array; one line per pattern.

**`test-on-stop.sh` runs unwanted tests** — `touch .claude/SKIP_TESTS` to disable for the session, then `rm` it when you're done.

---

## Specifications

- **Script size:** ~1,400 lines of bash
- **Dependencies:** `bash` (4+), `curl`, `jq`, Claude Code CLI
- **Stacks auto-detected:** Node/TypeScript, Python, Rust, Go, Ruby, PHP, JVM (Maven/Gradle), Terraform, Serverless Framework, Docker
- **Sub-agents:** 4 (planner, code-reviewer, test-runner, debugger)
- **Slash commands:** 3 (`/plan`, `/review`, `/ship`)
- **Hooks:** 3 (PostToolUse format, PreToolUse danger-guard, Stop test-runner)
- **Model presets:** 5 (opus-heavy, balanced, thrifty, minimal, haiku-runner)
- **Valid model values:** `opus`, `sonnet`, `haiku` (resolves to latest available on your subscription)
- **Config file location:** `${XDG_CONFIG_HOME:-$HOME/.config}/claude-init/config`
- **Idempotent:** yes
- **Safe to re-run on partially-initialized projects:** yes
- **Backs up before overwrites (`--force`):** yes, to `*.bak.<timestamp>`

---

## Contributing

PRs welcome. Areas where contributions are particularly useful:

- Stack-detection rules for languages/tools not yet covered
- Additional dangerous-pattern entries for `danger-guard.sh`
- New sub-agents for common workflows (e.g., `migration-writer`, `dependency-auditor`)
- New slash commands
- Translations of CLAUDE.md template

Run `shellcheck bin/claude-init install.sh` before opening a PR. CI runs the same.

---

## License

MIT. See [LICENSE](LICENSE).

---

## Credits

- Built on top of [Claude Code](https://code.claude.com/) by Anthropic.
- CLAUDE.md philosophy informed by [HumanLayer](https://humanlayer.dev/) and Anthropic's [Claude Code best practices](https://www.anthropic.com/engineering/claude-code-best-practices).
- MCP server reference draws on the [Model Context Protocol official servers list](https://github.com/modelcontextprotocol/servers) and community curations.