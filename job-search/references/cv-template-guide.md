# CV Template Guide

CV templates are markdown files that serve as the structural starting point for the tailor agent.
The agent rewrites them for each role — so templates define structure, section ordering, and tone,
not the final content.

---

## Template Types

| File | Use for |
|------|---------|
| `cv/templates/design-engineer.md` | Design systems, component libraries, frontend craft, animation |
| `cv/templates/dx-engineer.md` | Developer experience, documentation, SDKs, CLIs, devrel-adjacent |
| `cv/templates/product-engineer.md` | Product-facing features, growth, full-stack, user-facing impact |
| `cv/templates/software-engineer.md` | Backend, infrastructure, general engineering, systems |

The pipeline picks templates by matching keywords in the job title. The tailor agent then rewrites
the chosen template against the specific job description.

---

## ATS Best Practices (Baked In)

Apply these rules when writing or updating templates. They ensure documents survive automated
screening before reaching a human reader.

### Structure

- Use a single-column layout — no tables, no columns, no text boxes
- Use markdown headings (`##`, `###`) for sections, not horizontal rules or custom dividers
- Avoid headers and footers (some parsers strip them)
- No images, logos, or icons

### Text

- Use standard section headings: Experience, Skills, Projects, Education
- Spell out abbreviations on first use: "TypeScript (TS)" — parsers don't always resolve acronyms
- Use the role's exact language where it accurately describes the candidate.
  If the JD says "component library", use "component library" — not "UI library" or "design tokens system"
- Avoid: tables (columns collapse), columns (order randomises), text in brackets that reads as optional

### Keywords

- Skills should appear in at least two places: the Skills section and in experience bullets
- Don't keyword-stuff — only include skills the candidate genuinely has
- Include the full name of tools, not just abbreviations: "Figma" not "fig", "PostgreSQL" not "PG"

### Formatting

- Use plain hyphens for bullets (`-`), not asterisks or custom characters
- Dates: plain text ranges (`2022–2024`). ISO format optional. Avoid "Present" — use the role name as anchor
- Keep the document to one page for under 10 years experience, two pages maximum for senior roles

---

## Template Structure

Use this skeleton for all four template types. Adjust section emphasis per role type.

```markdown
# [Full Name]

[email] | [location] | [portfolio URL] | [linkedin]

---

## Summary

[2-3 sentence summary. Written in third person or noun phrase. The tailor agent adapts this
per role. Lead with discipline and experience level.]

---

## Experience

### [Job Title]
**[Company Name]** | [Year]–[Year] | [Remote / Location]

- [Achievement bullet — action verb + what + measurable result]
- [Achievement bullet]
- [Achievement bullet]

### [Job Title]
**[Company Name]** | [Year]–[Year]

- [Achievement bullet]
- [Achievement bullet]

---

## Skills

[Flat comma-separated list or short grouped lines. The tailor agent reorders by relevance.
Do not use a table.]

TypeScript, React, Next.js, Node.js, CSS, Tailwind CSS, Figma, Storybook, Playwright,
design systems, component libraries, accessibility, WCAG, performance optimisation

---

## Projects

### [Project Name]
[One sentence: what it does and your role. Include the URL if public.]
**Tech:** [Comma-separated list]

### [Project Name]
[One sentence description.]
**Tech:** [Comma-separated list]

---

## Education

**[Degree]** — [Institution], [Year]
```

---

## Per-Template Emphasis

### design-engineer.md

Lead the Skills section with: design tools, component/animation libraries, CSS depth.
Experience bullets should emphasise: design-to-code speed, component quality, cross-functional
collaboration, design system ownership.

Example bullet framing:
- "Built and maintained a typed component library used by 8 product teams, reducing design
  handoff time by 60%"
- "Owned the animation system — established motion guidelines and built reusable Framer Motion
  primitives adopted across the product"

### dx-engineer.md

Lead Skills with: documentation tooling, SDKs, CLIs, API design, writing.
Experience bullets should emphasise: developer onboarding, API ergonomics, docs quality,
feedback loops with external developers.

Example bullet framing:
- "Redesigned the SDK quickstart flow — reduced median time-to-first-API-call from 47 minutes
  to 8 minutes across 200 new signups"
- "Wrote and maintained the full API reference for a GraphQL surface of 120+ types"

### product-engineer.md

Lead Skills with: user-facing frameworks, analytics, A/B testing, full-stack.
Experience bullets should emphasise: feature ownership, user outcomes, conversion metrics,
working close to product decisions.

Example bullet framing:
- "Led the checkout redesign end-to-end (design → implementation → analysis), increasing
  completion rate from 64% to 81%"
- "Built the onboarding experiment framework — enabled the team to run 3 concurrent A/B tests
  without engineer involvement in test setup"

### software-engineer.md

Lead Skills with: languages, infrastructure, databases, testing.
Experience bullets should emphasise: system scale, reliability, performance, architecture decisions.

Example bullet framing:
- "Migrated a 200GB PostgreSQL monolith to a read-replica architecture, reducing p99 query
  latency from 4.2s to 340ms"
- "Designed and implemented a distributed job queue handling 50,000 events/minute with
  exactly-once delivery guarantees"

---

## Updating Templates

Update templates when:
- A role type consistently scores below 70 on ATS checks — the template likely lacks
  the structural keywords for that discipline
- New tooling becomes standard in a field (e.g. a new framework everyone lists)
- The tailor agent consistently adds the same section or reorders the same skills —
  bake that pattern into the template

Do not update templates after every application. They are structural anchors, not living documents.

---

## Checking a Template

Run a quick ATS check against a relevant job description to validate a new template:

```bash
cat cv/templates/design-engineer.md | claude --print -f agents/ats-checker.json \
  --user "Job description: [paste JD here]"
```

A score of 50-60 on a blank template is expected and fine — the tailor agent will bring it up.
A score below 40 suggests the template is missing structural keywords for that discipline.
