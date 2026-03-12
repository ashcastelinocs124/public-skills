#!/usr/bin/env python3
"""
Open an HTML file in the default browser.

Usage:
    open_viewer.py <path-to-html>
"""

import subprocess
import sys
import platform
from pathlib import Path

def open_in_browser(html_path):
    html_path = Path(html_path).resolve()
    if not html_path.exists():
        print(f"File not found: {html_path}")
        return False

    system = platform.system()
    if system == "Darwin":
        subprocess.run(["open", str(html_path)])
    elif system == "Linux":
        subprocess.run(["xdg-open", str(html_path)])
    elif system == "Windows":
        subprocess.run(["start", str(html_path)], shell=True)
    else:
        print(f"Unsupported platform: {system}")
        return False

    print(f"Opened in browser: {html_path}")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: open_viewer.py <path-to-html>")
        sys.exit(1)
    success = open_in_browser(sys.argv[1])
    sys.exit(0 if success else 1)
