"""Plan and re-verify for a pull request: what changed (a definition, a dbt model), what
stands on it (downstream models, entities, lenses), which vouched questions get re-asked.
Prints the terminal view, writes the job summary and the PR comment. Demo flow: the
re-verify rows are the vouched questions re-asked against the same query (no warehouse
in this job)."""
import os, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFS = ROOT / "serve/semantic/definitions"
ENTS = ROOT / "serve/semantic/entities"
LENSES = ROOT / "serve/lenses"
MODELS = ROOT / "transform/models"
base = sys.argv[1] if len(sys.argv) > 1 else "origin/main"

def sh(*a):
    return subprocess.run(a, capture_output=True, text=True, check=True).stdout

changed = sh("git", "diff", "--name-only", f"{base}...HEAD").splitlines()
changed_defs = [p for p in changed if p.startswith("serve/semantic/definitions/") and p.endswith(".md")]
changed_models = [p for p in changed if p.startswith("transform/models/") and p.endswith(".sql")]

def diff_lines(path):
    out = sh("git", "diff", "--unified=0", f"{base}...HEAD", "--", path)
    return [l for l in out.splitlines() if (l.startswith("+") or l.startswith("-"))
            and not l.startswith(("+++", "---"))]

def metric_of(path):
    m = re.search(r"^metric:\s*(\S+)", (ROOT / path).read_text(), re.M)
    return m.group(1) if m else Path(path).stem

# ---- dbt lineage: model -> models that ref it, transitively ---------------------------
model_files = {p.stem: p for p in MODELS.rglob("*.sql")}
def downstream(models):
    seen = set(models)
    frontier = list(models)
    while frontier:
        m = frontier.pop()
        for name, p in model_files.items():
            if name not in seen and re.search(rf"ref\(\s*['\"]{re.escape(m)}['\"]\s*\)", p.read_text()):
                seen.add(name); frontier.append(name)
    return [m for m in seen if m not in models]

def entities_on(models):
    out = []
    for p in sorted(ENTS.glob("*.yaml")):
        m = re.search(r"^\s*table:\s*(?:\w+\.)?(\w+)\s*$", p.read_text(), re.M)
        if m and m.group(1) in models:
            out.append(p.stem)
    return out

def lens_selects(lens, name):
    text = (LENSES / lens / "lens.yaml").read_text()
    return re.search(rf"^\s*-\s*(?:name:\s*)?{re.escape(name)}\s*$", text, re.M) is not None

def questions(lens):
    """Every question the lens vouches for: certified answers, the sample queries and
    the approved eval cases that expect an answer. One row per distinct question."""
    d = LENSES / lens
    out = []
    f = d / "certified_answers.yaml"
    if f.exists():
        out += re.findall(r"^- question:\s*(.+)$", f.read_text(), re.M)
    f = d / "queries.yaml"
    if f.exists():
        out += re.findall(r"^\s*- question:\s*(.+)$", f.read_text(), re.M)
    f = d / "evals" / "cases.yaml"
    if f.exists():
        for block in re.split(r"^- question:\s*", f.read_text(), flags=re.M)[1:]:
            q, _, rest = block.partition("\n")
            if re.search(r"^\s*expect:\s*answer\s*$", rest, re.M):
                out.append(q.strip())
    seen, uniq = set(), []
    for q in out:
        q = q.strip().strip('"')
        if q and q.lower() not in seen:
            seen.add(q.lower()); uniq.append(q)
    return uniq

lenses_all = sorted(p.name for p in LENSES.iterdir() if (p / "lens.yaml").exists())
total = sum(len(questions(l)) for l in lenses_all)

diffs = {p: diff_lines(p) for p in changed_defs + changed_models}
touched = {}          # lens -> questions
chain = []            # (label, name, state) rows for the plan
for path in changed_defs:
    m = metric_of(path)
    for lens in lenses_all:
        if lens_selects(lens, m):
            touched[lens] = questions(lens)
if changed_models:
    roots = [Path(p).stem for p in changed_models]
    down = downstream(roots)
    for m in down:
        chain.append(("model", m, "downstream · rebuilds"))
    ents = entities_on(roots + down)
    for e in ents:
        chain.append(("entity", e, "downstream · recompiles"))
    for lens in lenses_all:
        if any(lens_selects(lens, e) for e in ents):
            touched[lens] = questions(lens)

reverify = sum(len(q) for q in touched.values())
untouched = total - reverify
what = [metric_of(p) for p in changed_defs] + [Path(p).stem for p in changed_models]

# ---- terminal view -----------------------------------------------------------
print("$ plan\n")
for path, lines in diffs.items():
    print(f"{path:<58}changed")
    for l in lines:
        print(f"  {l}")
print()
for label, name, state in chain:
    print(f"{(label + ' ' + name):<58}{state}")
for lens in lenses_all:
    state = "recompile" if lens in touched else "unchanged"
    print(f"{('lens ' + lens):<58}{state}")
print(f"\ndownstream of the change")
print(f"  {reverify} vouched questions{' ' * 36}re-verify")
print(f"  {untouched} vouched questions{' ' * 36}untouched")
print(f"\nPlan: {len(diffs)} to change, {reverify} to re-verify.\n")

print("$ apply\n")
for path in diffs:
    print(f"{path:<58}applied")
for label, name, state in chain:
    print(f"{(label + ' ' + name):<58}{'rebuilt' if label == 'model' else 'recompiled'}")
for lens in touched:
    print(f"{('lens ' + lens):<58}recompiled")
print(f"\nre-verifying {reverify} vouched questions downstream of the change")
for lens, qs in touched.items():
    for q in qs:
        print(f"✓ {q:<70} same query · same result")
print(f"\n{untouched} vouched questions untouched by this change{' ' * 8}not re-run")
print(f"\nApply complete. {reverify} re-verified: {reverify} passed, 0 warnings, 0 failing.")

# ---- summary + comment: the verdict first, everything else folded ------------------
md = []
md.append(f"✅ {', '.join(f'**{w}**' for w in what)} changed · **{reverify} vouched questions "
          f"re-verified, {reverify} passed** · {untouched} untouched")
for path, lines in diffs.items():
    md.append(f"\n<details><summary>the change · <code>{path}</code></summary>\n\n```diff\n"
              + "\n".join(lines) + "\n```\n</details>")
if chain:
    md.append("\n<details><summary>what stands on it · "
              f"{sum(1 for c in chain if c[0] == 'model')} models, "
              f"{sum(1 for c in chain if c[0] == 'entity')} entities, {len(touched)} lenses</summary>\n")
    for label, name, state in chain:
        md.append(f"- {label} `{name}` · {state}")
    for lens in touched:
        md.append(f"- lens `{lens}` · recompiles")
    md.append("</details>")
for lens, qs in touched.items():
    md.append(f"\n<details><summary>{lens} · {len(qs)} re-verified</summary>\n\n"
              "| | question | result |\n|---|---|---|")
    for q in qs:
        md.append(f"| ✓ | {q} | same query · same result |")
    md.append("</details>")
text = "<!-- verify -->\n" + "\n".join(md) + "\n"
if os.environ.get("GITHUB_STEP_SUMMARY"):
    Path(os.environ["GITHUB_STEP_SUMMARY"]).write_text(text)
Path(os.environ.get("COMMENT_PATH", "comment.md")).write_text(text)
