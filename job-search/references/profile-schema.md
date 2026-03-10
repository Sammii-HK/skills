# Candidate Profile Schema

`master-profile.json` is the single source of truth for all CV and cover letter generation.
Every tailoring agent reads from it. Keep it accurate and updated — the quality of generated
documents is directly proportional to the quality of this file.

---

## Full Schema

```json
{
  "name": "string — full legal name as it appears on documents",
  "title": "string — current or target role title (e.g. 'Senior Design Engineer')",
  "email": "string — professional email address",
  "phone": "string — optional, include country code (e.g. '+44 7700 900000')",
  "location": "string — city and country (e.g. 'London, UK'). Used for eligibility checks.",
  "linkedin": "string — full LinkedIn URL or handle",
  "portfolio": "string — portfolio or personal site URL",
  "github": "string — GitHub profile URL, optional",
  "summary": "string — 2-3 sentences. Lead with years of experience and specialisation. Close with what you're looking for.",
  "experience": [
    {
      "title": "string — exact job title",
      "company": "string — company name",
      "duration": "string — year range (e.g. '2022–2024'). Omit months for ATS cleanliness.",
      "location": "string — 'Remote' or 'City, Country', optional",
      "bullets": [
        "string — achievement bullet. Lead with an action verb. Include a metric where possible.",
        "string — keep to 3-5 bullets per role. Quality over quantity."
      ],
      "highlight": "boolean — true if this is a key role to feature prominently. Used by the tailor agent."
    }
  ],
  "projects": [
    {
      "name": "string — project name",
      "url": "string — live URL or GitHub, optional",
      "description": "string — one sentence: what it does and what your role was",
      "tech": ["string — technology names"],
      "highlight": "boolean — true to surface this project in tailored CVs"
    }
  ],
  "skills": [
    "string — individual skill name. No categories needed here — the tailor agent reorders by relevance."
  ],
  "education": [
    {
      "degree": "string — e.g. 'BSc Computer Science'",
      "institution": "string — university or school name",
      "year": "string — graduation year or range",
      "note": "string — optional: grade, distinction, relevant modules"
    }
  ],
  "eligibility": {
    "authorized_countries": ["string — countries where legally authorised to work, e.g. 'UK'"],
    "requires_sponsorship": "boolean — true if visa sponsorship is needed",
    "remote_only": "boolean — true to filter out in-office roles"
  }
}
```

---

## Field Tips

### `summary`

Write this in third person or as a plain noun phrase — not "I am" or "I have". The tailor agent
will adapt voice to match the role. Aim for:

- Line 1: experience level + primary discipline
- Line 2: notable strengths or distinctive approach
- Line 3: what kind of role or environment you're targeting

Example:
```
"Senior design engineer with 8 years building component-driven UIs across
fintech and developer tooling. Bridges design systems and production code —
comfortable owning the gap between Figma and the browser. Seeking roles where
design quality and engineering rigour are equally valued."
```

### `experience[].bullets`

Follow the formula: **Action verb + what you did + measurable result**.

Strong: `"Rebuilt the component library from scratch, reducing design-to-code handoff time by 60%"`

Weak: `"Worked on the component library"`

Use past tense for previous roles, present tense for current role.

### `experience[].highlight`

Set `highlight: true` on the 2-3 roles most relevant to the types of jobs being targeted.
The tailor agent expands these and compresses non-highlighted roles when space is tight.

### `projects[].highlight`

Same principle — flag the 2-3 projects you most want to discuss in interviews.
These get surfaced by the interview research agent as talking points.

### `skills`

List as a flat array. No sections, no categories. Include:
- Languages (TypeScript, Python, Go)
- Frameworks (React, Next.js, Vue)
- Tools (Figma, Storybook, Playwright)
- Practices (design systems, accessibility, performance optimisation)

Avoid: "good communication skills", "team player", "fast learner" — these add no ATS value.

### `eligibility`

Used by the pre-flight eligibility agent. Be precise about `authorized_countries` — the agent
uses this to flag roles that list specific location requirements incompatible with your situation.

---

## Complete Example Profile

```json
{
  "name": "Alex Rivera",
  "title": "Senior Design Engineer",
  "email": "alex@example.com",
  "phone": "+44 7700 900123",
  "location": "London, UK",
  "linkedin": "https://linkedin.com/in/alexrivera",
  "portfolio": "https://alexrivera.dev",
  "github": "https://github.com/alexrivera",
  "summary": "Senior design engineer with 7 years building high-quality component-driven interfaces for developer tools and SaaS products. Specialises in design systems, interaction design, and bridging the gap between Figma and production code. Looking for a role where design quality and engineering craft are treated as equals.",
  "experience": [
    {
      "title": "Senior Design Engineer",
      "company": "BuildKit",
      "duration": "2022–present",
      "location": "Remote",
      "bullets": [
        "Led the v2 design system rewrite, consolidating 400+ components into a typed, accessible library used by 12 product teams",
        "Reduced average design-to-production time from 3 weeks to 4 days by introducing a token-first workflow across design and engineering",
        "Built an automated visual regression suite with Playwright and Chromatic, catching 94% of UI regressions before they reached staging",
        "Mentored 3 junior engineers through structured pairing and written playbooks, all promoted within 18 months"
      ],
      "highlight": true
    },
    {
      "title": "Frontend Engineer",
      "company": "Finovo",
      "duration": "2019–2022",
      "location": "London, UK",
      "bullets": [
        "Rebuilt the onboarding flow in React, improving completion rate from 61% to 84%",
        "Owned accessibility audit and remediation across the product — achieved WCAG 2.1 AA compliance",
        "Introduced Storybook as the team's component development environment"
      ],
      "highlight": true
    },
    {
      "title": "Junior Frontend Developer",
      "company": "Pixel Agency",
      "duration": "2017–2019",
      "location": "London, UK",
      "bullets": [
        "Built marketing sites and landing pages for 20+ clients using React and vanilla CSS",
        "Introduced Git workflow and code review process to a previously FTP-deploy team"
      ],
      "highlight": false
    }
  ],
  "projects": [
    {
      "name": "Tokens Studio Exporter",
      "url": "https://github.com/alexrivera/tokens-exporter",
      "description": "OSS plugin that exports Tokens Studio data to platform-specific formats (CSS, Tailwind, iOS, Android). 800+ GitHub stars.",
      "tech": ["TypeScript", "Figma Plugin API", "Node.js"],
      "highlight": true
    },
    {
      "name": "Scope",
      "url": "https://scope.alexrivera.dev",
      "description": "Component explorer for design tokens — visualise and audit token usage across a codebase in real time.",
      "tech": ["Next.js", "TypeScript", "Tailwind CSS"],
      "highlight": true
    }
  ],
  "skills": [
    "TypeScript", "React", "Next.js", "CSS", "Tailwind CSS",
    "Figma", "Storybook", "Playwright", "Radix UI",
    "design systems", "component libraries", "accessibility", "WCAG",
    "animation", "Framer Motion", "performance optimisation",
    "Node.js", "GraphQL", "PostgreSQL"
  ],
  "education": [
    {
      "degree": "BSc Software Engineering",
      "institution": "University of Manchester",
      "year": "2017",
      "note": "First Class Honours"
    }
  ],
  "eligibility": {
    "authorized_countries": ["UK"],
    "requires_sponsorship": false,
    "remote_only": false
  }
}
```

---

## Updating the Profile

Update `master-profile.json` after:
- Starting or leaving a role
- Completing a significant project
- Acquiring a new skill that's genuinely being used
- Getting a metric you didn't have before (conversion rate, team size, performance improvement)

Do not embellish metrics. Approximate ranges are fine — "reduced by ~40%" is honest and still effective.
