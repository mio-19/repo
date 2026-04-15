#!/usr/bin/env python3
import re
import subprocess
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


def run_nurl(url, rev):
    cmd = [
        "nurl",
        "--fetcher=fetchgit",
        "--arg", "leaveDotGit", "true",
        "--arg", "fetchSubmodules", "true",
        url,
        rev,
    ]
    try:
        return subprocess.check_output(cmd, text=True).strip()
    except subprocess.CalledProcessError:
        return None


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    exprs = []

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
            if not (ref_match and url_match):
                continue

            expr = run_nurl(url_match.group(0), ref_match.group(1))
            if expr:
                exprs.append(f"({expr})")

    print("[")
    for expr in exprs:
        print(f"  {expr}")
    print("]")


if __name__ == "__main__":
    main()