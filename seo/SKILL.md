---
name: seo
description: >
  Google Search Console performance digest via Chrome browser automation.
  Triggers on "/seo", "how's my SEO doing", "search console report", "check my search performance",
  "GSC digest", "keyword opportunities", or any request to review search rankings, impressions, CTR,
  or organic traffic trends. Also trigger when the user asks about their site's Google performance,
  indexing status, or search visibility — even if they don't say "Search Console" explicitly.
  Requires the Chrome MCP browser extension.
---

# SEO Digest — Google Search Console

Pull live data from Google Search Console via Chrome MCP and deliver an actionable SEO digest
across four time windows: **3 months, 28 days, 7 days, and 24 hours**.

## Quick Start

When triggered, follow these steps in order:

1. Read `references/gsc-navigation.md` for exact Chrome automation steps
2. Navigate to Google Search Console → Performance → Search Results
3. Collect data across four time windows (see Data Collection below)
4. Analyze and produce the digest (see Digest Structure below)
5. Deliver both a **chat summary** and a **saved Markdown file**

## Core Principles

### Be Constructive, Not Alarmist

Google regularly tests pages in new positions, indexes new content slowly, and fluctuates rankings.
This means there are many legitimate reasons CTR or impressions may be temporarily low.

**Before flagging anything as a problem, consider whether it's more likely a testing phase:**

- New pages (< 4-6 weeks old) will have low/erratic CTR — this is normal indexing behavior
- Sudden impression spikes with low CTR often mean Google is testing the page in new positions — this is a GOOD sign, not a bad one
- Position improvements from page 3+ to page 1-2 always come with temporarily low CTR because impressions jump before clicks catch up
- Seasonal queries will naturally fluctuate
- Brand new content hubs take 2-3 months to stabilize

**Frame these situations as:**
- "Google is testing [page] in new positions — impressions are up which suggests growing visibility"
- "[Query] is entering the testing phase — CTR will normalize as rankings stabilize"
- "New content is being indexed — too early to optimize, monitor for another X weeks"

**Never say:** "Your CTR is bad", "This page is underperforming", or "You're losing traffic" when the data pattern suggests a testing/growth phase.

### Prioritize Opportunities Over Problems

The digest should feel like a strategy briefing, not an audit report. Lead with what's working and where the growth potential is.

## Data Collection

### Property

Ask the user which GSC property to use if not already specified. Accept any valid Search Console property URL (e.g. `https://example.com` or `sc-domain:example.com`).

### Time Windows

Collect the **Performance > Search results** data for each window. For each, capture the summary cards (clicks, impressions, CTR, position) and scan the top queries and pages tables.

| Window | Purpose |
|--------|---------|
| **Last 3 months** | Baseline trends, seasonal patterns, overall trajectory |
| **Last 28 days** | Recent stable performance, month-over-month direction |
| **Last 7 days** | Short-term momentum, recent content impact |
| **Last 24 hours** | Live snapshot, any anomalies or spikes |

### What to Capture Per Window

For each time window, record:
- **Summary metrics**: Total clicks, total impressions, average CTR, average position
- **Top 10-15 queries**: Query, clicks, impressions, CTR, position
- **Top 10-15 pages**: URL, clicks, impressions, CTR, position
- **Notable patterns**: Any significant movers up or down

### Comparison Approach

When comparing across windows, look for:
- Queries gaining impressions (Google testing them → opportunity)
- Queries with high impressions but low clicks where page has been ranked > 6 weeks (actual CTR optimization candidates)
- Pages climbing in position over the 3-month → 28-day → 7-day progression
- New queries appearing in 7-day that weren't in 28-day (fresh indexing wins)
- Any queries/pages that dropped significantly and aren't explained by seasonality

## Digest Structure

Produce the digest in this order (ranked by what matters most):

### 1. 🔮 New Keyword Opportunities
Queries where Google is showing the site for new or growing terms. These are signals of where to double down with content.
- New queries appearing in recent windows
- Queries where impressions are growing significantly
- Related query clusters that suggest content gaps to fill
- For each, suggest whether to create new content, optimize existing content, or wait and monitor

### 2. ✨ CTR Optimization Candidates
Pages/queries where CTR improvements could unlock real traffic — but ONLY flag these when the page has had stable rankings for 6+ weeks. Anything newer should be in a "monitoring" bucket instead.
- High-impression, low-CTR queries (with stable rankings)
- Suggest specific improvements: title tag rewrites, meta description hooks, schema/rich snippets
- Estimate potential click gains (e.g., "moving from 2% to 4% CTR on 5,000 impressions = ~100 more clicks/month")

### 3. 📈 Momentum & Trends
What's moving and in which direction across the four windows.
- Growing queries and pages (celebrate wins!)
- Declining queries — with context on whether it's seasonal, testing, or needs attention
- Overall trajectory: is the site's organic footprint growing, stable, or contracting?

### 4. 🔧 Technical Signals (if visible)
Only include this section if there are notable technical items visible in GSC.
- Indexing issues or coverage problems
- Any warnings or manual actions
- If everything looks clean, just say "No technical issues flagged ✅" and move on

### 5. 📋 Action Items
A prioritized short list (max 5 items) of specific next steps, each with:
- What to do
- Which page/query it relates to
- Expected impact (high/medium/low)
- Urgency (this week / this month / when you get to it)

## Output Format

### Chat Summary
Deliver a concise conversational overview hitting the highlights:
- 2-3 sentence overall assessment (positive framing)
- Top 3 most exciting opportunities
- Any items needing attention (with proper context about testing phases)
- The action items list

### Detailed Markdown File
Save a comprehensive digest file to `./seo-digest-{YYYY-MM-DD}.md` and share via present_files.

The file should include:
- Date and property header
- Raw metrics summary table for all 4 time windows
- Full analysis for each of the 5 sections above
- The prioritized action items with context

## Edge Cases

- **First time running**: No historical baseline — focus on current snapshot and opportunities without trend language.
- **Very new site / low traffic**: Be encouraging. Focus on keyword signals and content strategy, not optimization.
- **Multiple properties**: If user asks about more than one, run for each and note cross-property insights.
- **GSC not loaded / auth issues**: Walk user through getting to the right page and retry.
- **Data discrepancies**: GSC data for the last 24-48 hours is often incomplete. Note this caveat for the 24-hour window.

## Chrome Navigation Reference

For detailed step-by-step Chrome MCP automation instructions, read:
```
references/gsc-navigation.md
```
