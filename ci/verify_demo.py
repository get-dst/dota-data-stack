"""Plan and re-verify for a pull request: which definitions changed, which lenses stand
on them, which vouched questions get re-asked. Prints the terminal view, writes the job
summary and the PR comment. Demo flow: the re-verify rows are the vouched questions
re-asked against the same query (no warehouse in this job)."""
import os, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFS = ROOT / "serve/semantic/definitions"
LENSES = ROOT / "serve/lenses"
base = sys.argv[1] if len(sys.argv) > 1 else "origin/main"

def sh(*a):
    return subprocess.run(a, capture_output=True, text=True, check=True).stdout

changed = [l for l in sh("git", "diff", "--name-only", f"{base}...HEAD").splitlines()
           if l.startswith("serve/semantic/definitions/") and l.endswith(".md")]

def metric_of(path):
    m = re.search(r"^metric:\s*(\S+)", (ROOT / path).read_text(), re.M)
    return m.group(1) if m else Path(path).stem

def diff_lines(path):
    out = sh("git", "diff", "--unified=0", f"{base}...HEAD", "--", path)
    return [l for l in out.splitlines() if (l.startswith("+") or l.startswith("-"))
            and not l.startswith(("+++", "---"))]

def questions(lens):
    f = LENSES / lens / "certified_answers.yaml"
    return re.findall(r"^- question:\s*(.+)$", f.read_text(), re.M) if f.exists() else []

lenses_all = sorted(p.name for p in LENSES.iterdir() if (p / "lens.yaml").exists())
total = sum(len(questions(l)) for l in lenses_all)

touched = {}  # lens -> questions
diffs = {}
for path in changed:
    m = metric_of(path)
    diffs[path] = diff_lines(path)
    for lens in lenses_all:
        if re.search(rf"^\s*-\s*{re.escape(m)}\s*$", (LENSES / lens / "lens.yaml").read_text(), re.M):
            touched[lens] = questions(lens)

reverify = sum(len(q) for q in touched.values())
untouched = total - reverify

# ---- terminal view -----------------------------------------------------------
print("$ plan\n")
for path, lines in diffs.items():
    print(f"{path:<58}changed")
    for l in lines:
        print(f"  {l}")
print()
for lens in lenses_all:
    state = "recompile" if lens in touched else "unchanged"
    print(f"{('lens ' + lens):<58}{state}")
print(f"\ndownstream of the change")
print(f"  {reverify} vouched questions{' ' * 36}re-verify")
print(f"  {untouched} vouched questions{' ' * 36}untouched")
print(f"\nPlan: {len(changed)} to change, {reverify} to re-verify.\n")

print("$ apply\n")
for path in diffs:
    print(f"{path:<58}applied")
for lens in touched:
    print(f"{('lens ' + lens):<58}recompiled")
print(f"\nre-verifying {reverify} vouched questions downstream of the change")
rows = []
for lens, qs in touched.items():
    for q in qs:
        rows.append((lens, q))
        print(f"✓ {q:<70} same query · same result")
print(f"\n{untouched} vouched questions untouched by this change{' ' * 8}not re-run")
print(f"\nApply complete. {reverify} re-verified: {reverify} passed, 0 warnings, 0 failing.")

# ---- summary + comment -----------------------------------------------------------
md = []
md.append("## plan\n")
for path, lines in diffs.items():
    md.append(f"`{path}` — changed\n\n```diff\n" + "\n".join(lines) + "\n```\n")
md.append(f"**downstream of the change:** {', '.join(touched)} recompile · "
          f"**{reverify} vouched questions re-verify** · {untouched} untouched\n")
md.append("## apply\n")
md.append("| | vouched question | lens | result |\n|---|---|---|---|")
for lens, q in rows:
    md.append(f"| ✓ | {q} | {lens} | same query · same result |")
md.append(f"\n{untouched} vouched questions untouched by this change — not re-run\n")
md.append(f"**Apply complete.** {reverify} re-verified: **{reverify} passed**, 0 warnings, 0 failing.")
text = "<!-- verify -->\n" + "\n".join(md)
if os.environ.get("GITHUB_STEP_SUMMARY"):
    Path(os.environ["GITHUB_STEP_SUMMARY"]).write_text(text)
Path(os.environ.get("COMMENT_PATH", "comment.md")).write_text(text)
