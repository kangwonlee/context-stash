# context-stash

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://claude.ai/code)

**`git stash` for Claude Code sessions.** Save your place, switch tasks, come back later.

---

## Why?

Every time you context-switch mid-session — a production bug, a teammate's question, a quick PR review — you lose all the accumulated context Claude has built up. Starting a new session means re-reading files, re-explaining your approach, and re-building the todo list from scratch.

`context-stash` gives you a `/push` and `/pop` for your sessions, so you can bookmark where you are and pick it back up later.

## Quick Start

```bash
git clone https://github.com/anthropics/context-stash ~/.claude/plugins/local/context-stash
```

Then in any Claude Code session:

```
/push refactor-auth       # save your place
# ... go do something else ...
/pop refactor-auth        # pick up where you left off
```

## What Gets Saved

| Saved | Not Saved |
|-------|-----------|
| Working directory path | Conversation history |
| Git state (branch, SHA, dirty/clean) | Model's reasoning state |
| Key files you were editing | In-flight analysis |
| Todo list with statuses | Accumulated understanding |
| Free-text summary of your work | |

**This is a structured bookmark, not a session snapshot.** Restoring a stash is like reading a colleague's detailed handoff notes — helpful, but not the same as resuming a paused session.

## Commands

### `/push [name]` — Save Context

```
/push refactor-auth
/push                     # auto-generates a name from your summary
```

Captures your current working context and saves it to `~/.claude/stash/<name>.json`. You'll be prompted to provide a summary and confirm which files you were working on.

### `/pop [name]` — Restore Context

```
/pop refactor-auth
/pop                      # restores the most recent stash
```

Restores the named bookmark: displays the summary, recreates your todo list, shows key files, and reports git state changes since the push.

After restoring, you'll be asked whether to keep or remove the stash file.

### `/stash-list` — List and Manage

```
/stash-list
/stash-list --delete old-feature
```

Lists all saved bookmarks with age, summary, and security audit (permission checks, staleness warnings). Use `--delete` to remove specific entries.

### Proactive Suggestions

The plugin also includes a context-awareness skill that detects task-switching signals ("switch to", "before I forget", "park this") and gently suggests `/push` before you lose context. It won't block you — just a nudge.

## How It Compares

| | context-stash | `/fork` | `/compact` |
|---|---|---|---|
| **Purpose** | Save your place, come back later | Branch into parallel work | Free up context window |
| **Cross-session** | Yes | No | No |
| **Preserves history** | No (structured bookmark) | Yes (full conversation) | No (irreversible compression) |
| **Modifies session** | No | Yes (creates new branch) | Yes (compresses messages) |

## Installation

```bash
# Option 1: Clone directly
git clone https://github.com/anthropics/context-stash ~/.claude/plugins/local/context-stash

# Option 2: Symlink from your dev directory
ln -s /path/to/context-stash ~/.claude/plugins/local/context-stash
```

## Stash File Format

Each bookmark is stored as JSON at `~/.claude/stash/<name>.json`:

```json
{
  "version": 1,
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "refactor-auth",
  "timestamp": "2026-03-15T14:30:00-07:00",
  "cwd": "/Users/me/project",
  "git": {
    "branch": "feature/auth-refactor",
    "ref": "abc123f",
    "dirty": true,
    "remote_url": "git@github.com:me/project.git"
  },
  "summary": "Refactoring auth middleware to use JWT. Halfway through token validation logic.",
  "key_files": [
    "/Users/me/project/src/auth/middleware.ts",
    "/Users/me/project/src/auth/token.ts"
  ],
  "todos": [
    { "content": "Update token validation", "status": "in_progress" },
    { "content": "Add refresh token flow", "status": "pending" }
  ],
  "notes": null
}
```

---

## Security and Privacy

> **Read this section before using context-stash.**

### Stash Files Contain Sensitive Context

Every stash file records directory paths, git branch names, commit SHAs, remote URLs, file paths, and a free-text summary. This metadata reveals what you're working on and how your projects are structured.

### File Permissions Are a Floor, Not a Ceiling

Stash files are created with `chmod 600` and the directory with `chmod 700`. This protects against other OS users, but any process running as your user can still read them.

### Cloud Sync Risk

If `~/.claude/` is within a folder synced by iCloud, Dropbox, Google Drive, or OneDrive, your stash files will be uploaded. Exclude `~/.claude/stash/` from cloud sync.

### No Encryption at Rest

Stash files are plaintext JSON. Use full-disk encryption (FileVault, LUKS) if you need encryption at rest.

### Old Stashes Accumulate Risk

Stash files don't expire. Audit regularly with `/stash-list` and delete what you no longer need.

---

## FAQ

### Why is `/pop` lossy?

An LLM's understanding is built through the sequence of messages in a conversation. The plugin system cannot access internal message history or model state. The stash captures observable metadata (files, git state, todos, summary) but not accumulated reasoning. This is a fundamental limitation, not a bug.

### Can I use this across machines?

The stash files are portable JSON, but paths inside them are absolute and machine-specific. Popping a stash from a different machine will show warnings for files that don't exist at those locations.

### What happens if I push but never pop?

The stash file sits on disk indefinitely. Use `/stash-list` periodically to clean up.

## Contributing

Contributions are welcome. Please:

1. Open an issue before starting significant work
2. Follow the existing code style and command structure
3. Add edge case handling for new features
4. Update this README for user-facing changes
5. Test on both macOS and Linux (the `stat` command differs)

## License

MIT — see [LICENSE](LICENSE).
