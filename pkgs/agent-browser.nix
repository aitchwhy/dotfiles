# agent-browser - Vercel AI browser automation CLI
# https://github.com/vercel-labs/agent-browser
#
# NOTE: agent-browser bundles its own Playwright version which may not match
# nixpkgs playwright-driver.browsers. We let agent-browser manage its own
# browsers via `agent-browser install` for version compatibility.
#
# The wrapper uses bunx per the dotfiles runtime convention (bun for
# tooling wrappers, pnpm + Node.js 25 for application code).
{
  lib,
  writeShellScriptBin,
  bun,
}:

writeShellScriptBin "agent-browser" ''
  export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
  exec ${bun}/bin/bunx agent-browser@latest "$@"
''
// {
  meta = with lib; {
    description = "AI browser automation CLI for Playwright-based testing";
    homepage = "https://github.com/vercel-labs/agent-browser";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "agent-browser";
  };
}
