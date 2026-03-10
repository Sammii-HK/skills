#!/usr/bin/env bash
# =============================================================================
# ORCHESTRATOR TEMPLATE — Multi-Agent Claude CLI Pipeline
# =============================================================================
# Copy this file, rename it orchestrator.sh, and adapt to your pipeline.
#
# Usage:
#   ./orchestrator.sh run              — run the full pipeline
#   ./orchestrator.sh resume           — resume from last checkpoint
#   ./orchestrator.sh status           — show current checkpoint status
#   ./orchestrator.sh costs            — show cost log summary
#   ./orchestrator.sh logs [N]         — show last N activity events (default 20)
#
# Requirements: bash 4+, jq, claude CLI
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION — edit this section for your pipeline
# =============================================================================

PIPELINE_NAME="my-pipeline"

# Agent sequence — ordered list of agent names to run
# Parallel groups are handled separately (see run_parallel_stage below)
AGENT_SEQUENCE=(
  "planner"       # Stage 1: always runs first
  # Stage 2 (parallel) is handled in run_pipeline
  "researcher"    # Stage 3: after parallel enrichment
  "writer"        # Stage 4: after research
  "reviewer"      # Stage 5: after writing
  "publisher"     # Stage 6: final
)

# Agents that run in parallel (Stage 2 enrichment)
PARALLEL_AGENTS=("analytics" "trend-scout")

# Criticality tiers: critical | enrichment | optional
declare -A AGENT_TIER=(
  ["planner"]="critical"
  ["analytics"]="enrichment"
  ["trend-scout"]="enrichment"
  ["researcher"]="critical"
  ["writer"]="critical"
  ["reviewer"]="enrichment"
  ["publisher"]="critical"
)

# Model per agent — default to Haiku, upgrade to Sonnet where needed
declare -A AGENT_MODEL=(
  ["planner"]="claude-haiku-4-5-20251001"
  ["analytics"]="claude-haiku-4-5-20251001"
  ["trend-scout"]="claude-haiku-4-5-20251001"
  ["researcher"]="claude-sonnet-4-5-20251001"
  ["writer"]="claude-sonnet-4-5-20251001"
  ["reviewer"]="claude-haiku-4-5-20251001"
  ["publisher"]="claude-haiku-4-5-20251001"
)

# Output file per agent (in state/queue/)
declare -A AGENT_OUTPUT=(
  ["planner"]="plan.json"
  ["analytics"]="metrics.json"
  ["trend-scout"]="trends.json"
  ["researcher"]="research-findings.json"
  ["writer"]="draft-content.json"
  ["reviewer"]="approved-content.json"
  ["publisher"]="publish-result.json"
)

# =============================================================================
# PATHS
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$SCRIPT_DIR/state"
QUEUE_DIR="$STATE_DIR/queue"
HANDOFFS_DIR="$STATE_DIR/handoffs"
CHECKPOINT_FILE="$STATE_DIR/checkpoint.json"
ACTIVITY_LOG="$STATE_DIR/activity.jsonl"
COST_LOG="$STATE_DIR/cost-log.jsonl"
AGENTS_DIR="$SCRIPT_DIR/agents"
MCPS_DIR="$SCRIPT_DIR/mcps"

# =============================================================================
# GLOBALS (set at runtime)
# =============================================================================

PIPELINE_ID=""
RESUME_MODE=false

# =============================================================================
# UTILITIES
# =============================================================================

log() { echo "[$(date '+%H:%M:%S')] $*"; }
err() { echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2; }
die() { err "$*"; exit 1; }

require_deps() {
  for dep in jq claude; do
    command -v "$dep" &>/dev/null || die "Required dependency not found: $dep"
  done
}

ensure_dirs() {
  mkdir -p "$QUEUE_DIR" "$HANDOFFS_DIR"
  touch "$ACTIVITY_LOG" "$COST_LOG"
}

now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
now_ms()  { date +%s%3N; }

# =============================================================================
# CHECKPOINT
# =============================================================================

init_checkpoint() {
  PIPELINE_ID=$(now_iso)

  # Build agents object with all agents set to "pending"
  local agents_json="{}"
  for agent in "${AGENT_SEQUENCE[@]}" "${PARALLEL_AGENTS[@]}"; do
    agents_json=$(echo "$agents_json" | jq --arg a "$agent" '.[$a] = "pending"')
  done

  jq -n \
    --arg pid "$PIPELINE_ID" \
    --arg started "$(now_iso)" \
    --argjson agents "$agents_json" \
    '{"pipeline_id":$pid,"started_at":$started,"agents":$agents}' \
    > "$CHECKPOINT_FILE"

  log "Checkpoint initialised — pipeline ID: $PIPELINE_ID"
}

load_checkpoint() {
  [[ -f "$CHECKPOINT_FILE" ]] || die "No checkpoint file found. Run without --resume first."
  PIPELINE_ID=$(jq -r '.pipeline_id' "$CHECKPOINT_FILE")
  log "Resuming pipeline: $PIPELINE_ID"
}

get_agent_status() {
  local agent="$1"
  jq -r ".agents[\"$agent\"] // \"pending\"" "$CHECKPOINT_FILE"
}

set_agent_status() {
  local agent="$1"
  local status="$2"  # pending | in_progress | completed | failed | skipped
  local tmp
  tmp=$(mktemp)
  jq --arg a "$agent" --arg s "$status" '.agents[$a] = $s' "$CHECKPOINT_FILE" > "$tmp"
  mv "$tmp" "$CHECKPOINT_FILE"
}

should_skip() {
  local agent="$1"
  local status
  status=$(get_agent_status "$agent")
  [[ "$status" == "completed" || "$status" == "skipped" ]]
}

# =============================================================================
# ACTIVITY LOG
# =============================================================================

log_activity() {
  local event="$1"   # pipeline_start | pipeline_end | agent_start | agent_complete | agent_fail | agent_skip
  local agent="${2:-}"

  local entry
  entry=$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg event "$event" \
    --arg agent "$agent" \
    --arg pid "$PIPELINE_ID" \
    '{"timestamp":$ts,"event":$event,"agent":$agent,"pipeline_id":$pid}')

  echo "$entry" >> "$ACTIVITY_LOG"

  # Trim to last 200 lines to prevent unbounded growth
  local line_count
  line_count=$(wc -l < "$ACTIVITY_LOG")
  if (( line_count > 200 )); then
    tail -200 "$ACTIVITY_LOG" > "${ACTIVITY_LOG}.tmp"
    mv "${ACTIVITY_LOG}.tmp" "$ACTIVITY_LOG"
  fi
}

# =============================================================================
# COST LOG
# =============================================================================

log_cost() {
  local agent="$1"
  local start_ms="$2"
  local status="$3"
  local model="${AGENT_MODEL[$agent]:-unknown}"

  local end_ms
  end_ms=$(now_ms)
  local duration_ms=$(( end_ms - start_ms ))

  local entry
  entry=$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg agent "$agent" \
    --arg model "$model" \
    --argjson dur "$duration_ms" \
    --arg status "$status" \
    '{"timestamp":$ts,"agent":$agent,"model":$model,"duration_ms":$dur,"status":$status}')

  echo "$entry" >> "$COST_LOG"
}

# =============================================================================
# HANDOFFS
# =============================================================================

save_handoff() {
  local agent="$1"
  local output_file="$2"

  [[ -f "$output_file" ]] || return 0

  # Try to extract content between <HANDOFF>...</HANDOFF> tags first
  local handoff
  handoff=$(grep -oP '(?<=<HANDOFF>).*(?=</HANDOFF>)' "$output_file" 2>/dev/null | head -1)

  # Fallback: take the last 1000 chars of the output file
  if [[ -z "$handoff" ]]; then
    handoff=$(tail -c 1000 "$output_file")
  fi

  echo "$handoff" > "${HANDOFFS_DIR}/${agent}.txt"
}

get_handoffs() {
  # Usage: get_handoffs agent1 agent2 agent3
  # Returns combined handoff text, max 3000 chars
  local combined=""
  for agent in "$@"; do
    local file="${HANDOFFS_DIR}/${agent}.txt"
    if [[ -f "$file" ]]; then
      combined+="=== $agent ===
$(cat "$file")

"
    fi
  done
  echo "$combined" | head -c 3000
}

# =============================================================================
# MCP CONFIG
# =============================================================================

get_mcp_config() {
  local agent="$1"
  local path="${MCPS_DIR}/${agent}-mcps.json"
  [[ -f "$path" ]] && echo "$path" || echo ""
}

# =============================================================================
# FAILURE HANDLING
# =============================================================================

handle_failure() {
  local agent="$1"
  local tier="${AGENT_TIER[$agent]:-enrichment}"

  set_agent_status "$agent" "failed"
  log_activity "agent_fail" "$agent"

  case "$tier" in
    critical)
      err "Critical agent '$agent' failed — aborting pipeline."
      log_activity "pipeline_end" ""
      exit 1
      ;;
    enrichment)
      log "Enrichment agent '$agent' failed — skipping and continuing."
      set_agent_status "$agent" "skipped"
      ;;
    optional)
      set_agent_status "$agent" "skipped"
      ;;
  esac
}

# =============================================================================
# AGENT RUNNER — SEQUENTIAL
# =============================================================================

# Build the user prompt for a given agent.
# Override this function to inject plan, handoffs, and dynamic data.
build_user_prompt() {
  local agent="$1"

  local plan=""
  [[ -f "$QUEUE_DIR/plan.json" ]] && plan=$(cat "$QUEUE_DIR/plan.json")

  # Collect handoffs from all previously completed agents
  local completed_agents=()
  for a in "${AGENT_SEQUENCE[@]}" "${PARALLEL_AGENTS[@]}"; do
    [[ "$(get_agent_status "$a")" == "completed" ]] && completed_agents+=("$a")
  done
  local handoffs
  handoffs=$(get_handoffs "${completed_agents[@]}")

  # Get agent-specific directive from the plan (if plan exists)
  local directive=""
  if [[ -n "$plan" ]]; then
    directive=$(echo "$plan" | jq -r ".agent_directives[\"$agent\"] // \"\"" 2>/dev/null || true)
  fi

  cat <<EOF
Pipeline ID: $PIPELINE_ID
Today: $(date -u +"%Y-%m-%d")

${plan:+Plan:
$plan

}${handoffs:+Previous agent summaries:
$handoffs

}${directive:+Your directive from the planner: $directive

}Proceed with your task as defined in your system prompt.
EOF
}

run_agent() {
  local agent="$1"
  local output_file="${QUEUE_DIR}/${AGENT_OUTPUT[$agent]}"
  local model="${AGENT_MODEL[$agent]:-claude-haiku-4-5-20251001}"
  local system_prompt_file="${AGENTS_DIR}/${agent}.md"
  local mcp_config
  mcp_config=$(get_mcp_config "$agent")

  # Skip if already done (resume mode)
  if $RESUME_MODE && should_skip "$agent"; then
    log "Skipping '$agent' (already ${$(get_agent_status "$agent")})"
    return 0
  fi

  # Skip if planner told us to
  if [[ -f "$QUEUE_DIR/plan.json" ]]; then
    local skipped_by_planner
    skipped_by_planner=$(jq -e ".skip_agents | index(\"$agent\") != null" "$QUEUE_DIR/plan.json" 2>/dev/null && echo true || echo false)
    if [[ "$skipped_by_planner" == "true" ]]; then
      log "Planner skipped '$agent' — marking as skipped."
      set_agent_status "$agent" "skipped"
      log_activity "agent_skip" "$agent"
      return 0
    fi
  fi

  [[ -f "$system_prompt_file" ]] || die "System prompt not found: $system_prompt_file"

  log "Running agent: $agent (model: $model)"
  set_agent_status "$agent" "in_progress"
  log_activity "agent_start" "$agent"
  local start_ms
  start_ms=$(now_ms)

  local mcp_args=()
  [[ -n "$mcp_config" ]] && mcp_args=(--mcp-config "$mcp_config")

  local user_prompt
  user_prompt=$(build_user_prompt "$agent")

  if claude --print \
    --model "$model" \
    --system-prompt "$(cat "$system_prompt_file")" \
    -p "$user_prompt" \
    "${mcp_args[@]}" \
    --output-format json \
    > "$output_file"; then

    set_agent_status "$agent" "completed"
    log_activity "agent_complete" "$agent"
    log_cost "$agent" "$start_ms" "completed"
    save_handoff "$agent" "$output_file"
    log "Agent '$agent' completed."
  else
    log_cost "$agent" "$start_ms" "failed"
    handle_failure "$agent"
  fi
}

# =============================================================================
# AGENT RUNNER — PARALLEL
# =============================================================================

run_agent_bg() {
  local agent="$1"
  local output_file="${QUEUE_DIR}/${AGENT_OUTPUT[$agent]}"
  local model="${AGENT_MODEL[$agent]:-claude-haiku-4-5-20251001}"
  local system_prompt_file="${AGENTS_DIR}/${agent}.md"
  local mcp_config
  mcp_config=$(get_mcp_config "$agent")

  (
    # Skip if already done (resume mode)
    if $RESUME_MODE && should_skip "$agent"; then
      log "Skipping '$agent' (already ${$(get_agent_status "$agent")})"
      exit 0
    fi

    [[ -f "$system_prompt_file" ]] || { err "System prompt not found: $system_prompt_file"; exit 1; }

    log "Running agent (parallel): $agent"
    set_agent_status "$agent" "in_progress"
    log_activity "agent_start" "$agent"
    local start_ms
    start_ms=$(now_ms)

    local mcp_args=()
    [[ -n "$mcp_config" ]] && mcp_args=(--mcp-config "$mcp_config")

    local user_prompt
    user_prompt=$(build_user_prompt "$agent")

    if claude --print \
      --model "$model" \
      --system-prompt "$(cat "$system_prompt_file")" \
      -p "$user_prompt" \
      "${mcp_args[@]}" \
      --output-format json \
      > "$output_file"; then

      set_agent_status "$agent" "completed"
      log_activity "agent_complete" "$agent"
      log_cost "$agent" "$start_ms" "completed"
      save_handoff "$agent" "$output_file"
    else
      log_cost "$agent" "$start_ms" "failed"
      set_agent_status "$agent" "failed"
      log_activity "agent_fail" "$agent"
      exit 1
    fi
  ) &
  echo $!
}

run_parallel_stage() {
  # Usage: run_parallel_stage agent1 agent2 agent3
  # Runs all agents concurrently, waits for all to finish,
  # then applies failure handling per criticality tier.
  local agents=("$@")
  local pids=()
  local pid_to_agent=()

  log "Starting parallel stage: ${agents[*]}"

  for agent in "${agents[@]}"; do
    local pid
    pid=$(run_agent_bg "$agent")
    pids+=("$pid")
    pid_to_agent+=("$pid:$agent")
  done

  # Wait for all and collect failures
  local failed_agents=()
  for i in "${!pids[@]}"; do
    local pid="${pids[$i]}"
    local agent="${agents[$i]}"
    if ! wait "$pid"; then
      failed_agents+=("$agent")
    fi
  done

  # Handle failures per tier
  for agent in "${failed_agents[@]}"; do
    handle_failure "$agent"
  done

  log "Parallel stage complete. Failed: ${#failed_agents[@]}"
}

# =============================================================================
# PIPELINE
# =============================================================================

run_pipeline() {
  log "Starting pipeline: $PIPELINE_NAME ($PIPELINE_ID)"
  log_activity "pipeline_start" ""

  # -------------------------------------------------------------------
  # Stage 1: Planner (always runs first, always critical)
  # -------------------------------------------------------------------
  run_agent "planner"

  # -------------------------------------------------------------------
  # Stage 2: Parallel enrichment agents
  # These run concurrently and are typically enrichment tier.
  # -------------------------------------------------------------------
  run_parallel_stage "${PARALLEL_AGENTS[@]}"

  # -------------------------------------------------------------------
  # Stage 3+: Sequential agents
  # Skip "planner" — it already ran. Run the rest in order.
  # -------------------------------------------------------------------
  for agent in "${AGENT_SEQUENCE[@]}"; do
    [[ "$agent" == "planner" ]] && continue
    run_agent "$agent"
  done

  # -------------------------------------------------------------------
  # Done
  # -------------------------------------------------------------------
  log_activity "pipeline_end" ""
  log "Pipeline complete."
}

# =============================================================================
# STATUS COMMAND
# =============================================================================

show_status() {
  if [[ ! -f "$CHECKPOINT_FILE" ]]; then
    echo "No checkpoint file found. Pipeline has not been run yet."
    return
  fi

  echo ""
  echo "Pipeline: $(jq -r '.pipeline_id' "$CHECKPOINT_FILE")"
  echo "Started:  $(jq -r '.started_at' "$CHECKPOINT_FILE")"
  echo ""
  echo "Agent statuses:"
  jq -r '.agents | to_entries[] | "  \(.key): \(.value)"' "$CHECKPOINT_FILE"
  echo ""
}

# =============================================================================
# COSTS COMMAND
# =============================================================================

show_costs() {
  if [[ ! -f "$COST_LOG" ]] || [[ ! -s "$COST_LOG" ]]; then
    echo "No cost log found."
    return
  fi

  echo ""
  echo "Cost log summary:"
  echo ""
  echo "Total agent runs: $(wc -l < "$COST_LOG")"
  echo "Failed:           $(grep -c '"status":"failed"' "$COST_LOG" || true)"

  local total_ms
  total_ms=$(jq -s '[.[].duration_ms] | add // 0' "$COST_LOG")
  echo "Total duration:   ${total_ms}ms"
  echo ""
  echo "Per-agent breakdown:"
  jq -r '"  \(.agent)\t\(.model)\t\(.duration_ms)ms\t\(.status)"' "$COST_LOG" | column -t
  echo ""
}

# =============================================================================
# LOGS COMMAND
# =============================================================================

show_logs() {
  local n="${1:-20}"
  if [[ ! -f "$ACTIVITY_LOG" ]] || [[ ! -s "$ACTIVITY_LOG" ]]; then
    echo "No activity log found."
    return
  fi

  echo ""
  echo "Last $n activity events:"
  echo ""
  tail -"$n" "$ACTIVITY_LOG" | jq -r '"[\(.timestamp)] \(.event) \(if .agent != "" then "(\(.agent))" else "" end)"'
  echo ""
}

# =============================================================================
# ENTRYPOINT
# =============================================================================

main() {
  local command="${1:-run}"

  require_deps
  ensure_dirs

  case "$command" in
    run)
      init_checkpoint
      run_pipeline
      show_status
      show_costs
      ;;
    resume)
      RESUME_MODE=true
      load_checkpoint
      run_pipeline
      show_status
      show_costs
      ;;
    status)
      show_status
      ;;
    costs)
      show_costs
      ;;
    logs)
      show_logs "${2:-20}"
      ;;
    *)
      echo "Usage: $0 {run|resume|status|costs|logs [N]}"
      exit 1
      ;;
  esac
}

main "$@"
