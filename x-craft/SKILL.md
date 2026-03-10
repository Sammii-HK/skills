---
name: x-craft
description: >
  Craft high-performing X (Twitter) posts and threads using algorithm-backed content strategy.
  Triggers on: "write a tweet", "draft a thread", "craft a post", "X post", "twitter post",
  "/x-craft", "build in public post", "schedule a tweet", or any request to create content
  for X (Twitter).
---

# x-craft

Craft high-performing X (Twitter) posts and threads. Apply algorithm knowledge, content strategy, and format rules to turn any topic, idea, rough draft, or data point into content that is ready to post.

## Triggers

Activate when the user says any of:
- "write a tweet"
- "draft a thread"
- "craft a post"
- "X post"
- "twitter post"
- "/x-craft"
- "build in public post"
- "schedule a tweet"
- "post about [topic]"

---

## Workflow

### Step 1 — Analyse the input

Identify:
- **Content type**: Build in Public / Technical deep dive / Lesson or insight / Opinion or hot take / Educational save bait / Product announcement
- **Best format**: Single tweet or thread (see decision rule below)
- **What's already strong**: a number, a contrast, a hook buried in the middle that belongs at the top

### Step 2 — Check for required inputs

- **Build in Public**: requires specific numbers. If none provided, ask: "What are the actual numbers — revenue, users, growth, streak? BIP posts without specifics don't perform."
- **Technical deep dive**: requires the actual decision, code snippet, or result. Ask if missing.
- All other types: proceed with what's provided, noting any assumptions.

### Step 3 — Draft the content

Apply all format rules below. Write the post as it will appear on X — no markdown formatting, no asterisks, just plain text with line breaks.

### Step 4 — Present the output

Show each piece clearly:

For a **single tweet**:
```
TWEET

[tweet text exactly as it will appear]

Characters: X / 280
```

For a **thread**:
```
THREAD — X slides

SLIDE 1 (hook)
[text]
— X chars

SLIDE 2
[text]
— X chars

[continue for each slide]

SLIDE X (close)
[text]
— X chars
```

### Step 5 — Suggest a self-reply

Always provide a self-reply to post in the first comment within 30 minutes of going live. This is where links go. Format:

```
SELF-REPLY (post in first comment within 30 min)

[extra context, a question to the audience, or the link if there is one]
```

### Step 6 — Hand off

State: "Ready to copy and post, or want changes?" Note that this skill does not schedule — the user copies and posts, or uses their own scheduler.

---

## Format Rules

### The hook (first line)

The first line determines reach. It must contain one of:
- A specific number
- An unexpected contrast or contradiction
- A concrete detail that creates curiosity

Never open with "I", "We", or a generic statement. See `references/hooks.md` for formulas and worked examples.

### Sentence and line structure

- Short sentences. One idea per line.
- Line breaks between thoughts. White space is engagement — it signals to skimmers that the post is readable.
- No padding, no preamble, no "so I wanted to share..."

### Character limits

- Single tweet: max 280 characters
- Thread slide: max 280 characters each. Every slide must be self-contained — readable in isolation — while still flowing from the previous.

### Thread slide rules

- Slide 1: hook only. Strong enough to make someone click "show this thread."
- Middle slides: one point each. Teach, show, or prove something per slide.
- Final slide: punchy takeaway or specific CTA. Never "follow for more" or "that's a wrap" or "hope this helps."

### Links

Never put links in the tweet body. Links cut reach 50–90% on X. Put all URLs in the self-reply (first comment).

### Hashtags

Use zero hashtags as the default. Use one hashtag only if it is highly relevant and community-specific. Hashtags reduce reach on X in 2026 — they signal low-quality to the algorithm.

---

## Content Type Rules

### Build in Public

- Hook = a number or milestone. Specific. Not "things are going well."
- Tone: honest, grounded, specific. No toxic positivity. Share what's hard alongside what's working.
- Include: the number, the context, what's next or what was learned.
- If vague: ask for the numbers before drafting.

### Technical deep dive

- Lead with the non-obvious insight, not the background.
- Show the actual decision, code, or result — not just that a decision was made.
- Precise and confident. Teach something that takes effort to learn elsewhere.
- Format: often works as a thread. Single tweet if the insight is tight enough.

### Lesson / insight

- Reflect on a process, mistake, or shift in thinking.
- Make it universal: readers should recognise their own situation in it.
- Structure: what happened → what it revealed → what changed.
- First line: the lesson stated plainly, not the story. Story comes after.

### Opinion / hot take

- State the position in the first line. No hedging, no "it depends."
- Back it up in the body — one or two concrete reasons, not a list of five.
- Invite disagreement without baiting ("prove me wrong" is fine; "fight me" is not).
- Format: almost always a single tweet. Threads dilute hot takes.

### Educational / save bait

- Frameworks, checklists, numbered lists, step-by-step processes.
- Write as if it will be saved, screenshotted, and re-read later. It should still make sense without the surrounding feed.
- Bookmarks are weighted ~5× more than likes — optimise for save-ability.
- Format: thread for multi-step content; single tweet for a tight framework or insight that fits.

### Product announcement

- Lead with what changed for the user, not what was built.
- Grounded excitement — specific about what's new, why it matters.
- Avoid hype language: "game-changing", "excited to announce", "thrilled to share."
- If there's a link: body has no link, self-reply carries it.

---

## Thread vs Single Tweet

**Use a thread when:**
- There are multiple distinct points that tell a story together
- The content is step-by-step (process, tutorial, framework)
- Educational content has a clear structure (numbered, sequential)
- There is a narrative arc with a beginning, middle, and payoff

**Use a single tweet when:**
- One insight, one hot take, one milestone, one question
- The whole point can be stated in under 280 characters without loss
- It is an opinion or reaction

**When unclear:** default to single tweet. Threads that sprawl lose readers. Expand later if the single tweet performs and there is more to say.

---

## Algorithm Signals — Summary

Full detail in `references/algorithm.md`. Key rules:

| Signal | Weight | Rule |
|---|---|---|
| Bookmarks | ~5× likes | Write content people want to find again |
| Author reply within 30 min | High | Always plan a self-reply |
| Links in body | −50–90% reach | Never. Put in first comment. |
| Hashtags | Negative in 2026 | Zero, or max one |
| Impressions vs clicks | Impressions first | Don't optimise CTR at cost of reach |

---

## References

- `references/algorithm.md` — deep dive on X algorithm signals
- `references/hooks.md` — hook formulas and worked examples per content type
