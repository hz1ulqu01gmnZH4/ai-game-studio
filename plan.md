# Multi-Agent Game Studio Plan

Adapting multi-agent-shogun for game development with Sakurai's methods and Gemini 3 Pro for visual tasks.

---

## Executive Summary

An **AI game development studio** where:
- **総監督 (Executive Director)** = You - final creative authority
- **監督 (Director)** = Claude Opus (extended thinking) - creative decisions that cascade
- **マネージャー (Manager)** = Claude Sonnet (thinking off) - fast delegation by rules
- **Dynamic Specialist Pool** = Roles activate/deactivate by phase & genre

**Model Architecture:**
- **Claude Opus + Extended Thinking** - Director only (creative decisions cascade)
- **Claude Sonnet** - マネージャー + all specialists (fast delegation, execution)
- **Gemini 3 Pro** - Vision tool invoked by Claude roles when visual analysis needed
- Philosophy: "Structure prevents errors, not deliberation" (仕組みで防ぐ) -- except Director, where wrong decisions cascade to all downstream work

---

## Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    総監督 (Executive Director)               │
│                         = YOU                                │
│  Final creative authority    Approves milestones            │
│  Sets vision & constraints   Resolves escalations           │
└─────────────────────────────────┬───────────────────────────┘
                                  |
┌─────────────────────────────────────────────────────────────┐
│                      監督 (Director)                         │
│              Claude Opus (thinking: EXTENDED)                │
│  Creative decisions          Scope trimming                 │
│  Task prioritization         Vision alignment               │
│  Sakurai: "Director's Job is to Trim"                       │
│  Deep reasoning: wrong decisions cascade everywhere         │
└─────────────────────────────────┬───────────────────────────┘
                                  |
┌─────────────────────────────────────────────────────────────┐
│                     マネージャー (Manager)                    │
│              Claude Sonnet (thinking: OFF)                   │
│  Task decomposition          Role assignment                │
│  Dependency planning         Dashboard updates              │
│  Gemini escalation approval                                 │
│  "Don't think. Delegate." -- fast by rules & structure      │
│  F001: CANNOT write to src/, assets/, production files      │
│  F002: Re-read role file after context compression          │
└─────────────────────────────────┬───────────────────────────┘
                                  |
┌─────────────────────────────────────────────────────────────┐
│              Dynamic Specialist Pool                         │
│    [Roles activate based on phase, genre, and need]         │
│                                                              │
│  CREATORS          REVIEWERS           SUPPORT              │
│  - Asset Gen       - Art Director      - QA Lead            │
│  - Programmer      - Anim Director     - Tech Writer        │
│  - (+ custom)      - Audio Director    - Story Writer       │
│                    - (+ custom)        - (+ custom)          │
└─────────────────────────────────────────────────────────────┘
```

---

## マネージャー (Manager): Delegation & Role Assignment

The マネージャー uses **Claude Sonnet with thinking OFF** -- fast delegation by rules and structure, not deliberation. Inspired by the original Multiple Shoguns architecture: "Don't think. Delegate." (考えるな。委譲しろ。)

### Forbidden Rules (仕組みで防ぐ)

| Rule | Description | Why |
|------|-------------|-----|
| **F001** | マネージャー can ONLY write to `dashboard.md` and `queue/` files. Cannot write to `src/`, `assets/`, or production files. | All execution must be delegated to specialists. Prevents role confusion during context compression. |
| **F002** | After context compression, MUST re-read `instructions/manager.md` | Context compression strips role constraints. Recovery procedure prevents F001 violations. |
| **F003** | CANNOT override Director's creative decisions | Only 総監督 can override Director. マネージャー implements, not decides. |

### Assignment Decision Matrix

```yaml
assignment_factors:
  task_type:
    visual_creation: asset_generator
    visual_review: art_director, animation_director
    code_implementation: gameplay_programmer, audio_director
    testing: qa_lead
    documentation: tech_writer
    narrative: story_writer
    balance: balance_designer

  dependencies:
    art_director: [requires: asset_generator output]
    animation_director: [requires: asset_generator output]
    qa_lead: [requires: gameplay_programmer output]

  parallelization:
    parallel_safe:
      - [asset_generator, gameplay_programmer]
      - [art_director, audio_director]
    sequential:
      - [asset_generator, art_director]
      - [gameplay_programmer, qa_lead]

  phase_awareness:
    concept: [asset_generator, story_writer]
    production: [all roles]
    polish: [qa_lead, vfx_artist, audio_director]
```

### マネージャー Responsibilities

| Responsibility | Method (rules, not thinking) |
|----------------|------------------------------|
| Task Decomposition | Match task_type to role using assignment matrix |
| Role Selection | Lookup table by task type, not deliberation |
| Dependency Ordering | Apply dependency rules (review after creation, test after code) |
| Parallel Planning | Check parallel_safe rules |
| Dashboard Updates | ONLY マネージャー updates dashboard (accountability) |
| Gemini Approval | Auto-approve if confidence < 0.7 or reviewers disagree (see below) |

---

## Development Phases

### Phase Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                        DEVELOPMENT TIMELINE                          │
├────────────┬────────────┬────────────────────────────┬──────────────┤
│   CONCEPT  │    DEMO    │      FULL PRODUCTION       │   RELEASE    │
│  (1-2 wks) │ (2-4 wks)  │        (8-16 wks)          │  (2-4 wks)   │
├────────────┼────────────┼────────────────────────────┼──────────────┤
│ Brainstorm │ Prototype  │  PARALLEL TRACKS:          │ Final QA     │
│ Concept Art│ Core Loop  │  - Asset Creation          │ Polish       │
│ GDD Draft  │ Vertical   │  - Mechanics Impl          │ Release Prep │
│ Tech Eval  │ Slice      │  - Playtesting             │ Launch       │
│            │            │  - Integration             │              │
└────────────┴────────────┴────────────────────────────┴──────────────┘
```

### Phase 1: Concept (1-2 weeks)

**Goal:** Define what the game IS before building anything.

| Role | Responsibility |
|------|----------------|
| Director (Opus) | Facilitate brainstorming, make concept decisions |
| Concept Artist (Sonnet) | Generate mood boards, style explorations |
| Game Designer (Sonnet) | Draft GDD, define core loop |
| Story Writer (Sonnet) | (if narrative game) World building, premise |

**Deliverables:** `context/vision.md`, `context/gdd_draft.md`, `context/art_style_guide.md`, `assets/concepts/`

**Sakurai:** "Start with the Climax" -- define the most exciting moment first. "Staying True to Concept" -- lock vision before production.

### Phase 2: Demo (2-4 weeks)

**Goal:** Prove the core loop is fun with minimal assets.

| Role | Responsibility |
|------|----------------|
| Director (Opus) | Prioritize what's in demo, cut scope |
| Gameplay Programmer (Sonnet) | Implement core mechanics |
| Asset Generator (Sonnet + tools) | Placeholder + key polished assets |
| Art Director (Sonnet + Gemini) | Ensure visual consistency |

**Key Activities:** Vertical slice, core feel testing, technical validation.

**Sakurai:** "Make Retries Quick" -- fast iteration on feel. "Give Yourself a Handicap When Balancing" -- test at extremes.

### Phase 3: Full Production (8-16 weeks)

**Goal:** Build the complete game with parallel workstreams.

| Track | Roles | Focus |
|-------|-------|-------|
| **Assets** | Asset Gen, Art Dir, Anim Dir, Audio Dir | Sprites, models, animation, audio, VFX |
| **Mechanics** | Gameplay Prog, Systems Prog, UI Prog, Balance Designer | Core systems, game logic, UI, save/load |
| **Testing** | QA Lead, Playtester, Balance Designer | Unit tests, playtesting, balance, bugs |
| **Integration** | Tech Lead, DevOps | Asset import, build pipeline, CI/CD |

Weekly sync by Director for concept alignment. All values externalized in config files (Sakurai: "Making Your Game Easy to Tune").

**Bug Severity:** S = crash/blocker (fix immediately), A = major broken (fix this sprint), B = workaround exists (schedule), C = cosmetic (backlog).

### Phase 4: Polish & Release (2-4 weeks)

**Goal:** Final quality pass, launch preparation.

| Focus | Details |
|-------|---------|
| Quality | All S/A bugs resolved, performance targets met |
| Polish | Screen shake, hit stop, UI feedback sounds, transitions |
| Content | All levels complete, save/load verified, tutorial tested |
| Release | Store page assets, trailer, patch notes |

---

## Dynamic Role System

### Core Roles (Always Available)

| Role ID | Name | Model | Thinking | Description |
|---------|------|-------|----------|-------------|
| `director` | 監督 | Claude Opus | **Extended** | Creative decisions, scope -- wrong call cascades everywhere |
| `manager` | マネージャー | Claude Sonnet | **OFF** | Fast delegation by rules. F001: cannot execute. |
| `asset_generator` | Asset Generator | Claude Sonnet | Normal | Creates assets via APIs (Qwen, SD, etc.) |
| `gameplay_programmer` | Gameplay Programmer | Claude Sonnet | Normal | Core game code |
| `qa_lead` | QA Lead | Claude Sonnet | Normal | Testing, bug tracking |

### Conditional Roles (Activate by Genre/Need)

| Role ID | Name | Vision | Activates When |
|---------|------|--------|----------------|
| `art_director` | Art Director | Two-tier | Visual assets needed |
| `animation_director` | Animation Director | Two-tier | Animated content |
| `audio_director` | Audio Director | - | Audio integration |
| `story_writer` | Story Writer | - | Narrative games |
| `ui_designer` | UI Designer | Two-tier | UI-heavy games |
| `balance_designer` | Balance Designer | - | Competitive/RPG games |
| `level_designer` | Level Designer | - | Level-based games |
| `tech_writer` | Tech Writer (Haiku) | - | Documentation needed |
| `vfx_artist` | VFX Artist | Two-tier | Effects-heavy games |
| `localization` | Localization Lead | - | Multi-language |

**Two-tier vision** = Primary: `agentic-image-analysis` skill. Escalation: Gemini 3 Pro (requires Manager approval).

---

## Vision Analysis: Two-Tier System

All roles run on Claude. Visual analysis uses a two-tier approach:

1. **Tier 1 (Default):** Claude's `agentic-image-analysis` skill -- no approval needed
2. **Tier 2 (Escalation):** Gemini 3 Pro -- requires Manager approval

### When to Escalate

| Situation | Tool | Approval |
|-----------|------|----------|
| Standard asset review | Claude `agentic-image-analysis` | None |
| UI screenshot analysis | Claude `agentic-image-analysis` | None |
| Animation timing check | Claude `agentic-image-analysis` | None |
| Reviewers disagree | Gemini 3 Pro | **Auto-approved** |
| Claude analysis confidence < 0.7 | Gemini 3 Pro | **Auto-approved** |
| Complex spatial reasoning | Gemini 3 Pro | Manager |
| Style comparison across many assets | Gemini 3 Pro | Manager |

### Gemini Escalation Rules

Hard rules so マネージャー does not need to reason:

| Condition | Action |
|-----------|--------|
| Primary analysis confidence < 0.7 | **Auto-approve** Gemini escalation |
| Two or more reviewers disagree | **Auto-approve** Gemini escalation |
| Director explicitly requests | **Auto-approve** Gemini escalation |
| Single reviewer wants second opinion | Manager reviews request, may approve or reject |
| All other cases | Manager reviews request |

Escalation request format: `queue/gemini_requests/request_{id}.md` with fields: `request_id`, `requested_by`, `reason`, `assets_to_analyze`, `analysis_needed`, `status`.

---

## Inter-Agent Communication Protocol

### File-Based Task Handoff

```
queue/
  pending/       # マネージャー writes new tasks here
  in-progress/   # Specialist moves task here when starting
  done/          # Specialist moves task here when complete
```

### Task File Format

Each task is a markdown file (`queue/pending/task_{id}.md`):

```markdown
# Task: {task_id}
- assigned_to: {role_id}
- depends_on: [task_ids]
- status: pending | in-progress | done | failed
- priority: S | A | B | C
- description: {what to do}
- output_path: {where to write results}
- created_by: manager
- created_at: {timestamp}
```

### Flow

1. マネージャー writes task files to `queue/pending/`
2. Specialist picks up their assigned task, moves to `queue/in-progress/`
3. Specialist completes work, writes output to `output_path`, moves task to `queue/done/`
4. マネージャー polls `queue/done/`, updates dashboard, assigns next tasks
5. If task has `depends_on`, マネージャー holds it in `pending/` until dependencies are in `done/`

---

## Error Recovery

| Scenario | Detection | Response |
|----------|-----------|----------|
| **Agent crash / stale task** | Task in `in-progress/` with no update for 10+ minutes | マネージャー reassigns to same or different specialist |
| **Bad output** | Director reviews and rejects | Task re-queued to `pending/` with rejection feedback appended |
| **Context compression** | Agent detects compressed context | F002 rule: agent re-reads its `instructions/{role}.md` file |
| **API failure** (image gen, etc.) | Specialist reports error | Task marked `failed` with error details. マネージャー reassigns or escalates to Director. |
| **Conflicting outputs** | Two specialists produce contradictory work | Director resolves. Decision logged in dashboard. Losing output archived. |
| **Dependency deadlock** | マネージャー detects circular `depends_on` | Escalate to Director for re-scoping |

---

## Context Window Budget

| Agent | Model | Context Strategy |
|-------|-------|------------------|
| **Director** | Opus + thinking | Heavy usage. Holds project vision + current phase focus only. Archive completed phase details to files. |
| **マネージャー** | Sonnet, no thinking | Light context. Holds current task queue + role availability. Stateless between delegation rounds -- reads `queue/` files fresh each cycle. |
| **Specialists** | Sonnet | Task-scoped context only. Receives task description, produces output. No full project awareness needed. |

**Rule:** No agent holds full project state in context. State lives in files (`dashboard.md`, `queue/`, `context/`).

---

## Configuration

```yaml
# config/studio.yaml

studio:
  name: "AI Game Studio"

  hierarchy:
    executive_director: "user"  # 総監督
    director:
      model: "claude-opus"
      extended_thinking: true
    manager:
      model: "claude-sonnet"
      extended_thinking: false
      forbidden_rules:
        - F001: "Can ONLY write to dashboard.md and queue/ files"
        - F002: "Must re-read role file after context compression"
        - F003: "Cannot override Director's creative decisions"

  models:
    director: "claude-opus"
    manager: "claude-sonnet"
    specialists: "claude-sonnet"
    lightweight: "claude-haiku"

  vision:
    primary:
      tool: "agentic-image-analysis"
      type: "claude-skill"
      approval_required: false
    escalation:
      tool: "gemini-3-pro"
      command: "gemini -m gemini-3-pro"
      approval_required: true
      auto_approve_when:
        - "confidence < 0.7"
        - "reviewers disagree"
        - "director requests"
      used_by_roles: [art_director, animation_director, ui_designer, vfx_artist]

  paths:
    context: "./context"
    assets: "./assets"
    builds: "./builds"
    queue: "./queue"
    dashboard: "./dashboard.md"
```

---

## Launch Script

```bash
#!/bin/bash
# game_studio_launch.sh
STUDIO_DIR="${GAME_STUDIO_DIR:-$HOME/game-studio}"
PROJECT="$1"
PHASE="${2:-concept}"

CONFIG="$STUDIO_DIR/config/projects/${PROJECT}.yaml"
[ ! -f "$CONFIG" ] && echo "Config not found: $CONFIG" && exit 1

GENRE=$(yq '.project.genre' "$CONFIG")
echo "Launching Game Studio: $PROJECT ($GENRE) - Phase: $PHASE"

# Director (Claude Opus)
tmux new-session -d -s director -n director
tmux send-keys -t director "cd $STUDIO_DIR && claude --model opus" Enter
sleep 2
tmux send-keys -t director "/read instructions/director.md" Enter

# Manager (Claude Sonnet - thinking OFF)
tmux new-session -d -s studio -n workers
tmux send-keys -t studio:workers.0 "cd $STUDIO_DIR && claude --model sonnet" Enter
sleep 1
tmux send-keys -t studio:workers.0 "/read instructions/manager.md" Enter

# Specialists - activate based on project config
ACTIVE_ROLES=$(yq '.project.active_roles.active[]' "$CONFIG")
PANE=1
for role in $ACTIVE_ROLES; do
  tmux split-window -t studio:workers
  tmux send-keys -t studio:workers.$PANE \
    "cd $STUDIO_DIR && claude" Enter
  sleep 1
  tmux send-keys -t studio:workers.$PANE \
    "/read instructions/${role}.md" Enter
  ((PANE++))
done

tmux select-layout -t studio:workers tiled
echo "Studio launched! Director: tmux attach -t director | Workers: tmux attach -t studio"
```

---

## Dashboard Format

```markdown
# Game Studio Dashboard

**Project:** {name}  |  **Genre:** {genre}  |  **Phase:** {phase} (Week X/Y)
**Vision:** {one-line vision}

## Decisions for 総監督

| # | Decision Needed | Options | Deadline |
|---|-----------------|---------|----------|

## Phase Progress

ASSETS    ████████████░░░░░░░░ 60%  (Art Dir, Anim Dir)
MECHANICS ██████████████░░░░░░ 70%  (Gameplay Prog)
TESTING   ████████░░░░░░░░░░░░ 40%  (QA Lead)
INTEGR.   ██████████████████░░ 90%  (Tech Lead)

## Active Tasks

| Role | Task | Status |
|------|------|--------|

## Completed Today

| Time | Role | Deliverable |
|------|------|-------------|

## Concept Alignment

Last check: {date}  |  Status: {on track / at risk}
Notes: {bullet points}

## New Role Proposals

| Proposed By | Role | Status |
|-------------|------|--------|

*Last updated: {timestamp} by Manager*
```

---

## Summary of Changes from Original

| Aspect | multi-agent-shogun | Game Studio |
|--------|-------------------|-------------|
| Top role | Shogun (将軍) | 総監督 (you) + 監督 (AI) |
| Middle role | マネージャー (Karo) | マネージャー -- Sonnet, thinking OFF, F001-F003 |
| Workers | 8 identical 足軽 | Dynamic specialist pool |
| Models | All Claude | All Claude + Gemini 3 Pro as vision tool |
| Phases | Generic tasks | Concept, Demo, Production, Release |
| Parallelism | Task-level | Track-level (Assets/Mechanics/Testing/Integration) |
| Roles | Fixed 10 agents | Dynamic by genre + phase + need |
| Communication | Direct | File-based queue system (pending/in-progress/done) |
| Error recovery | None | Stale task detection, reassignment, escalation |
| Context management | Unmanaged | Per-agent budget, state in files not context |
| Principles | Generic | Sakurai methods embedded per role |
| Vision | None | Two-tier: Claude skill primary, Gemini 3 Pro escalation |

---

## References

- [multi-agent-shogun](../../multi-agent-shogun/) - Base orchestration system
- [Sakurai Methods](skill-candidates.md) - Game dev principles
- [AI Game Dev Framework](ai-game-dev-framework.md) - Tool integration
- Claude `agentic-image-analysis` skill - Primary vision analysis
- [Gemini 3 Pro](https://blog.google/products/gemini/gemini-3/) - Escalation vision tool

---

*Plan created: 2026-01-30*
*Status: Draft v6 -- Trimmed: removed self-improvement system, tool researcher role, genre presets. Added: inter-agent communication, error recovery, context window budget.*
