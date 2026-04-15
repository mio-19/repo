#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path


def extract_block(text, start):
    i = start
    depth = 0
    while i < len(text):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
        i += 1
    return None


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    results = []

    for path in root.rglob("CMakeLists.txt"):
        try:
            text = path.read_text(errors="ignore")
        except Exception:
            continue

        for m in re.finditer(r"\bexternal_project\s*\(", text, re.IGNORECASE):
            open_paren = text.find("(", m.start())
            if open_paren == -1:
                continue

            block = extract_block(text, open_paren)
            if not block:
                continue

            ref_match = re.search(r"\bDOWNLOAD\s+GIT\s+([^\s)]+)", block, re.IGNORECASE)
            url_match = re.search(r"\bhttps?://[^\s)]+", block, re.IGNORECASE)

            if ref_match and url_match:
                results.append(
                    {
                        "file": str(path),
                        "ref": ref_match.group(1),
                        "url": url_match.group(0),
                        "hash": "",
                    }
                )

    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()