---
name: agent-memory
description: >
  Shared memory system for multi-agent coordination and persistent state between sessions.
  Triggers on: "memory system", "agent coordination", "multi-agent", "session handoff",
  "task tracking", "shared context", "/agent-memory", or when setting up a new project
  that needs persistent state between sessions.
metadata:
  tags: memory, coordination, multi-agent, tasks, state, handoff, sessions
---

# Agent Memory — Multi-Agent Coordination Protocol

A `memory/` directory at `.claude/memory/` (or `~/.claude/projects/<project>/memory/`) gives
multiple agents and sequential sessions a shared source of truth. Any agent entering a project
reads from memory to get context, claims work, tracks tasks, and leaves a clean handoff.

## File Structure

```
memory/
  MEMORY.md              # Index — brief, always loaded into context
  tasks.json             # Task tracker SSOT — all open/in-progress/done tasks
  active-work.md         # Live coordination — what's actively being worked on
  completed-work.md      # Archive of finished work with details
  worklog.md             # Rolling session history (last 30 sessions)
  decisions.md           # Architecture decisions with rationale
  gotchas.md             # Known bugs, workarounds, things to avoid
  projects/              # Per-project or per-topic state files
```

For full file schemas and update rules, read `references/file-guide.md`.
For copy-paste templates, read `references/templates.md`.

---

## Session Start Protocol

1. Read `MEMORY.md` — get the index and any critical rules
2. Read `tasks.json` — understand what needs doing
3. Read `active-work.md` — see what other agents are doing right now; do not touch their files
4. Read relevant `projects/` files for the current task

---

## During Work

- Add new tasks to `tasks.json` the moment they come up — not at session end
- Check `active-work.md` before touching any file another agent might own
- Add an entry to `active-work.md` when starting work on something
- Update task status as it changes: `ready` → `in_progress` → `done`
- Record gotchas in `gotchas.md` the moment they are discovered
- Record decisions in `decisions.md` when they are made
- Update the relevant `projects/` file immediately after any meaningful change

---

## Session End Protocol

1. Move completed tasks to `completed-work.md` with full details
2. Remove own entry from `active-work.md`
3. Append a session summary to `worklog.md` (keep last 30 entries)
4. Ensure all `projects/` state files reflect current state

---

## tasks.json Schema

```json
{
  "tasks": [
    {
      "id": "unique-kebab-id",
      "title": "Short description",
      "status": "ready | in_progress | blocked | done",
      "blocked_reason": "Only present when status is blocked",
      "created": "YYYY-MM-DD",
      "notes": "Any relevant context"
    }
  ]
}
```

Status lifecycle: `ready` → `in_progress` → `done` (or `blocked` at any point).

---

## active-work.md Entry Format

```markdown
### [task-id] — Task title
- **Status**: working | paused | done
- **What**: Brief description of what is being done
- **Files**: List of files being modified
```

Remove the entry at session end or when work is handed off.

---

## Key Rules

- `tasks.json` is the single source of truth — never track tasks anywhere else
- Check `active-work.md` before modifying any file in a multi-agent environment
- Record gotchas immediately — do not wait until session end
- `MEMORY.md` must stay short (under 100 lines) — it is loaded into every context window
- `worklog.md` rolls at 30 entries — remove the oldest when adding a new one
