---
name: holocron-research
description: Deep-dive into any topic — searches the web, reads articles, synthesizes findings into structured concepts, and generates 10-15 spaced repetition cards. Creates a mini learning path.
user_invocable: true
argument: The topic or question to research (required). E.g., "How do AI agents handle tool use?" or "FSRS spaced repetition algorithm"
---

# Holocron Research

You are the Holocron research agent. Given a topic or question, you do a deep dive: multiple web searches, read top articles, synthesize findings into structured knowledge, and generate a comprehensive set of spaced repetition cards.

## Configuration

```
API_URL: http://localhost:8000 (or https://backend-production-e316.up.railway.app)
API_PREFIX: /api/v1
AUTH: Login with environment credentials to get a JWT token
```

## Process

### Step 1: Authenticate

Get a JWT token from the backend (same as /holocron-refresh).

### Step 2: Parse the Research Topic

From the user's argument, identify:
- **Core topic**: The main subject to research
- **Specific angle**: Any particular aspect or question to focus on
- **Suggested topic name**: For the Holocron topic (e.g., "AI Agent Tool Use")

### Step 3: Research Phase

Run **3-5 web searches** with different angles:

```
Search 1: "[topic] overview explanation"
Search 2: "[topic] best practices 2026"
Search 3: "[topic] examples real world"
Search 4: "[topic] vs alternatives comparison"
Search 5: "[topic] advanced techniques"
```

For each search:
1. Use WebSearch to find relevant results
2. Use WebFetch to read the top 2-3 articles
3. Extract key concepts, frameworks, examples, and insights
4. Note the source URL and title for attribution

### Step 4: Synthesize

Organize findings into a structured knowledge map:

```
Topic: [name]
├── Concept 1: [fundamental concept]
│   ├── Definition
│   ├── Why it matters
│   └── Key details
├── Concept 2: [related concept]
│   ├── Definition
│   ├── How it relates to Concept 1
│   └── Practical application
├── Concept 3: [advanced concept]
│   ├── Definition
│   ├── When to use
│   └── Tradeoffs
...
```

Aim for **5-8 concepts** that build on each other, from foundational to advanced.

### Step 5: Generate Cards

For each concept, generate **2-3 cards** mixing types:

#### Must-have per concept:
1. **One concept card** — tests core understanding
2. **One cloze card** — tests recall of key terms in context

#### Optional per concept (for richer topics):
3. **Another concept card** — tests a different angle (e.g., "why" vs "how")

**Card quality guidelines:**
- Questions should be specific and unambiguous
- Answers should be self-contained (understandable without the question)
- Cloze blanks should test the most important terms, not filler words
- Include source attribution in the source field
- Total: 10-15 cards across all concepts

**Confidence scoring:**
- Cards from well-sourced, clear articles: 0.90+
- Cards synthesized from multiple sources: 0.80-0.89
- Cards where you're extrapolating or uncertain: 0.60-0.79

### Step 6: Create in Holocron

1. Create or find the topic:
```
GET /api/v1/topics → check if topic exists
POST /api/v1/topics → create if not
```

2. Create a source record for the research:
```
POST /api/v1/sources
{"type": "web", "name": "Research: [topic]", "uri": "[primary source URL]"}
```

3. For each concept, create the concept then its cards:
```
POST /api/v1/concepts
{"topic_id": <id>, "name": "...", "description": "..."}

POST /api/v1/learning-units
{
  "concept_id": <id>,
  "type": "concept",
  "front_content": "...",
  "back_content": "...",
  "source_id": <id>,
  "ai_generated": true,
  "confidence_score": 0.91
}
```

### Step 7: Report

```
## Holocron Research Complete: [Topic]

**Sources read:** [N] articles
- [Article 1 title] (url)
- [Article 2 title] (url)
- ...

**Knowledge structure:**
- [Concept 1 name] — [one-line description]
- [Concept 2 name] — [one-line description]
- ...

**Cards generated:** [N] total
- Auto-accepted: [N] (confidence >= 85%)
- Sent to inbox: [N] (need review)

**Learning path:** Start with [Concept 1], then [Concept 2], ...

**Next step:** Review inbox or start a review session
```

## Quality Checklist

Before POSTing cards, verify:
- [ ] No duplicate concepts (check existing concepts in the topic)
- [ ] Questions are specific, not vague ("What is X?" is fine, "Tell me about X" is not)
- [ ] Cloze blanks test important terms, not articles or prepositions
- [ ] Answers are factually accurate based on the sources read
- [ ] Each concept has at least 2 cards
- [ ] Total card count is 10-15 (not too few, not overwhelming)

## Argument Examples

```
/holocron-research "How do AI agents handle tool use?"
/holocron-research "FSRS spaced repetition algorithm deep dive"
/holocron-research "React Server Components vs Client Components"
/holocron-research "Ben Thompson's Aggregation Theory applied to AI"
```
