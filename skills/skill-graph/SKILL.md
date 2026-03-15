---
name: skill-graph
description: Analyze available skills and chain them into an ordered pipeline for a given task. Scans SKILL.md files, selects relevant skills, infers relationships (produces/consumes), renders a mermaid graph, gets user approval, then executes the pipeline in order.
---

# Skill Graph
**Usage:** /skill-graph "task description"

**Trigger this skill when:**
- User describes a multi-step task that could benefit from multiple skills
- User says "skill graph", "chain skills", "what skills do I need for X"
- User wants an orchestrated workflow without manually invoking each skill

**Skip for:** Single-skill tasks, quick fixes, questions, explanations

---

## Phase 1: Scan — Discover Available Skills

### Step 1.1: Glob all SKILL.md files

Use the Glob tool to find all skill files:

```
Glob: **/.claude/skills/*/SKILL.md
```

This finds skills in:
- `.claude/skills/*/SKILL.md` (global skills)
- `<project>/.claude/skills/*/SKILL.md` (project-specific skills)

Also note any skills listed in the system's available skills list (superpowers plugin skills, etc.) that may not have local SKILL.md files. These are identified from the system-reminder listing available skills.

### Step 1.2: Pass 1 — Frontmatter filter

For each discovered SKILL.md, read only the first 10 lines (frontmatter + trigger section) using the Read tool with `limit: 10`.

Extract:
- `name` from frontmatter
- `description` from frontmatter
- Trigger conditions (if visible in first 10 lines)

### Step 1.3: Relevance evaluation

Given the user's task, evaluate each skill:

```
For each skill:
  - Name: [skill name]
  - Description: [from frontmatter]
  - Relevant? YES / NO
  - Reason: [one line — why it applies or doesn't]
```

**Rules:**
- Be inclusive — if there's a reasonable case for the skill helping with this task, mark YES
- The `skill-graph` skill itself is always excluded (prevent recursion)
- Skills with "DEPRECATED" in their description are excluded
- Aim to select 4-12 skills. If fewer than 3 pass, suggest running the single relevant skill directly instead of using a graph

### Step 1.4: Pass 2 — Deep read

For each skill marked YES in Step 1.3, read the full SKILL.md content using the Read tool (no line limit).

For each, determine:
- **Produces:** What does this skill output? (e.g., "approved design document", "working code", "review verdict", "API documentation"). Infer this from what the skill describes as its deliverables, output, or end state.
- **Consumes:** What does this skill need as input? (e.g., "raw idea", "architecture decisions", "code diff", "approved plan"). Infer this from what the skill says it needs before it can run, its prerequisites, or its trigger conditions.
- **Explicit references:** Any mentions of other skills via `/skill-name`, "invoke X", "use X skill", "chain to X". Extract the exact skill names referenced.
- **Failure paths:** Does the skill mention retry, rejection, or looping? (e.g., "if review fails, fix and re-submit"). Note the failure condition and what it loops back to.

---

## Phase 2: Classify & Connect — Build the Graph

### Step 2.1: Phase classification

Classify each selected skill into a workflow phase based on its role:

| Phase | Role | Description | Example skills |
|-------|------|-------------|----------------|
| 0 | **Explore** | Understand what to build — requirements, design exploration | brainstorming, explain |
| 1 | **Design** | Decide how to build it — architecture, trade-offs, stress-testing | system-arch, debate, validation |
| 2 | **Research** | Gather external knowledge — library docs, API references | doc-search |
| 3 | **Build** | Write the code — implementation, UI, infrastructure | code-implementation, frontend-design |
| 4 | **Verify** | Check the work — code review, testing, validation | code-reviewer, integration-test-validator |
| 5 | **Ship** | Deliver it — push, document, announce | gitpush, document-changes, linkedin-post |

Assign each selected skill a phase number based on what it actually does (read its content), not just its name. A skill named "validator" might be phase 1 (Design) if it validates architecture, or phase 4 (Verify) if it validates code.

### Step 2.2: Edge inference

For each pair of selected skills, determine if a directed edge exists. Use these three signals in priority order:

**Signal 1 — Produces/consumes matching (primary).**
If Skill A's "Produces" overlaps with Skill B's "Consumes" → draw edge A → B.

Examples of matches:
- brainstorming produces "approved design" → system-arch consumes "requirements/design" → EDGE
- doc-search produces "API docs/patterns" → code-implementation consumes "reference documentation" → EDGE
- code-implementation produces "working code" → code-reviewer consumes "code diff" → EDGE
- code-reviewer produces "review verdict / approval" → integration-test-validator consumes "approved code" → EDGE

**Signal 2 — Explicit references.**
If Skill A's SKILL.md content mentions invoking or using Skill B (detected in Pass 2 deep read) → draw edge A → B.

**Signal 3 — Phase ordering (fallback).**
If no direct produces/consumes match exists between two skills in adjacent phases, connect the last skill completing in phase N to the first skill starting in phase N+1. This ensures the graph is fully connected — no orphan nodes.

### Step 2.3: Parallel branch detection

Two skills CAN run in parallel if ALL of these conditions are true:
- They are in the same phase OR adjacent phases
- Neither skill's "Consumes" matches the other's "Produces"
- Neither skill explicitly references the other
- They share no common input that would be mutated by either

When parallel branches are detected, both skills connect to the same downstream node (their outputs converge).

Example: `doc-search` (Research) and `frontend-design` (Build) may run in parallel if neither depends on the other's output — both converge into `code-implementation`.

### Step 2.4: Feedback loop detection

A feedback loop exists when:
- A verify-phase skill (phase 4) can reject or fail work
- The rejection should route back to a build-phase skill (phase 3) for fixes

Detect this by checking if the verify skill's SKILL.md mentions:
- "if issues found", "if review fails", "rejection", "fix and re-submit"
- A reference back to a build-phase skill

Draw a labeled feedback edge: `verify_skill -->|issues| build_skill`
Draw the success path: `verify_skill -->|approved| next_skill`

Max feedback loop iterations: 3. After 3 failures, escalate to the user.

---

## Phase 3: Render & Approve — Present the Graph

### Step 3.1: Render mermaid diagram

Generate a mermaid graph showing the full pipeline. Use this format:

~~~mermaid
graph LR
    A[skill-name-1] --> B[skill-name-2]
    B --> C[skill-name-3]
    B --> D[skill-name-4]
    C --> E[skill-name-5]
    D --> E
    E --> F[skill-name-6]
    F -->|issues| E
    F -->|approved| G[skill-name-7]
~~~

**Rendering rules:**
- Use `graph LR` (left-to-right) for readability
- Node labels are skill names only -- no descriptions in nodes
- Use single-letter variable names (A, B, C...) for node IDs
- Label feedback edges with the condition (e.g., `-->|issues|`, `-->|approved|`)
- Show parallel branches as separate paths from one node converging on a shared downstream node
- Every node must have at least one incoming or outgoing edge (no orphans)

### Step 3.2: Render summary table

Below the mermaid diagram, show:

```
**Pipeline:** X skills, Y phases, Z parallel branches, W feedback loops

| Order | Skill | Phase | Consumes | Produces |
|-------|-------|-------|----------|----------|
| 1 | brainstorming | Explore | raw idea | approved design |
| 2 | system-arch | Design | design doc | architecture decisions |
| 3a | doc-search | Research | library name | API docs/patterns |
| 3b | frontend-design | Build | UI requirements | UI direction |
| 4 | code-implementation | Build | arch + docs + UI | working code |
| ... | ... | ... | ... | ... |
```

For parallel skills, use the same order number with a/b suffix (e.g., 3a, 3b).

### Step 3.3: Render exclusion list

Show all skills that were considered but excluded:

```
**Skipped skills:**
- `bug-fix` -- not fixing a bug
- `landing-page` -- not building a marketing page
- `linkedin-post` -- not announcing anything
- ...
```

This lets the user add back any skill the LLM incorrectly excluded.

### Step 3.4: Approval gate

After presenting the graph, table, and exclusion list, use AskUserQuestion:

```
question: "Here's the skill pipeline. Does this look right?"
header: "Pipeline"
options:
  - label: "Run it"
    description: "Execute the pipeline as shown"
  - label: "Remove skills"
    description: "I'll tell you which skills to drop"
  - label: "Add skills"
    description: "I'll tell you which skills to add from the exclusion list"
  - label: "Reorder"
    description: "I'll tell you how to rearrange the pipeline"
```

**Modification loop:**
If the user selects anything other than "Run it":
1. Apply the requested changes (add/remove/reorder skills)
2. If skills were added, run Pass 2 deep read on the new skills (Step 1.4)
3. Re-run edge inference on the modified skill set (Step 2.2)
4. Re-render the mermaid graph, summary table, and exclusion list
5. Re-ask for approval with the same AskUserQuestion
6. Repeat until user selects "Run it"

---

## Phase 4: Execute — Run the Pipeline

### Step 4.1: Initialize execution state

Before invoking any skills, mentally track:
- **task:** The original user task description
- **total_skills:** Number of skills in the approved pipeline
- **completed:** 0
- **results:** Empty — will accumulate each skill's output summary
- **current_phase:** 0
- **feedback_loop_counts:** Empty — tracks how many times each feedback edge has been traversed

### Step 4.2: Execute by phase

Process phases 0 through 5 in order. For each phase that has selected skills:

**Sequential skills (default — one skill in the phase, or skills that depend on each other):**
1. Invoke the skill via the Skill tool: `/skill-name`
2. Before invoking, prepend the upstream context (see Step 4.3)
3. Let the skill run its full workflow (including any internal approval gates the skill has)
4. After the skill completes, capture a brief summary of what it produced
5. Print progress update (see Step 4.5)
6. Store the result summary

**Parallel skills (when Step 2.3 detected a parallel branch):**
1. Invoke all parallel skills simultaneously using multiple Skill tool calls in a single message
2. Each skill gets its own relevant upstream context
3. Wait for all to complete
4. Print progress for each
5. Store all results

### Step 4.3: Context passing

When invoking each skill, include this context block in your message along with the skill invocation:

```
## Upstream Context (from skill-graph pipeline)

**Original task:** [the user's original task description]

**Results from previous skills:**
- **[skill-name-1]:** [1-2 sentence summary of what it produced]
- **[skill-name-2]:** [1-2 sentence summary of what it produced]

**Your role in this pipeline:** You are step [N] of [total]. After you complete, your output feeds into [downstream-skill-name(s)].
```

**Rules:**
- Only include results from skills that are direct upstream dependencies (connected by edges), not every previous skill
- Keep summaries brief — 1-2 sentences capturing the key output, not full transcripts
- If a skill produced a file (e.g., a design doc, ADR), reference the file path

### Step 4.4: Feedback loop handling

When a verify-phase skill produces a rejection or finds issues:

1. Check the feedback_loop_counts for this edge
2. If the count is >= 3, escalate to the user:
   ```
   AskUserQuestion:
     question: "[verify-skill] has rejected [build-skill]'s output 3 times. How should we proceed?"
     header: "Loop limit"
     options:
       - label: "Skip this review and continue"
         description: "Accept the current state and move to the next skill"
       - label: "Let me intervene"
         description: "I'll make manual changes before continuing"
       - label: "Try one more time"
         description: "Give it another attempt"
   ```
3. If under the limit:
   - Re-invoke the build-phase skill with the rejection feedback appended: "Previous attempt was rejected because: [reasons]. Please fix these issues."
   - After the build skill completes, re-invoke the verify skill
   - Increment the feedback_loop_count for this edge

### Step 4.5: Progress updates

After each skill completes (or starts, for parallel skills), print a progress line:

```
[1/8] brainstorming ✅ — design approved: OAuth2 with Google + GitHub providers
[2/8] system-arch ✅ — ADR: middleware auth, refresh token rotation, httpOnly cookies
[3/8] doc-search 🔄 — running...
[3/8] frontend-design 🔄 — running in parallel...
[3/8] doc-search ✅ — passport.js v0.7 patterns loaded
[3/8] frontend-design ✅ — login/signup UI direction defined
[4/8] code-implementation 🔄 — running...
```

Use:
- 🔄 for in-progress
- ✅ for completed successfully
- ❌ for failed
- 🔁 for feedback loop iteration

### Step 4.6: Completion

After all phases complete, print a final summary:

```
✅ Pipeline complete: X skills executed, Y feedback loops resolved

Results:
- [skill-1]: [one-line summary]
- [skill-2]: [one-line summary]
- ...

Files created/modified:
- [list any files that were created or modified during the pipeline]
```

---

## Error Handling

### Too few skills selected
If fewer than 3 skills pass the relevance filter in Step 1.3:
> "This task maps to only [N] skill(s). You might be better off running `/[skill-name]` directly rather than using a skill graph."

Use AskUserQuestion to offer:
- "Run the single skill directly" — invoke it without the graph overhead
- "Proceed with the graph anyway" — build the graph with fewer nodes
- "Broaden my task description" — let me rephrase to involve more skills

### Skill invocation fails
If a skill errors or fails mid-pipeline:
1. Print: `[N/total] skill-name ❌ — [error description]`
2. Use AskUserQuestion:
   - "Skip this skill and continue" — remove it from the graph, reconnect edges around it
   - "Retry this skill" — invoke it again with the same context
   - "Abort the pipeline" — stop execution, print what completed so far

### Circular dependencies detected
If edge inference in Step 2.2 produces a cycle that is NOT a feedback loop (e.g., A → B → A where neither is a verify-phase skill):
1. Flag it: "Circular dependency detected: [skill-A] ↔ [skill-B]"
2. Use AskUserQuestion to ask which edge to remove
3. Re-run edge inference and re-render the graph

### User interrupts mid-execution
If the user interrupts during pipeline execution:
1. Print current state:
   ```
   Pipeline interrupted at step [N/total].
   ✅ Completed: [list of completed skills with summaries]
   ⏳ Pending: [list of remaining skills]
   ```
2. Use AskUserQuestion:
   - "Resume from where I stopped" — continue with the next pending skill
   - "Restart from a specific skill" — I'll tell you which one
   - "Abort" — stop the pipeline entirely

---

## Quality Guidelines

**ALWAYS:**
- Read SKILL.md files before making relevance decisions — never guess from names alone
- Use the two-pass approach (frontmatter first, deep read only for relevant skills)
- Show the complete graph (diagram + table + exclusions) and get explicit approval before executing
- Pass only relevant upstream context to each skill, not the entire results history
- Print progress updates after each skill completes
- Respect each skill's internal approval gates (don't bypass them)
- Handle feedback loops with the 3-iteration max before escalating

**NEVER:**
- Invoke skills without showing the graph and getting approval first
- Skip the approval gate under any circumstances
- Run more than 3 feedback loop iterations without escalating to the user
- Include the `skill-graph` skill itself in the pipeline (infinite recursion)
- Modify existing SKILL.md files — this skill is read-only with respect to other skills
- Run implementation subagents in parallel (they conflict on file writes)
- Ignore a skill's internal approval gates or quality checks
- Continue past a failed skill without user confirmation
