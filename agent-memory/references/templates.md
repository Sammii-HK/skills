# Templates — Agent Memory System

Copy-paste templates for every file in the `memory/` directory. Adapt as needed.

---

## tasks.json — Initial File

```json
{
  "tasks": []
}
```

## tasks.json — Single Task Entry

```json
{
  "id": "unique-kebab-id",
  "title": "Short description of the task",
  "status": "ready",
  "created": "YYYY-MM-DD",
  "notes": ""
}
```

## tasks.json — Blocked Task Entry

```json
{
  "id": "unique-kebab-id",
  "title": "Short description of the task",
  "status": "blocked",
  "blocked_reason": "Explain what is blocking this task",
  "created": "YYYY-MM-DD",
  "notes": ""
}
```

---

## active-work.md — Single Entry

```markdown
### [task-id] — Task title
- **Status**: working
- **What**: Brief description of what is being done right now
- **Files**: path/to/file.ts, path/to/other.ts
```

## active-work.md — Initial File

```markdown
# Active Work

Nothing active right now.
```

---

## worklog.md — Session Entry

```markdown
## Session — YYYY-MM-DD

**Tasks worked on:** task-id-one, task-id-two

**Summary:**
Brief description of what happened this session. What was completed, what was started,
what was blocked, any notable decisions or discoveries.

**Left off:** What state things are in and what the next logical step is.
```

## worklog.md — Initial File

```markdown
# Worklog

(Sessions appended below, newest first. Keep last 30.)
```

---

## completed-work.md — Single Entry

```markdown
## [task-id] — Task title
**Completed:** YYYY-MM-DD

### What was done
Brief summary of the work completed.

### Files changed
- `path/to/file.ts` — what changed and why

### Notes
Any important context for future agents.
```

## completed-work.md — Initial File

```markdown
# Completed Work

(Entries below, newest first.)
```

---

## decisions.md — Single Entry

```markdown
## Decision title
**Date:** YYYY-MM-DD

**Decision:** What was decided.

**Rationale:** Why this approach was chosen.

**Alternatives considered:**
- Alternative A — why rejected
- Alternative B — why rejected
```

## decisions.md — Initial File

```markdown
# Decisions

(Entries below, newest first.)
```

---

## gotchas.md — Single Entry

```markdown
## Short title describing the gotcha
**Discovered:** YYYY-MM-DD

**Problem:** What the issue is and when it occurs.

**Workaround:** How to avoid or fix it.
```

## gotchas.md — Initial File

```markdown
# Gotchas

(Entries below, newest first.)
```

---

## MEMORY.md — Full Starter Template

```markdown
# Memory Index

## Critical Rules
- [Add project-specific rules here]

## Files

| File | Contents |
|------|----------|
| `tasks.json` | SSOT for all open tasks — read on every session start |
| `active-work.md` | Live coordination — what is actively being worked on |
| `completed-work.md` | Archive of finished work |
| `worklog.md` | Rolling session history (last 30) |
| `decisions.md` | Architecture decisions with rationale |
| `gotchas.md` | Known bugs and workarounds |
| `projects/` | Per-project state files |

## Current Date
YYYY-MM-DD
```

---

## projects/example.md — Starter Template

```markdown
# [Project Name]

## Status
[One sentence describing current state.]

## Recent Changes
- YYYY-MM-DD: [What changed]

## Architecture / Key Facts
[The most important things to know about how this project works.]

## Known Issues
[Any open bugs or limitations.]

## Next Steps
[What should happen next.]
```
