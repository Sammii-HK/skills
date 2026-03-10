# sammiihk/skills

A collection of Claude Code skills for developers — covering job hunting, multi-agent orchestration, content creation, and SEO.

Install all skills:
```bash
npx skills add sammiihk/skills
```

Install a single skill:
```bash
npx skills add sammiihk/skills/agent-memory
```

---

## Skills

### `agent-memory`
Multi-agent coordination protocol. Teaches any Claude agent how to use a shared memory system — reading context on session start, tracking tasks in `tasks.json`, claiming work in `active-work.md`, and leaving clean handoffs for the next agent.

**Trigger:** "set up agent memory", "multi-agent coordination", "session handoff", `/agent-memory`

---

### `job-search`
Full AI-powered job application pipeline. Tailors your CV to a job description, ATS-scores it, writes a cover letter, generates a merged PDF, and preps tailored interview questions — all from a single job URL.

**Trigger:** "apply for job", "tailor CV", "cover letter", "ATS check", "interview prep", `/job-search`

---

### `multi-agent-orchestration`
Battle-tested patterns for building CLI-based multi-agent pipelines with the Claude Code CLI. Covers checkpoint/resume, agent criticality tiers, handoff compression, parallel execution, cost logging, and the planner-first pattern.

**Trigger:** "multi-agent pipeline", "agent orchestration", "orchestrator script", `/multi-agent-orchestration`

---

### `x-craft`
Craft high-performing X (Twitter) posts and threads. Covers hook formulas, algorithm signals (what kills reach, what boosts it), content type detection, and thread structure.

**Trigger:** "write a tweet", "draft a thread", "X post", "build in public post", `/x-craft`

---

### `seo`
Google Search Console performance digest via Chrome browser automation. Pulls live data across 4 time windows and delivers an actionable SEO briefing with keyword opportunities, CTR optimisation candidates, and momentum trends.

**Trigger:** "how's my SEO", "search console report", "GSC digest", `/seo`

---

## Requirements

- Claude Code CLI
- Chrome MCP extension (for `seo`)
- Python 3, `pdfunite` (for `job-search`)
