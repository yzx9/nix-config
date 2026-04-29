import os
import subprocess
import time


def draw_title(data: dict) -> str:
    dir_name = get_dir_name(data)
    if dir_name:
        fmt = data.get("fmt", {})
        return f"{fmt.bold}[{dir_name}]{fmt.nobold} "

    return ""


# -------------------------------------
# Current working directory
# -------------------------------------


def get_dir_name(data: dict) -> str | None:
    tab = data.get("tab", {})
    exe = os.path.basename(tab.active_exe or "")
    if exe in ["ssh", "s"]:
        return None  # show nothing for ssh sessions

    cwd = get_cwd(data)
    return git_git_root(cwd)


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
    if not path:
        return None

    now = time.monotonic()
    if path in _cache:
        result, ts = _cache[path]
        if now - ts < _CACHE_TTL:
            return result
        del _cache[path]

    # if is the home directory, return ~
    if path == os.path.expanduser("~"):
        return _put(path, "~", now)

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
                        return _put(
                            path,
                            f"{os.path.basename(main_root)}/{os.path.basename(root)}",
                            now,
                        )
                return _put(path, os.path.basename(root), now)
    except Exception:
        pass

    # if starts with home directory, replace it with ~
    if path.startswith(os.path.expanduser("~")):
        return _put(path, "~" + path[len(os.path.expanduser("~")) :], now)

    return _put(path, path, now)


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
