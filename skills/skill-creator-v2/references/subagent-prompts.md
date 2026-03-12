# Subagent Prompt Templates

## Overview
During the A/B benchmark phase, two isolated subagents are spawned in parallel using the Task tool. One has the skill loaded, one does not. Both execute the same test cases. These templates define their prompts.

## Agent A: With-Skill Prompt Template

```
You are benchmarking a skill. The following skill instructions are loaded — follow them EXACTLY.

--- SKILL START ---
{{SKILL_MD_CONTENTS}}
--- SKILL END ---

Execute each test case below. For each test case:
1. Read the input prompt as if a real user said it
2. Follow the skill instructions above to produce your response
3. Write your complete output to the specified file path

{{TEST_CASES}}

Output instructions:
- Write each output to: /tmp/skill-benchmark-with/output-{n}.md (where n is the test number, starting at 1)
- Each file should contain ONLY your response to that test case
- Do NOT include meta-commentary about the skill or the test — just produce the output as if responding to a real user
- Handle ALL test cases, do not skip any
```

## Agent B: Without-Skill Prompt Template

```
Execute each task below. Do your best using only your general knowledge — no special instructions are provided.

For each test case:
1. Read the input prompt as if a real user said it
2. Produce the best response you can
3. Write your complete output to the specified file path

{{TEST_CASES}}

Output instructions:
- Write each output to: /tmp/skill-benchmark-without/output-{n}.md (where n is the test number, starting at 1)
- Each file should contain ONLY your response to that test case
- Do NOT include meta-commentary — just produce the output as if responding to a real user
- Handle ALL test cases, do not skip any
```

## Test Case Injection Format

When injecting test cases into the prompts above, format them as:

```
### Test 1: {test_name}
**Prompt:** "{input_prompt}"

### Test 2: {test_name}
**Prompt:** "{input_prompt}"
```

## Task Tool Configuration

Both agents use:
- `subagent_type: "general-purpose"`
- Both launched in the SAME message (parallel execution)
- Both run in background (`run_in_background: true`) to enable parallel execution
- Track wall-clock time by recording timestamps before and after

## Important Rules
- Agents MUST be completely isolated — no shared context
- Both agents get the EXACT same test cases
- Agent A gets the full SKILL.md injected; Agent B gets nothing extra
- Output files must be separate so grading can compare them
- If an agent fails to write an output file, score that test as 0 across all dimensions
