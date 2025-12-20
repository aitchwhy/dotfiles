# nix2container Patterns

## Minimal Container Build

```nix
{ inputs, ... }:
{
  perSystem = { pkgs, system, self', ... }:
  let
    nix2container = inputs.nix2container.packages.${system}.nix2container;
    ports = import ../lib/ports.nix;
  in
  {
    packages.container-api = nix2container.buildImage {
      name = "api";
      tag = "latest";

      copyToRoot = pkgs.buildEnv {
        name = "api-root";
        paths = [
          self'.packages.api
          pkgs.cacert
        ];
        pathsToLink = [ "/bin" "/etc" ];
      };

      config = {
        Cmd = [ "${self'.packages.api}/bin/api" ];
        ExposedPorts."${toString ports.development.api}/tcp" = {};
        Env = [
          "PORT=${toString ports.development.api}"
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        ];
      };
    };
  };
}
```

## Layer Optimization

```nix
packages.container-api = nix2container.buildImage {
  name = "api";

  # Separate layers for better caching
  layers = [
    # Base runtime (rarely changes)
    (nix2container.buildLayer {
      deps = [ pkgs.glibc pkgs.cacert ];
    })
    # Application runtime (changes occasionally)
    (nix2container.buildLayer {
      deps = [ pkgs.bun ];
    })
  ];

  # Application code (changes frequently - top layer)
  copyToRoot = [ self'.packages.api ];
};
```

## Build and Push

```bash
# Build container
nix build .#container-api

# Load into Docker (local testing)
./result | docker load

# Push directly to registry
nix run .#container-api.copyToRegistry -- docker://ghcr.io/org/api:latest
```
