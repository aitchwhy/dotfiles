# mywhoop - WHOOP API CLI client
# https://github.com/karl-cardenas-coding/mywhoop
#
# Used by: ADR-011 for WHOOP data export
# Features: Rate limiting, exponential backoff, token refresh
{
  lib,
  stdenv,
  fetchzip,
}:
let
  version = "0.3.1";
  # Platform-specific binary sources
  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/karl-cardenas-coding/mywhoop/releases/download/v${version}/mywhoop_darwin_arm64.zip";
      hash = "sha256-0w6bs5aj5gwvfcmj0db8arca420h92fangaqw1rris7i0fhijzs6=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/karl-cardenas-coding/mywhoop/releases/download/v${version}/mywhoop_darwin_amd64.zip";
      hash = lib.fakeHash;
    };
    "x86_64-linux" = {
      url = "https://github.com/karl-cardenas-coding/mywhoop/releases/download/v${version}/mywhoop_linux_amd64.zip";
      hash = lib.fakeHash;
    };
    "aarch64-linux" = {
      url = "https://github.com/karl-cardenas-coding/mywhoop/releases/download/v${version}/mywhoop_linux_arm64.zip";
      hash = lib.fakeHash;
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "mywhoop";
  inherit version;

  src = fetchzip {
    inherit (source) url hash;
    stripRoot = false;
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 mywhoop $out/bin/mywhoop
    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI tool for interacting with the WHOOP API";
    homepage = "https://github.com/karl-cardenas-coding/mywhoop";
    license = licenses.mit;
    maintainers = [ ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "mywhoop";
  };
}
