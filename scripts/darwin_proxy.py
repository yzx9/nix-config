"""Set proxy for nix-daemon to speed up downloads.

You can safely ignore this file if you don't need a proxy.


See Also
--------

https://github.com/NixOS/nix/issues/1472#issuecomment-1532955973
"""

import argparse
import os
import plistlib
import shlex
import subprocess
from pathlib import Path


class DarwinProxyManager:
    nix_daemon_name = "org.nixos.nix-daemon"

    # NOTE: curl only accept the lowercase of `http_proxy`!
    # NOTE: https://curl.se/libcurl/c/libcurl-env.html
    keys = ["http_proxy", "https_proxy"]

    def __init__(self, proxy: str) -> None:
        self.proxy = proxy
        self.nix_daemon_plist = Path(
            "/Library/LaunchDaemons/org.nixos.nix-daemon.plist"
        )
        self.plist = plistlib.loads(self.nix_daemon_plist.read_bytes())

    def set_proxy(self):
        # set http/https proxy
        for k in self.keys:
            self.plist["EnvironmentVariables"][k] = self.proxy

        self._update_plist()
        self._reload_daemon()

    def unset_proxy(self):
        # remove http proxy
        for k in self.keys:
            self.plist["EnvironmentVariables"].pop(k, None)

        self._update_plist()
        self._reload_daemon()

    def auto_switch_proxy(self):
        for k in self.keys:
            if k not in self.plist["EnvironmentVariables"]:
                has_proxy = False
                break
        else:
            has_proxy = True

        print(f"Auto switch to {'unset' if has_proxy else 'set'} proxy")
        if has_proxy:
            self.unset_proxy()
        else:
            self.set_proxy()

    def _update_plist(self):
        os.chmod(self.nix_daemon_plist, 0o644)
        self.nix_daemon_plist.write_bytes(plistlib.dumps(self.plist))
        os.chmod(self.nix_daemon_plist, 0o444)

    def _reload_daemon(self):
        # reload the plist
        for cmd in (
            f"launchctl unload {self.nix_daemon_plist}",
            f"launchctl load {self.nix_daemon_plist}",
        ):
            print(cmd)
            subprocess.run(shlex.split(cmd), capture_output=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser("Set proxy for nix-daemon to speed up downloads.")
    parser.add_argument(
        "mode", type=str, choices=["set", "unset", "auto_switch"], default="auto_switch"
    )
    parser.add_argument("proxy", type=str, default="")

    args = parser.parse_args()
    pm = DarwinProxyManager(args.proxy)
    match args.mode:
        case "set":
            pm.set_proxy()
        case "unset":
            pm.unset_proxy()
        case "auto_switch":
            pm.auto_switch_proxy()
        case _, _:
            raise ValueError("Invalid arguments")
