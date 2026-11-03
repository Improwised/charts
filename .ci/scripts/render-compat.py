#!/usr/bin/env python3
"""Render-compatibility gate for a chart.

Renders every values file in <chart>/ci/compat/values/ with the chart as it is on the base ref (the last
released version on the default branch) and with the chart in the working tree, then compares the rendered
Kubernetes objects. Any difference fails the check unless <chart>/ci/compat/allowed-changes.yaml lists it
under the base chart's version, so an intentional change has to be declared in the PR that makes it.
Entries keyed by an older version stop applying once that version is no longer the base.

The helm.sh/chart label value is normalised because it changes on every version bump.

Usage: render-compat.py <chart-dir> [base-ref]     (base-ref defaults to origin/main)
Needs: helm, git, PyYAML.
"""
import io
import json
import os
import re
import subprocess
import sys
import tarfile
import tempfile

import yaml


def run(*args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def base_chart(chart_dir, ref, dest):
    """Extract <chart_dir> at <ref> into dest; return its path, or None if the chart is new."""
    archive = subprocess.run(["git", "archive", ref, "--", chart_dir], capture_output=True)
    if archive.returncode != 0:
        return None
    with tarfile.open(fileobj=io.BytesIO(archive.stdout)) as tar:
        tar.extractall(dest, filter="data")
    path = os.path.join(dest, chart_dir)
    return path if os.path.isfile(os.path.join(path, "Chart.yaml")) else None


def render(chart, values):
    r = run("helm", "template", "compat", chart, "--namespace", "compat", "-f", values)
    if r.returncode != 0:
        return None, r.stderr.strip().splitlines()[-1] if r.stderr.strip() else "render failed"
    objs = {}
    for doc in yaml.safe_load_all(r.stdout):
        if doc:
            text = re.sub(r'"helm\.sh/chart": "[^"]*"', '"helm.sh/chart": "<chart>"', json.dumps(doc))
            obj = json.loads(text)
            objs[f"{obj['kind']}/{obj['metadata']['name']}"] = obj
    return objs, None


def diff_paths(a, b, path=""):
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            yield from diff_paths(a.get(k, "<absent>"), b.get(k, "<absent>"), f"{path}.{k}")
    elif isinstance(a, list) and isinstance(b, list) and len(a) == len(b):
        for x, y in zip(a, b):
            yield from diff_paths(x, y, f"{path}[]")
    elif a != b:
        yield path, a, b


def main():
    chart_dir = sys.argv[1].rstrip("/")
    ref = sys.argv[2] if len(sys.argv) > 2 else "origin/main"
    compat = os.path.join(chart_dir, "ci", "compat")
    values_dir = os.path.join(compat, "values")
    if not os.path.isdir(values_dir):
        print(f"{chart_dir}: no ci/compat/values, skipping")
        return 0
    with tempfile.TemporaryDirectory() as tmp:
        base = base_chart(chart_dir, ref, tmp)
        if base is None:
            print(f"{chart_dir}: not present on {ref}, nothing to compare against")
            return 0
        base_version = str(yaml.safe_load(open(os.path.join(base, "Chart.yaml")))["version"])
        allowed_file = os.path.join(compat, "allowed-changes.yaml")
        allowed_all = (yaml.safe_load(open(allowed_file)) or {}) if os.path.exists(allowed_file) else {}
        allowed = [re.compile(e["path"]) for e in allowed_all.get(base_version, [])]
        print(f"{chart_dir}: comparing against {ref} (version {base_version}), {len(allowed)} allowed change pattern(s)")
        failures = 0
        for name in sorted(os.listdir(values_dir)):
            if not name.endswith((".yaml", ".yml")):
                continue
            values = os.path.join(values_dir, name)
            old, old_err = render(base, values)
            new, new_err = render(chart_dir, values)
            if new is None:
                print(f"  FAIL {name}: does not render: {new_err}")
                failures += 1
                continue
            if old is None:
                print(f"  ok   {name}: did not render on {base_version} ({old_err}); renders now")
                continue
            problems, accepted = [], 0
            for key in sorted(set(old) | set(new)):
                if key not in new or key not in old:
                    problems.append(f"{key}: {'removed' if key not in new else 'added'}")
                    continue
                for path, a, b in diff_paths(old[key], new[key]):
                    where = f"{key.split('/')[0]}{path}"
                    if any(p.search(where) for p in allowed):
                        accepted += 1
                    else:
                        problems.append(f"{key}{path}: {json.dumps(a)} -> {json.dumps(b)}")
            if problems:
                failures += 1
                print(f"  FAIL {name}: {len(problems)} undeclared change(s)")
                for p in problems[:20]:
                    print(f"         {p}")
            else:
                print(f"  ok   {name}" + (f" ({accepted} declared change(s))" if accepted else ""))
        if failures:
            print(f"{chart_dir}: {failures} values file(s) render differently. Fix the regression, or declare the "
                  f"change under \"{base_version}\" in ci/compat/allowed-changes.yaml with a reason.")
        return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
