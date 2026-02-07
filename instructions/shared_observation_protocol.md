# Shared Communication & Observation Protocol

**Every agent in the studio must follow this protocol. It is referenced by all role instruction files.**

---

## 🔴 Communication Rule: NEVER TALK TO YOUR SCREEN

**Your terminal output is NOT a communication channel. Nobody reads your pane unless they actively check it.**

If you need to tell Manager something — a question, a blocker, a completion, an observation — you MUST use `scripts/notify.sh`. Printing text to your terminal and waiting for a response will leave you stuck forever.

### ALL Communication Goes Through notify.sh

```bash
# Task completed
scripts/notify.sh manager "Task task_XXX completed. Check queue/done/task_XXX.md"

# You have a question
scripts/notify.sh manager "QUESTION from {role}: {your question}. Options: A) ... B) ... Awaiting answer."

# You are blocked
scripts/notify.sh manager "BLOCKED {role} on task_XXX: {what is blocking you}. Cannot proceed until {what you need}."

# You found a bug or issue
scripts/notify.sh manager "OBSERVATION from {role}: {description}. Suggest: {action}."

# You need a decision
scripts/notify.sh manager "DECISION NEEDED from {role}: {question}. Option A: {desc}. Option B: {desc}. Recommend: {which}."

# Progress update on long task
scripts/notify.sh manager "PROGRESS {role} task_XXX: {what is done so far, what remains}."
```

### NEVER Do This

```
# ❌ WRONG — talking to your own screen, nobody sees this
print("Should I use approach A or B? Waiting for guidance...")

# ❌ WRONG — asking a question in your output text
"I have a question about whether to use procedural or AI-generated audio.
Which approach should I take?"

# ❌ WRONG — reporting completion only to your terminal
"Task complete! All files written."
```

### ALWAYS Do This

```bash
# ✅ RIGHT — notify Manager of question
scripts/notify.sh manager "QUESTION from audio_director: Procedural audio or Qwen3-TTS for combat barks? Procedural is faster but lower quality. Recommend Qwen3-TTS per updated instructions. Awaiting confirmation."

# ✅ RIGHT — notify Manager of completion
scripts/notify.sh manager "Task task_059 completed. Check queue/done/task_059.md"

# ✅ RIGHT — notify Manager of blocker
scripts/notify.sh manager "BLOCKED gameplay_programmer on task_061: Need weapon model .glb from asset_generator before I can implement viewmodel. Cannot proceed without it."
```

### When to Notify (Event-Driven)

| Event | Notify? | Message Type |
|-------|---------|-------------|
| Task completed | ✅ ALWAYS | Completion |
| Task started | ✅ YES | Progress |
| You have a question | ✅ ALWAYS | Question |
| You are blocked | ✅ ALWAYS | Blocked |
| You found a problem | ✅ ALWAYS | Observation |
| You need a decision | ✅ ALWAYS | Decision needed |
| Long task progress (every significant milestone) | ✅ YES | Progress |
| Context running low (<15%) | ✅ YES | "CONTEXT LOW {role}: ~X% remaining on task_XXX. May need restart." |

---

## Core Principle

**You are not just a task executor. You are an expert with eyes on the product.**

When you work on a task, you see things beyond your task scope — broken features, missing essentials, process failures, potential improvements. **You MUST report these.** Staying silent about problems you notice is a failure of your role.

## When to Report Observations

Observations are **event-driven** — triggered by specific moments, not polling:

| Event | Required Action |
|-------|----------------|
| **Task completion** | Include observations in completion notes (mandatory) |
| **Bug discovery** (even outside your task) | Report immediately via notify.sh to Manager |
| **Integration failure** | Report what broke AND why the process allowed it |
| **Reading others' code/output** | Note quality issues, inconsistencies, or gaps |
| **Blocked by something** | Report the blocker AND suggest a process fix |

## Observation Categories

### 1. Product Observations (what's wrong or missing in the game)

```markdown
### Product Observation
- **what:** {specific thing observed — e.g., "scav death animation is missing"}
- **where:** {file, system, or feature — e.g., "scav_ai.gd, DEAD state"}
- **impact:** {how it affects player experience — e.g., "scavs pop out of existence on death"}
- **severity_estimate:** S|A|B|C
- **suggested_fix:** {optional — your expert opinion on what should be done}
```

### 2. Process Observations (what's wrong with how we work)

```markdown
### Process Observation
- **what:** {specific process failure — e.g., "unit tests pass but game doesn't work"}
- **root_cause:** {why the process allowed this — e.g., "no runtime verification step"}
- **impact:** {what went wrong as a result — e.g., "shipped broken build twice"}
- **suggested_fix:** {concrete rule change — e.g., "add mandatory runtime spawn check after every code task"}
- **which_instruction:** {file to update — e.g., "instructions/gameplay_programmer.md"}
```

### 3. Improvement Suggestions (how to make things better)

```markdown
### Improvement Suggestion
- **what:** {specific improvement — e.g., "add ambient audio layer to raid scene"}
- **why:** {why it matters — e.g., "silent environments feel like a tech demo, not a game"}
- **effort:** small|medium|large
- **priority_opinion:** S|A|B|C
```

### 4. Approval Requests (needs 総監督 sign-off)

```markdown
### Approval Request for 総監督
- **decision_needed:** {clear question requiring human judgment}
- **options:** A) {option} B) {option} C) {option}
- **recommendation:** {your recommended option with rationale}
- **deadline:** {when this blocks progress}
```

## How to Report

### During Task Completion (MANDATORY)

Add an `## Observations` section to your completion notes:

```markdown
## Completion
- completed_at: {timestamp}
- output_files: [...]
- tests: pass
- notes: {task-specific notes}

## Observations
{list all observations from the 4 categories above that you noticed while working on this task}
{if none, write "No observations beyond task scope."}
```

### Urgent Observations (Don't Wait for Task Completion)

If you discover something S-priority or blocking while mid-task:

```bash
scripts/notify.sh manager "OBSERVATION from {role}: {brief description}. Details: {1-2 sentences}. Suggest: {action}."
```

Manager routes these to Director. Director escalates to 総監督 if approval is needed.

## Manager's Observation Routing Rules

Manager MUST process observations as follows:

| Observation Type | Route To | Action |
|-----------------|----------|--------|
| Product S-priority | Director immediately | Create bug fix task |
| Product A-priority | Director in next update | Add to dashboard backlog |
| Product B/C | Dashboard backlog | Batch update |
| Process observation | Director immediately | Director updates instructions |
| Improvement suggestion | Director in next update | Director evaluates |
| Approval request | Dashboard "Decisions for 総監督" | Block until answered |

## What GOOD Observations Look Like

**Good:** "While implementing combat barks, I noticed scav death has no animation — they just disappear. This breaks immersion. Suggest adding a ragdoll or collapse animation. Severity: A. Effort: medium."

**Bad:** "Game could be better." (vague, no actionable info)

**Good:** "The process allowed task_051-054 to complete without runtime verification. Root cause: gameplay_programmer instructions didn't require runtime spawn check. Suggest adding mandatory runtime verification step to instructions/gameplay_programmer.md."

**Bad:** "Tests should be better." (vague, no specific fix)

## Shared Studio Memory Protocol

All specialists have access to the **shared studio memory** via `universal-memory` MCP tools. This is the studio's persistent knowledge blackboard — it survives context compression and session restarts.

### Before Every Task (MANDATORY)

Search for relevant prior knowledge:

```
recall_memories(query="{task-relevant keywords}", search_mode="hybrid", limit=10)
```

This prevents duplicate work and ensures you build on prior findings. Check if someone already solved a related problem, established a pattern, or documented a decision.

### After Every Task (MANDATORY)

Store your key finding(s):

```python
result = store_memory(
  content="{concise key finding — what you learned, decided, or built}",
  memory_type="semantic",     # "semantic" for facts/decisions, "episodic" for events, "procedural" for how-tos
  agent_id="{your_role_id}",  # e.g. "gameplay_programmer", "qa_lead"
  metadata={"task_id": "task_XXX", "tags": ["relevant", "tags"]},
  importance=0.8              # 0.0-1.0: 0.9+ for critical decisions, 0.7-0.8 for standard findings, 0.5 for minor notes
)
# Save result["memory_id"] if you need to link memories
```

### Linking Related Memories

When your finding relates to a prior memory (builds on it, contradicts it, or follows from it):

```python
link_memories(
  from_id="{your_memory_id}",
  to_id="{related_memory_id}",
  relation_type="related_to",  # or "caused_by", "contradicts", "supports", "follows"
  strength=0.8,
  created_by="{your_role_id}"
)
```

### Agent ID Conventions

Use your `role_id` (from your instruction file name) as `agent_id` in all memory calls:
- `gameplay_programmer`, `qa_lead`, `asset_generator`, `ui_designer`, `story_writer`
- `balance_designer`, `animation_director`, `art_director`, `audio_director`
- `manager` (for Manager's own entries), `director` (read-only)

### What to Store

| Store | Don't Store |
|-------|-------------|
| Key decisions and rationale | Raw task descriptions |
| Discovered bugs or patterns | Verbose logs |
| Architecture decisions | Temporary work notes |
| Style guide findings | Duplicate information |
| Integration requirements | Trivial observations |

### Importance Scale

| Score | Use For |
|:-----:|---------|
| 0.9–1.0 | Critical decisions, blocking issues, architecture choices |
| 0.7–0.8 | Standard findings, completed features, resolved bugs |
| 0.5–0.6 | Minor notes, preferences, non-blocking observations |

---

## Culture Rules

- **No blame, only fixes.** Observations are about improving the product and process, not criticizing people.
- **Specific over vague.** File names, line numbers, exact behavior. Not "something seems off."
- **Suggest, don't demand.** You observe and suggest. Director decides. 総監督 approves.
- **Silence is failure.** If you saw a problem and didn't report it, that's worse than the problem itself.
