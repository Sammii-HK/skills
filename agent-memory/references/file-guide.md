# File Guide — Agent Memory System

Detailed reference for every file in the `memory/` directory: purpose, schema, update rules,
and examples.

---

## MEMORY.md

**Purpose:** The index. Loaded into every context window at session start. Must stay short.

**Rules:**
- Keep under 100 lines
- List every other memory file with a one-line description
- Include any critical rules that apply to all agents (e.g. "never delete files without asking")
- Include the current date so agents can reason about time-sensitive tasks
- Do not put task details or project specifics here — link to the relevant file instead

**Example structure:**
```markdown
# Memory Index

## Critical Rules
- Never delete files without explicit user permission

## Files
| File | Contents |
|------|----------|
| tasks.json | SSOT for all open tasks |
| active-work.md | Live coordination |
| projects/myapp.md | Current state of myapp |
| gotchas.md | Known bugs and workarounds |

## Current Date
2025-01-15
```

---

## tasks.json

**Purpose:** Single source of truth for all open, in-progress, and blocked tasks.

**Rules:**
- Add tasks the moment they come up in conversation — not at session end
- Never track tasks anywhere else (not in chat, not in other files)
- Update status immediately when it changes
- Move `done` tasks to `completed-work.md` at session end, then remove from this file
- Keep `notes` brief — detailed context goes in `completed-work.md`

**Schema:**
```json
{
  "tasks": [
    {
      "id": "unique-kebab-id",
      "title": "Short description of the task",
      "status": "ready | in_progress | blocked | done",
      "blocked_reason": "Only present when status is blocked — explain what is blocking it",
      "created": "YYYY-MM-DD",
      "notes": "Any relevant context, links, or sub-steps"
    }
  ]
}
```

**Status lifecycle:**
```
ready → in_progress → done
          ↓
        blocked → in_progress (when unblocked)
```

**Example:**
```json
{
  "tasks": [
    {
      "id": "add-auth-middleware",
      "title": "Add authentication middleware to API routes",
      "status": "in_progress",
      "created": "2025-01-15",
      "notes": "Use JWT. Routes under /api/protected/* need it. See decisions.md for token strategy."
    },
    {
      "id": "migrate-users-table",
      "title": "Add role column to users table",
      "status": "blocked",
      "blocked_reason": "Waiting on auth middleware to be done first — need to know what roles are required",
      "created": "2025-01-15",
      "notes": ""
    }
  ]
}
```

---

## active-work.md

**Purpose:** Live coordination between parallel agents (or parallel sessions). Shows what is
actively being worked on right now so other agents know which files to avoid.

**Rules:**
- Add an entry when starting work on a task
- Update status when pausing or resuming
- Remove the entry at session end or when handing off cleanly
- Check this file before touching any file that another agent might own
- If two entries claim the same file, do not proceed — flag the conflict

**Entry format:**
```markdown
### [task-id] — Task title
- **Status**: working | paused | done
- **What**: Brief description of what is being done right now
- **Files**: Comma-separated list of files being modified
```

**Example:**
```markdown
### [add-auth-middleware] — Add authentication middleware to API routes
- **Status**: working
- **What**: Implementing JWT verification in src/middleware/auth.ts
- **Files**: src/middleware/auth.ts, src/lib/jwt.ts
```

**Conflict resolution:** If two entries claim the same file, stop and surface the conflict to
the user before proceeding.

---

## completed-work.md

**Purpose:** Archive of finished work with enough detail to understand what was done and why.
Useful for writing summaries, avoiding duplicate work, and onboarding new agents.

**Rules:**
- Add entries at session end when tasks move to `done`
- Include enough detail that someone unfamiliar with the work can understand it
- Keep entries in reverse chronological order (newest first)
- Never remove entries — this is a permanent archive

**Entry format:**
```markdown
## [task-id] — Task title
**Completed:** YYYY-MM-DD

### What was done
Brief summary of the work completed.

### Files changed
- `path/to/file.ts` — what changed and why
- `path/to/other.ts` — what changed and why

### Notes
Any important context, decisions made, or things to know for future work.
```

---

## worklog.md

**Purpose:** Rolling session history. Gives any agent a quick way to understand what happened
recently without reading through all the individual files.

**Rules:**
- Append one entry per session at session end
- Keep only the last 30 entries — remove the oldest when adding a new one
- Write in past tense
- Keep entries to 5-10 lines

**Entry format:**
```markdown
## Session — YYYY-MM-DD [optional: agent name or model]

**Tasks worked on:** task-id-one, task-id-two

**Summary:**
Brief description of what happened this session. What was completed, what was started,
what was blocked, any notable decisions or discoveries.

**Left off:** What state things are in and what the next logical step is.
```

---

## decisions.md

**Purpose:** Record of architecture and technical decisions with rationale. Prevents the same
decision from being revisited and re-debated in every session.

**Rules:**
- Add an entry when a non-obvious choice is made
- Include the alternatives that were considered and why they were rejected
- Never remove entries — decisions are permanent context
- Use reverse chronological order (newest first)

**Entry format:**
```markdown
## [decision title]
**Date:** YYYY-MM-DD

**Decision:** What was decided.

**Rationale:** Why this approach was chosen.

**Alternatives considered:**
- Alternative A — why rejected
- Alternative B — why rejected
```

---

## gotchas.md

**Purpose:** Known bugs, unexpected behaviours, environment quirks, and things to avoid.
Prevents agents from wasting time rediscovering the same problems.

**Rules:**
- Add entries immediately when a gotcha is discovered — do not wait
- Include enough context to understand when the gotcha applies and how to work around it
- Never remove entries unless the underlying issue is confirmed fixed
- Use reverse chronological order (newest first)

**Entry format:**
```markdown
## [short title]
**Discovered:** YYYY-MM-DD

**Problem:** What the issue is and when it occurs.

**Workaround:** How to avoid or fix it.
```

---

## projects/

**Purpose:** Per-project or per-topic state files. Each file captures the current state of a
specific area so agents do not have to read through commit history or code to get context.

**Rules:**
- Create one file per distinct project or topic area (e.g. `projects/api.md`, `projects/frontend.md`)
- Update immediately after any meaningful change to that project
- Include: current status, recent changes, known issues, and next steps
- Link to relevant `decisions.md` entries and `gotchas.md` entries

**Suggested structure:**
```markdown
# [Project Name]

## Status
Current state in one sentence.

## Recent Changes
- YYYY-MM-DD: What changed

## Architecture / Key Facts
The most important things to know about how this project works.

## Known Issues
Any open bugs or limitations.

## Next Steps
What should happen next.
```
