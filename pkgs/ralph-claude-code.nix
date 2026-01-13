# ralph-claude-code - Autonomous AI development loop for Claude Code
# https://github.com/frankbria/ralph-claude-code
#
# Features: Rate limiting, circuit breaker, tmux integration, intelligent exit detection
# Provides: ralph, ralph-monitor, ralph-setup, ralph-import
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  tmux,
  jq,
  gnugrep,
  gnused,
  coreutils,
  bash,
  gawk,
}:

stdenvNoCC.mkDerivation rec {
  pname = "ralph-claude-code";
  version = "0.9.0";

  src = fetchFromGitHub {
    owner = "frankbria";
    repo = "ralph-claude-code";
    rev = "50f54e82e10d54f5b22bec58b5c08b7dc16dd343";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  dontConfigure = true;

  postPatch = ''
    for script in ralph_loop.sh ralph_monitor.sh setup.sh ralph_import.sh; do
      if [ -f "$script" ]; then
        substituteInPlace "$script" \
          --replace 'source "$(dirname "$0")/lib/' 'source "$RALPH_LIB/' \
          --replace 'source lib/' 'source "$RALPH_LIB/' \
          --replace './lib/' '"$RALPH_LIB/'
      fi
    done

    for libfile in lib/*.sh; do
      if [ -f "$libfile" ]; then
        substituteInPlace "$libfile" \
          --replace 'source "$(dirname "$0")/' 'source "$RALPH_LIB/' \
          --replace 'source lib/' 'source "$RALPH_LIB/'
      fi
    done
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/ralph
    cp -r lib/* $out/lib/ralph/

    install -Dm755 ralph_loop.sh $out/bin/ralph
    install -Dm755 ralph_monitor.sh $out/bin/ralph-monitor
    install -Dm755 setup.sh $out/bin/ralph-setup
    install -Dm755 ralph_import.sh $out/bin/ralph-import

    for script in $out/bin/*; do
      wrapProgram "$script" \
        --prefix PATH : ${lib.makeBinPath [ tmux jq gnugrep gnused coreutils bash gawk ]} \
        --set RALPH_LIB "$out/lib/ralph"
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Autonomous AI development loop for Claude Code with intelligent exit detection";
    homepage = "https://github.com/frankbria/ralph-claude-code";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "ralph";
  };
}
