import os
import subprocess
import time

from kitty.fast_data_types import get_boss


def draw_title(data: dict) -> str:
    dir_name = get_dir_name(data)
    if dir_name:
        fmt = data.get("fmt", {})
        return f"{fmt.bold}[{dir_name}]{fmt.nobold} "

    return ""


def get_dir_name(data: dict) -> str | None:
    ta = data.get("tab")
    if not ta:
        return None

    exe = os.path.basename(ta.active_exe or "")
    if exe in ["ssh", "s"]:
        return get_ssh_target(ta)

    cwd = get_cwd(data)
    if not cwd:
        return None

    now = time.monotonic()
    if cwd in _cache:
        result, ts = _cache[cwd]
        if now - ts < _CACHE_TTL:
            return result
        del _cache[cwd]

    # if is the home directory, return ~
    if cwd == os.path.expanduser("~"):
        return _put(cwd, "~", now)

    # if is a git managed directory, show the git root name instead of the full path
    git_root = git_git_root(cwd)
    if git_root is not None:
        return _put(cwd, git_root, now)

    # if starts with home directory, replace it with ~
    if cwd.startswith(os.path.expanduser("~")):
        return _put(cwd, "~" + cwd[len(os.path.expanduser("~")) :], now)

    path = os.path.basename(cwd) or cwd  # show full path if it's root
    return _put(cwd, path, now)


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
# Current working directory
# -------------------------------------


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


def git_git_root(path: str) -> str | None:
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

        # Check if we're in a worktree by comparing common git dir
        common_result = subprocess.run(
            ["git", "-C", path, "rev-parse", "--git-common-dir"],
            capture_output=True,
            text=True,
            timeout=0.2,
            check=False,
        )
        if common_result.returncode == 0:
            common_dir = common_result.stdout.strip()
            if not os.path.isabs(common_dir):
                common_dir = os.path.normpath(os.path.join(root, common_dir))
            main_root = os.path.dirname(common_dir)
            if main_root != root:
                # In a worktree: show main repo name + worktree dir name
                return f"{os.path.basename(main_root)}/{os.path.basename(root)}"

        return os.path.basename(root)

    except Exception:
        return None


# -------------------------------------
# Git cache
# -------------------------------------

_cache: dict[str, tuple[str, float]] = {}
_CACHE_TTL = 3600  # 1 hour
_CACHE_MAX = 32


def _evict(now: float) -> None:
    if len(_cache) <= _CACHE_MAX:
        return
    # drop expired first
    expired = [k for k, (_, ts) in _cache.items() if now - ts >= _CACHE_TTL]
    for k in expired:
        del _cache[k]
    # still too many? drop oldest
    if len(_cache) > _CACHE_MAX:
        oldest = sorted(_cache, key=lambda k: _cache[k][1])
        for k in oldest[: len(_cache) - _CACHE_MAX]:
            del _cache[k]


def _put(path: str, name: str, now: float) -> str:
    _cache[path] = (name, now)
    _evict(now)
    return name
