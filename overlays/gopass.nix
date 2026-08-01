final: prev:

let
  # Patches against the age backend in the gopass *library* (gopasspw/gopass).
  # Applied to both consumers below: the `gopass` binary and `gopass-jsonapi`,
  # which vendors the same library under vendor/github.com/gopasspw/gopass.

  # gopasspw/gopass#3488 — "fix(age): recover agent on missing identities, not
  # only when locked". Merged to master 2026-07-07 but not in a release, so
  # nixpkgs' v1.16.1 tag doesn't have it yet.
  #
  # home/gopass.nix starts the age agent up front under launchd. That agent is
  # reachable but holds no identities, so decryptWithAgent's self-heal path —
  # which fired only on "agent is locked" — never triggered. Age.Decrypt then
  # silently fell back to direct decryption on every call, leaving the agent
  # empty and unused for its whole lifetime. #3488 makes "no identities
  # specified" trigger the same unlock + send-identities + retry recovery.
  #
  # #3488 also adds a regression test (decrypt_agent_test.go) whose helpers
  # (newTestAge, addIdentity) don't exist on v1.16.1. gopass sets no doCheck, so
  # test files are never compiled and it would be dead source here — drop it.
  pr3488 = final.fetchpatch {
    url = "https://github.com/gopasspw/gopass/commit/af0279e4980d95c2bc271e90d654ddaa0a9e69b5.patch";
    hash = "sha256-3uIdyqGQ47Gj4B50Icp296RGkEDvWJlx1hvbY9Ld8Tc=";
    excludes = [ "internal/backend/crypto/age/decrypt_agent_test.go" ];
  };

  # gopasspw/gopass#3509 — "fix(age): send agent identities space-separated on a
  # single line". The client serialized identities newline-separated, but the age
  # agent's line-oriented parser reads only the first line, so every identity
  # after the first was discarded — the agent loaded at most one identity, and
  # Go's randomized map order made this non-deterministic (the browser extension
  # and CLI appeared to behave differently).
  #
  # Vendored (not fetchpatch) because the upstream commit doesn't apply to
  # v1.16.1 cleanly: it also touches commands.go and three _test.go files whose
  # context/helpers don't exist on this tag, and its identityToString switch
  # adds `case *age.HybridIdentity` and `case *plugin.Identity` — both absent
  # from the filippo.io/age v1.2.1 that v1.16.1 vendors (HybridIdentity arrived
  # in age v1.3.x; plugin.Identity has no String() method yet). Both cases are
  # dropped here; the production hunks otherwise match the PR byte-for-byte.
  pr3509 = ./gopass/pr3509.patch;

  # NOTE: gopasspw/gopass#3510 (agent-start fork-bomb guard) is intentionally
  # not applied: it can't be fetchpatch'd cleanly onto v1.16.1, and the
  # launchd-supervised age agent in home/gopass.nix keeps the agent running, so
  # tryStartAgent's Ping() succeeds and the auto-spawn path that fork-bombs
  # never fires.
in
{
  gopass = prev.gopass.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      pr3488
      pr3509
    ];
  });

  # gopass-jsonapi is a separate repo (gopasspw/gopass-jsonapi) that pulls the
  # gopass library in as a vendored module dependency — gopass v1.16.1 + age
  # v1.2.1, identical to the `gopass` package above. Its own source doesn't
  # contain the age backend, so apply the same fixes to the vendored copy.
  # buildGoModule populates vendor/ during configurePhase, so patch it in
  # postConfigure; `pushd` lets the same -p1 patches resolve there.
  gopass-jsonapi = prev.gopass-jsonapi.overrideAttrs (old: {
    postConfigure = (old.postConfigure or "") + ''
      pushd vendor/github.com/gopasspw/gopass >/dev/null
      chmod -R u+w .
      patch -p1 < ${pr3488}
      patch -p1 < ${pr3509}
      popd >/dev/null
    '';
  });
}
