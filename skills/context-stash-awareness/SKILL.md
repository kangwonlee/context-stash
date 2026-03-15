---
name: context-stash-awareness
description: "Suggests saving context before a task switch. Triggers when the user mentions switching tasks, context switching, coming back to something later, parking work, bookmarking progress, saving their place, pausing current work, or indicating they want to do something unrelated before returning. Also triggers on phrases like 'let me quickly check', 'before I forget', 'sidetrack', or 'I need to handle something else first'."
version: 1.0.0
---

# Context Stash Awareness

When the user signals intent to switch away from their current task, gently suggest saving context first.

## Detection Signals

Watch for phrases indicating a task switch:

- "I need to switch to..."
- "Let me quickly look at / check..."
- "Before I forget, can you..."
- "Let's come back to this later"
- "Save my place / bookmark this"
- "Park this for now"
- "I need to context switch"
- "Let me handle something else first"
- "Sidetrack: ..."
- "Unrelated, but..."
- "Hold that thought"
- "Stash this"

## Response

When detecting task-switching intent, suggest briefly:

> Before switching, would you like to save your current context with `/push`?
> This captures your directory, git state, key files, and todos as a bookmark you can `/pop` later.
>
> Note: This saves a structured bookmark — not a full session snapshot. Your current conversation context will be lost once you switch topics.

## Behavior Guidelines

- **Do not block**: This is a suggestion, not a gate. If the user ignores it, proceed with their request.
- **Once per switch**: Only suggest once per apparent task switch. Don't repeat if the user has already declined or ignored the suggestion.
- **Don't suggest for quick questions**: If the user asks a simple factual question mid-task ("what's the syntax for X?"), that's not a task switch — don't suggest stashing.
- **Don't suggest if already stashed**: If the user already ran `/push` recently in this session, don't suggest it again.
