# public-skills

A collection of skills and agents for AI coding workflows. Works with **Claude Code**, **Codex**, and any agent that supports a skills directory.

---

## Quick Start (2 steps)

```bash
git clone https://github.com/ashcastelinocs124/public-skills.git
cd public-skills
chmod +x setup.sh && ./setup.sh
```

`setup.sh` will:
1. Detect your agent (Claude Code or Codex) and ask where to install
2. Prompt for your GitHub username and email — personalizes skills so you never re-enter them
3. Copy all skills and agents to the right directory
4. Set your global `git config` if it isn't already

---

## Manual Install

If you prefer not to use the script:

**Claude Code (global — all projects):**
```bash
cp -r skills/gitpush ~/.claude/skills/
cp -r skills/code-implementation ~/.claude/skills/
# etc.
cp agents/*.md ~/.claude/agents/
```

**Claude Code (project-only):**
```bash
cp -r skills/gitpush .claude/skills/
```

**Codex:**
```bash
cp -r skills/* ~/.agents/skills/
cp agents/*.md ~/.agents/agents/
```

Then open any `SKILL.md` that contains `YOUR_GITHUB_USERNAME` or `YOUR_EMAIL` and replace with your own values.

---

## Skills

| Skill | What it does |
|-------|-------------|
| `gitpush` | Safe GitHub push — identity check, .gitignore enforcement, secret scan, confirm gate |
| `code-implementation` | Plan → approve → implement → review cycle for features |
| `capture-learnings` | Extract session learnings to `learnings.md` and improve skills |
| `skill-creator` | Guide + scripts for creating new skills |
| `screen-recording` | Automate polished screen recordings via Steel Dev + Remotion |

## Agents

Sub-agents dispatched automatically by the skills above:

| Agent | What it does |
|-------|-------------|
| `code-implementation` | Heavy implementation — plans, checklists, execution |
| `code-reviewer` | Validates implementation against plan and coding standards |
| `integration-test-validator` | Runs full test suite after code review passes |

---

## Configuring a Skill

Each skill that needs personal info (like `gitpush`) has a **Configuration** block at the top of its `SKILL.md`. If you ran `setup.sh` these are already filled in. To update them manually:

```bash
# Example: update gitpush with your details
sed -i 's/YOUR_GITHUB_USERNAME/yourname/g' ~/.claude/skills/gitpush/SKILL.md
sed -i 's/YOUR_EMAIL/you@example.com/g'    ~/.claude/skills/gitpush/SKILL.md
```

---

## Agent Compatibility

| Agent | Skills dir | Agents dir |
|-------|-----------|-----------|
| Claude Code (global) | `~/.claude/skills/` | `~/.claude/agents/` |
| Claude Code (project) | `.claude/skills/` | `.claude/agents/` |
| Codex | `~/.agents/skills/` | `~/.agents/agents/` |
| Other | Check your agent's docs | — |

---

## Invoke a Skill

**Claude Code:** Use the `Skill` tool or type `/skill-name` in the chat.

**Codex / other:** Skills are plain Markdown — paste or reference them in your agent's system prompt or tool interface.
