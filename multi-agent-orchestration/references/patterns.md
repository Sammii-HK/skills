# Multi-Agent Orchestration — Implementation Reference

Detailed implementation guide for all 10 patterns. Copy these directly into new pipelines.

---

## Pattern 1 — Agent as a CLI Process

### Basic invocation

```bash
# Minimal agent call
claude --print \
  --model claude-haiku-4-5-20251001 \
  --system-prompt "$(cat agents/planner.md)" \
  -p "$(cat state/queue/input.json)" \
  > state/queue/plan.json
```

### With MCP config and JSON output format

```bash
claude --print \
  --model claude-haiku-4-5-20251001 \
  --system-prompt "$(cat agents/researcher.md)" \
  -p "$USER_PROMPT" \
  --mcp-config mcps/researcher-mcps.json \
  --output-format json \
  > state/queue/research-findings.json
```

### Wrapping in a reusable function

```bash
run_agent() {
  local agent_name="$1"
  local user_prompt="$2"
  local output_file="$3"
  local model="${4:-claude-haiku-4-5-20251001}"
  local mcp_config="${5:-}"

  local mcp_args=""
  if [[ -n "$mcp_config" && -f "$mcp_config" ]]; then
    mcp_args="--mcp-config $mcp_config"
  fi

  claude --print \
    --model "$model" \
    --system-prompt "$(cat "agents/${agent_name}.md")" \
    -p "$user_prompt" \
    $mcp_args \
    --output-format json \
    > "$output_file"

  return $?
}
```

### Writing the system prompt

Keep system prompts in `agents/{name}.md`. Each one should specify:
- What this agent does (one sentence)
- What input it receives (file paths or data structure)
- What output it must produce (JSON schema or plain text format)
- Any constraints (length limits, tone, format requirements)

Example `agents/planner.md`:
```
You are a planning agent for a daily content pipeline.

INPUT: A JSON object with keys: metrics (usage data), queue_depth (int), recent_output (string).

OUTPUT: A JSON object with keys:
  - focus_topic (string): the single highest-priority topic for today
  - agent_directives (object): keyed by agent name, each value is a short instruction string
  - skip_agents (array of strings): agent names to skip today based on conditions
  - reasoning (string): one paragraph explaining the plan

Respond with only the JSON object. No preamble, no explanation outside the JSON.
```

---

## Pattern 2 — State Queue

### Initialise the queue directory

```bash
mkdir -p state/queue state/handoffs
```

### Validate that a required input file exists before calling an agent

```bash
require_file() {
  local file="$1"
  local agent="$2"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: Required input file '$file' missing for agent '$agent'" >&2
    exit 1
  fi
}

require_file state/queue/plan.json researcher
```

### Build a user prompt from multiple queue files

```bash
PLAN=$(cat state/queue/plan.json)
METRICS=$(cat state/queue/metrics.json 2>/dev/null || echo "{}")

USER_PROMPT=$(cat <<EOF
Plan:
$PLAN

Metrics:
$METRICS

Your task: Research the focus topic from the plan and produce a findings report.
EOF
)
```

### Naming convention

Use `{stage}-{type}.json` to make the data flow self-documenting:

| File | Written by | Read by |
|------|-----------|---------|
| `plan.json` | planner | all downstream agents |
| `metrics.json` | analytics | planner, scriptwriter |
| `research-findings.json` | researcher | scriptwriter, reviewer |
| `draft-content.json` | scriptwriter | reviewer, publisher |
| `approved-content.json` | reviewer | publisher |
| `publish-result.json` | publisher | notifier |

---

## Pattern 3 — Checkpoint and Resume

### Checkpoint file schema

```json
{
  "pipeline_id": "2026-03-10T08:00:00Z",
  "started_at": "2026-03-10T08:00:00Z",
  "agents": {
    "planner":      "completed",
    "analytics":    "completed",
    "researcher":   "failed",
    "scriptwriter": "pending",
    "reviewer":     "pending",
    "publisher":    "pending"
  }
}
```

Valid status values: `pending`, `in_progress`, `completed`, `failed`, `skipped`

### Initialise checkpoint

```bash
init_checkpoint() {
  local pipeline_id
  pipeline_id=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > state/checkpoint.json <<EOF
{
  "pipeline_id": "$pipeline_id",
  "started_at": "$pipeline_id",
  "agents": {
    "planner":      "pending",
    "analytics":    "pending",
    "researcher":   "pending",
    "scriptwriter": "pending",
    "reviewer":     "pending",
    "publisher":    "pending"
  }
}
EOF
  echo "$pipeline_id"
}
```

### Read agent status

```bash
get_agent_status() {
  local agent="$1"
  jq -r ".agents[\"$agent\"]" state/checkpoint.json
}
```

### Update agent status

```bash
set_agent_status() {
  local agent="$1"
  local status="$2"
  local tmp
  tmp=$(mktemp)
  jq ".agents[\"$agent\"] = \"$status\"" state/checkpoint.json > "$tmp" && mv "$tmp" state/checkpoint.json
}
```

### Resume logic

```bash
should_skip() {
  local agent="$1"
  local status
  status=$(get_agent_status "$agent")
  [[ "$status" == "completed" || "$status" == "skipped" ]]
}

# In the main pipeline loop:
if should_skip "researcher"; then
  echo "Skipping researcher (already completed)"
else
  set_agent_status "researcher" "in_progress"
  run_agent "researcher" "$PROMPT" "state/queue/research-findings.json"
  if [[ $? -eq 0 ]]; then
    set_agent_status "researcher" "completed"
  else
    set_agent_status "researcher" "failed"
  fi
fi
```

---

## Pattern 4 — Agent Criticality Tiers

### Declare criticality in config

In `config.json`:
```json
{
  "agents": {
    "planner":      { "tier": "critical",    "model": "claude-haiku-4-5-20251001" },
    "analytics":    { "tier": "enrichment",  "model": "claude-haiku-4-5-20251001" },
    "researcher":   { "tier": "critical",    "model": "claude-sonnet-4-5-20251001" },
    "trend-scout":  { "tier": "enrichment",  "model": "claude-haiku-4-5-20251001" },
    "scriptwriter": { "tier": "critical",    "model": "claude-sonnet-4-5-20251001" },
    "fact-checker": { "tier": "optional",    "model": "claude-haiku-4-5-20251001" },
    "reviewer":     { "tier": "enrichment",  "model": "claude-haiku-4-5-20251001" },
    "publisher":    { "tier": "critical",    "model": "claude-haiku-4-5-20251001" }
  }
}
```

### Handle failure by tier

```bash
get_tier() {
  local agent="$1"
  jq -r ".agents[\"$agent\"].tier" config.json
}

handle_agent_failure() {
  local agent="$1"
  local tier
  tier=$(get_tier "$agent")

  case "$tier" in
    critical)
      echo "CRITICAL: Agent '$agent' failed. Aborting pipeline." >&2
      log_activity "agent_abort" "$agent"
      exit 1
      ;;
    enrichment)
      echo "WARNING: Enrichment agent '$agent' failed. Continuing without it." >&2
      log_activity "agent_skip" "$agent"
      set_agent_status "$agent" "skipped"
      ;;
    optional)
      set_agent_status "$agent" "skipped"
      ;;
  esac
}

# Usage:
run_agent "researcher" "$PROMPT" "state/queue/research-findings.json" || handle_agent_failure "researcher"
```

---

## Pattern 5 — Handoff Compression

### Agent system prompt instruction (add to every agent's prompt)

```
At the END of your response, after the main output, append a section delimited by
<HANDOFF> and </HANDOFF> tags. This handoff is a plain-text summary of your key findings,
decisions, and outputs — maximum 1000 characters. Write it for a downstream agent that
needs context without reading your full output.
```

### Extract and save the handoff

```bash
save_handoff() {
  local agent="$1"
  local output_file="$2"

  # Extract content between <HANDOFF> and </HANDOFF>
  local handoff
  handoff=$(sed -n 's/.*<HANDOFF>\(.*\)<\/HANDOFF>.*/\1/p' "$output_file" 2>/dev/null)

  # Fallback: if no tags, take last 1000 chars of output
  if [[ -z "$handoff" ]]; then
    handoff=$(tail -c 1000 "$output_file")
  fi

  mkdir -p state/handoffs
  echo "$handoff" > "state/handoffs/${agent}.txt"
}

# After a successful agent run:
save_handoff "researcher" "state/queue/research-findings.json"
```

### Inject handoffs into a downstream prompt

```bash
build_prompt_with_handoffs() {
  local agents=("$@")
  local handoffs=""

  for agent in "${agents[@]}"; do
    local handoff_file="state/handoffs/${agent}.txt"
    if [[ -f "$handoff_file" ]]; then
      handoffs+="=== $agent ===\n$(cat "$handoff_file")\n\n"
    fi
  done

  # Trim to 3000 chars total to be safe
  echo -e "$handoffs" | head -c 3000
}

# Usage:
UPSTREAM_CONTEXT=$(build_prompt_with_handoffs "planner" "analytics" "researcher")
USER_PROMPT="Upstream context:\n$UPSTREAM_CONTEXT\n\nYour task: Write a script based on the research above."
```

---

## Pattern 6 — Cost Logging

### Log an agent run

```bash
log_cost() {
  local agent="$1"
  local model="$2"
  local start_ms="$3"
  local status="$4"

  local end_ms
  end_ms=$(date +%s%3N)
  local duration_ms=$(( end_ms - start_ms ))

  local entry
  entry=$(jq -nc \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg agent "$agent" \
    --arg model "$model" \
    --argjson dur "$duration_ms" \
    --arg status "$status" \
    '{"timestamp":$ts,"agent":$agent,"model":$model,"duration_ms":$dur,"status":$status}')

  echo "$entry" >> state/cost-log.jsonl
}

# Usage:
START_MS=$(date +%s%3N)
run_agent "researcher" "$PROMPT" "state/queue/research-findings.json"
RESULT=$?
STATUS=$([[ $RESULT -eq 0 ]] && echo "completed" || echo "failed")
log_cost "researcher" "claude-sonnet-4-5-20251001" "$START_MS" "$STATUS"
```

### Summarise costs after the pipeline

```bash
summarise_costs() {
  echo "--- Pipeline cost summary ---"
  echo "Total agents run: $(wc -l < state/cost-log.jsonl)"
  echo "Failed agents:    $(grep -c '"status":"failed"' state/cost-log.jsonl)"
  echo "Total duration:   $(jq -s '[.[].duration_ms] | add' state/cost-log.jsonl)ms"
  echo ""
  echo "Per-agent breakdown:"
  jq -r '"\(.agent)\t\(.model)\t\(.duration_ms)ms\t\(.status)"' state/cost-log.jsonl | column -t
}
```

---

## Pattern 7 — Planner-First

### Planner inputs

Gather everything the planner needs to make good decisions:

```bash
build_planner_prompt() {
  local metrics="{}"
  local recent_output="none"

  [[ -f state/queue/metrics.json ]] && metrics=$(cat state/queue/metrics.json)
  [[ -f state/handoffs/last-run.txt ]] && recent_output=$(cat state/handoffs/last-run.txt)

  cat <<EOF
Today: $(date -u +"%Y-%m-%d")

Current metrics:
$metrics

Last run summary:
$recent_output

Produce a plan.json with:
- focus_topic: the single highest-priority topic for today's content
- agent_directives: per-agent instructions keyed by agent name
- skip_agents: list of agent names that should be skipped today
- reasoning: one paragraph explaining your decisions
EOF
}
```

### Inject plan into downstream agents

```bash
PLAN=$(cat state/queue/plan.json)
AGENT_DIRECTIVE=$(echo "$PLAN" | jq -r ".agent_directives.researcher // \"Follow standard research procedure.\"")

USER_PROMPT="Today's plan:
$PLAN

Your directive: $AGENT_DIRECTIVE

Proceed with your research task."
```

### Check whether an agent was skipped by the planner

```bash
planner_skipped() {
  local agent="$1"
  jq -e ".skip_agents | index(\"$agent\") != null" state/queue/plan.json > /dev/null 2>&1
}

if planner_skipped "trend-scout"; then
  echo "Planner skipped trend-scout for today."
  set_agent_status "trend-scout" "skipped"
else
  run_agent "trend-scout" "$PROMPT" "state/queue/trends.json" || handle_agent_failure "trend-scout"
fi
```

---

## Pattern 8 — Selective MCP Injection

### MCP config file per agent

`mcps/researcher-mcps.json`:
```json
{
  "mcpServers": {
    "web-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": { "BRAVE_API_KEY": "${BRAVE_API_KEY}" }
    }
  }
}
```

`mcps/publisher-mcps.json`:
```json
{
  "mcpServers": {
    "spellcast": {
      "command": "node",
      "args": ["/path/to/spellcast-mcp/index.js"]
    }
  }
}
```

### Resolve MCP config path in the orchestrator

```bash
get_mcp_config() {
  local agent="$1"
  local path="mcps/${agent}-mcps.json"
  [[ -f "$path" ]] && echo "$path" || echo ""
}

run_agent_with_mcps() {
  local agent="$1"
  local prompt="$2"
  local output="$3"
  local model="$4"
  local mcp_config
  mcp_config=$(get_mcp_config "$agent")

  local mcp_args=""
  [[ -n "$mcp_config" ]] && mcp_args="--mcp-config $mcp_config"

  claude --print \
    --model "$model" \
    --system-prompt "$(cat "agents/${agent}.md")" \
    -p "$prompt" \
    $mcp_args \
    --output-format json \
    > "$output"
}
```

---

## Pattern 9 — Parallel Agent Execution

### Basic parallel pattern

```bash
run_agent_bg() {
  local agent="$1"
  local prompt="$2"
  local output="$3"
  local model="${4:-claude-haiku-4-5-20251001}"

  (
    set_agent_status "$agent" "in_progress"
    log_activity "agent_start" "$agent"
    local start_ms
    start_ms=$(date +%s%3N)

    claude --print \
      --model "$model" \
      --system-prompt "$(cat "agents/${agent}.md")" \
      -p "$prompt" \
      --output-format json \
      > "$output"

    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
      set_agent_status "$agent" "completed"
      log_activity "agent_complete" "$agent"
      log_cost "$agent" "$model" "$start_ms" "completed"
      save_handoff "$agent" "$output"
    else
      set_agent_status "$agent" "failed"
      log_activity "agent_fail" "$agent"
      log_cost "$agent" "$model" "$start_ms" "failed"
    fi
    exit $exit_code
  ) &
  echo $!
}

# Run a parallel stage
pids=()
pids+=($(run_agent_bg "researcher" "$RESEARCH_PROMPT" "state/queue/research-findings.json" "claude-sonnet-4-5-20251001"))
pids+=($(run_agent_bg "trend-scout" "$SCOUT_PROMPT"   "state/queue/trends.json"))
pids+=($(run_agent_bg "analytics"   "$ANALYTICS_PROMPT" "state/queue/metrics.json"))

# Wait and collect failures
failed=()
for i in "${!pids[@]}"; do
  local pid="${pids[$i]}"
  wait "$pid" || failed+=("$pid")
done

if [[ ${#failed[@]} -gt 0 ]]; then
  echo "WARNING: ${#failed[@]} parallel agent(s) failed. Check checkpoint for details." >&2
fi
```

### Coordinate shared state writes in parallel agents

Parallel agents must never write to the same file. Enforce this by:
1. Assigning each parallel agent its own output file
2. Having a merge agent run afterwards to combine outputs if needed

```bash
# Each agent writes its own file
researcher  → state/queue/research-findings.json
trend-scout → state/queue/trend-data.json
analytics   → state/queue/metrics.json

# A merge step combines them for downstream agents
MERGED_INPUT=$(jq -s '.[0] * .[1] * .[2]' \
  state/queue/research-findings.json \
  state/queue/trend-data.json \
  state/queue/metrics.json)
```

---

## Pattern 10 — Activity Log

### Log an event

```bash
PIPELINE_ID=""  # set at pipeline start

log_activity() {
  local event="$1"   # agent_start, agent_complete, agent_fail, agent_skip, pipeline_start, pipeline_end
  local agent="${2:-}"

  local entry
  entry=$(jq -nc \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg event "$event" \
    --arg agent "$agent" \
    --arg pid "$PIPELINE_ID" \
    '{"timestamp":$ts,"event":$event,"agent":$agent,"pipeline_id":$pid}')

  echo "$entry" >> state/activity.jsonl

  # Trim to last 200 lines
  if [[ $(wc -l < state/activity.jsonl) -gt 200 ]]; then
    tail -200 state/activity.jsonl > state/activity.jsonl.tmp
    mv state/activity.jsonl.tmp state/activity.jsonl
  fi
}
```

### Read recent activity

```bash
# Show last 20 events
tail -20 state/activity.jsonl | jq -r '"[\(.timestamp)] \(.event) \(.agent)"'

# Show only failures from the last run
jq -r 'select(.event == "agent_fail") | "\(.timestamp) \(.agent)"' state/activity.jsonl
```

---

## Putting It All Together — Wiring the Pipeline

### Typical sequential pipeline

```bash
# Stage 1: Plan (critical)
run_sequential_agent "planner" "$PLANNER_PROMPT" "state/queue/plan.json" "claude-haiku-4-5-20251001"

# Stage 2: Parallel enrichment (enrichment tier, run concurrently)
PLAN=$(cat state/queue/plan.json)
pids=()
pids+=($(run_agent_bg "analytics"   "$(build_prompt analytics)"   "state/queue/metrics.json"))
pids+=($(run_agent_bg "trend-scout" "$(build_prompt trend-scout)" "state/queue/trends.json"))
wait "${pids[@]}"

# Stage 3: Research (critical, uses plan + enrichment handoffs)
UPSTREAM=$(build_prompt_with_handoffs "planner" "analytics" "trend-scout")
run_sequential_agent "researcher" "$UPSTREAM Your task: ..." "state/queue/research-findings.json" "claude-sonnet-4-5-20251001"

# Stage 4: Write (critical, uses all upstream handoffs)
UPSTREAM=$(build_prompt_with_handoffs "planner" "researcher" "analytics")
run_sequential_agent "scriptwriter" "$UPSTREAM Your task: ..." "state/queue/draft-content.json" "claude-sonnet-4-5-20251001"

# Stage 5: Review + publish
run_sequential_agent "reviewer"  "..." "state/queue/approved-content.json" "claude-haiku-4-5-20251001"
run_sequential_agent "publisher" "..." "state/queue/publish-result.json"   "claude-haiku-4-5-20251001"
```
