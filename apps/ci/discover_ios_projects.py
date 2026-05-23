#!/usr/bin/env python3
import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPS_DIR = ROOT / "apps"

SHARED_PATH_PREFIXES = [
    "shared/",
    "packages/",
    "ci/",
    "fastlane/",
    "Gemfile",
    "Gemfile.lock",
    ".github/workflows/ios-monorepo-build.yml",
]

REQUIRED_KEYS = [
    "id",
    "project_path",
    "scheme",
    "configuration",
    "export_method",
    "bundle_id",
]


def run(cmd):
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def load_projects():
    projects = []

    for config_path in sorted(APPS_DIR.glob("*/ci/ios.json")):
        with open(config_path, "r", encoding="utf-8") as file:
            config = json.load(file)

        missing = [key for key in REQUIRED_KEYS if not config.get(key)]
        if missing:
            raise RuntimeError(f"{config_path} missing required keys: {missing}")

        config["config_path"] = str(config_path.relative_to(ROOT)).replace("\\", "/")
        config["app_root"] = str(config_path.parents[1].relative_to(ROOT)).replace("\\", "/")
        projects.append(config)

    return projects


def get_changed_files():
    base_sha = os.environ.get("BASE_SHA", "").strip()
    head_sha = os.environ.get("HEAD_SHA", "").strip()

    if not base_sha or not head_sha:
        return None

    if set(base_sha) == {"0"}:
        return None

    try:
        output = run(["git", "diff", "--name-only", base_sha, head_sha])
        return [line.strip() for line in output.splitlines() if line.strip()]
    except Exception:
        return None


def has_shared_change(changed_files):
    if changed_files is None:
        return True

    for file in changed_files:
        for prefix in SHARED_PATH_PREFIXES:
            if file == prefix or file.startswith(prefix):
                return True

    return False


def project_changed(project, changed_files):
    if changed_files is None:
        return True

    app_root = project["app_root"].rstrip("/") + "/"
    project_path = project["project_path"].rstrip("/") + "/"

    return any(file.startswith(app_root) or file.startswith(project_path) for file in changed_files)


def select_projects(projects):
    event_name = os.environ.get("EVENT_NAME", "")
    ref_name = os.environ.get("REF_NAME", "")
    manual_project = os.environ.get("MANUAL_PROJECT", "").strip()

    if event_name == "workflow_dispatch":
        if manual_project and manual_project != "all":
            return [project for project in projects if project["id"] == manual_project]
        return projects

    if ref_name.startswith("ios/"):
        parts = ref_name.split("/")
        if len(parts) >= 3:
            project_id = parts[1]
            return [project for project in projects if project["id"] == project_id]

    changed_files = get_changed_files()

    if has_shared_change(changed_files):
        return projects

    return [project for project in projects if project_changed(project, changed_files)]


def main():
    projects = load_projects()
    selected = select_projects(projects)

    matrix = {"include": selected}

    print(json.dumps(matrix, ensure_ascii=False, indent=2))

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as file:
            file.write(f"matrix={json.dumps(matrix, ensure_ascii=False)}\n")
            file.write(f"count={len(selected)}\n")


if __name__ == "__main__":
    main()
