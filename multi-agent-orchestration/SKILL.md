---
name: multi-agent-orchestration
description: >
  Design and build CLI-based multi-agent pipelines using the Claude Code CLI (claude --print).
  Battle-tested patterns from a real production system (an 11-agent content pipeline).
  Triggers on: "multi-agent pipeline", "agent orchestration", "build an agent pipeline",
  "claude --print agents", "orchestrator script", "/multi-agent-orchestration".
metadata:
  tags: agents, orchestration, pipeline, bash, claude-cli, multi-agent, automation
---

# Multi-Agent Orchestration — CLI Pipeline Patterns

Build multi-agent pipelines using `claude --print` and bash. No Python frameworks, no
LangChain, no message brokers. Just Claude CLI calls, JSON files, and a bash orchestrator.

These patterns come from a production 11-agent content pipeline (Orbit) that runs daily.

For full implementation examples and a copy-paste orchestrator template, read:
- `references/patterns.md` — detailed implementation guide for all 10 patterns
- `references/orchestrator-template.sh` — complete working orchestrator to copy and adapt

---

## The Core Mental Model

Every agent is a short-lived process:
1. Read input from a JSON file in `state/queue/`
2. Do work via a `claude --print` call
3. Write output to a JSON file in `state/queue/`
4. Exit

A bash orchestrator runs agents in sequence (or in parallel), tracks state in
`state/checkpoint.json`, and handles failures per criticality tier.

---

## Pattern 1 — Agent as a CLI Process

Each agent is a `claude --print` invocation with a system prompt, a data-rich user prompt,
and optional MCP config. The orchestrator calls it, captures the output, and moves on.

```bash
claude --print \
  --model claude-haiku-4-5-20251001 \
  --system-prompt "$(cat agents/my-agent.md)" \
  -p "$USER_PROMPT" \
  --output-format json \
  > state/queue/output.json
```

Use Haiku for cheap, fast agents (planners, summarisers, classifiers). Use Sonnet for
agents that need reasoning, code generation, or nuanced judgment.

**When to use:** always — this is the atomic unit of the whole system.

---

## Pattern 2 — State Queue (JSON Files as Inter-Agent Messaging)

Agents communicate by reading and writing JSON files in `state/queue/`. No databases,
no network calls between agents, no shared memory.

Naming convention: `{stage}-{type}.json`

Examples: `plan.json`, `research-findings.json`, `draft-content.json`, `approved-content.json`

Each agent's system prompt specifies exactly which files it reads and which it writes.
The orchestrator ensures files exist before calling downstream agents.

**When to use:** always — the queue is the spine of every pipeline.

---

## Pattern 3 — Checkpoint and Resume

`state/checkpoint.json` tracks agent status: `completed`, `failed`, `pending`, or `skipped`.
On `--resume`, the orchestrator reads the checkpoint and skips completed agents, picking up
from the first non-completed one.

```json
{
  "pipeline_id": "2026-03-10T08:00:00Z",
  "agents": {
    "planner":    "completed",
    "analytics":  "completed",
    "researcher": "failed",
    "scriptwriter": "pending"
  }
}
```

**When to use:** any pipeline with more than 3 agents, or any pipeline that may be interrupted.

---

## Pattern 4 — Agent Criticality Tiers

Classify every agent as one of three tiers and handle failures accordingly:

| Tier | Behaviour on failure |
|------|----------------------|
| **critical** | Abort the entire pipeline immediately |
| **enrichment** | Log the failure, skip the agent, continue |
| **optional** | Fail silently, do not log prominently |

Declare tiers in a config or at the top of the orchestrator. The failure handler reads the
tier and decides whether to `exit 1` or `continue`.

**When to use:** any pipeline where some agents are non-negotiable and others are nice-to-have.

---

## Pattern 5 — Handoff Compression

Each agent produces a short plain-text summary (target: ~1000 chars) saved to
`state/handoffs/{agent-name}.txt`. Downstream agents receive these summaries injected into
their user prompt — context without loading full JSON outputs into the context window.

```bash
HANDOFFS=$(cat state/handoffs/planner.txt state/handoffs/analytics.txt 2>/dev/null | head -c 2000)
USER_PROMPT="Previous agent summaries:\n$HANDOFFS\n\nYour task: ..."
```

**When to use:** any pipeline where agents need context from earlier stages. Always cheaper
than passing raw JSON downstream.

---

## Pattern 6 — Cost Logging

Append one JSONL line to `state/cost-log.jsonl` after every agent run:

```json
{"timestamp":"2026-03-10T08:01:23Z","agent":"analytics","model":"claude-haiku-4-5-20251001","duration_ms":4231,"status":"completed"}
```

Review the log to find slow agents, repeated failures, and opportunities to downgrade models.

**When to use:** any pipeline running on a schedule. Indispensable for cost auditing.

---

## Pattern 7 — Planner-First

Run a cheap planning agent (Haiku) as the first step. It reads all available state
(metrics, recent outputs, queue depth) and produces a `plan.json` with per-agent directives.
Every subsequent agent receives the plan as part of its user prompt.

This makes the pipeline adaptive — instead of every agent running with static instructions,
each one gets guidance calibrated to today's conditions.

**When to use:** any pipeline that runs repeatedly (daily, hourly) on changing inputs.

---

## Pattern 8 — Selective MCP Injection

Give each agent only the MCPs it actually needs via `--mcp-config agent-mcps.json`.
Do not pass a global MCP config to every agent.

Benefits: smaller context, tighter blast radius if an agent misbehaves, easier debugging.

Maintain one MCP config file per agent (or per agent group). The orchestrator passes the
correct one when invoking each agent.

**When to use:** any pipeline where agents have different tool access requirements.

---

## Pattern 9 — Parallel Agent Execution

Independent agents at the same pipeline stage run in parallel using bash `&` and `wait`.
Collect PIDs, wait for all, then check exit codes before proceeding.

```bash
pids=()
run_agent "researcher" & pids+=($!)
run_agent "scout"      & pids+=($!)
wait "${pids[@]}"
# check exit codes before continuing
```

**When to use:** whenever two or more agents in the same stage have no data dependency on
each other. Common in research/enrichment stages.

---

## Pattern 10 — Activity Log

Append-only JSONL activity log at `state/activity.jsonl`. Log every agent start, complete,
fail, and skip event. Auto-trim to the last 200 lines to prevent unbounded growth.

```json
{"timestamp":"2026-03-10T08:00:01Z","event":"agent_start","agent":"planner","pipeline_id":"2026-03-10T08:00:00Z"}
{"timestamp":"2026-03-10T08:01:10Z","event":"agent_complete","agent":"planner","pipeline_id":"2026-03-10T08:00:00Z"}
```

**When to use:** always. The activity log is the first thing to read when debugging a failed run.

---

## Recommended Directory Layout

```
pipeline-name/
  orchestrator.sh           # Main entry point
  agents/
    planner.md              # System prompts (one file per agent)
    researcher.md
    writer.md
    ...
  mcps/
    researcher-mcps.json    # Per-agent MCP configs
    writer-mcps.json
  state/
    queue/                  # Inter-agent JSON messages
      plan.json
      research-findings.json
      draft-content.json
    handoffs/               # Compressed summaries for downstream injection
      planner.txt
      researcher.txt
    checkpoint.json         # Pipeline resume state
    activity.jsonl          # Append-only event log
    cost-log.jsonl          # Per-agent cost/duration log
  config.json               # Pipeline config (model choices, criticality tiers, etc.)
```

---

## Choosing Models

| Use case | Model |
|----------|-------|
| Planning, classification, summarisation | Haiku (fast, cheap) |
| Research synthesis, content drafting | Sonnet |
| Complex reasoning, code generation | Sonnet or Opus |

Default to Haiku unless the task demonstrably needs more capability. A 10-agent pipeline
running daily on Haiku costs a fraction of the same pipeline on Sonnet.
