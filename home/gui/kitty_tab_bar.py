import os
import subprocess
import time
from collections import OrderedDict
from functools import wraps
from typing import Callable

from kitty.fast_data_types import get_boss

# -------------------------------------
# SSH
# -------------------------------------


def get_ssh_target(ta) -> str | None:
    try:
        tab = get_boss().tab_for_id(ta.tab_id)
        if not tab or not tab.active_window:
            return None
        cmdline = tab.active_window.child.foreground_cmdline
    except Exception:
        return None

    if not cmdline or os.path.basename(cmdline[0]) not in ("ssh", "s"):
        return None

    target = None
    args = cmdline[1:]
    # find "--" separator: everything after it is [user@]hostname [command]
    try:
        sep_idx = args.index("--")
        target = args[sep_idx + 1] if sep_idx + 1 < len(args) else None
    except ValueError:
        pass

    # fallback: skip flags, last non-flag argument is the hostname
    if target is None:
        i = 0
        while i < len(args):
            if args[i].startswith("-"):
                if args[i] in ("-p", "-i", "-l", "-F", "-J", "-o", "-S", "-W", "-w"):
                    i += 2
                    continue
                i += 1
                continue
            target = args[i]
            i += 1

    if target is None:
        return None

    # strip common ssh config prefixes that some users use to group hosts, e.g. "yzx9-" or "cvcd-"
    for prefix in ["yzx9-", "cvcd-"]:
        if target.startswith(prefix):
            target = target[len(prefix) :]
            break

    return target


# -------------------------------------
# Git
# -------------------------------------


def get_git_root(path: str, *, max_length: int) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", path, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            timeout=0.2,
            check=False,
        )
        if result.returncode != 0:
            return None

        root = result.stdout.strip()
        if not root:
            return None

        # Check if we're in a worktree
        worktree_root = get_git_worktree_root(path, root, max_length=max_length)
        if worktree_root is not None:
            return worktree_root

        name = os.path.basename(root)
        if len(name) > max_length:
            name = name[: max_length - 3] + "..."

        return name

    except Exception:
        return None


def get_git_worktree_root(path: str, root: str, *, max_length: int) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", path, "rev-parse", "--git-common-dir"],
            capture_output=True,
            text=True,
            timeout=0.2,
            check=False,
        )
        if result.returncode != 0:
            return None

        common_dir = result.stdout.strip()
        if not os.path.isabs(common_dir):
            common_dir = os.path.normpath(os.path.join(root, common_dir))

        main_root = os.path.dirname(common_dir)
        if main_root == root:
            return None

        main_repo_name = os.path.basename(main_root)
        root_name = os.path.basename(root)
        if root_name.startswith(main_repo_name):
            return root_name  # show worktree name only if it starts with main repo name

        # In a worktree: show main repo name + worktree dir name
        if len(main_repo_name) + len(root_name) > max_length - 1:  # -1 for the slash
            if len(root_name) > 10:
                root_name = root_name[:7] + "..."

            if len(main_repo_name) + len(root_name) > max_length - 1:
                main_repo_name = main_repo_name[:5]

        return f"{main_repo_name}/{root_name}"

    except Exception:
        return None


# -------------------------------------
# Cache
# -------------------------------------


def ttl_cache(maxsize: int, ttl: float):
    def decorator(func: Callable[[str], str]) -> Callable[[str], str]:
        cache: OrderedDict[str, tuple[str, float]] = OrderedDict()

        @wraps(func)
        def wrapper(path: str) -> str:
            now = time.monotonic()

            if path in cache:
                value, ts = cache[path]
                if now - ts < ttl:
                    cache.move_to_end(path)
                    return value
                del cache[path]

            value = func(path)
            cache[path] = (value, now)
            cache.move_to_end(path)

            # drop expired first
            expired = [k for k, (_, ts) in cache.items() if now - ts >= ttl]
            for k in expired:
                del cache[k]

            # still too many? drop oldest
            while len(cache) > maxsize:
                cache.popitem(last=False)

            return value

        return wrapper

    return decorator


# -------------------------------------
# Main
# -------------------------------------


def get_dir_name(data: dict) -> str | None:
    tab = data.get("tab")
    if not tab:
        return None

    exe = os.path.basename(tab.active_exe or "")
    if exe in {"ssh", "s"}:
        return get_ssh_target(tab)

    tab = data.get("tab", {})
    cwd = tab.active_wd or ""
    if not cwd:
        return None

    return _dir_name_from_cwd(cwd)


@ttl_cache(
    maxsize=32,
    ttl=3600,  # 1hours
)
def _dir_name_from_cwd(cwd: str) -> str:
    home = os.path.expanduser("~")

    # if is the home directory, return ~
    if cwd == home:
        return "~"

    # if is a git managed directory, show the git root name instead of the full path
    git_root = get_git_root(cwd, max_length=15)
    if git_root is not None:
        return git_root

    # if starts with home directory, replace it with ~
    if cwd.startswith(home):
        return "~" + cwd[len(home) :]

    # show full path if it's root
    return os.path.basename(cwd) or cwd


def draw_title(data: dict) -> str:
    dir_name = get_dir_name(data)
    if dir_name:
        fmt = data.get("fmt", {})
        return f"{fmt.bold}[{dir_name}]{fmt.nobold} "

    return ""
