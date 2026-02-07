# Sub-Agent Delegation Protocol (AORCHESTRA)

This protocol defines how specialists create and delegate work to sub-agents. Based on the AORCHESTRA framework (arXiv 2602.03786): every agent is a 4-tuple `<Instruction, Context, Tools, Model>`.

**You are a team leader.** When your task contains parallelizable subtasks, mechanical work, or search-heavy components, you MAY spawn sub-agents to handle them. You remain responsible for the final output quality.

---

## The 4-Tuple Abstraction

Before spawning a sub-agent, compose all four elements:

| Tuple Element | What It Specifies | Maps To |
|---------------|-------------------|---------|
| **Instruction** | Objective, success criteria, constraints | Task tool `prompt` body |
| **Context** | Curated facts, prior results, relevant files | Prepended in Task tool `prompt` |
| **Tools** | What the sub-agent can do | Task tool `subagent_type` |
| **Model** | Intelligence tier for this subtask | Task tool `model` parameter |

---

## When to Delegate

**DO delegate when:**
- You have 2+ independent subtasks that can run in parallel
- A subtask is mechanical (file search, data extraction, formatting, running tests)
- You need to search many files, read large codebases, or gather context from many sources
- A subtask is clearly scoped with objective success criteria
- A task has 3+ distinct deliverables (e.g., "create 5 voice lines + integrate + test")
- A task mixes research AND implementation

**DO NOT delegate when:**
- The subtask requires your specialist judgment (creative decisions, quality review)
- The work is a single simple step you can do faster yourself
- The subtask's output needs tight integration with your ongoing reasoning
- You're a quality gate role (reviewer) — that judgment is yours alone
- Decomposition overhead exceeds the benefit

---

## How to Delegate: The 4-Tuple Composition

### Step 1: Instruction

Write a clear, self-contained objective. The sub-agent has no prior context — everything it needs must be in the prompt.

```
## Instruction
{What to do — specific, unambiguous}

## Success Criteria
- {Measurable criterion 1}
- {Measurable criterion 2}

## Constraints
- {What NOT to do}
- {Boundaries and limitations}
```

### Step 2: Context (CRITICAL — This Is the Biggest Performance Gain)

**Do NOT pass your full conversation history.** Do NOT pass zero context. Curate only what's relevant.

**Context curation checklist:**
1. **Query shared memory** for the 3-5 most relevant findings:
   ```
   recall_memories(query="{subtask keywords}", search_mode="hybrid", limit=5, min_importance=0.7)
   ```
2. **Reference specific files** the sub-agent needs (exact paths, not directories)
3. **Summarize prior results** in 2-5 sentences — don't paste raw output
4. **Include numerical values** the sub-agent needs (poly counts, test counts, config values)

Prepend context in the prompt:
```
## Context
{Curated summary — 5-15 lines, not a dump}
Relevant files: {path1}, {path2}
Prior finding: {key result from memory, with memory ID}
Baseline: {specific number}
```

### Step 3: Tools (Sub-Agent Type Selection)

| subagent_type | Capabilities | Use When |
|---------------|-------------|----------|
| `Bash` | Shell commands only | Running godot tests, gpu-run.sh, file operations, builds |
| `Explore` | Read, Grep, Glob, Search | Searching codebase, finding files/patterns, reading docs |
| `general-purpose` | All tools | Complex multi-step tasks requiring reading, writing, searching, and execution |

**Default to `Bash` or `Explore` when possible** — they are faster and cheaper than `general-purpose`.

### Step 4: Model Selection

| Model | Cost | Use When |
|-------|------|----------|
| `haiku` | Low | File reading, search, formatting, running predefined tests, boilerplate, summarizing |
| `sonnet` | Medium | Code implementation, asset creation, design docs, integration, test writing, creative writing |
| `opus` | High | Unknown-cause debugging, architectural decisions, complex multi-file refactoring, deep system understanding |

**Refer to `config/model_routing.yaml` for task-type defaults.**

**Rules:**
- Default to `sonnet` unless you have a reason to go higher or lower
- Use `haiku` for anything a junior assistant could do (reading files, running commands, formatting)
- Use `opus` only when the subtask requires deep reasoning AND errors would be costly
- Quality gate subtasks (reviewing, verifying) should use at least `sonnet`

---

## Example Delegations

### Example 1: Gameplay Programmer — Read Code Before Implementing

```python
# 4-Tuple: <read existing code structure, inventory system context, Explore, haiku>
Task(
    subagent_type="Explore",
    model="haiku",
    prompt="""
## Context
We're implementing a new inventory transfer system.
The existing inventory code is in src/systems/inventory/.
The player inventory is managed by player_inventory.gd.
Config values are in config/balance.toml under [inventory].

## Instruction
Read all files in src/systems/inventory/ and summarize:
1. Current inventory data structure (how items are stored)
2. How add/remove operations work
3. Any existing transfer logic
4. Config values that affect inventory behavior

## Success Criteria
- Summary of each file's purpose and key functions
- Data structure diagram (text-based)
- List of all config keys used by inventory code

## Constraints
- Read-only — do not modify any files
- Focus on public API and data flow, not implementation details
"""
)
```

### Example 2: Asset Generator — Batch Voice Generation

```python
# 4-Tuple: <generate scav combat bark, voice spec context, general-purpose, sonnet>
# Launch 5 of these in parallel, one per bark line
Task(
    subagent_type="general-purpose",
    model="sonnet",
    prompt="""
## Context
Creating combat voice barks for scav enemies.
Voice spec from story_bible.md: "Gruff male, Russian-accented, aged 35, aggressive, military background"
GPU usage: MUST use scripts/gpu-run.sh --vram 6500 --caller asset_generator
Output directory: assets/audio/voice/scav/

## Instruction
Generate a scav combat bark for the line: "Сюда! Contact!"
Use Qwen3-TTS VoiceDesign model with the voice spec above.

## Success Criteria
- WAV file saved at assets/audio/voice/scav/bark_contact_001.wav
- Audio is clear, aggressive tone, matches military context
- No artifacts or glitches

## Constraints
- Use gpu-run.sh for GPU access (MANDATORY)
- Do not modify any existing audio files
"""
)
```

### Example 3: QA Lead — Run Test Suite

```python
# 4-Tuple: <run automated tests, test runner context, Bash, haiku>
Task(
    subagent_type="Bash",
    model="haiku",
    prompt="""
## Context
Running post-implementation verification for the combat damage system update.
Test runner is at tests/test_runner.gd in the Godot project at ~/etf-like-demo.
Need headless validation + unit tests + runtime spawn check.

## Instruction
Run these three checks in order and report all output:

1. Headless validation:
   godot --headless --path ~/etf-like-demo --quit 2>&1

2. Unit tests:
   godot --headless --path ~/etf-like-demo --script tests/test_runner.gd

3. Runtime spawn verification:
   godot --headless --path ~/etf-like-demo --script tests/verify_runtime.gd

## Success Criteria
- All three commands executed
- Full stdout/stderr captured for each
- Clear PASS/FAIL verdict for each check

## Constraints
- Do not modify any game files
- Do not attempt to fix errors — only report them
"""
)
```

### Example 4: Researcher — Parallel Source Search

```python
# Launch 3 sub-agents in parallel for different search angles
# 4-Tuple: <search for AI director systems, game AI context, Explore, haiku>
Task(
    subagent_type="general-purpose",
    model="haiku",
    prompt="""
## Context
Researching AI director systems for our EFT-like game.
Need to understand how games dynamically adjust difficulty and tension pacing.
Reference games: Left 4 Dead, Resident Evil 4, Tarkov (implicit difficulty via loot/spawns).

## Instruction
Search for GDC talks and academic papers on AI director systems.
Focus on: dynamic difficulty adjustment, tension curves, spawn rate manipulation.

## Success Criteria
- List of 5-10 relevant sources with title, author/speaker, year, and 2-sentence summary
- Classify each as: theory, implementation guide, or postmortem
- Note any Godot-specific implementations found

## Constraints
- Use WebSearch and arXiv tools
- Do not download full papers — summaries only
"""
)
```

---

## Parallel Delegation

You can launch multiple sub-agents in a single message. Use this when:
- You have 2+ independent subtasks with no data dependencies
- Results from one sub-agent don't feed into another

Call multiple Task tools in one response — they will run concurrently.

**Do NOT parallelize when:**
- Sub-agent B needs output from sub-agent A
- The subtasks write to the same file
- You need to review sub-agent A's result before deciding what sub-agent B should do

---

## Reporting Delegations

In your task completion notes, include a `## Delegations` section:

```markdown
## Delegations
| Sub-Agent | Type | Model | Objective | Outcome |
|-----------|------|-------|-----------|---------|
| code_reader | Explore | haiku | Read inventory code structure | Success — 6 files summarized |
| test_runner | Bash | haiku | Run headless + unit tests | Success — 218/218 pass |
| bark_gen_1 | general-purpose | sonnet | Generate scav bark "Contact!" | Success — WAV saved |
```

This helps Manager and Director track delegation patterns and improve routing over time.

---

## Anti-Patterns (Avoid These)

1. **Over-delegation**: Spawning a sub-agent for a 2-line task you could do yourself
2. **Context dumping**: Pasting your entire conversation into the sub-agent prompt
3. **Zero context**: Telling the sub-agent "analyze the code" without specifying which code, where, or what to look for
4. **Wrong model tier**: Using opus for file reading or haiku for architectural decisions
5. **Sequential when parallel**: Spawning sub-agents one at a time when they're independent
6. **Delegating judgment**: Having a sub-agent make creative or quality decisions that are your responsibility
7. **Ignoring results**: Not reviewing sub-agent output before incorporating it into your work

---

## Context Curation Quick Reference

| What to Include | What to Exclude |
|-----------------|-----------------|
| Specific file paths | "Check the src directory" |
| Numerical values (poly counts, test counts) | Your internal reasoning process |
| 2-5 sentence summary of prior work | Full text of prior task completions |
| Relevant memory IDs | Unrelated memory results |
| Success/failure criteria | Vague goals like "make it good" |
| Explicit constraints | Assumed common knowledge |
| GPU usage rules (if applicable) | Full studio instruction files |

**The 80/20 rule**: 80% of sub-agent failures come from bad context curation. Spend time here.

---

## Error Handling

If a sub-agent fails:
1. Read the error output
2. Diagnose: was it a context problem, a model capability problem, or a tool problem?
3. Options (in order of preference):
   a. Fix the issue yourself directly (fastest)
   b. Re-spawn with better context (if context was insufficient)
   c. Re-spawn with a stronger model (if capability was insufficient)
   d. Re-spawn with different subagent_type (if tool access was insufficient)
4. If 3 attempts fail on the same subtask: do it yourself directly
5. **NEVER report a task as complete if any subtask failed without resolution**

---

## Visibility Rules

**INVISIBLE to Manager/Director/Reviewer:**
- Sub-agent invocations are INTERNAL to you
- Completion notes report the FINAL integrated result, not sub-agent details
- You are responsible for all output quality
- If a sub-agent produces bad output, YOU failed, not the sub-agent

**VISIBLE in completion notes (for transparency):**
- `## Delegations` table showing what was delegated and outcomes
- This helps the studio learn and improve routing over time

**DO NOT include in completion notes:**
- Individual sub-agent prompts
- Raw sub-agent outputs (only integrated results)
- Sub-agent error logs (unless they reveal a systemic issue worth reporting as an observation)
