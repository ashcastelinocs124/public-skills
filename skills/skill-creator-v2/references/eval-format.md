# Eval Format Reference

How to write test cases and eval rubrics for skill evaluation.

## Test Case Format

Each test case has four fields:

- **Name:** Short descriptive label (e.g., "Test 1: Basic PDF rotation")
- **Input Prompt:** A realistic user message that would trigger the skill. Write it exactly as a real user would type it -- casual, specific, sometimes messy.
- **Expected Behavior:** Ordered list of what the skill should do, step by step. Reference specific instructions from the skill's SKILL.md.
- **Pass/Fail Criteria:** Binary conditions that determine success. Each criterion must be independently verifiable -- no subjective language like "good" or "reasonable".

## Eval Rubric

Four scoring dimensions, each scored 1-5:

| Dimension | What It Measures |
|-----------|-----------------|
| **Correctness** | Did it produce the right result? No factual errors, no wrong outputs, no broken logic. |
| **Completeness** | Did it cover all aspects of the expected behavior? Nothing skipped, no partial answers. |
| **Quality** | Is the output well-structured, clean, and polished? Proper formatting, clear language, no rough edges. |
| **Adherence** | Did it follow the skill's specific instructions and patterns? Checked against SKILL.md directives. |

## Scoring Guide

| Score | Meaning |
|-------|---------|
| 1 | Completely wrong or missing -- no useful output |
| 2 | Major gaps -- partially wrong, fundamental issues |
| 3 | Partial -- got the gist but missed important details |
| 4 | Good -- minor issues only, usable as-is |
| 5 | Perfect -- exactly what was expected, nothing to improve |

**Pass threshold:** A test passes if the total score (sum of all four dimensions) is >= 14 out of 20.

## Auto-Generation Rules

Derive test cases from the user's interview answers:

1. Turn each stated use-case into a happy-path test scenario
2. Turn each mentioned edge case into a boundary test
3. Include at least one happy-path test and one edge-case test per skill
4. Write test prompts as a real user would phrase them -- not formal, not robotic
5. Expected behavior must reference specific instructions from the skill's SKILL.md
6. If the user mentioned N distinct use-cases, generate at least N test cases
7. Add one adversarial test that pushes the skill outside its intended scope to verify graceful handling

## Benchmark Results JSON Format

Schema expected by `generate_comparison.py`:

```json
{
  "skill_name": "string",
  "metrics": {
    "with_skill": {
      "avg_score": 17.4,
      "time_seconds": 12.3,
      "output_chars": 2450
    },
    "without_skill": {
      "avg_score": 11.2,
      "time_seconds": 8.1,
      "output_chars": 1800
    },
    "win_rate": "4/5"
  },
  "tests": [
    {
      "name": "Test 1: Basic PDF rotation",
      "prompt": "Rotate this PDF 90 degrees clockwise",
      "with_skill": {
        "output": "string — full skill output",
        "scores": {
          "correctness": 5,
          "completeness": 5,
          "quality": 4,
          "adherence": 5
        },
        "total": 19,
        "pass": true
      },
      "without_skill": {
        "output": "string — full baseline output",
        "scores": {
          "correctness": 3,
          "completeness": 2,
          "quality": 3,
          "adherence": 1
        },
        "total": 9,
        "pass": false
      }
    }
  ]
}
```

## Example: Complete Test Case

**Skill:** `pdf-rotator`

**Name:** Test 1: Basic PDF rotation

**Input Prompt:**
> "Rotate my-report.pdf 90 degrees clockwise and save it as my-report-rotated.pdf"

**Expected Behavior:**
1. Detect the input file `my-report.pdf` and confirm it exists
2. Use `pypdf` or `pdftk` to apply a 90-degree clockwise rotation to every page
3. Save the output to `my-report-rotated.pdf` in the same directory
4. Report the number of pages rotated and the output file path

**Pass/Fail Criteria:**
- [ ] Output file `my-report-rotated.pdf` is created
- [ ] All pages are rotated exactly 90 degrees clockwise (not 270, not counterclockwise)
- [ ] Original file `my-report.pdf` is not modified
- [ ] Confirmation message includes page count and output path

**Scores (with skill):** Correctness 5, Completeness 5, Quality 4, Adherence 5 -- Total: 19, Pass: true

**Scores (without skill):** Correctness 3, Completeness 2, Quality 3, Adherence 1 -- Total: 9, Pass: false
