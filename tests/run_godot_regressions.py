"""Run the real demo and regression autoload in a disposable project copy."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
HARNESS = "demo_regressions.gd"
SUCCESS = "TIDEWRACK_GODOT_REGRESSIONS_OK"


def replace_once(path, old, new):
    text = path.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise SystemExit(f"Cannot safely configure temporary copy of {path.name}")
    path.write_text(text.replace(old, new), encoding="utf-8")


def engine(command, env):
    result = subprocess.run(command, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, timeout=90)
    print(result.stdout, end="")
    if result.returncode or "SCRIPT ERROR:" in result.stdout:
        raise SystemExit(result.returncode or 1)
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot", help="Godot 4.3+ executable")
    binary = shutil.which(parser.parse_args().godot)
    if not binary:
        raise SystemExit("Godot executable unavailable; no engine tests ran.")
    with tempfile.TemporaryDirectory(prefix="tidewrack-regression-") as temp:
        scratch = Path(temp).resolve()
        project = scratch / "project"
        project.mkdir()
        for directory in ("assets", "data", "scenes", "scripts"):
            shutil.copytree(ROOT / directory, project / directory)
        for name in ("project.godot", "icon.svg"):
            shutil.copy2(ROOT / name, project / name)
        slot = scratch / "save.json"
        replace_once(project / "scripts/autoload/game_state.gd",
                     'const SAVE_PATH := "user://save.json"',
                     "const SAVE_PATH := " + json.dumps(slot.as_posix(), ensure_ascii=False))
        # A distinct user-data namespace also isolates engine logs/settings.
        replace_once(project / "project.godot", 'config/name="Tidewrack"',
                     f'config/name="{scratch.name}"')
        replace_once(project / "project.godot", 'Journal="*res://scripts/journal.gd"',
                     'Journal="*res://scripts/journal.gd"\nRegression="*res://' + HARNESS + '"')
        shutil.copy2(ROOT / "tests" / HARNESS, project / HARNESS)
        env = dict(os.environ, TIDEWRACK_REGRESSION_SLOT=slot.as_posix())
        command = [binary, "--headless", "--path", str(project)]
        engine(command + ["--import"], env)
        output = engine(command + ["--fixed-fps", "60"], env)
        if SUCCESS not in output.splitlines():
            raise SystemExit("Engine exited without the regression suite's success marker.")


if __name__ == "__main__":
    main()
