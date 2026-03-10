# X Algorithm Reference — What Boosts Reach, What Kills It

Last updated: 2026. X's algorithm evolves — validate any major changes against current observed data.

---

## How X Distributes Content

X uses a multi-stage ranking pipeline:

1. **Candidate retrieval** — pulls posts from accounts you follow, accounts you've engaged with, and accounts the network engages with
2. **Ranking** — scores each post by predicted engagement across weighted signal types
3. **Filters** — removes low-quality signals (spam patterns, low-trust accounts, policy violations)
4. **Injection** — adds posts from outside your follow graph based on topic affinity

The implication: reach is not limited to followers. A high-scoring post gets distributed beyond the follow graph. A low-scoring post may not even reach all followers.

---

## Engagement Signal Weights

Not all engagement is equal. Approximate weighting (observed, not officially published):

| Signal | Relative Weight | Why |
|---|---|---|
| Bookmark | ~5× likes | Signals intent to return — high-value content |
| Reply | ~2–3× likes | Signals conversation, keeps post in feeds longer |
| Repost (RT) | ~2× likes | Distributes to new audiences |
| Like | 1× | Baseline positive signal |
| Profile click | ~0.5× | Curiosity signal, lower weight |
| Link click | Low / negative context | Signals leaving the platform |

**Implication for content strategy:** Write content that people want to save and return to. Lists, frameworks, step-by-step processes, contrarian takes with receipts — these earn bookmarks. Emotional posts earn likes. Educational posts earn bookmarks and likes. Controversial posts earn replies.

---

## What Boosts Reach

### Strong positive signals

**Early engagement velocity**
The first 15–30 minutes after posting are disproportionately important. If a post earns high engagement quickly, the algorithm amplifies it. If it's slow, it's deprioritised and the window closes. Post when the audience is active. For most creators: weekday mornings (08:00–10:00 local time for the primary audience), Tuesday–Thursday performing strongest.

**Author self-reply within 30 minutes**
Reply to your own post in the first 30 minutes. This adds engagement, extends the thread, keeps it in feeds, and is where to put the link (see link rule below). Ask a question in the reply — questions drive replies, replies drive reach.

**High bookmark-to-impression ratio**
Bookmark rate is the strongest quality signal per impression. Write content that people want to find again: specific data, actionable frameworks, memorable contrarian positions with evidence.

**Replies to the post**
Replies from other accounts signal conversation quality. Posts that generate back-and-forth threads stay in more feeds longer. Ask genuine questions in the final slide or body to invite this.

**Staying on platform**
X actively favours content that keeps users on X. Posts with no external links perform better. Posts that open conversations perform better.

**Profile completion and account health**
Verified accounts (paid or institutional), older accounts with consistent engagement history, and accounts with high follower-to-engagement ratios all receive ranking boosts. Account health compounds over time.

---

## What Kills Reach

### Links in the tweet body

This is the single largest reach killer. X suppresses posts with external links by an estimated 50–90% compared to the same post without a link.

**Why:** X's business interest is keeping users on X. External links undermine that.

**Rule:** Never put a URL in the tweet body. Put it in the first reply/comment. This is not optional — it is the difference between 500 and 50,000 impressions on an otherwise identical post.

### Hashtags (in 2026)

Hashtags actively reduce reach on X as of 2025–2026. The algorithm now treats hashtag use as a signal of low-quality or spam content.

**Rule:** Use zero hashtags by default. If using one, it must be highly community-specific and earned — not appended to chase discovery. Never use more than one.

**Why the change:** Hashtag stuffing was prevalent spam behaviour. X updated ranking to penalise it.

### Cross-posting patterns

Posts that look copy-pasted from other platforms (e.g. Instagram line breaks, long paragraph blocks, excessive emoji clusters, tagged @ handles from other platforms) are deprioritised. X wants native-feeling content.

**Rule:** Write for X specifically. Format for X. Line breaks should serve readability, not replicate another platform's visual style.

### Engagement bait

Posts that explicitly ask for likes, reposts, or follows ("RT if you agree", "like and follow for more") are penalised. X distinguishes between authentic engagement requests (questions, calls to reply) and mechanical engagement bait.

### Low reply-to-impression ratio

A post with high impressions but almost no replies signals low genuine interest. This can cause the algorithm to stop distributing it. A question in the body or self-reply helps.

### Posting too frequently without engagement

Posting multiple times per day without each post earning baseline engagement can suppress reach on all posts. Quality over volume.

---

## Timing

### When to post

- **Best window (for most audiences):** 08:00–10:00 and 12:00–13:00 audience local time
- **Best days:** Tuesday, Wednesday, Thursday
- **Avoid:** Friday afternoons, weekends (lower engagement, same distribution competition)

### Reply timing

- **Self-reply:** within 30 minutes of posting — this is when the post is most active in feeds
- **Replies to others' posts:** within the first hour of their post for maximum visibility in their thread

### Frequency

- 1–3 posts per day is the sustainable high-performance range
- More than 5 posts per day risks diluting per-post engagement signals
- Spacing: minimum 2 hours between posts unless there is a strong reason to cluster

---

## Content Formats That Perform

### Numbered lists and frameworks

"7 things I learned after X" — performs because it sets a clear expectation (the number) and is easy to skim. Each item should be genuinely useful, not padded.

### Contrarian takes with receipts

State a position that contradicts conventional wisdom, then back it up with evidence. The hook earns initial impressions. The receipts earn bookmarks and replies from people who want to argue or agree with specifics.

### Step-by-step processes

"How to do X in N steps" — works best as a thread. Each slide is one step. Highly bookmarkable.

### Before / after or then / now

Shows transformation over time. Works for BIP, lessons, product evolution. The contrast between states is the hook.

### Data and numbers

Specific numbers outperform vague claims every time. "37% improvement" beats "major improvement." "3 paying users in week 1" beats "early traction." Specificity signals credibility.

### Questions

Genuine questions to the audience — not rhetorical — drive replies. Replies drive reach. Use sparingly to keep them feeling authentic.

---

## Thread Mechanics

### How threads are distributed

- Only the first slide (hook tweet) is shown in the feed initially
- The algorithm scores the hook tweet's engagement to decide whether to surface the rest
- "Show this thread" click counts as engagement and signals interest in the full content
- Each slide can also be indexed and found independently

### Implications

- The hook must earn the click without relying on the thread existing
- Every slide should be worth reading on its own
- Threads that are too long (12+ slides) lose engagement sharply at the end
- Optimal thread length: 4–8 slides for most content types

### Thread reply engagement

Replies to specific slides within a thread boost the entire thread's distribution, not just that slide. Encourage replies on the slide most likely to generate a reaction.

---

## Account-Level Signals

The algorithm assesses account quality as a multiplier on post-level signals:

- **Engagement rate over time:** accounts with consistent high engagement get stronger distribution per post
- **Follower quality:** followers who engage > followers who exist. A smaller engaged audience is algorithmically more valuable than a large passive one.
- **Account age and history:** older accounts with clean history outperform newer ones with the same engagement signals
- **Posting consistency:** accounts that post regularly (even if not daily) maintain stronger baseline distribution than accounts that go silent and burst

---

## Engagement Loops

The highest-performing accounts run intentional engagement loops:

1. Post goes live
2. Self-reply within 30 min (adds context, adds the link, asks a question)
3. Reply to 3–5 posts in the niche within 30 min of your own post going live (drives traffic back to your profile)
4. Respond to every reply within the first hour
5. If the post performs well, quote-tweet it 24–48 hours later with a new angle or update

The loop compounds: each interaction keeps the post in more feeds for longer.
