---
description: "Restore a previously saved context bookmark from disk. Use after a task switch to pick up where you left off. Counterpart to /push."
argument-hint: "[name]"
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(chmod:*), Bash(rm:*), Bash(git:*), Bash(date:*), Bash(stat:*), Bash(wc:*), Read, Write, Glob, Grep, TodoWrite
---

# /pop — Restore Context Bookmark

Restore a previously saved context bookmark from `~/.claude/stash/`.

## LOSSY RESTORATION WARNING — Always Display

Before restoring, always show this notice:

> **Important — Lossy Restoration**
>
> Context restoration is inherently **lossy**. What this restores:
> - Working directory path, git state, key file list, summary, and todos
>
> What this **cannot** restore:
> - The model's internal reasoning state and accumulated understanding
> - Conversation history and in-flight analysis from the original session
> - Any unsaved mental context from the previous conversation
>
> Think of this as reading a colleague's detailed handoff notes — not resuming a paused session. You will likely want to re-read the key files listed below to rebuild context.

## Arguments

The user invoked this command with: $ARGUMENTS

- If an argument is provided, use it as the stash name to look up.
- If no argument is provided, restore the **most recently created** stash (by timestamp in the JSON, not file modification time).

## Steps

### 1. Locate stash file

- If name given: look for `~/.claude/stash/<name>.json`
- If no name: list all `.json` files in `~/.claude/stash/`, read each to find the one with the most recent `timestamp` field.
- If `~/.claude/stash/` does not exist or contains no `.json` files:

  > No stash entries found. Use `/push [name]` to save your current context first.

  Stop here.

### 2. Validate the stash file

Read the JSON file and validate:

- **Parseable JSON**: If malformed, abort with:
  > This stash file appears to be corrupted (invalid JSON). For safety, corrupted files are not restored. Use `/stash-list --delete <name>` to remove it.

- **Required fields present**: `version`, `id`, `timestamp`, `cwd`

- **Schema version check**: If `version` > 1:
  > This stash was created by a newer version of context-stash (schema v<N>). Some fields may not be recognized. Proceeding with best-effort restore.

### 3. Permission audit

Check file permissions with `stat`. If permissions are not `600`:

> **WARNING:** Stash file `<name>.json` has permissions `<actual>` (expected `600`). This means other processes or users may have had access to this file. The file contents may have been read or modified by another process.
>
> Do you still want to restore from this file?

Wait for user confirmation before continuing.

### 4. Staleness check

Calculate the age of the stash entry from its `timestamp` field.

- **Older than 7 days**:
  > **Note:** This stash is <N> days old. The project state may have changed significantly since it was created.

- **Older than 30 days**:
  > **Warning:** This stash is <N> days old. It likely contains outdated context. Consider reviewing before restoring, and deleting it afterward.

### 5. Display stash summary

Show the user what will be restored:

```
Restoring: <name>
Created:   <timestamp> (<relative age>)
Summary:   <summary text>
Directory: <cwd>
Git:       <branch> @ <ref> (dirty/clean)
Key files: <count> files
Todos:     <count> items
```

### 6. Restore working directory context

Check if the recorded `cwd` still exists:

- **Exists**: Inform the user:
  > Your working directory for this context was: `<cwd>`
  > (Note: I cannot change your terminal's directory. If you're not already there, switch to it.)

- **Does not exist**:
  > **Warning:** The original working directory `<cwd>` no longer exists. The project may have been moved or deleted. Continuing with remaining context.

### 7. Display git context

If `git` field is present (not null):

- Show branch, ref, and dirty state from the stash
- Check current git state in the working directory (if it exists and is a git repo):
  - Same branch and ref: "Git state matches the stash."
  - Same branch, different ref: "Branch `<branch>` has moved since the stash. Stash ref: `<old>`, current: `<new>` (<N> commits apart)."
  - Different branch: "You're now on branch `<current>`, but the stash was on `<stashed>`."
  - Not a git repo anymore: "This directory is no longer a git repository."

### 8. Restore todo list

If the stash contains a non-empty `todos` array:

- Use TodoWrite to recreate the todo items with their original statuses
- Display the restored todos to the user

If `todos` is empty or missing, skip this step silently.

### 9. Display key files

If `key_files` is present and non-empty:

- List each file path
- For each file, check if it still exists on disk
- Mark missing files: `<path> [MISSING]`
- Suggest: "You may want to re-read the existing files above to rebuild context."

### 10. Display notes

If `notes` is present and non-null, display them under a "Notes:" heading.

### 11. Ask about stash file retention

> Keep or remove this stash entry?
> - **Keep**: The stash file stays at `~/.claude/stash/<name>.json` for future use
> - **Remove**: The stash file is deleted from disk

If remove:
```bash
rm ~/.claude/stash/<name>.json
```
Confirm deletion.

### 12. Suggest next steps

> **Suggested next steps:**
> 1. Re-read the key files listed above to rebuild your understanding
> 2. Review the restored todos and update their status as needed
> 3. Use `/stash-list` to see other saved bookmarks

## Edge Cases

- **Empty stash directory**: Friendly message pointing to `/push`. No error trace.
- **Corrupted JSON**: Abort restore immediately. Do not attempt partial restore from bad data.
- **Missing cwd**: Warn but continue restoring other fields (todos, summary, key files).
- **All key files missing**: Note that all recorded files are gone. Suggest checking git history.
- **Permission anomaly**: Require explicit user confirmation before restoring from a file with wrong permissions.
- **Multiple stashes, no name given**: Pick the newest by `timestamp` field. If timestamps are identical, pick alphabetically.
- **Name not found**: List available stash names and suggest the closest match.
