# Pipeline Guide

Detailed walkthrough of every stage, agent, and configuration option in the job search pipeline.

---

## Stage 1 — Apply (`apply.sh`)

### Step 1: Fetch job description

`scripts/fetch-jd.py` takes a URL and returns structured JSON:

```json
{
  "company": "Acme Corp",
  "title": "Senior Design Engineer",
  "description": "Full job description text...",
  "location": "Remote",
  "url": "https://..."
}
```

**Extraction priority order:**

1. JSON-LD (`<script type="application/ld+json">`) — most reliable, structured
2. Structured data meta tags (`og:title`, role-specific schemas)
3. HTML heuristics — extracts the largest text block in a `<main>` or `<article>` element

**Company name override:**

If the scraper returns `"company": "Unknown"`, pass the company name as a second argument:

```bash
./apply.sh "https://jobs.ashby.io/company/some-id" "Acme Corp"
```

The pipeline checks for `"Unknown"` company at Step 1b and aborts early rather than generating
documents for a job that wasn't found.

---

### Step 1b: Pre-flight eligibility check

Haiku agent (`agents/eligibility.json`) receives:
- The extracted job description
- The candidate's `location` and `eligibility` fields from `master-profile.json`

Returns one of three verdicts:

| Verdict | Action |
|---------|--------|
| `ELIGIBLE` | Continue pipeline |
| `INELIGIBLE` | Abort immediately with reason |
| `UNCLEAR` | Print warning, ask user to confirm before continuing |

**System prompt skeleton for `agents/eligibility.json`:**

```json
{
  "system": "You assess whether a job posting is eligible for a candidate based on location requirements. The candidate's details will be in the user message. Reply with exactly one of: ELIGIBLE, INELIGIBLE, or UNCLEAR — followed by a one-sentence explanation. INELIGIBLE only when the posting explicitly restricts to locations that exclude the candidate. UNCLEAR when location requirements are ambiguous or not stated."
}
```

**Example call in apply.sh:**

```bash
VERDICT=$(echo "$JD_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
profile = json.load(open('master-profile.json'))
print(f\"Job: {data['title']} at {data['company']}\\nLocation field: {data.get('location','')}\\nDescription snippet: {data['description'][:2000]}\\nCandidate location: {profile['location']}\\nAuthorised countries: {profile['eligibility']['authorized_countries']}\")
" | claude --print -f agents/eligibility.json)

if echo "$VERDICT" | grep -q "^INELIGIBLE"; then
  echo "Skipping: $VERDICT"
  exit 1
fi
```

---

### Step 2: Pick CV template

Match the job title against template keywords:

```bash
pick_template() {
  local title="${1,,}"  # lowercase
  if [[ "$title" =~ (design engineer|design systems|component) ]]; then
    echo "cv/templates/design-engineer.md"
  elif [[ "$title" =~ (developer experience|dx|devrel|docs engineer) ]]; then
    echo "cv/templates/dx-engineer.md"
  elif [[ "$title" =~ (product engineer|product.*engineer|growth engineer) ]]; then
    echo "cv/templates/product-engineer.md"
  else
    echo "cv/templates/software-engineer.md"
  fi
}
```

Fallback to `software-engineer.md` when no keywords match.

---

### Step 3: Tailor CV (Sonnet)

The CV tailor agent rewrites the chosen template. It receives:

- The selected template (markdown)
- The full `master-profile.json`
- The full job description

**System prompt skeleton for `agents/cv-tailor.json`:**

```json
{
  "system": "You are an expert CV writer. You receive a CV template, a candidate profile JSON, and a job description. Rewrite the CV to maximise relevance for this specific role. Rules: (1) Never fabricate experience or skills not in the profile. (2) Reorder skills to lead with the most relevant. (3) Expand highlighted experience entries where relevant, compress others. (4) Mirror keywords from the job description where they accurately describe the candidate's experience. (5) Keep the document to one page unless the candidate has 10+ years of experience. (6) Output valid markdown only — no commentary, no preamble."
}
```

**Example call:**

```bash
TEMPLATE=$(cat "$TEMPLATE_PATH")
PROFILE=$(cat master-profile.json)
JD=$(echo "$JD_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['description'])")

TAILORED_CV=$(printf "# Template\n%s\n\n# Profile\n%s\n\n# Job Description\n%s" \
  "$TEMPLATE" "$PROFILE" "$JD" | claude --print -f agents/cv-tailor.json)

echo "$TAILORED_CV" > "cv/generated/${SLUG}-cv.md"
```

---

### Step 4: ATS score (Haiku)

Haiku evaluates the tailored CV and returns a structured report.

**System prompt skeleton for `agents/ats-checker.json`:**

```json
{
  "system": "You are an ATS (Applicant Tracking System) evaluator. You receive a tailored CV and the job description it was written for. Return a JSON object with: score (0-100 integer), missing_keywords (array of strings from the JD not present in the CV), present_keywords (array of key matches found), fixes (array of specific actionable suggestions). Only return the JSON object, no other text."
}
```

**Interpreting scores:**

| Score | Action |
|-------|--------|
| 80–100 | Proceed |
| 60–79 | Proceed with caution — review missing keywords manually |
| Below 60 | Re-tailor. Pass missing keywords explicitly to the tailor agent. |

**Re-tailoring with missing keywords:**

```bash
TAILORED_CV=$(printf "# Template\n%s\n\n# Profile\n%s\n\n# Job Description\n%s\n\n# Required keywords to include (only if they accurately describe the candidate)\n%s" \
  "$TEMPLATE" "$PROFILE" "$JD" "$MISSING_KEYWORDS" | claude --print -f agents/cv-tailor.json)
```

---

### Step 5: Generate cover letter (Sonnet)

**System prompt skeleton for `agents/cover-letter.json`:**

```json
{
  "system": "You write targeted, human cover letters for job applications. You receive a candidate profile, job description, and tailored CV. Write a cover letter that: (1) Opens with a specific hook about the company or role — not 'I am writing to apply'. (2) Connects 2-3 specific achievements from the CV to the role's key requirements. (3) Shows genuine understanding of what the company is building. (4) Closes with a clear, confident call to action. (5) Stays under 350 words. (6) Uses the candidate's name in the sign-off. Output plain markdown only."
}
```

---

### Step 5b: Verification check

```bash
COMPANY=$(echo "$JD_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['company'])")

if ! echo "$COVER_LETTER" | grep -qi "$COMPANY"; then
  echo "Warning: cover letter does not mention '$COMPANY'. Regenerating..."
  # Re-run cover letter generation with explicit instruction to mention company name
fi
```

---

### Step 6: Generate PDFs

Requires `md-to-pdf` (`npm install -g md-to-pdf`) and `pdfunite` (`brew install poppler`).

```bash
# Convert to PDFs
md-to-pdf "cv/generated/${SLUG}-cover.md" --dest "cv/generated/${SLUG}-cover.pdf"
md-to-pdf "cv/generated/${SLUG}-cv.md" --dest "cv/generated/${SLUG}-cv.pdf"

# Merge (cover letter first)
pdfunite \
  "cv/generated/${SLUG}-cover.pdf" \
  "cv/generated/${SLUG}-cv.pdf" \
  "cv/generated/${SLUG}-combined.pdf"
```

**If pdfunite is unavailable**, the pipeline can exit after generating separate PDFs. Most
application forms accept multiple file uploads.

---

## Troubleshooting — Stage 1

### Ashby SPA scraping returns "Unknown"

Ashby job boards are single-page applications. The Python scraper gets the shell HTML before
React renders the content.

**Fix:** Open the job listing in a browser, copy the full job description text, and pipe it
directly instead of fetching via URL. Or use the company name override to at least get documents
generated, then verify the JD text manually.

### `md-to-pdf` hangs or crashes

Stale Puppeteer headless Chrome processes block new renders.

**Fix:**
```bash
pkill -f "chromium.*headless"
pkill -f "chrome.*headless"
```

Then retry. If it still hangs, check available disk space — Puppeteer can fail silently when
the system is full.

### Cover letter mentions wrong company

Happens when the job description prominently mentions partner companies or competitors.
The verification check catches this. On regeneration, prepend the system prompt with:
`"The company being applied to is {COMPANY}. Mention them by name in the letter."`

---

## Stage 2 — Interview Prep (`interview-prep.sh`)

### Company research agent (Sonnet)

**System prompt skeleton for `agents/interview-research.json`:**

```json
{
  "system": "You research companies for job interview preparation. Given a job description and candidate profile, return a structured markdown brief with these sections: Company Overview (what they build, business model, stage), Design & Engineering Maturity (signals from the JD about their culture), Tech Stack (explicitly mentioned or strongly implied), Likely Interview Format (based on role type and company size), Talking Points (3-4 angles to connect the candidate's background to this role), Projects to Highlight (from the profile, which are most relevant and why). Be specific and actionable — this is read minutes before an interview."
}
```

### Question bank generator (Sonnet)

Generates 20 questions as CSV for flashcard import.

**CSV format:**

```
front,back
"Why do you want to work at {Company}?","Focus on: their specific product vision, the design maturity signals in the JD, and the opportunity to work at their scale. Reference your research brief."
"Walk me through your design system experience.","Lead with BuildKit: 400+ components consolidated, token-first workflow. Mention the measurable outcome (4-day design-to-production). Ask what their current system looks like."
```

**Question categories to cover in the 20:**

- Company/role motivation (3)
- Technical depth questions specific to the JD (6)
- Behavioural/STAR format (4)
- Design/process questions (3)
- Questions to ask the interviewer (4) — these go on the back as suggested follow-up prompts

**System prompt skeleton for `agents/interview-questions.json`:**

```json
{
  "system": "You generate tailored interview question banks as CSV. Given a job description, company research brief, and candidate profile, generate exactly 20 rows. Format: front (the question or prompt), back (how the candidate should approach answering it, referencing their specific experience). Include 4 'questions to ask the interviewer' rows — front is the question to ask, back is what a good answer from the interviewer looks like. Output CSV only, with a header row: front,back. Escape commas in fields with double quotes."
}
```

---

## Stage 3 — Automated Job Board Scanning

### Overview

A cron job (or Windmill workflow) that runs daily:

1. Fetches search result pages from configured job boards
2. Extracts individual job listings
3. Haiku scores each listing against the candidate profile (fit score 0-100)
4. Deduplicates against a local seen-jobs store
5. Writes new qualifying jobs to a Notion database

### Configuration

Create `scan-config.json`:

```json
{
  "boards": [
    {
      "name": "Ashby",
      "search_url": "https://jobs.ashby.io/?search=design+engineer&remote=true",
      "parser": "ashby"
    },
    {
      "name": "Greenhouse",
      "search_url": "https://boards.greenhouse.io/...",
      "parser": "greenhouse"
    }
  ],
  "min_fit_score": 65,
  "notion_database_id": "YOUR_DATABASE_ID",
  "seen_jobs_file": "state/seen-jobs.json"
}
```

### Haiku fit scoring agent

**System prompt skeleton:**

```json
{
  "system": "You score job listings for candidate fit. Given a job description and candidate profile, return a JSON object: score (0-100), reasons (array of 3 bullet strings — top matching factors), flags (array of concern strings — location, seniority mismatch, etc.). Score 80+ = strong match, 60-79 = worth reviewing, below 60 = skip. Return JSON only."
}
```

### Notion integration

Requires a Notion integration token with access to the target database.

```bash
export NOTION_TOKEN="ntn_..."
export NOTION_DATABASE_ID="..."

# Write a new job to Notion
python3 scripts/notion-write.py \
  --title "Senior Design Engineer @ Acme" \
  --url "https://..." \
  --score 82 \
  --status "To apply"
```

**Notion database schema (create these properties):**

| Property | Type |
|----------|------|
| Name | Title |
| Company | Text |
| Role | Text |
| URL | URL |
| Fit Score | Number |
| Status | Select: To apply / Applied / Interview / Rejected / Offer |
| Notes | Text |
| Added | Date |

### Deduplication

`state/seen-jobs.json` stores a list of URLs already processed. Check before writing to Notion:

```python
import json, os

seen_file = "state/seen-jobs.json"
seen = json.load(open(seen_file)) if os.path.exists(seen_file) else []

if job_url not in seen:
    # Write to Notion
    seen.append(job_url)
    json.dump(seen, open(seen_file, "w"))
```
