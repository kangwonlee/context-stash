---
description: "List all saved context stash entries with metadata, age warnings, and permission audits. Supports deleting specific entries."
argument-hint: "[--delete name]"
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(rm:*), Bash(stat:*), Bash(date:*), Bash(du:*), Bash(wc:*), Read, Glob
---

# /stash-list — List Context Bookmarks

List all saved context bookmarks in `~/.claude/stash/` with metadata, staleness warnings, and security audits.

## Arguments

The user invoked this command with: $ARGUMENTS

- If arguments include `--delete` followed by a name: delete that specific stash entry (with confirmation).
- Otherwise: list all entries.

## Steps

### 1. Check stash directory

If `~/.claude/stash/` does not exist or contains no `.json` files:

> No stash entries found. Use `/push [name]` to save your current context.

Stop here.

Check directory permissions. If not `700`:

> **WARNING:** Stash directory has permissions `<actual>` (expected `700`). Other users may be able to list your stash files. Fixing permissions...

Fix with `chmod 700 ~/.claude/stash`.

### 2. List all entries

For each `.json` file in `~/.claude/stash/`:

1. Read the JSON content
2. If JSON is malformed, mark as `[CORRUPTED]` and continue to next file
3. Extract: name, timestamp, summary (truncate to 80 chars), cwd, git branch
4. Calculate age from `timestamp` field
5. Check file permissions with `stat`
6. Get file size

### 3. Display entries

Sort by `timestamp` descending (newest first). Display as a table or formatted list:

```
NAME              AGE          SUMMARY                                            DIRECTORY
refactor-auth     2 hours ago  Refactoring auth middleware to use JWT tokens...    /Users/me/project
fix-bug-123       3 days ago   Investigating memory leak in worker pool...         /Users/me/api
old-feature       45 days ago  Adding dashboard charts [OLD - consider deleting]   /Users/me/frontend
broken-entry      unknown      [CORRUPTED]                                        unknown
```

### 4. Staleness warnings

Apply markers based on age:

- **7-30 days old**: Append `[stale]` to the entry
- **Over 30 days old**: Append `[OLD - consider deleting]`
- **Corrupted**: Append `[CORRUPTED]`

If any entries are older than 30 days, add a footer note:

> **Security note:** Old stash files accumulate sensitive context (directory paths, branch names, work summaries) that may no longer be relevant. Consider deleting stale entries with `/stash-list --delete <name>`.

### 5. Permission audit

For each file, check if permissions are `600`. If any file has different permissions:

> **WARNING:** `<filename>` has permissions `<actual>` (expected `600`). This file may have been accessed or modified by another process.

### 6. Handle `--delete`

If `--delete <name>` was provided:

1. Verify `~/.claude/stash/<name>.json` exists. If not:
   > No stash entry named `<name>` found. Available entries: <list names>

2. Read and display the entry summary:
   > **About to delete:**
   > - Name: <name>
   > - Created: <timestamp> (<age>)
   > - Summary: <summary>
   >
   > This action is permanent. Confirm deletion?

3. Wait for user confirmation.

4. If confirmed:
   ```bash
   rm ~/.claude/stash/<name>.json
   ```
   > Deleted stash entry `<name>`.

5. If not confirmed, abort.

### 7. Summary footer

After the entry list, show:

```
Total: <N> stash entries | Disk usage: <size> | Oldest: <age>
```

## Edge Cases

- **Corrupted JSON files**: List with `[CORRUPTED]` marker. Do not skip them — users need to know they exist so they can delete them.
- **Empty stash directory**: Friendly message, no error trace.
- **Mixed permissions**: Report each file individually, don't batch.
- **Very large number of entries (>20)**: Show the 20 newest and note: "<N> more entries not shown. Consider cleaning up old stashes."
- **`--delete` with non-existent name**: Show available names to help the user.
- **File exists but is not valid JSON**: Treat as corrupted.
