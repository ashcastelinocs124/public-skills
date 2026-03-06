#!/usr/bin/env bash
# setup.sh — one-time setup for public-skills
# Detects your coding agent, collects config, personalizes skills, and installs them.

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║        public-skills setup           ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════╝${RESET}"
echo ""

# ── 1. Detect agent ──────────────────────────────────────────────────────────

detect_agent() {
  if command -v claude &>/dev/null && [ -d "$HOME/.claude" ]; then
    echo "claude-code"
  elif [ -d "$HOME/.agents" ]; then
    echo "codex"
  else
    echo "unknown"
  fi
}

AGENT=$(detect_agent)

echo -e "${YELLOW}Detected agent:${RESET} $AGENT"
echo ""
echo "Where should skills be installed?"
echo "  1) Claude Code  — ~/.claude/skills/  (global, all projects)"
echo "  2) Claude Code  — ./.claude/skills/  (this project only)"
echo "  3) Codex        — ~/.agents/skills/"
echo "  4) Custom path  — I'll enter it manually"
echo ""

# Pre-select based on detection
case "$AGENT" in
  claude-code) DEFAULT=1 ;;
  codex)       DEFAULT=3 ;;
  *)           DEFAULT=4 ;;
esac

read -rp "Choice [$DEFAULT]: " CHOICE
CHOICE="${CHOICE:-$DEFAULT}"

case "$CHOICE" in
  1) SKILLS_DIR="$HOME/.claude/skills";  AGENTS_DIR="$HOME/.claude/agents" ;;
  2) SKILLS_DIR="./.claude/skills";      AGENTS_DIR="./.claude/agents" ;;
  3) SKILLS_DIR="$HOME/.agents/skills";  AGENTS_DIR="$HOME/.agents/agents" ;;
  4)
    read -rp "Skills path: " SKILLS_DIR
    read -rp "Agents path (leave blank to skip): " AGENTS_DIR
    ;;
  *) echo -e "${RED}Invalid choice.${RESET}"; exit 1 ;;
esac

echo ""
echo -e "${GREEN}Skills → $SKILLS_DIR${RESET}"
[ -n "$AGENTS_DIR" ] && echo -e "${GREEN}Agents → $AGENTS_DIR${RESET}"
echo ""

# ── 2. Collect personal config ───────────────────────────────────────────────

echo -e "${CYAN}Personal config (used in gitpush and commits):${RESET}"
echo "Press Enter to keep current git config value if shown."
echo ""

CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

read -rp "GitHub username [${CURRENT_NAME:-YOUR_GITHUB_USERNAME}]: " GIT_NAME
GIT_NAME="${GIT_NAME:-${CURRENT_NAME:-YOUR_GITHUB_USERNAME}}"

read -rp "Email [${CURRENT_EMAIL:-YOUR_EMAIL}]: " GIT_EMAIL
GIT_EMAIL="${GIT_EMAIL:-${CURRENT_EMAIL:-YOUR_EMAIL}}"

echo ""
echo -e "  Name:  ${GREEN}$GIT_NAME${RESET}"
echo -e "  Email: ${GREEN}$GIT_EMAIL${RESET}"
echo ""
read -rp "Looks good? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
[[ "$CONFIRM" =~ ^[Nn] ]] && echo "Aborted." && exit 0

# ── 3. Copy and personalize skills ───────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_skill() {
  local skill_name="$1"
  local src="$SCRIPT_DIR/skills/$skill_name"
  local dst="$SKILLS_DIR/$skill_name"

  if [ ! -d "$src" ]; then
    echo -e "${RED}Skill not found: $skill_name${RESET}"
    return
  fi

  mkdir -p "$dst"
  cp -r "$src/." "$dst/"

  # Personalize placeholders
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/YOUR_GITHUB_USERNAME/$GIT_NAME/g" "$dst/SKILL.md" 2>/dev/null || true
    sed -i '' "s/YOUR_EMAIL/$GIT_EMAIL/g"           "$dst/SKILL.md" 2>/dev/null || true
  else
    sed -i "s/YOUR_GITHUB_USERNAME/$GIT_NAME/g" "$dst/SKILL.md" 2>/dev/null || true
    sed -i "s/YOUR_EMAIL/$GIT_EMAIL/g"           "$dst/SKILL.md" 2>/dev/null || true
  fi

  echo -e "  ${GREEN}✓${RESET} $skill_name"
}

install_agent() {
  local agent_name="$1"
  local src="$SCRIPT_DIR/agents/$agent_name.md"
  local dst="$AGENTS_DIR/$agent_name.md"

  [ -z "$AGENTS_DIR" ] && return

  if [ ! -f "$src" ]; then
    echo -e "${RED}Agent not found: $agent_name${RESET}"
    return
  fi

  mkdir -p "$AGENTS_DIR"
  cp "$src" "$dst"
  echo -e "  ${GREEN}✓${RESET} $agent_name"
}

echo -e "${CYAN}Installing skills:${RESET}"
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  install_skill "$(basename "$skill_dir")"
done

echo ""
if [ -n "$AGENTS_DIR" ]; then
  echo -e "${CYAN}Installing agents:${RESET}"
  for agent_file in "$SCRIPT_DIR/agents"/*.md; do
    [ -f "$agent_file" ] && install_agent "$(basename "$agent_file" .md)"
  done
  echo ""
fi

# ── 4. Set global git config if not already set ──────────────────────────────

if [ -z "$CURRENT_NAME" ] || [ -z "$CURRENT_EMAIL" ]; then
  echo -e "${CYAN}Setting global git config:${RESET}"
  git config --global user.name  "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  echo -e "  ${GREEN}✓${RESET} git config user.name  = $GIT_NAME"
  echo -e "  ${GREEN}✓${RESET} git config user.email = $GIT_EMAIL"
  echo ""
fi

# ── 5. Done ──────────────────────────────────────────────────────────────────

echo -e "${GREEN}✓ Setup complete!${RESET}"
echo ""
echo "Skills installed to: $SKILLS_DIR"
echo ""
echo "Usage:"
case "$CHOICE" in
  1|2) echo "  In Claude Code: use the Skill tool, e.g. /gitpush or /code-implementation" ;;
  3)   echo "  In Codex: skills are available in ~/.agents/skills/" ;;
  4)   echo "  Place skills in your agent's configured skills directory." ;;
esac
echo ""
