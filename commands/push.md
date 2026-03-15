---
description: "Save current conversation context as a structured bookmark to disk (like git stash). Use when switching tasks, pausing work, or wanting to resume later."
argument-hint: "[name]"
allowed-tools: Bash(mkdir:*), Bash(chmod:*), Bash(date:*), Bash(git:*), Bash(uuidgen:*), Bash(ls:*), Bash(stat:*), Bash(wc:*), Read, Write, Glob, Grep
---

# /push — Save Context Bookmark

Save the current working context as a structured bookmark to `~/.claude/stash/`.

## SECURITY WARNING — Display Before Proceeding

Before doing anything else, show this warning and wait for user confirmation:

> **Privacy Notice:** This will save context metadata to `~/.claude/stash/`.
>
> The stash file will contain:
> - Your working directory path
> - Git branch name, commit SHA, and remote URL
> - File paths you were working on
> - A text summary of your current work
> - Your current todo list
>
> **Risks:**
> - Files are created with owner-only permissions (`chmod 600`), but **any process running as your OS user can read them**
> - If `~/.claude/` is synced by iCloud, Dropbox, Google Drive, or similar services, **stash files may be uploaded to the cloud**
> - Old stash files accumulate sensitive context over time — use `/stash-list` to audit and clean up
>
> Proceed with saving context?

**Do NOT proceed until the user confirms.** If the user declines, abort gracefully.

## Arguments

The user invoked this command with: $ARGUMENTS

- If an argument is provided, use it as the stash name (sanitize to lowercase alphanumeric + hyphens only, max 40 characters).
- If no argument is provided, you will auto-generate a name after collecting the summary.

## Steps

### 1. Create stash directory

```bash
mkdir -p ~/.claude/stash && chmod 700 ~/.claude/stash
```

If the directory already exists, verify its permissions are `700`. Fix if not.

### 2. Generate stash ID

Run `uuidgen` to create a unique ID for this stash entry.

### 3. Capture working directory

Record the current working directory (the absolute path).

### 4. Capture git state (if applicable)

Check if the current directory is inside a git repository. If yes, capture:

- **Branch**: `git branch --show-current`
- **Ref**: `git rev-parse --short HEAD`
- **Dirty**: `git status --porcelain` (non-empty output = dirty working tree)
- **Remote URL**: `git remote get-url origin 2>/dev/null` (may not exist)

If not in a git repo, set the `git` field to `null` in the JSON. Do not error.

### 5. Ask for summary

Ask the user:

> Describe what you were working on in 1-2 sentences. This will help you remember the context when you `/pop` later.

If the user prefers, offer to auto-generate a summary from the conversation context so far.

### 6. Identify key files

Ask the user which files they were actively working on. Offer to auto-detect by checking:

- Files with recent git modifications: `git diff --name-only HEAD 2>/dev/null`
- Files modified in the last hour: check git status

Present the detected files and let the user confirm or edit the list. Store as absolute paths.

### 7. Capture todo list

Check if there are active todos in the current session. If there are, capture them with their current status (pending, in_progress, completed). Include all non-completed todos.

### 8. Auto-generate name (if needed)

If no name was provided via arguments, generate one from the summary:
- Take first 3-4 meaningful words from the summary
- Convert to kebab-case
- Truncate to 40 characters
- Example: "Refactoring auth middleware" -> `refactoring-auth-middleware`

### 9. Check for name collision

If `~/.claude/stash/<name>.json` already exists:

> A stash entry named `<name>` already exists (created <timestamp>).
> Would you like to **overwrite** it or choose a **different name**?

Wait for user decision.

### 10. Build and write JSON

Assemble the stash JSON:

```json
{
  "version": 1,
  "id": "<uuid>",
  "name": "<name>",
  "timestamp": "<ISO 8601 with timezone>",
  "cwd": "<absolute path>",
  "git": {
    "branch": "<branch-name>",
    "ref": "<short-sha>",
    "dirty": true,
    "remote_url": "<url>"
  },
  "summary": "<user-provided summary>",
  "key_files": ["<absolute paths>"],
  "todos": [
    { "content": "<todo text>", "status": "<status>" }
  ],
  "notes": null
}
```

Write to `~/.claude/stash/<name>.json` using the Write tool, then set permissions:

```bash
chmod 600 ~/.claude/stash/<name>.json
```

### 11. Verify file size

Check the written file size. If it exceeds 100KB, warn:

> The stash file is unusually large (<size>). This typically means the key_files list or notes are very long. Large stash files increase the risk of sensitive data exposure.

### 12. Confirm to user

Display a summary:

> **Context saved as `<name>`**
> - Summary: <summary text>
> - Directory: <cwd>
> - Git: <branch> @ <ref> (dirty/clean)
> - Key files: <count> files recorded
> - Todos: <count> items captured
> - Stored at: `~/.claude/stash/<name>.json`
>
> **Reminder:** This is a structured bookmark, not a full session snapshot. The model's reasoning state and conversation history cannot be captured. When you `/pop` this later, you'll get a detailed handoff note — not a resumed session.

## Edge Cases

- **Not in a git repo**: Skip all git fields, set `git: null`. No error.
- **No todos**: Set `todos: []`. No error.
- **User provides no summary**: Require at least a one-sentence summary. Do not save without one.
- **Name contains invalid characters**: Sanitize to `[a-z0-9-]`. Warn if name was modified.
- **Stash directory has wrong permissions**: Fix with `chmod 700` and warn the user.
- **Disk write failure**: Report the error clearly. Do not leave partial files.
