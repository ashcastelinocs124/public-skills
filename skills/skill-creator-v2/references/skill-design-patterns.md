# Skill Design Patterns

Condensed reference for structuring skills correctly. Read this during the Build phase.

---

## Skill Directory Layout

```
skill-name/
  SKILL.md          <- Required. Frontmatter + instructions.
  scripts/           <- Optional. Executable code (Python/Bash).
  references/        <- Optional. Docs loaded into context as needed.
  assets/            <- Optional. Files used in output (templates, images).
```

## Frontmatter

```yaml
---
name: my-skill-name
description: |
  What the skill does. When to trigger it. All synonyms and phrasings
  a user might use. This is the ONLY text Claude sees when deciding
  whether to load the skill — put ALL trigger info here, not in the body.
---
```

**Rules:**
- `name`: lowercase hyphen-case, max 64 chars
- `description`: max 1024 chars. Must cover purpose AND all trigger conditions.
- No other fields allowed (except `license`)

## Body Writing Guidelines

1. **Imperative voice.** "Run the linter" not "The linter should be run."
2. **Concise.** Claude is already smart. Only add what it does not know.
3. **Examples over explanations.** Show, don't tell.
4. **Mandatory example.** Every SKILL.md must include at least one:
   ```
   Example:
   User: "deploy my app to staging"
   Action: Run preflight checks, build, push to staging env
   Output: Deployment URL + summary of what changed
   ```
5. **Max 500 lines.** If longer, split into `references/`.

## Progressive Disclosure (Three Levels)

| Level | What | When Loaded | Budget |
|-------|------|-------------|--------|
| 1. Metadata | `name` + `description` | Always in context | ~100 words |
| 2. SKILL.md body | Full instructions | When skill triggers | <5k words |
| 3. Bundled resources | scripts/, references/, assets/ | On demand by Claude | Unlimited |

Context window is a public good. Minimize token cost at every level.

## When to Use Each Resource Type

**scripts/** -- Use when the same code would be rewritten repeatedly, or for
deterministic operations (file conversion, PDF rotation, data transforms).

**references/** -- Domain knowledge Claude should read while working: schemas,
API docs, style guides, checklists. Keeps SKILL.md lean.

**assets/** -- Files used in output but NOT loaded into context: templates,
boilerplate files, images, fonts.

## Structure Patterns

Pick the pattern that fits the skill's nature:

### Workflow-Based (sequential processes)
```
Overview
Decision Tree (which path to take)
Step 1: ...
Step 2: ...
Step N: ...
Post-completion checks
```
Best for: deploy, bug-fix, code-review, migration skills.

### Task-Based (tool collections)
```
Overview
Quick Start
Task Category 1
  - Task A
  - Task B
Task Category 2
  - Task C
```
Best for: utility skills, multi-purpose skills, "Swiss army knife" skills.

### Reference/Guidelines (standards and rules)
```
Overview
Core Guidelines
Specifications / Rules
Usage Examples
```
Best for: style guides, coding standards, architecture patterns.

## Key Structural Rules

- **One level of nesting max.** SKILL.md can reference `references/` files.
  References must NOT reference sub-references.
- **No duplication.** Information lives in SKILL.md OR references/, never both.
- **TOC for long references.** Any reference file over 100 lines gets a table
  of contents at the top.

## What NOT to Include

Do not create any of these inside a skill:
- README.md, CHANGELOG.md, INSTALLATION_GUIDE.md
- Setup or testing procedures
- User-facing documentation
- Anything Claude already knows (common language syntax, well-known APIs)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Trigger info buried in body | Move ALL triggers to `description` |
| Description says what, not when | Add "Trigger when..." phrasing |
| Giant SKILL.md (500+ lines) | Extract to `references/` files |
| Duplicated content across files | Single source of truth, reference it |
| Script for something Claude can do inline | Remove script, let Claude do it |
| Over-explaining known concepts | Delete. Trust Claude's training. |
| No concrete example | Add at least one realistic prompt-to-output example |

## Quick Checklist Before Shipping

- [ ] `description` covers ALL trigger phrases and synonyms
- [ ] Body is under 500 lines
- [ ] At least one concrete example in SKILL.md
- [ ] No duplicated info between SKILL.md and references/
- [ ] scripts/ only contains truly reusable/deterministic code
- [ ] No README, CHANGELOG, or setup docs included
- [ ] Reference files over 100 lines have a TOC
