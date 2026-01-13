# drizzle-kit - Drizzle ORM CLI with Studio
# https://orm.drizzle.team/kit-docs/overview
#
# Provides: drizzle-kit (includes `drizzle-kit studio` for GUI)
# Usage: drizzle-kit studio (launches browser-based GUI)
#        drizzle-kit generate/migrate/push/pull (schema operations)
{
  lib,
  stdenvNoCC,
  bun,
  makeWrapper,
  cacert,
}:

stdenvNoCC.mkDerivation rec {
  pname = "drizzle-kit";
  version = "0.31.8";

  # No source - we install from npm via bun
  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
    bun
    cacert
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

    # Install drizzle-kit via bun
    mkdir -p $TMPDIR/node_modules
    cd $TMPDIR
    bun add drizzle-kit@${version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/drizzle-kit $out/bin

    # Copy node_modules
    cp -r $TMPDIR/node_modules $out/lib/drizzle-kit/

    # Create wrapper script
    makeWrapper ${bun}/bin/bun $out/bin/drizzle-kit \
      --add-flags "$out/lib/drizzle-kit/node_modules/drizzle-kit/bin.cjs"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Drizzle ORM CLI toolkit with schema-aware Studio GUI";
    homepage = "https://orm.drizzle.team/kit-docs/overview";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "drizzle-kit";
  };
}
