---
name: job-search
description: >
  AI-assisted job application pipeline covering CV tailoring, ATS scoring, cover letter generation,
  interview preparation, and optional automated job board scanning.
  Triggers on: "job application", "apply for job", "apply to job", "tailor CV", "tailor my CV",
  "cover letter", "interview prep", "job hunting", "/job-search", "ATS check", "ATS score",
  "scan job boards", "job search pipeline", or any request to prepare application documents for a role.
---

# Job Search Pipeline

Automate the job application process from URL to finished PDF. Three stages: apply, interview prep,
and (optional) automated scanning. All document generation runs through Claude Code CLI agents.

## Prerequisites

- Claude Code CLI installed (`claude` in PATH)
- Python 3 with `requests`, `beautifulsoup4`, `lxml` (`pip install requests beautifulsoup4 lxml`)
- `pdfunite` for PDF merging (`brew install poppler` on macOS) — optional, skip to get separate files
- A `master-profile.json` describing the candidate — see `references/profile-schema.md`
- CV templates in `cv/templates/` — see `references/cv-template-guide.md`
- Notion API token (optional, Stage 3 only)

## Setup

```
job-search/
  apply.sh                  # Stage 1 — apply to a job from URL
  interview-prep.sh         # Stage 2 — research + flashcard generation
  master-profile.json       # Candidate profile (the source of truth)
  cv/
    templates/              # Base CV templates (one per role type)
    generated/              # Output: tailored CVs, cover letters, PDFs
  agents/
    cv-tailor.json          # System prompt: CV tailoring agent
    cover-letter.json       # System prompt: cover letter agent
    ats-checker.json        # System prompt: ATS scoring agent
    eligibility.json        # System prompt: pre-flight eligibility check
    interview-research.json # System prompt: company research agent
    interview-questions.json # System prompt: question bank generator
  scripts/
    fetch-jd.py             # Fetch and extract job description from URL
    generate-pdf.sh         # Convert .md to .pdf via md-to-pdf
```

---

## Stage 1 — Apply (`apply.sh <job-url>`)

Run with a job posting URL. Outputs a merged PDF (cover letter + CV) ready to submit.

### Pipeline steps

1. **Fetch job description** — Python scraper tries JSON-LD, structured data, then HTML fallback.
   Pass a second argument to override company name if scraping fails: `./apply.sh <url> "Acme Corp"`

2. **Pre-flight eligibility check** — Haiku reads the JD and the candidate's location from
   `master-profile.json`. Returns `ELIGIBLE`, `INELIGIBLE` (abort), or `UNCLEAR` (warn and continue).
   Catches location-restricted roles before spending time on documents.

3. **Pick CV template** — match role title keywords to a template:
   - `design-engineer.md` — design systems, component libraries, animation
   - `dx-engineer.md` — developer experience, docs, SDKs, CLIs
   - `product-engineer.md` — product-facing features, growth, full-stack
   - `software-engineer.md` — backend, infrastructure, general engineering

4. **Tailor CV** — Sonnet rewrites the chosen template against the JD and candidate profile.
   Optimises for keyword alignment, relevant achievements, and role-specific framing.

5. **ATS score** — Haiku scores the tailored CV (0–100), lists missing keywords, and suggests fixes.
   Review the score before proceeding. Below 70 warrants another tailoring pass.

6. **Generate cover letter** — Sonnet writes a targeted cover letter using the JD, profile, and
   tailored CV as context.

7. **Verification check** — confirm the cover letter explicitly mentions the company name.
   If not, regenerate. (CV is intentionally generic — no check needed.)

8. **Generate PDFs** — `md-to-pdf` converts both documents. `pdfunite` merges into a single file:
   `cv/generated/{company}-{role}.pdf`

### Troubleshooting apply.sh

See `references/pipeline-guide.md` — troubleshooting section covers:
- Ashby SPA scraping failures (company returns "Unknown")
- `md-to-pdf` / Puppeteer hangs
- Low ATS scores and when to re-tailor

---

## Stage 2 — Interview Prep (`interview-prep.sh <job-url>`)

Run after getting an interview. Accepts a URL or paste a JD directly.

### Pipeline steps

1. **Fetch or accept job description** — same scraper as Stage 1, or pipe JD text directly

2. **Company research** — Sonnet agent returns a structured brief:
   - Company summary and product type
   - Design / engineering maturity signals
   - Known tech stack
   - Likely interview format (take-home, system design, portfolio review, etc.)
   - Talking points aligned to the candidate's profile
   - Projects from `master-profile.json` most worth highlighting

3. **Question bank** — Sonnet generates 20 tailored questions as a CSV:
   `interview-questions-{company}.csv` (front/back format, importable to Anki or Notion)

4. **Terminal summary** — prints the research brief and next-step checklist

---

## Stage 3 — Scan (optional, advanced)

Daily automated job board scraping with Haiku filtering against the candidate profile.

Writes new matching roles to a Notion database. Deduplicates against seen jobs.

Full setup instructions in `references/pipeline-guide.md` — Stage 3 section.

---

## Reference Files

| File | Contents |
|------|----------|
| `references/profile-schema.md` | Full schema for `master-profile.json` with field descriptions and a complete example |
| `references/pipeline-guide.md` | Detailed walkthrough of every pipeline stage, agent prompts, config, and troubleshooting |
| `references/cv-template-guide.md` | How to write CV templates, ATS best practices, section structure |

---

## Quick Commands

```bash
# Apply to a job
./apply.sh "https://jobs.example.com/senior-engineer"

# Apply with company name override (for SPAs that don't scrape cleanly)
./apply.sh "https://jobs.ashby.io/company/job-id" "Acme Corp"

# Interview prep
./interview-prep.sh "https://jobs.example.com/senior-engineer"

# ATS check only (on an existing CV file)
cat cv/generated/acme-cv.md | claude --print -f agents/ats-checker.json
```
