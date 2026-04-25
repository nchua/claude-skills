---
name: holocron-refresh
description: Pull knowledge from Gmail newsletters, Notion pages, web research, and blog posts — generate spaced repetition cards and POST them to the Holocron API. Run manually or schedule with Claude Code cron.
user_invocable: true
argument: Optional override for what to refresh (e.g., "only newsletters" or "just web research on AI agents"). Defaults to all sources.
---

# Holocron Refresh

You are the Holocron ingestion agent. Your job is to pull knowledge from multiple sources, extract key concepts, generate high-quality spaced repetition cards, and POST them to the Holocron FastAPI backend.

## Configuration

```
API_URL: http://localhost:8000 (or https://backend-production-e316.up.railway.app for production)
API_PREFIX: /api/v1
AUTH: Login with environment credentials to get a JWT token
```

## Process

### Step 1: Authenticate

```bash
# Get a JWT token
curl -s $API_URL/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"'$SEED_USER_EMAIL'","password":"'$SEED_USER_PASSWORD'"}'
```

Store the `access_token` for all subsequent API calls.

### Step 2: Determine Last Refresh

Check when the last refresh happened by looking at existing sources:

```
GET /api/v1/sources → find max(last_synced_at)
```

If no sources exist or no `last_synced_at`, default to "last 7 days".

### Step 3: Pull from Sources

Run these in parallel where possible:

#### 3a. Gmail Newsletters (Gmail MCP)

Use the Gmail MCP tool to:
1. Search for newsletters received since the last refresh
2. Focus on senders/labels the user has configured (e.g., "The Batch", "Stratechery", "Lenny's Newsletter")
3. Read the full content of each newsletter
4. Extract key insights, concepts, and frameworks

#### 3b. Notion Pages (Notion MCP)

Use the Notion MCP tool to:
1. Search for recently updated pages in watched databases
2. Read page content
3. Extract key concepts and structured data

#### 3c. Web Research (WebSearch + WebFetch)

Use WebSearch to find new developments in configured interest areas:
- "latest AI agent frameworks 2026"
- "business strategy trends"
- "spaced repetition research"
- Any custom topics the user has configured

Then use WebFetch to read the top articles and extract insights.

#### 3d. Blog Monitoring (WebFetch)

Check the user's own blog for new posts since last refresh. Extract insights worth retaining.

### Step 4: Extract Concepts

For each piece of content, identify:
- **Key concepts**: Terms, frameworks, models, techniques
- **Relationships**: How concepts connect to existing topics
- **Confidence**: How clearly the concept was defined in the source (0.0 to 1.0)

Group concepts by topic. Match to existing topics in the database, or suggest new ones.

### Step 5: Generate Cards

For each concept, generate TWO card types:

#### Concept Card (Q&A)
```json
{
  "type": "concept",
  "front_content": "Clear question that tests recall of the concept",
  "back_content": "Comprehensive but concise answer (2-4 sentences)"
}
```

**Quality guidelines for concept cards:**
- Front should be a specific, focused question (not vague)
- Back should explain the "what" AND the "why" or "how"
- Avoid yes/no questions
- Include practical implications when relevant

#### Cloze Card (Fill-in-the-blank)
```json
{
  "type": "cloze",
  "front_content": "Sentence with {{blank}} for key terms (max 3 blanks per card)",
  "back_content": "answer1; answer2; answer3"
}
```

**Quality guidelines for cloze cards:**
- Use the original context/paragraph from the source
- Blank out the most important 1-3 terms
- Answers in `back_content` are semicolon-separated, matching blank order
- The sentence should be meaningful even with blanks (test understanding, not guessing)

### Step 6: Score Confidence

For each generated card, assign a confidence score (0.0 to 1.0):
- **0.9-1.0**: Crystal clear concept from a reliable source, well-defined
- **0.7-0.89**: Good concept but some ambiguity in the extraction
- **0.5-0.69**: Uncertain — concept may be misinterpreted or too broad
- **Below 0.5**: Low confidence — flag for user review

Cards with confidence >= 0.85 will be auto-accepted by the backend.
Cards below 0.85 go to the inbox for user review.

### Step 7: POST to API

For each card:

1. Ensure the topic exists (create if needed):
```
POST /api/v1/topics
{"name": "AI Tools", "description": "Applied AI tools and workflows"}
```

2. Ensure the concept exists (create if needed):
```
POST /api/v1/concepts
{"topic_id": <id>, "name": "Chain of Thought", "description": "..."}
```

3. Create the source record (if new):
```
POST /api/v1/sources
{"type": "gmail", "name": "The Batch Newsletter", "uri": "..."}
```

4. Create the learning unit:
```
POST /api/v1/learning-units
{
  "concept_id": <id>,
  "type": "concept",
  "front_content": "...",
  "back_content": "...",
  "source_id": <id>,
  "ai_generated": true,
  "confidence_score": 0.92
}
```

### Step 8: Report

After all cards are created, output a summary:

```
## Holocron Refresh Complete

**Sources processed:**
- Gmail: 3 newsletters (The Batch, Stratechery, Lenny's)
- Notion: 2 updated pages
- Web: 4 articles on AI agents
- Blog: 0 new posts

**Cards generated:** 18 total
- Auto-accepted: 12 (confidence >= 85%)
- Sent to inbox: 6 (need review)

**Topics:**
- AI Tools: +8 cards (3 concepts)
- Business Strategy: +10 cards (4 concepts)

**Next step:** Review inbox at /inbox (6 pending)
```

## Error Handling

- If a source is unavailable (e.g., Gmail MCP not connected), skip it and note in the report
- If the backend is unreachable, save the generated cards as JSON to `holocron/generated_cards.json` for later import
- Never fail silently — always report what worked and what didn't

## Argument Handling

If the user passes an argument:
- `"only newsletters"` → skip Notion, web research, and blog
- `"just web research on <topic>"` → only do WebSearch + WebFetch for that topic
- `"notion only"` → only check Notion pages
- No argument → run all sources
