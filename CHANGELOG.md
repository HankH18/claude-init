# Changelog

All notable changes to `claude-init` are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.3.0] — 2026-05-10

### Added
- **Configurable sub-agent models.** Each of the four sub-agents (planner, code-reviewer, test-runner, debugger) can now be assigned to `opus`, `sonnet`, or `haiku` independently.
- **Five model presets:** `opus-heavy`, `balanced` (default), `thrifty`, `minimal`, `haiku-runner`.
- **CLI flags:** `--planner=`, `--reviewer=`, `--test-runner=`, `--debugger=`, `--preset=`.
- **Environment variables:** `CLAUDE_INIT_PLANNER_MODEL`, `CLAUDE_INIT_REVIEWER_MODEL`, `CLAUDE_INIT_TESTRUNNER_MODEL`, `CLAUDE_INIT_DEBUGGER_MODEL`.
- **Config file:** `~/.config/claude-init/config` (XDG-aware) for global defaults.
- **`--configure` mode:** interactive walk-through to set global defaults.
- **`--show-config` mode:** prints the resolved configuration.
- **Installer (`install.sh`):** one-line public install via `curl | bash`.
- **Fork setup (`setup-fork.sh`):** one-shot placeholder replacement for downstream forks.
- **README, LICENSE, CHANGELOG:** repo packaging for public distribution.

### Changed
- **CLAUDE.md sub-agents section** now reflects the actually-configured models, not hardcoded labels.
- **Final summary output** now lists the resolved models.

### Configuration priority order
1. CLI flags (highest)
2. Environment variables
3. Config file (`~/.config/claude-init/config`)
4. Built-in defaults (the `balanced` preset)

## [1.2.0] — 2026-05-09 (internal)

### Added
- **Comprehensive `MCP_SETUP.md`:** ~610 lines covering 60+ MCP servers across 10 categories (Core, Databases, Cloud, Browser/Web, Observability, Communication, Commerce, Marketing, AI/ML, Specialty), plus stack-archetype "kits", discipline guidance, and a debugging cheat sheet.

## [1.1.0] — 2026-05-09 (internal)

### Changed
- **Sub-agent model upgrades:** code-reviewer Sonnet → Opus, debugger Sonnet → Opus, test-runner Haiku → Sonnet. Three of four sub-agents now on Opus.

## [1.0.0] — 2026-05-09 (internal)

### Added
- Initial release.
- Polyglot stack detection (Node/TS, Python, Rust, Go, Ruby, PHP, JVM, Terraform, Serverless, Docker).
- Auto-detected build/test/lint/dev commands populated in `CLAUDE.md`.
- Three hooks: PostToolUse format, PreToolUse danger-guard, Stop test-runner.
- Four sub-agents: planner (Opus), code-reviewer (Sonnet), test-runner (Haiku), debugger (Sonnet).
- Three slash commands: `/plan`, `/review`, `/ship`.
- Idempotent file creation with `--force` and `--dry-run` modes.
- Initial MCP_SETUP.md with copy-paste recipes for top servers.
