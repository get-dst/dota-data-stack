"""`dst test --json` → job-summary markdown; exits 1 when the run proves less than it claims.

dst's exit 4 catches an empty org. It can't catch a lens that silently dropped out
(unpublished, renamed, its cases gone) while the others passed — so every lens
directory in the repo must show up with at least one case, and a zero exit must
agree with the rows.

usage: test_report.py <test.json> <lenses dir> <dst test exit code>
"""

import json
import sys
from collections import Counter
from pathlib import Path


def main(path: str, lenses_dir: str, rc: int) -> int:
    problems: list[str] = []
    try:
        data = json.loads(Path(path).read_text())
        rows = data["results"]
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"### dst test: unreadable result ({exc})\n\n`dst test` exit code {rc}.")
        return 1

    expected = sorted(p.parent.name for p in Path(lenses_dir).glob("*/lens.yaml"))
    ran: Counter[str] = Counter(r["lens"] for r in rows)
    passed: Counter[str] = Counter(r["lens"] for r in rows if r["verdict"] == "pass")
    failed = [r for r in rows if r["verdict"] != "pass"]

    if not expected:
        problems.append(f"no lenses found under {lenses_dir}")
    for lens in expected:
        if not ran[lens]:
            problems.append(f"lens `{lens}` ran no cases")
    if not rows:
        problems.append("the suite was empty")
    if rc == 0 and failed:
        problems.append("dst test exited 0 with failing rows")

    ok = rc == 0 and not problems
    verdict = "PASS" if ok else "FAIL"
    out = [
        f"### dst test: {verdict} — {data.get('passed')}/{data.get('total')} passed",
        "",
        f"certified {data.get('certified')} · behavioral {data.get('behavioral')}"
        f" · untyped answers {data.get('untyped_answers')}"
        f" · ungoverned passes {data.get('ungoverned_passes')} · exit {rc}",
        "",
        "| lens | passed | cases |",
        "|---|---:|---:|",
        *(f"| {x} | {passed[x]} | {ran[x]} |" for x in sorted(set(expected) | set(ran))),
    ]
    if failed:
        out += ["", "| lens | lane | question | reason |", "|---|---|---|---|"]
        for r in failed:
            reason = str(r.get("reason") or r["verdict"]).replace("|", "\\|").replace("\n", " ")
            out.append(f"| {r['lens']} | {r.get('lane') or 'rows'} | {r['question']} | {reason} |")
    if problems:
        out += ["", *(f"- **{p}**" for p in problems)]
    print("\n".join(out))
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2], int(sys.argv[3])))
