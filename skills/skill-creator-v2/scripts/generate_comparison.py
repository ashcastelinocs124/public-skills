#!/usr/bin/env python3
"""
Generate HTML comparison page from benchmark results.

Usage:
    generate_comparison.py <results.json> [--template <template.html>] [--output <output.html>]
"""

import json
import sys
from pathlib import Path

def generate(results_path, template_path=None, output_path=None):
    results_path = Path(results_path)
    results = json.loads(results_path.read_text())

    if template_path is None:
        template_path = Path(__file__).parent.parent / "assets" / "comparison-template.html"
    else:
        template_path = Path(template_path)

    template = template_path.read_text()

    if output_path is None:
        output_path = Path("/tmp/skill-benchmark-results.html")
    else:
        output_path = Path(output_path)

    html = template.replace("{{SKILL_NAME}}", results.get("skill_name", "Unknown"))
    html = html.replace("{{METRICS_JSON}}", json.dumps(results.get("metrics", {})))
    html = html.replace("{{TEST_RESULTS_JSON}}", json.dumps(results.get("tests", [])))

    output_path.write_text(html)
    print(f"Generated: {output_path}")
    return str(output_path)

def main():
    if len(sys.argv) < 2:
        print("Usage: generate_comparison.py <results.json> [--template <path>] [--output <path>]")
        sys.exit(1)

    results_path = sys.argv[1]
    template_path = None
    output_path = None

    args = sys.argv[2:]
    i = 0
    while i < len(args):
        if args[i] == "--template" and i + 1 < len(args):
            template_path = args[i + 1]
            i += 2
        elif args[i] == "--output" and i + 1 < len(args):
            output_path = args[i + 1]
            i += 2
        else:
            i += 1

    generate(results_path, template_path, output_path)

if __name__ == "__main__":
    main()
