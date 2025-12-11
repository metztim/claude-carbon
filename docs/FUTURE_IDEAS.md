# Future Feature Ideas

Ideas for future sessions. Not prioritized - just captured to avoid forgetting.

---

## 1. Claude Web/Desktop Integration

**Goal:** Track token usage from Claude web interface and desktop app, not just Claude Code CLI.

**Challenge:** Unknown how/if those apps expose usage data. Would need to investigate:
- Browser extension approach for web?
- API interception?
- Whether Anthropic exposes any usage data we could tap into

**Why it matters:** Users who switch between Claude Code and web/desktop get incomplete picture of their total consumption.

---

## 2. Personal Best Leaderboard

**Goal:** Gamify efficiency by encouraging users to "beat" their lowest-usage days.

**Key insight:** Raw daily totals are misleading - a day with 2 hours of work will naturally use fewer tokens than an 8-hour day. Need to normalize.

**Proposed metric:** Average tokens per active hour per day
- Track active hours (hours with any token usage)
- Calculate: total_tokens / active_hours
- Rank days by this normalized rate

**Example:**
- Monday: 50k tokens over 8 hours = 6,250/hr
- Tuesday: 20k tokens over 2 hours = 10,000/hr
- Monday wins despite higher absolute usage

**Motivation mechanism:** Encourage users to:
- Use less wasteful models for simpler tasks (Haiku vs Opus)
- Simplify/clarify their prompts
- Be more intentional about when to invoke AI

**UI considerations:**
- Show "personal bests" somewhere in the app
- Maybe weekly/monthly rankings
- Avoid making it feel punitive - frame as achievement/awareness
