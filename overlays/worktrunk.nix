final: prev:

# worktrunk's `shell::utils` tests probe the live process table — on macOS that
# means libproc (`proc_listallpids` / `proc_pidinfo`). Inside the Nix darwin
# sandbox (unprivileged `nixbld` user, and especially under macOS 26 / Darwin
# 25, which tightened process introspection), those calls are denied. The build
# process can't even read its own pid from the table, so two tests panic:
#
#   shell::utils::tests::test_process_name_and_ppid_self
#     ("own pid must be readable from the process table")
#   shell::utils::tests::test_probe_reports_invoked_name_for_sh
#     ("child sh must be visible to the probe")
#
# These tests pass upstream (CI runs outside the sandbox); skip just them on
# darwin so the rest of the suite still runs. Drop this overlay if worktrunk
# ever marks these tests `#[cfg(not(target_os = "macos"))]` / `#[ignore]`.
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  worktrunk = prev.worktrunk.overrideAttrs (old: {
    checkFlags = (old.checkFlags or [ ]) ++ [
      "--skip=shell::utils::tests::test_process_name_and_ppid_self"
      "--skip=shell::utils::tests::test_probe_reports_invoked_name_for_sh"
    ];
  });
}
