import os
import subprocess


def git_dir_name(path: str) -> str:
    if not path:
        return ""

    # if is the home directory, return ~
    if path == os.path.expanduser("~"):
        return "~"

    # if is a git managed directory, get the root name
    try:
        result = subprocess.run(
            ["git", "-C", path, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            timeout=0.2,
            check=False,
        )
        if result.returncode == 0:
            root = result.stdout.strip()
            if root:
                return os.path.basename(root)
    except Exception:
        pass

    # if starts with home directory, replace it with ~
    if path.startswith(os.path.expanduser("~")):
        return "~" + path[len(os.path.expanduser("~")) :]

    return path


def draw_title(data: dict) -> str:
    fmt = data.get("fmt", {})

    tab = data.get("tab", {})
    dir_part = git_dir_name(tab.active_wd or "")
    if dir_part:
        return f"{fmt.bold}[{dir_part}]{fmt.nobold} "
    else:
        return ""
