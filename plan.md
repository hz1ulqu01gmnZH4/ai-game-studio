# Multi-Agent Game Studio Plan

Adapting multi-agent-shogun for game development with Sakurai's methods, Gemini 3 Pro for visual tasks, and self-improving role/skill system.

---

## Executive Summary

A **self-improving AI game development studio** where:
- **総監督 (Executive Director)** = You - final creative authority
- **監督 (Director)** = Claude Opus (extended thinking) - creative decisions that cascade
- **マネージャー (Manager)** = Claude Sonnet (thinking off) - fast delegation by rules
- **Dynamic Specialist Pool** = Roles activate/deactivate by phase & genre
- **Self-Improvement** = New roles defined on-demand, experiences become skills

**Model Architecture:**
- **Claude Opus + Extended Thinking** - Director only (creative decisions cascade)
- **Claude Sonnet** - マネージャー/Manager + all specialists (fast delegation, execution)
- **Gemini 3 Pro** - Vision tool invoked by Claude roles when visual analysis needed
- Philosophy: "Structure prevents errors, not deliberation" (仕組みで防ぐ) — except Director, where wrong decisions cascade to all downstream work

---

## Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    総監督 (Executive Director)               │
│                         = YOU                                │
│  • Final creative authority    • Approves milestones        │
│  • Sets vision & constraints   • Resolves escalations       │
└─────────────────────────────────┬───────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────┐
│                      監督 (Director)                         │
│              Claude Opus (thinking: EXTENDED)                │
│  • Creative decisions          • Scope trimming             │
│  • Task prioritization         • Vision alignment           │
│  • Sakurai: "Director's Job is to Trim"                     │
│  • Deep reasoning: wrong decisions cascade everywhere       │
└─────────────────────────────────┬───────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────┐
│                     マネージャー (Manager)                            │
│              Claude Sonnet (thinking: OFF)                   │
│  • Task decomposition          • Role assignment            │
│  • Dependency planning         • Dashboard updates          │
│  • Gemini escalation approval                               │
│  • "Don't think. Delegate." — fast by rules & structure     │
│  • F001: CANNOT execute tasks — must delegate               │
│  • F002: Re-read role file after context compression        │
└─────────────────────────────────┬───────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────┐
│              Dynamic Specialist Pool                         │
│    [Roles activate based on phase, genre, and need]         │
│                                                              │
│  CREATORS          REVIEWERS           SUPPORT              │
│  ├─ Asset Gen      ├─ Art Director     ├─ QA Lead          │
│  ├─ Programmer     ├─ Anim Director    ├─ Tech Writer      │
│  └─ (+ custom)     ├─ Audio Director   ├─ Story Writer     │
│                    └─ (+ custom)       ├─ Tool Researcher  │
│                                        └─ (+ custom)        │
└─────────────────────────────────────────────────────────────┘
```

---

## マネージャー (Manager): Delegation & Role Assignment

The マネージャー uses **Claude Sonnet with thinking OFF** — fast delegation by rules and structure, not deliberation. Inspired by the original Multiple Shoguns architecture: "Don't think. Delegate." (考えるな。委譲しろ。)

### Why Sonnet Without Thinking?

The original Multiple Shoguns author found the 将軍 (Shogun) was **spending 5 minutes overthinking 30-second directives** with extended thinking enabled. The same applies to the マネージャー role:

1. **Director already did the thinking** — creative/scope decisions are resolved before reaching マネージャー
2. **Decomposition is mechanical** — with good Director input, task breakdown follows rules
3. **Structure prevents errors** — forbidden rules (F001, F002) catch mistakes that deliberation misses
4. **Speed matters** — fast delegation keeps 足軽 (specialists) busy, not waiting

### Forbidden Rules (仕組みで防ぐ)

| Rule | Description | Why |
|------|-------------|-----|
| **F001** | マネージャー CANNOT read/write files or execute tasks directly | All execution must be delegated to specialists. Prevents role confusion during context compression. |
| **F002** | After context compression, MUST re-read `instructions/manager.md` | Context compression strips role constraints. Recovery procedure prevents F001 violations. |
| **F003** | CANNOT override Director's creative decisions | Only 総監督 can override Director. マネージャー implements, not decides. |

### Role Assignment Flow

```
総監督: "Add enemy types with varied attack patterns"
         │
         ▼
監督 (Director - Opus, EXTENDED THINKING):
         │ Deep reasoning: evaluates scope, risks, creative fit
         │ Decision: "5 enemies, 2 melee, 2 ranged, 1 boss"
         │ Considers: Does this fit vision? Is scope realistic?
         │ OUTPUT: Well-scoped, reasoned directive
         ▼
マネージャー (Manager - Sonnet, THINKING OFF):
         │ Receives well-scoped directive from Director
         │ Applies assignment rules mechanically:
         │
         ├─ DECOMPOSES by task_type rules:
         │   visual_creation → asset_generator
         │   code_implementation → gameplay_programmer
         │   testing → qa_lead
         │
         ├─ PLANS by dependency rules:
         │   Phase 1 (parallel):
         │   ├─ Asset Generator → Generate sprite concepts
         │   └─ Gameplay Programmer → Design attack patterns
         │
         │   Phase 2 (after Phase 1):
         │   ├─ Art Director → Review sprites
         │   └─ Animation Director → Review attack anims
         │
         │   Phase 3 (after Phase 2):
         │   └─ QA Lead → Test enemy behaviors
         │
         ├─ WRITES task YAMLs (delegation, not execution)
         │
         └─ UPDATES dashboard
```

### マネージャー's Responsibilities

| Responsibility | Method (rules, not thinking) |
|----------------|------------------------------|
| **Task Decomposition** | Match task_type → role using assignment matrix |
| **Role Selection** | Lookup table by task type, not deliberation |
| **Dependency Ordering** | Apply dependency rules (review after creation, test after code) |
| **Parallel Planning** | Check parallel_safe rules |
| **Dashboard Updates** | ONLY マネージャー updates dashboard (accountability) |
| **Gemini Approval** | Check escalation criteria (confidence < 70%, disagreement) |

### Assignment Decision Matrix

マネージャー applies these rules mechanically when assigning:

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
    # Can't review what doesn't exist
    art_director: [requires: asset_generator output]
    animation_director: [requires: asset_generator output]
    qa_lead: [requires: gameplay_programmer output]

  parallelization:
    # These can run simultaneously
    parallel_safe:
      - [asset_generator, gameplay_programmer]  # Different outputs
      - [art_director, audio_director]          # Different domains
    # These must be sequential
    sequential:
      - [asset_generator, art_director]  # Review needs assets
      - [gameplay_programmer, qa_lead]   # Test needs code

  phase_awareness:
    concept: [asset_generator, story_writer]
    production: [all roles]
    polish: [qa_lead, vfx_artist, audio_director]
```

### Hybrid Model: Why Director Thinks, マネージャー Doesn't

Based on the [Multiple Shoguns architecture](https://zenn.dev/shio_shoppaize/articles/8870bbf7c14c22) and our adaptation:

**Director (Opus, extended thinking ON):**
| Risk Without | Benefit With |
|--------------|--------------|
| Wrong scope → ALL work wasted | Evaluates feasibility before committing |
| Misaligned vision → rework | Checks creative fit with project vision |
| Missed edge cases → bugs | Considers implications of decisions |
| Poor prioritization → delays | Reasons about what matters most |

**マネージャー (Sonnet, thinking OFF):**
| Original Problem | Solution |
|-----------------|----------|
| Shogun spent 5 min on 30-sec directives | Thinking OFF — fast delegation |
| Context compression stripped role boundaries | F001/F002 rules in permanent files |
| Role confusion after long sessions | Re-read instructions after compression |

**Why this hybrid works:**
- **Director** = high-leverage decisions → worth the thinking cost
- **マネージャー** = mechanical delegation → Director already resolved ambiguity
- **Structure** (F001, F002, F003) prevents マネージャー errors that thinking can't catch anyway
- **Cost savings**: Sonnet without thinking is ~10x cheaper than Opus with thinking
- **Speed**: マネージャー delegates instantly, keeping specialists busy instead of waiting

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
│ Brainstorm │ Prototype  │ ┌─────────────────────────┐│ Final QA     │
│ Concept Art│ Core Loop  │ │ PARALLEL TRACKS:        ││ Polish       │
│ GDD Draft  │ Vertical   │ │ • Asset Creation        ││ Release Prep │
│ Tech Eval  │ Slice      │ │ • Mechanics Impl        ││ Launch       │
│            │            │ │ • Playtesting           ││              │
│            │            │ │ • Integration           ││              │
│            │            │ └─────────────────────────┘│              │
└────────────┴────────────┴────────────────────────────┴──────────────┘
```

---

### Phase 1: Concept (Brainstorming & Concept Building)

**Duration:** 1-2 weeks
**Goal:** Define what the game IS before building anything

**Active Roles:**
| Role | Model | Responsibility |
|------|-------|----------------|
| Director | Claude Opus | Facilitate brainstorming, make concept decisions |
| Concept Artist | Claude Sonnet | Generate mood boards, style explorations |
| Game Designer | Claude | Draft GDD, define core loop |
| Story Writer | Claude | (if narrative game) World building, premise |
| Tech Lead | Claude | Evaluate technical feasibility |

**Deliverables:**
```
context/
├── vision.md              # One-page game vision
├── gdd_draft.md           # Game Design Document (draft)
├── art_style_guide.md     # Visual direction with reference images
├── technical_notes.md     # Engine choice, scope constraints
└── story_bible.md         # (if applicable) World, characters, themes

assets/concepts/
├── mood_boards/           # Style exploration images
├── character_sketches/    # Early character concepts
└── environment_thumbs/    # Environment mood pieces
```

**Sakurai Principles:**
- "Start with the Climax" → Define the most exciting moment first
- "Staying True to Concept" → Lock vision before production
- "When Ideas Won't Come" → Brainstorming cascade for stuck points

**Workflow:**
```
総監督: "I want to make a roguelike with cooking mechanics"
         ↓
Director: Brainstorming session
  → What's the core loop?
  → What makes it unique?
  → What's the "climax" moment?
         ↓
Game Designer: Drafts GDD with core mechanics
Concept Artist: Generates style options (pixel? 3D? painterly?)
Story Writer: Proposes world premise options
         ↓
Director: Consolidates into vision.md
         ↓
総監督: Reviews, approves, or redirects
```

---

### Phase 2: Demo Development (Playable Prototype)

**Duration:** 2-4 weeks
**Goal:** Prove the core loop is fun with minimal assets

**Active Roles:**
| Role | Model | Responsibility |
|------|-------|----------------|
| Director | Claude Opus | Prioritize what's in demo, cut scope |
| Gameplay Programmer | Claude | Implement core mechanics |
| Asset Generator | Claude + Tools | Placeholder → polished key assets |
| Art Director | Claude + Gemini vision | Ensure visual consistency |
| Playtester | Claude | Test core loop, report feel issues |

**Deliverables:**
```
builds/
└── demo_v1/               # Playable demo build

docs/
├── demo_scope.md          # What's in, what's out
└── playtest_report_v1.md  # First playtest findings

assets/
├── sprites/player/        # Player character (polished)
├── sprites/placeholder/   # Everything else (rough)
└── audio/placeholder/     # Temp sound effects
```

**Key Activities:**
1. **Vertical Slice** - One complete gameplay loop
2. **Core Feel Testing** - Is the basic action fun?
3. **Technical Validation** - Does the architecture work?

**Sakurai Principles:**
- "Make Retries Quick" → Fast iteration on feel
- "Give Yourself a Handicap When Balancing" → Test at extremes
- "Elementary School Play Testers" → Fresh eyes on core loop

---

### Phase 3: Full Production (Parallel Tracks)

**Duration:** 8-16 weeks (varies by scope)
**Goal:** Build the complete game with parallel workstreams

#### Parallel Track Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRODUCTION PARALLEL TRACKS                    │
├─────────────────┬─────────────────┬─────────────────┬───────────┤
│  ASSET TRACK    │  MECHANICS TRACK│  TEST TRACK     │INTEGRATION│
│                 │                 │                 │  TRACK    │
├─────────────────┼─────────────────┼─────────────────┼───────────┤
│ Concept Art     │ Core Systems    │ Unit Tests      │ Asset     │
│ Sprites/Models  │ Game Logic      │ Playtesting     │ Import    │
│ Animation       │ UI/UX Code      │ Balance Testing │ Build     │
│ Audio/Music     │ Save/Load       │ Bug Tracking    │ Pipeline  │
│ VFX             │ Networking (opt)│ Perf Testing    │ CI/CD     │
│                 │                 │                 │           │
│ Art Director    │ Gameplay Prog   │ QA Lead         │ Tech Lead │
│ Anim Director   │ Systems Prog    │ Playtester      │ DevOps    │
│ Audio Director  │ UI Programmer   │ Balance Designer│           │
└─────────────────┴─────────────────┴─────────────────┴───────────┘
         ↑                 ↑                 ↑              ↑
         └─────────────────┴─────────────────┴──────────────┘
                            ↓
                  CONCEPT ALIGNMENT CHECK
                  (Weekly sync by Director)
```

#### Track A: Asset Creation

**Active Roles:**
| Role | Model | Focus |
|------|-------|-------|
| Asset Generator | Claude + Qwen/SD/TRELLIS | Create raw assets |
| Art Director | Claude + Gemini vision | Review visual consistency |
| Animation Director | Claude + Gemini vision | Review motion, timing |
| Audio Director | Claude | Review sound integration |

**Asset Pipeline:**
```
Request → Generate → Review → Iterate → Approve → Integrate
   ↑         ↓          ↓         ↓          ↓          ↓
Director  Asset Gen  Art Dir   Asset Gen  Director   Tech Lead
                    (Gemini)              (if major)
```

**Tools by Asset Type:**
| Asset | Creation Tool | Review Agent |
|-------|---------------|--------------|
| Concept Art | Qwen-Image, Stable Diffusion | Art Director (uses Gemini vision) |
| Sprites | Stable Diffusion + sprite LoRA | Art Director (uses Gemini vision) |
| 3D Models | TRELLIS.2, Meshy AI, Tripo3D | Art Director (uses Gemini vision) |
| Textures | Stable Diffusion | Art Director (uses Gemini vision) |
| Animation | ActionMesh, MoCapAnything | Animation Director (uses Gemini vision) |
| SFX | ElevenLabs SFX, SFX Engine | Audio Director (Claude) |
| Music | Suno API, Udio | Audio Director (Claude) |
| Voice | Fish Audio, ElevenLabs | Audio Director (Claude) |

#### Track B: Game Mechanics Implementation

**Active Roles:**
| Role | Model | Focus |
|------|-------|-------|
| Gameplay Programmer | Claude | Core mechanics, player systems |
| Systems Programmer | Claude | Save/load, networking, engine |
| UI Programmer | Claude | Menus, HUD, input handling |
| Balance Designer | Claude | Tuning parameters, curves |

**Sakurai Principles Applied:**
- "Making Your Game Easy to Tune" → All values in config files
- "Risk and Reward" → Document risk/reward for each mechanic
- "Behavior at Ledges" → Handle all edge cases explicitly

**Code Standards:**
```rust
// config/balance.toml - External parameters
[player]
speed = 5.0
jump_height = 3.0
attack_damage = 10

// src/player.rs - References config, not magic numbers
impl Player {
    /// Risk: Exposed during windup
    /// Reward: High damage, knockback
    fn heavy_attack(&mut self, config: &Config) {
        self.damage = config.player.heavy_attack_damage;
        // ...
    }
}
```

#### Track C: Playtesting & QA

**Active Roles:**
| Role | Model | Focus |
|------|-------|-------|
| QA Lead | Claude | Bug tracking, test plans |
| Playtester | Claude | Feel testing, UX issues |
| Balance Designer | Claude | Number tuning |
| Concept Alignment Checker | Claude + Gemini vision | Visual/gameplay coherence |

**Testing Cycles:**
```
Weekly Playtest Loop:
  Monday    → Build candidate ready
  Tue-Wed   → Playtesting (QA + Playtester agents)
  Thursday  → Bug triage, balance review
  Friday    → Fixes integrated, Director review

Milestone Playtest:
  Every 2-4 weeks → Full concept alignment check
  → Does it still match the vision?
  → Are we on track for scope?
```

**Bug Severity System (Sakurai-inspired):**
| Severity | Definition | Response |
|----------|------------|----------|
| **S** | Crash, data loss, blocker | Fix immediately, halt other work |
| **A** | Major functionality broken | Fix this sprint |
| **B** | Noticeable but workaround exists | Schedule fix |
| **C** | Minor/cosmetic | Backlog |

#### Track D: Integration

**Active Roles:**
| Role | Model | Focus |
|------|-------|-------|
| Tech Lead | Claude | Architecture, pipelines |
| DevOps | Claude | CI/CD, build automation |

**Integration Points:**
- Asset import automation
- Build verification tests
- Performance benchmarks
- Platform-specific builds

---

### Phase 4: Polish & Release

**Duration:** 2-4 weeks
**Goal:** Final quality pass, launch preparation

**Active Roles:**
| Role | Model | Focus |
|------|-------|-------|
| QA Lead | Claude | Final bug sweep |
| VFX Polish | Claude + Gemini vision | Juice, screen shake, particles |
| Audio Polish | Claude | Mix balancing, final SFX |
| Tech Writer | Claude | Help text, patch notes |
| Marketing | Claude | Trailer script, store page |

**Checklist:**
```markdown
## Release Checklist

### Quality
- [ ] All S/A bugs resolved
- [ ] B bugs triaged (fix or won't fix)
- [ ] Performance targets met (60fps on target hardware)
- [ ] All platforms tested

### Polish
- [ ] Screen shake on impacts
- [ ] Hit stop on heavy attacks
- [ ] UI feedback sounds
- [ ] Loading screens/transitions smooth

### Content
- [ ] All levels complete
- [ ] All unlockables working
- [ ] Save/load verified
- [ ] Tutorial flow tested

### Release
- [ ] Store page assets ready
- [ ] Trailer complete
- [ ] Patch notes written
- [ ] Day-1 patch prepared (if needed)
```

---

## Dynamic Role System

### Core Roles (Always Available)

| Role ID | Name | Model | Thinking | Description |
|---------|------|-------|----------|-------------|
| `director` | 監督 | Claude Opus | **Extended** | Creative decisions, scope — wrong call cascades everywhere |
| `manager` | マネージャー | Claude Sonnet | **OFF** | Fast delegation by rules. F001: cannot execute. |
| `tool_researcher` | Tool Researcher | Claude Sonnet | Normal | Discovers new tools, proposes upgrades |
| `asset_generator` | Asset Generator | Claude Sonnet | Normal | Creates assets via APIs (Qwen, SD, etc.) |
| `gameplay_programmer` | Gameplay Programmer | Claude Sonnet | Normal | Core game code |
| `qa_lead` | QA Lead | Claude Sonnet | Normal | Testing, bug tracking |

**Hybrid Thinking Model** (inspired by [Multiple Shoguns v1.1.0](https://zenn.dev/shio_shoppaize/articles/8870bbf7c14c22)):

| Role | Model | Thinking | Rationale |
|------|-------|----------|-----------|
| **監督 (Director)** | Opus | Extended | Wrong decisions cascade to ALL downstream work. Worth the cost. |
| **マネージャー (Manager)** | Sonnet | OFF | "Don't think. Delegate." Director already resolved ambiguity. Structure (F001-F003) prevents errors. |
| **Specialists** | Sonnet | Normal | Execute well-defined tasks from マネージャー. |

### Conditional Roles (Activate by Genre/Need)

| Role ID | Name | Model | Vision | Activates When |
|---------|------|-------|--------|----------------|
| `art_director` | Art Director | Claude Sonnet | **Two-tier** | Visual assets needed |
| `animation_director` | Animation Director | Claude Sonnet | **Two-tier** | Animated content |
| `audio_director` | Audio Director | Claude Sonnet | - | Audio integration |
| `story_writer` | Story Writer | Claude Sonnet | - | Narrative games |
| `ui_designer` | UI Designer | Claude Sonnet | **Two-tier** | UI-heavy games |
| `balance_designer` | Balance Designer | Claude Sonnet | - | Competitive/RPG games |
| `level_designer` | Level Designer | Claude Sonnet | - | Level-based games |
| `tech_writer` | Tech Writer | Claude Haiku | - | Documentation needed |
| `vfx_artist` | VFX Artist | Claude Sonnet | **Two-tier** | Effects-heavy games |
| `localization` | Localization Lead | Claude Sonnet | - | Multi-language |

**Two-tier vision** = Primary: `agentic-image-analysis` skill → Escalation: Gemini 3 Pro (requires Manager approval)

### Vision Analysis: Two-Tier System

**All roles run on Claude.** Visual analysis uses a two-tier approach:

1. **Primary:** Claude's `agentic-image-analysis` skill (built-in)
2. **Escalation:** Gemini 3 Pro (requires Manager approval)

```
┌─────────────────────────────────────────────────────────────────────┐
│  VISUAL ANALYSIS FLOW                                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  TIER 1: Claude agentic-image-analysis (DEFAULT)            │   │
│  │  • Use /agentic-image-analysis skill                        │   │
│  │  • Handles most visual review tasks                         │   │
│  │  • No approval needed                                       │   │
│  └─────────────────────────────┬───────────────────────────────┘   │
│                                │                                    │
│                    Inconclusive or disagreement?                   │
│                                │                                    │
│                                ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  TIER 2: Gemini 3 Pro (ESCALATION - requires approval)      │   │
│  │  • Request Manager approval first                           │   │
│  │  • Used when multiple reviewers disagree                    │   │
│  │  • Used when Claude analysis is inconclusive                │   │
│  │  • Acts as tiebreaker / second opinion                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**When to use each tier:**

| Situation | Tool | Approval |
|-----------|------|----------|
| Standard asset review | Claude `agentic-image-analysis` | None |
| UI screenshot analysis | Claude `agentic-image-analysis` | None |
| Animation timing check | Claude `agentic-image-analysis` | None |
| Art Director & Animation Director disagree | Gemini 3 Pro | **Manager** |
| Claude analysis says "uncertain" | Gemini 3 Pro | **Manager** |
| Complex spatial reasoning needed | Gemini 3 Pro | **Manager** |
| Style comparison across many assets | Gemini 3 Pro | **Manager** |

**Gemini 3 Pro Escalation Protocol:**

```yaml
# queue/gemini_requests/request_001.yaml
request_id: gemini_001
requested_by: art_director
timestamp: 2026-01-30T14:00:00Z

reason: |
  Art Director and Animation Director disagree on sprite readability.
  Art Director: "Silhouette is clear enough"
  Animation Director: "Attack pose doesn't read at game speed"
  Claude agentic-image-analysis: "Borderline - recommend second opinion"

assets_to_analyze:
  - assets/sprites/hero_attack_v3.png

analysis_needed: |
  Evaluate attack animation readability at 32x32 resolution.
  Which reviewer's assessment is more accurate?

status: pending_manager_approval  # → approved / rejected
```

**Example: Art Director reviewing sprites (updated flow)**
```
Art Director (Claude) receives task: "Review enemy sprite batch"
    │
    ├─ 1. Claude reads task, loads Sakurai visual principles
    │
    ├─ 2. Claude uses agentic-image-analysis skill (TIER 1):
    │      /agentic-image-analysis assets/sprites/enemy_batch_3.png
    │      "Analyze for silhouette clarity, color contrast, readability"
    │
    ├─ 3. Skill returns analysis:
    │      "Sprite 3: sword blends with body (confidence: high)
    │       Sprite 7: color contrast uncertain (confidence: low)"
    │
    ├─ 4. For Sprite 3 (high confidence): Claude proceeds with decision
    │      "Per 'Too Much is Just Right': sword needs 20% larger"
    │
    ├─ 5. For Sprite 7 (low confidence): Request Gemini escalation
    │      → Submit gemini_request to Manager
    │      → Wait for approval
    │      → If approved, invoke Gemini 3 Pro for Sprite 7 only
    │
    └─ 6. Claude writes final review report
```

**Technical Implementation:**
```yaml
# instructions/art_director.md

vision_tools:
  # TIER 1: Primary (no approval needed)
  primary:
    skill: "agentic-image-analysis"
    usage: "/agentic-image-analysis {image_path}"
    use_for:
      - Standard asset review
      - UI screenshots
      - Animation frames
      - Style checks

  # TIER 2: Escalation (requires Manager approval)
  escalation:
    tool: "gemini-3-pro"
    command: "gemini -m gemini-3-pro"
    requires_approval: true
    approval_from: manager
    use_when:
      - Primary analysis confidence < 70%
      - Multiple reviewers disagree
      - Complex spatial reasoning needed
      - Explicit request from Director
    request_format: "queue/gemini_requests/request_{id}.yaml"
```

### Genre Presets

```yaml
# config/genre_presets.yaml

presets:
  2d_platformer:
    description: "Side-scrolling action platformer"
    required_roles:
      - director
      - manager
      - asset_generator
      - gameplay_programmer
      - qa_lead
    recommended_roles:
      - art_director
      - animation_director
    optional_roles:
      - audio_director
      - level_designer
    asset_types: [sprites, tilesets, animations_2d, sfx]

  3d_action:
    description: "Third-person action game"
    required_roles:
      - director
      - manager
      - asset_generator
      - gameplay_programmer
      - qa_lead
    recommended_roles:
      - art_director
      - animation_director
      - audio_director
      - vfx_artist
    asset_types: [3d_models, textures, animations_3d, vfx, music, sfx]

  visual_novel:
    description: "Story-driven visual novel"
    required_roles:
      - director
      - manager
      - asset_generator
      - story_writer
    recommended_roles:
      - art_director
      - ui_designer
      - audio_director
    optional_roles:
      - localization
    asset_types: [illustrations, backgrounds, ui, music, voice]

  roguelike:
    description: "Procedural dungeon crawler"
    required_roles:
      - director
      - manager
      - asset_generator
      - gameplay_programmer
      - balance_designer
      - qa_lead
    recommended_roles:
      - art_director
    asset_types: [sprites, tilesets, sfx, procedural_rules]

  puzzle_game:
    description: "Logic/puzzle focused game"
    required_roles:
      - director
      - manager
      - gameplay_programmer
      - ui_designer
      - qa_lead
    recommended_roles:
      - audio_director
    asset_types: [ui_elements, sfx, minimal_sprites]

  rpg:
    description: "Role-playing game with story and progression"
    required_roles:
      - director
      - manager
      - asset_generator
      - gameplay_programmer
      - story_writer
      - balance_designer
      - qa_lead
    recommended_roles:
      - art_director
      - animation_director
      - audio_director
      - ui_designer
    asset_types: [sprites_or_3d, portraits, ui, music, sfx, dialogue]
```

---

## Tool Researcher Role

A dedicated role that keeps the studio's toolset current by researching new AI models, MCP servers, APIs, and techniques.

### Purpose

The game dev AI landscape evolves rapidly:
- New image generation models (better quality, faster)
- New MCP servers (GitHub, databases, specialized tools)
- New AI models (Gemini updates, Claude updates, specialized models)
- New techniques (better prompting, new workflows)

**Tool Researcher** proactively discovers these and proposes upgrades.

### Role Definition

```yaml
role:
  id: tool_researcher
  name: Tool Researcher
  model: claude-sonnet

  description: |
    Researches latest AI tools, MCP servers, models, and techniques.
    Proposes toolset upgrades. On approval, integrates into role configs.

  responsibilities:
    - Monitor for new MCP servers relevant to game dev
    - Track AI model releases (image, 3D, audio, code)
    - Evaluate new tools against current toolset
    - Propose upgrades with justification
    - On approval, update role tool configurations
    - Document tool capabilities and limitations

  tools_available:
    - WebSearch (research new tools)
    - WebFetch (read documentation)
    - arXiv search (academic papers)
    - GitHub search (new repos, MCP servers)
    - npm/pip search (new packages)

  activation: always  # Core role, always available

  schedule:
    - trigger: weekly_scan
      action: "Scan for new tools in all categories"
    - trigger: on_demand
      action: "Research specific tool/capability when requested"
    - trigger: tool_failure
      action: "Find alternative when current tool fails"
```

### Research Categories

| Category | What to Monitor | Current Tools | Example Discoveries |
|----------|-----------------|---------------|---------------------|
| **Image Gen** | New SD models, LoRAs, services | Qwen-Image, SD | "FLUX.1 dev has better anatomy" |
| **3D Gen** | Mesh generation, texturing | TRELLIS.2, Meshy | "Tripo3D v2 supports animation" |
| **Animation** | Motion capture, retargeting | ActionMesh, MoCapAnything | "MotionGPT generates from text" |
| **Audio** | SFX, music, voice | Suno, ElevenLabs | "Udio v2 has better game music" |
| **Code AI** | Coding assistants, specialized | Claude, Gemini | "Codestral excels at game engines" |
| **MCP Servers** | New integrations | Current MCPs | "New Godot MCP for direct editing" |
| **Vision AI** | Image understanding | Gemini 3 Pro | "GPT-5 vision handles sprites better" |

### Tool Proposal Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    TOOL DISCOVERY FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐ │
│  │ RESEARCH │───>│ EVALUATE │───>│ PROPOSE  │───>│ APPROVE  │ │
│  │          │    │          │    │          │    │          │ │
│  └──────────┘    └──────────┘    └──────────┘    └────┬─────┘ │
│       │               │               │               │       │
│  Web search      Test locally    Write proposal   総監督      │
│  Read docs       Compare to      Show benefits    reviews     │
│  Check reviews   current tool    List tradeoffs              │
│                                                      │       │
│                                              ┌───────┴──────┐ │
│                                              │   INTEGRATE  │ │
│                                              │              │ │
│                                              └──────────────┘ │
│                                               Update configs  │
│                                               Add to roles    │
│                                               Document usage  │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

### Tool Proposal Format

```yaml
# queue/tool_proposals/tool_001.yaml
proposal_id: tool_001
proposed_by: tool_researcher
timestamp: 2026-01-30T14:00:00Z

tool_discovery:
  name: "Tripo3D v2"
  category: 3d_generation
  source: "https://www.tripo3d.ai"

  capabilities:
    - Image-to-3D mesh generation
    - NEW: Direct animation support
    - NEW: PBR texture generation
    - Faster than TRELLIS.2 (30s vs 2min)

  comparison_to_current:
    current_tool: "TRELLIS.2"
    advantages:
      - 4x faster generation
      - Built-in animation (no separate pipeline)
      - Better topology for game engines
    disadvantages:
      - Requires API key (paid service)
      - Less control over mesh density

  cost:
    pricing: "$0.10 per model"
    estimated_monthly: "$20-50 for typical project"

  integration_effort:
    difficulty: low
    changes_needed:
      - Add API key to secrets
      - Update asset_generator instructions
      - Add to 3d_action genre preset
    estimated_time: "1 hour"

recommendation: |
  RECOMMEND ADOPTION for 3D projects.
  Speed improvement significant for iteration.
  Animation support eliminates separate pipeline step.
  Cost reasonable for productivity gain.

affected_roles:
  - asset_generator  # Primary user
  - art_director     # Review outputs

status: pending_approval
```

### Approval & Integration Flow

**Step 1: 総監督 Reviews Proposal**
```
Dashboard shows:
┌─────────────────────────────────────────────────────┐
│ 🔧 Tool Proposals                                   │
├─────────────────────────────────────────────────────┤
│ #001 Tripo3D v2 (3D generation)                     │
│      Benefit: 4x faster, built-in animation         │
│      Cost: ~$30/month                               │
│      [Approve] [Reject] [Need More Info]            │
└─────────────────────────────────────────────────────┘
```

**Step 2: On Approval, Tool Researcher Integrates**

```yaml
# Updated config/tools/3d_generation.yaml
tools:
  3d_generation:
    primary: tripo3d_v2  # Changed from trellis2
    fallback: trellis2   # Keep as backup

    tripo3d_v2:
      api_endpoint: "https://api.tripo3d.ai/v2"
      api_key_env: "TRIPO3D_API_KEY"
      capabilities: [image_to_3d, animation, pbr_textures]
      cost_per_call: 0.10
      timeout_seconds: 60

    trellis2:
      # Previous config preserved as fallback
      ...
```

**Step 3: Update Role Instructions**

```yaml
# Updated instructions/asset_generator.md additions
## 3D Asset Generation

Primary tool: **Tripo3D v2** (as of 2026-01-30)
- Use for all image-to-3D conversions
- Supports direct animation export
- PBR textures included

Fallback: TRELLIS.2 (if Tripo3D unavailable)

### Usage
\`\`\`bash
# Via MCP or API call
tripo3d generate --input concept.png --animate --format glb
\`\`\`
```

**Step 4: Update Toolset Registry**

```yaml
# config/toolset_registry.yaml
# Auto-maintained by Tool Researcher

registry:
  last_updated: 2026-01-30

  categories:
    image_generation:
      current: [qwen_image, stable_diffusion]
      evaluated: [flux1_dev, midjourney_api]
      rejected: [dall_e_3]  # Reason: No game style LoRAs

    3d_generation:
      current: [tripo3d_v2, trellis2]  # tripo3d_v2 added
      evaluated: [meshy_v2]

    audio:
      current: [suno, elevenlabs_sfx]
      evaluated: [udio_v2]
      pending_proposal: [udio_v2]  # Under evaluation

    mcp_servers:
      current: [github, memory, playwright, arxiv, context7]
      evaluated: [godot_mcp, unity_mcp]
      pending_proposal: [godot_mcp]
```

### Periodic Research Schedule

```yaml
# Tool Researcher's scheduled tasks

schedule:
  weekly:
    - task: "Scan Awesome-MCP-Servers for new game-dev relevant servers"
      sources:
        - "https://github.com/punkpeye/awesome-mcp-servers"
        - "https://github.com/modelcontextprotocol/servers"

    - task: "Check major AI model announcements"
      sources:
        - Google AI blog (Gemini updates)
        - Anthropic blog (Claude updates)
        - OpenAI blog (GPT updates)
        - Stability AI (image models)

    - task: "Review game dev AI tool releases"
      sources:
        - Product Hunt (AI category)
        - Hacker News (AI threads)
        - r/gamedev (AI tools)

  monthly:
    - task: "Full toolset audit"
      action: "Compare all current tools against alternatives"
      output: "Monthly tool report in dashboard"

    - task: "Cost analysis"
      action: "Review API costs, suggest optimizations"

  on_failure:
    - trigger: "Any tool fails or produces poor results"
      action: "Immediate research for alternatives"
      priority: high
```

### Example Research Session

```markdown
## Tool Research Report: 2026-01-30

### Scan Results

**New MCP Servers Found:**
1. `godot-mcp` - Direct Godot editor integration
   - Can create scenes, add nodes, modify properties
   - Recommendation: EVALUATE for Godot projects

2. `blender-mcp` - Blender automation
   - Script execution, render control
   - Recommendation: EVALUATE for 3D projects

**Model Updates:**
1. Gemini 3 Pro Vision update (Jan 28)
   - Improved spatial reasoning
   - Better at UI screenshot analysis
   - Status: Already using, no action needed

2. Stable Diffusion 3.5 Large Turbo
   - Faster than SD3, comparable quality
   - Recommendation: PROPOSE as SD upgrade

**API Changes:**
1. Suno API v2 released
   - Better instrumental control
   - Recommendation: PROPOSE upgrade

### Proposals Generated
- [ ] tool_002: godot-mcp integration
- [ ] tool_003: sd35-large-turbo upgrade
- [ ] tool_004: suno-api-v2 upgrade

### No Action Needed
- Meshy AI: No significant updates
- ElevenLabs: Current version sufficient
- TRELLIS: Superseded by Tripo3D (already adopted)
```

---

## Self-Improvement System

### 1. Dynamic Role Definition

When existing roles don't cover a need, the system can define new roles on-the-fly.

**Trigger:** Manager identifies a task that doesn't fit existing roles

**Process:**
```yaml
# queue/role_proposals/new_role_001.yaml
proposal_id: role_001
proposed_by: manager
timestamp: 2026-01-30T10:00:00Z

role_definition:
  id: marketing_specialist
  name: Marketing Specialist
  model: claude-sonnet
  description: "Handles store pages, trailer scripts, social media"
  responsibilities:
    - Write compelling store page copy
    - Script trailer sequences
    - Plan social media announcements
  sakurai_principles:
    - "Show the Actual Game" - Trailers show real gameplay
    - "Start with the Climax" - Lead with exciting moments
  tools_needed:
    - video editing guidance
    - copywriting
  activation_conditions:
    - phase: [polish, release]
    - trigger: "marketing task assigned"

justification: |
  Current release preparation requires marketing materials.
  No existing role covers store page copy or trailer scripting.

status: pending_approval  # → approved / rejected
```

**Approval Flow:**
```
Manager proposes → Director reviews → 総監督 approves
                                           ↓
                              Role added to config/custom_roles.yaml
                              Role instructions generated
                              Role available for future use
```

### 2. Skill Accumulation

Patterns discovered during work become reusable skills, following multi-agent-shogun's model.

**Skill Discovery Sources:**
| Source | Example Discovery |
|--------|-------------------|
| Asset Generator | "Consistent sprite style prompt template" |
| Art Director | "Sakurai exaggeration checklist for readability" |
| Gameplay Programmer | "State machine pattern for player actions" |
| QA Lead | "Edge case checklist for platformer mechanics" |
| Any Role | Workflow pattern that worked well |

**Skill Proposal Format:**
```yaml
# queue/skill_proposals/skill_001.yaml
proposal_id: skill_001
proposed_by: animation_director
timestamp: 2026-01-30T14:30:00Z

skill_definition:
  name: sakurai-animation-review
  description: "Review animations using Sakurai's timing principles"
  trigger_phrases:
    - "review this animation"
    - "check animation timing"
    - "animation feel off"

  checklist:
    - lead_in_frames: "Does anticipation exist? (1-3 frames typical)"
    - action_frames: "Is the action clear and readable?"
    - follow_through: "Does recovery exist? Shows weight."
    - exaggeration: "Is it exaggerated enough for game speed?"
    - squash_stretch: "Weight conveyed through deformation?"
    - hit_stop: "Recommend duration if impact moment"
    - screen_shake: "Recommend intensity if heavy impact"

  example_output: |
    ## Animation Review: hero_slash
    - ✅ Lead-in: 2 frames anticipation, good
    - ✅ Action: 3 frames, clear arc
    - ⚠️ Follow-through: Missing! Add 2-3 recovery frames
    - ✅ Exaggeration: Sword oversized, reads well
    - ❌ Hit stop: None. Recommend 3-frame freeze on contact
    - ⚠️ Screen shake: Light shake (2px, 2 frames) suggested

source_experience:
  - project: ninja_roguelike
  - tasks_applied: 12
  - success_rate: "All animations improved after this checklist"

status: pending_approval
```

**Skill Storage:**
```
~/.claude/skills/
├── studio-skills/
│   ├── sakurai-animation-review/
│   │   └── SKILL.md
│   ├── sprite-style-consistency/
│   │   └── SKILL.md
│   ├── platformer-edge-cases/
│   │   └── SKILL.md
│   └── ... (accumulated skills)
└── studio-roles/
    ├── marketing-specialist/
    │   └── ROLE.md
    └── ... (custom roles)
```

### 3. Experience Memory

Long-term memory persists across projects.

**Memory Categories:**
```yaml
# memory/studio_memory.jsonl

# Project history
{"type": "project", "id": "ninja_roguelike", "genre": "roguelike", "duration_weeks": 12, "outcome": "completed", "lessons": ["balance took longer than expected", "sprite style locked early helped"]}

# Role effectiveness
{"type": "role_performance", "role": "animation_director", "project": "ninja_roguelike", "tasks_completed": 45, "approval_rate": 0.92, "notes": "Gemini 3 Pro excellent at timing review"}

# Skill usage
{"type": "skill_usage", "skill": "sakurai-animation-review", "times_used": 23, "avg_iterations_saved": 1.5}

# Decision patterns
{"type": "decision", "context": "2d vs 3d art style", "decision": "2d_pixel", "reasoning": "Faster iteration, fits roguelike genre", "outcome": "good choice"}

# Custom rules
{"type": "rule", "rule": "Always externalize balance parameters", "source": "gameplay_programmer", "validated": true}
```

### 4. Tool Discovery & Integration

The Tool Researcher continuously improves the studio's capabilities.

**Memory of Tool Performance:**
```yaml
# memory/studio_memory.jsonl (tool entries)

# Tool adoptions
{"type": "tool_adoption", "tool": "tripo3d_v2", "category": "3d_generation", "date": "2026-01-30", "replaced": "trellis2", "reason": "4x faster, built-in animation"}

# Tool performance tracking
{"type": "tool_performance", "tool": "tripo3d_v2", "uses": 47, "success_rate": 0.96, "avg_time_seconds": 35, "issues": ["occasional texture artifacts on complex shapes"]}

# Tool rejections (avoid re-proposing)
{"type": "tool_rejected", "tool": "dall_e_3", "category": "image_generation", "reason": "No game style LoRAs, inconsistent style", "date": "2026-01-15"}

# Cost tracking
{"type": "tool_cost", "month": "2026-01", "tool": "tripo3d_v2", "calls": 150, "cost_usd": 15.00}
```

**Integration with Role Configs:**
```yaml
# When tool approved, auto-update affected roles

# config/role_tools.yaml
role_tools:
  asset_generator:
    image_generation: [qwen_image, stable_diffusion]
    3d_generation: [tripo3d_v2, trellis2]  # Auto-updated on approval
    audio: [suno, elevenlabs_sfx]

  art_director:
    vision_primary: agentic-image-analysis  # Claude skill, no approval
    vision_escalation: gemini-3-pro         # Requires Manager approval
    reference_search: [web_search]

  animation_director:
    vision_primary: agentic-image-analysis  # Claude skill, no approval
    vision_escalation: gemini-3-pro         # Requires Manager approval
    motion_reference: [youtube_analysis]

  ui_designer:
    vision_primary: agentic-image-analysis
    vision_escalation: gemini-3-pro

  vfx_artist:
    vision_primary: agentic-image-analysis
    vision_escalation: gemini-3-pro
```

### 5. Self-Improvement Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                  SELF-IMPROVEMENT LOOP                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  THREE IMPROVEMENT PATHS (all feed back into work):                 │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ PATH A: SKILL DISCOVERY                                      │   │
│  │ Work → Notice Pattern → Propose Skill → Approve → Store     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ PATH B: ROLE DEFINITION                                      │   │
│  │ Need Gap → Propose Role → 総監督 Approves → Add to Pool     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ PATH C: TOOL DISCOVERY (Tool Researcher)                     │   │
│  │ Research → Evaluate → Propose Tool → Approve → Integrate    │   │
│  │                                                              │   │
│  │ Weekly scan ─┐                                               │   │
│  │ On failure ──┼──> Find better tools ──> Update role configs │   │
│  │ User request─┘                                               │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│                           ↓                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    WORK (IMPROVED)                           │   │
│  │  • Skills auto-suggested for matching tasks                  │   │
│  │  • New roles available when needed                           │   │
│  │  • Better tools for each capability                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Example Flows:**

**Skill Discovery:**
1. Animation Director reviews 10 animations using mental checklist
2. Notices same checklist applies every time → PATTERN
3. Proposes "sakurai-animation-review" skill
4. Director approves, skill stored in ~/.claude/skills/
5. Next animation task → skill auto-suggested

**Role Definition:**
1. Project needs marketing materials, no role covers it
2. Manager proposes "marketing_specialist" role
3. 総監督 reviews and approves
4. Role added to pool, available for this and future projects

**Tool Discovery:**
1. Tool Researcher's weekly scan finds "Godot MCP"
2. Evaluates: direct Godot editor integration, huge time saver
3. Proposes tool with cost/benefit analysis
4. 総監督 approves
5. Tool added to asset_generator and programmer configs
6. Next Godot task uses direct integration instead of manual export

---

## Configuration

### Main Settings

```yaml
# config/studio.yaml

studio:
  name: "AI Game Studio"

  hierarchy:
    executive_director: "user"  # 総監督
    director:
      model: "claude-opus"
      extended_thinking: true   # Wrong decisions cascade everywhere
    manager:
      model: "claude-sonnet"
      extended_thinking: false  # "Don't think. Delegate." (考えるな。委譲しろ。)
      forbidden_rules:
        - F001: "Cannot read/write files or execute tasks directly"
        - F002: "Must re-read role file after context compression"
        - F003: "Cannot override Director's creative decisions"

  # Model assignments
  models:
    director: "claude-opus"       # Deep thinking, creative decisions
    manager: "claude-sonnet"      # Fast delegation by rules
    specialists: "claude-sonnet"  # Task execution
    lightweight: "claude-haiku"   # Documentation, simple tasks

  # Vision analysis (two-tier system)
  vision:
    # TIER 1: Primary - Claude's built-in skill (no approval)
    primary:
      tool: "agentic-image-analysis"
      type: "claude-skill"
      approval_required: false

    # TIER 2: Escalation - Gemini 3 Pro (requires Manager approval)
    escalation:
      tool: "gemini-3-pro"
      command: "gemini -m gemini-3-pro"
      approval_required: true
      approval_from: "manager"
      use_when:
        - "primary analysis inconclusive"
        - "multiple reviewers disagree"
        - "complex spatial reasoning"
      used_by_roles:
        - art_director
        - animation_director
        - ui_designer
        - vfx_artist

  # Current project
  current_project: null
  current_phase: null

  # Self-improvement
  self_improvement:
    auto_propose_skills: true
    skill_approval_required: true  # Director must approve
    role_approval_required: true   # 総監督 must approve new roles
    tool_approval_required: true   # 総監督 must approve new tools
    memory_file: "memory/studio_memory.jsonl"

  # Tool Research
  tool_research:
    enabled: true
    researcher_model: "claude-sonnet"
    schedule:
      weekly_scan: true
      scan_day: "monday"
    sources:
      - "https://github.com/punkpeye/awesome-mcp-servers"
      - "https://github.com/modelcontextprotocol/servers"
      - "huggingface.co/models"  # New AI models
      - "arxiv.org"  # Research papers
    categories:
      - image_generation
      - 3d_generation
      - animation
      - audio
      - mcp_servers
      - ai_models
    cost_tracking: true
    max_monthly_tool_cost: 100  # USD budget alert threshold

  # Paths
  paths:
    skills: "~/.claude/skills/studio-skills"
    custom_roles: "~/.claude/skills/studio-roles"
    tool_registry: "./config/toolset_registry.yaml"
    tool_proposals: "./queue/tool_proposals"
    context: "./context"
    assets: "./assets"
    builds: "./builds"
```

### Project Configuration

```yaml
# config/projects/ninja_roguelike.yaml

project:
  id: ninja_roguelike
  name: "Ninja Roguelike"
  genre: roguelike

  vision: |
    A roguelike where you cook ingredients found in dungeons
    to gain temporary powers. Fast-paced, high risk/reward.

  phase: production

  # Active roles for this project
  active_roles:
    required:
      - director
      - manager
      - tool_researcher  # Always active, keeps toolset current
      - asset_generator
      - gameplay_programmer
      - balance_designer
      - qa_lead
    active:
      - art_director
      - animation_director
    dormant:
      - story_writer  # Minimal narrative
      - localization  # English only for now

  # Phase-specific role activation
  phase_overrides:
    polish:
      activate: [vfx_artist, audio_director]
      deactivate: [balance_designer]

  # Asset configuration
  assets:
    style: "pixel_art_16x16"
    palette: "limited_32_colors"
    target_resolution: "1920x1080"
```

---

## Startup & Usage

### Launch Script

```bash
#!/bin/bash
# game_studio_launch.sh

STUDIO_DIR="${GAME_STUDIO_DIR:-$HOME/game-studio}"
PROJECT="$1"
PHASE="$2"

# Load project config
if [ -n "$PROJECT" ]; then
  CONFIG="$STUDIO_DIR/config/projects/${PROJECT}.yaml"
  if [ ! -f "$CONFIG" ]; then
    echo "Project config not found: $CONFIG"
    exit 1
  fi
fi

# Determine active roles from genre/phase
GENRE=$(yq '.project.genre' "$CONFIG")
ACTIVE_ROLES=$(yq '.project.active_roles.active[]' "$CONFIG")

echo "🎮 Launching Game Studio"
echo "   Project: $PROJECT"
echo "   Genre: $GENRE"
echo "   Phase: $PHASE"
echo "   Active Roles: $ACTIVE_ROLES"

# Create tmux sessions
tmux new-session -d -s director -n director
tmux new-session -d -s studio -n workers

# Director (Claude Opus)
tmux send-keys -t director \
  "cd $STUDIO_DIR && claude --model opus" Enter
sleep 2
tmux send-keys -t director "/read instructions/director.md" Enter

# マネージャー/Manager (Claude Sonnet - thinking OFF, fast delegation)
tmux send-keys -t studio:workers.0 \
  "cd $STUDIO_DIR && claude --model sonnet" Enter
sleep 1
tmux send-keys -t studio:workers.0 "/read instructions/manager.md" Enter

# All specialist roles use Claude
# Visual-review roles (art_director, etc.) invoke Gemini 3 Pro as a TOOL when needed
ALL_ROLES=(
  "tool_researcher"
  "art_director"
  "animation_director"
  "ui_designer"
  "vfx_artist"
  "gameplay_programmer"
  "audio_director"
  "qa_lead"
  "balance_designer"
  "story_writer"
  "tech_writer"
)

PANE=1
for role in "${ALL_ROLES[@]}"; do
  if echo "$ACTIVE_ROLES" | grep -q "$role"; then
    tmux split-window -t studio:workers
    tmux send-keys -t studio:workers.$PANE \
      "cd $STUDIO_DIR && claude" Enter
    sleep 1
    tmux send-keys -t studio:workers.$PANE \
      "/read instructions/${role}.md" Enter
    ((PANE++))
  fi
done

# Balance layout
tmux select-layout -t studio:workers tiled

echo ""
echo "✅ Studio launched!"
echo "   Director: tmux attach -t director"
echo "   Workers:  tmux attach -t studio"
```

### Usage Examples

```bash
# Start new project
./game_studio_launch.sh ninja_roguelike concept

# Resume existing project
./game_studio_launch.sh ninja_roguelike production

# Check status
cat dashboard.md

# Talk to Director
tmux attach -t director
> "What's the status of character sprites?"

# Add a custom role mid-project
> "We need someone to handle localization"
# → Manager proposes role, Director approves, 総監督 confirms
```

---

## Dashboard Format

```markdown
# 🎮 Game Studio Dashboard

**Project:** Ninja Roguelike
**Genre:** Roguelike
**Phase:** Production (Week 6/12)
**Vision:** Cook ingredients from dungeons for temporary powers

---

## 🚨 要対応 (Decisions for 総監督)

| # | Decision Needed | Options | Deadline |
|---|-----------------|---------|----------|
| 1 | Boss design: one large or swarm? | A) Single boss B) Swarm of mini | Today |
| 2 | Add fishing minigame? | A) Yes (adds 1 week) B) No | EOW |

---

## 📊 Phase Progress

### Production - Parallel Tracks
```
ASSETS    ████████████░░░░░░░░ 60%  (Art Dir, Anim Dir)
MECHANICS ██████████████░░░░░░ 70%  (Gameplay Prog)
TESTING   ████████░░░░░░░░░░░░ 40%  (QA Lead)
INTEGR.   ██████████████████░░ 90%  (Tech Lead)
```

---

## 🎬 Active Tasks

### Review Roles (Claude + Gemini vision tool)
| Role | Task | Status |
|------|------|--------|
| Art Director | Review enemy sprite batch 3 | In Progress |
| Animation Director | Validate cooking animation timing | Waiting for asset |

### Development Roles (Claude)
| Role | Task | Status |
|------|------|--------|
| Gameplay Programmer | Ingredient combination system | Testing |
| Balance Designer | Tune recipe power curves | In Progress |
| QA Lead | Edge case: inventory overflow | Investigating |

---

## 🏆 Completed Today

| Time | Role | Deliverable |
|------|------|-------------|
| 15:30 | Art Director | Approved 12 food sprites |
| 14:00 | Gameplay Prog | Recipe crafting system done |
| 11:00 | Animation Dir | Walk cycle timing fixed |

---

## 🔧 Concept Alignment Check

Last check: 2 days ago
Status: ✅ On track

Notes:
- Core loop feels good
- Art style consistent
- Cooking mechanic is fun as hoped
- Consider: enemy variety lower than planned (scope trim?)

---

## 🎯 Skill Candidates

| Proposed By | Skill | Status |
|-------------|-------|--------|
| Animation Director | sakurai-animation-review | ✅ Approved |
| Gameplay Programmer | parameter-externalization | ⏳ Pending |
| Art Director | pixel-exaggeration-guide | ⏳ Pending |

---

## 📝 New Role Proposals

| Proposed By | Role | Status |
|-------------|------|--------|
| Manager | marketing_specialist | ⏳ Needs 総監督 approval |

---

## 🔧 Tool Proposals

| Proposed By | Tool | Category | Benefit | Cost | Status |
|-------------|------|----------|---------|------|--------|
| Tool Researcher | Tripo3D v2 | 3D Gen | 4x faster, built-in anim | $0.10/model | ✅ Approved |
| Tool Researcher | Godot MCP | Engine | Direct editor control | Free | ⏳ Pending |
| Tool Researcher | Udio v2 | Music | Better game music | $0.05/track | ⏳ Pending |

**Monthly Tool Costs:** $45.20 / $100.00 budget

---

## 📡 Tool Researcher Activity

**Last Scan:** 2026-01-29 (Monday)
**Next Scan:** 2026-02-05

**Recent Discoveries:**
- Godot MCP - Direct Godot editor integration (PROPOSED)
- Udio v2 - Improved game music generation (PROPOSED)
- SD 3.5 Turbo - Faster image gen (EVALUATING)

**Rejected This Month:**
- DALL-E 3: No game style LoRAs

---

*Last updated: 2026-01-30 16:00 by Manager*
```

---

## Summary of Changes from Original

| Aspect | multi-agent-shogun | Game Studio |
|--------|-------------------|-------------|
| Top role | Shogun (将軍) | 総監督 (you) + 監督 (AI) |
| Middle role | マネージャー (Karo) | マネージャー (Manager) — Sonnet, thinking OFF, F001-F003 |
| Workers | 8 identical 足軽 | Dynamic specialist pool |
| Models | All Claude | All Claude + Gemini 3 Pro as vision tool |
| Phases | Generic tasks | Concept → Demo → Production → Release |
| Parallelism | Task-level | Track-level (Assets/Mechanics/Testing/Integration) |
| Roles | Fixed 10 agents | Dynamic by genre + phase + need |
| Tool management | Manual | Tool Researcher auto-discovers & proposes |
| Self-improvement | Rule accumulation | Skills + Roles + Tools accumulation |
| Principles | Generic | Sakurai methods embedded per role |
| Vision capability | None | Two-tier: Claude skill primary, Gemini 3 Pro escalation |

---

## References

- [multi-agent-shogun](../../multi-agent-shogun/) - Base orchestration system
- [Sakurai Methods](skill-candidates.md) - Game dev principles
- [AI Game Dev Framework](ai-game-dev-framework.md) - Tool integration
- Claude `agentic-image-analysis` skill - Primary vision analysis
- [Gemini 3 Pro](https://blog.google/products/gemini/gemini-3/) - Escalation vision tool (requires approval)

---

*Plan created: 2026-01-30*
*Status: Draft v5 - Hybrid thinking: Director thinks (cascading decisions), マネージャー delegates fast (F001-F003 structural safeguards)*
