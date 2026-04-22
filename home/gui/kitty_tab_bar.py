import os
import subprocess
from functools import lru_cache


@lru_cache(32)
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


def get_cwd(data: dict) -> str:
    # Fastpath: use the last reported cwd from the window, which is updated by
    # the shell integration and should be more responsive than querying the
    # tab's active_wd
    window = data.get("window", {})
    cwd = window.get("screen", {}).get("last_reported_cwd")
    if cwd:
        return cwd

    # Fallback
    tab = data.get("tab", {})
    cwd = tab.active_wd or ""
    return cwd


def draw_title(data: dict) -> str:
    tab = data.get("tab", {})
    exe = os.path.basename(tab.active_exe or "")
    if exe == "ssh":
        return ""  # show nothing for ssh sessions

    cwd = get_cwd(data)
    dir_part = git_dir_name(cwd)
    if dir_part:
        fmt = data.get("fmt", {})
        return f"{fmt.bold}[{dir_part}]{fmt.nobold} "

    return ""
