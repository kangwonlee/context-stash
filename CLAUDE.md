# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**context-stash** is a Claude Code plugin that provides "git stash for sessions" — saving and restoring conversation context bookmarks across different sessions. It's installed by cloning/symlinking to `~/.claude/plugins/local/context-stash`.

## Architecture

The plugin has three user-facing commands and one proactive skill:

- **`/push [name]`** (`commands/push.md`) — Saves current context (cwd, git state, key files, todos, summary) as a JSON bookmark to `~/.claude/stash/<name>.json`. Auto-generates a name if omitted. Checks for name collisions.
- **`/pop [name]`** (`commands/pop.md`) — Restores a saved bookmark. Performs staleness checks, validates JSON, audits file permissions, detects git state drift, and restores todos via `TodoWrite`. Falls back to newest stash if no name given. Asks user whether to keep or delete the stash after restoring.
- **`/stash-list [--delete name]`** (`commands/stash-list.md`) — Lists all bookmarks sorted newest-first with age warnings (stale >7d, OLD >30d), permission audits, and disk usage. Supports `--delete` for removal with confirmation.
- **context-stash-awareness** (`skills/context-stash-awareness/`) — A proactive skill that detects task-switching signals ("switch to", "before I forget", "park this", etc.) and gently suggests `/push`. Only suggests once per switch, doesn't block.

## Shared Utilities

`scripts/stash-utils.sh` — Bash helper library sourced by commands. Provides:
- `ensure_stash_dir()`, `check_file_perms()`, `get_perms()` — directory/file permission management (600 for files, 700 for dir)
- `relative_age()` — ISO 8601 timestamp to human-readable age
- `sanitize_name()` — lowercase alphanumeric + hyphens, max 40 chars
- `list_stash_names()`, `count_stash_entries()` — stash enumeration

All utilities are cross-platform (macOS BSD stat vs Linux GNU stat).

## Stash Data Format

Bookmarks are stored as JSON at `~/.claude/stash/<name>.json` with fields: `version`, `id` (UUID), `name`, `timestamp` (ISO 8601), `cwd`, `git` (branch, ref, dirty, remote_url), `summary`, `key_files` (absolute paths), `todos` (content + status), `notes`.

## Key Design Decisions

- **Restoration is lossy** — only structured fields are captured; conversation history and model reasoning state cannot be saved by the plugin system.
- **Security-conscious** — stash files contain sensitive context (paths, branches, SHAs, remote URLs, summaries). Files use restrictive permissions but any process running as the OS user can read them. No encryption at rest. Cloud sync of `~/.claude/` is a risk the README calls out.
- **No auto-expiration** — old stashes accumulate and require manual cleanup via `/stash-list --delete`.
