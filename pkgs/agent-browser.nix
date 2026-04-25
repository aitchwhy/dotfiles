# agent-browser - Vercel AI browser automation CLI
# https://github.com/vercel-labs/agent-browser
#
# NOTE: agent-browser bundles its own Playwright version which may not match
# nixpkgs playwright-driver.browsers. We let agent-browser manage its own
# browsers via `agent-browser install` for version compatibility.
#
# The wrapper uses bunx per the dotfiles runtime convention (bun for
# tooling wrappers, pnpm + Node.js 25 for application code).
#
# Version is pinned to mitigate npm supply-chain attacks (e.g., the
# 2026-04-22 @bitwarden/cli compromise via Checkmarx-style attack on a
# vendor's GitHub Actions release pipeline). Bump deliberately after
# reviewing release notes.
{
  lib,
  writeShellScriptBin,
  bun,
}:

let
  version = "0.26.0";
in
writeShellScriptBin "agent-browser" ''
  export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
  exec ${bun}/bin/bunx agent-browser@${version} "$@"
''
// {
  inherit version;
  meta = with lib; {
    description = "AI browser automation CLI for Playwright-based testing";
    homepage = "https://github.com/vercel-labs/agent-browser";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "agent-browser";
  };
}
