# context-stash

**Save and restore conversation context bookmarks in Claude Code — like `git stash` for your sessions.**

## What This Does

When you're deep in a task and need to context-switch (investigate a bug, answer a question, help a colleague), `context-stash` lets you save a structured bookmark of your current work and restore it later.

### What It Saves

- Working directory path
- Git state (branch, commit SHA, dirty/clean, remote URL)
- Key files you were working on
- Todo list with statuses
- A text summary of your current work

### What It Does NOT Save

- Conversation history or message content
- The model's internal reasoning state
- In-flight analysis or accumulated understanding
- Any data beyond the structured fields above

**This is a structured bookmark, not a session snapshot.** Restoring a stash is like reading a colleague's detailed handoff notes — helpful, but not the same as resuming a paused session.

## Installation

Clone or symlink into your Claude Code plugins directory:

```bash
# Option 1: Clone directly
git clone https://github.com/yourname/context-stash ~/.claude/plugins/local/context-stash

# Option 2: Symlink from your dev directory
ln -s /path/to/context-stash ~/.claude/plugins/local/context-stash
```

## Usage

### `/push [name]` — Save Context

```
/push refactor-auth
```

Captures your current working context and saves it to `~/.claude/stash/refactor-auth.json`. You'll be prompted to provide a summary and confirm which files you were working on.

If you omit the name, one is auto-generated from your summary.

### `/pop [name]` — Restore Context

```
/pop refactor-auth
```

Restores the named bookmark: displays the summary, recreates your todo list, shows key files, and reports git state changes since the push. If you omit the name, the most recent stash is restored.

After restoring, you'll be asked whether to keep or remove the stash file.

### `/stash-list` — List and Manage

```
/stash-list
/stash-list --delete old-feature
```

Lists all saved bookmarks with age, summary, and security audit (permission checks, staleness warnings). Use `--delete` to remove specific entries.

## Stash File Format

Each bookmark is stored as a JSON file at `~/.claude/stash/<name>.json`:

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

## Security and Privacy Warnings

> **Read this section carefully before using context-stash.**

### 1. Stash Files Contain Sensitive Context

Every stash file records your working directory path, git branch names, commit SHAs, remote repository URLs, file paths, and a free-text summary of your work. This metadata reveals:

- What projects you're working on
- What features or bugs you're addressing
- Your repository structure and internal file organization
- Your git remote URLs (which may be private repositories)

### 2. File Permissions Are Necessary But Not Sufficient

Stash files are created with `chmod 600` (owner read/write only) and the stash directory with `chmod 700`. This protects against other OS users reading your files.

**However**, any process running as your OS user — including malware, compromised npm packages, browser extensions with filesystem access, or rogue scripts — can read files with these permissions. File permissions are a floor, not a ceiling.

### 3. Cloud Sync May Exfiltrate Stash Files

If your `~/.claude/` directory is within a folder synced by iCloud, Dropbox, Google Drive, OneDrive, or similar services, your stash files will be uploaded to those cloud providers.

**Recommended mitigations:**

- Exclude `~/.claude/stash/` from cloud sync
- For iCloud on macOS: move `~/.claude/` outside of `~/Library/Mobile Documents/` or add to exclusion list
- For Dropbox: use Selective Sync to exclude `~/.claude/stash/`
- For Google Drive: ensure `~/.claude/` is not within your synced folder

### 4. Restoration Is Lossy — Expect Degraded Context

When you `/pop` a stash, the model receives a structured summary of your previous work. It does **not** receive:

- The original conversation that built up its understanding
- The specific reasoning chain that led to your current approach
- Nuances and context from tool results during the original session

The model will do its best to pick up where you left off, but it is working from handoff notes, not from memory. You should expect to re-read key files and re-explain nuances.

### 5. Old Stash Files Are a Liability

Stash files do not expire automatically. Over time, they accumulate a history of your work: which projects, which branches, which files, what you were thinking. This is a data exposure risk that grows with time.

**Recommendations:**

- Regularly audit stashes with `/stash-list`
- Delete stashes you no longer need: `/stash-list --delete <name>`
- Pay attention to `[stale]` and `[OLD]` warnings
- Consider periodic cleanup as a habit (e.g., weekly)

### 6. No Encryption At Rest

Stash files are stored as plaintext JSON. They are not encrypted. If you require encryption at rest, consider:

- Using full-disk encryption (FileVault on macOS, LUKS on Linux)
- Wrapping the stash directory with an encrypted volume
- Filing a feature request for optional `age`/`gpg` encryption support

---

## FAQ

### How is this different from `/fork`?

`/fork` creates a new, independent conversation branch. You end up with two separate sessions. `context-stash` saves a bookmark from your current session and lets you restore it in any future session — the intent is "save my place and come back" rather than "branch into parallel work."

### How is this different from `/compact`?

`/compact` compresses your conversation history irreversibly to free up context window space. `context-stash` saves structured metadata externally to disk without modifying your current session.

### Why is `/pop` lossy?

An LLM's "understanding" is built up through the sequence of messages in a conversation. Skills and commands cannot access the internal message history or model state. The stash captures observable metadata (files, git state, todos, summary) but not the accumulated reasoning. This is a fundamental limitation of the skill system, not a bug.

### Can someone steal my context?

Anyone or anything with read access to `~/.claude/stash/` can read your stash files. This includes: other processes running as your user, cloud sync services, backup tools, and anyone with physical access to your machine. See the Security section above for mitigations.

### What happens if I push but never pop?

The stash file sits on disk indefinitely. It does not expire. Use `/stash-list` periodically to audit and clean up old entries.

### Can I use this across machines?

The stash files are portable JSON, but the paths inside them (cwd, key_files) are absolute and machine-specific. Popping a stash from a different machine will show path warnings for files that don't exist at those locations.

## Contributing

Contributions are welcome. Please:

1. Open an issue before starting significant work
2. Follow the existing code style and command structure
3. Add edge case handling for new features
4. Update this README for user-facing changes
5. Test on both macOS and Linux (the `stat` command differs)

## License

MIT — see [LICENSE](LICENSE).
