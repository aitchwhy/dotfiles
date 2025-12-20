# process-compose-flake Patterns

## Nix-Native Service Definitions

```nix
# flake/process-compose.nix
{ inputs, ... }:
{
  imports = [ inputs.process-compose-flake.flakeModule ];

  perSystem = { pkgs, ... }:
  let
    ports = import ../lib/ports.nix;
  in
  {
    process-compose.dev = {
      settings.processes = {
        api = {
          command = "${pkgs.bun}/bin/bun run dev";
          environment.PORT = toString ports.development.api;
          ready_log_line = "listening on";
        };

        redis = {
          command = "${pkgs.redis}/bin/redis-server --port ${toString ports.databases.redis}";
          is_daemon = true;
          readiness_probe = {
            exec.command = "${pkgs.redis}/bin/redis-cli -p ${toString ports.databases.redis} ping";
            initial_delay_seconds = 1;
            period_seconds = 2;
          };
        };

        postgres = {
          command = "${pkgs.postgresql_18}/bin/postgres -D $PGDATA -p ${toString ports.databases.postgresql}";
          environment.PGDATA = "/tmp/pgdata-dev";
          readiness_probe = {
            exec.command = "${pkgs.postgresql_18}/bin/pg_isready -p ${toString ports.databases.postgresql}";
          };
          depends_on.postgres-init.condition = "process_completed_successfully";
        };

        postgres-init = {
          command = ''
            if [ ! -d /tmp/pgdata-dev ]; then
              ${pkgs.postgresql_18}/bin/initdb -D /tmp/pgdata-dev
            fi
          '';
          is_foreground = false;
        };
      };
    };

    # Process groups
    process-compose.minimal = {
      settings.processes = {
        redis = config.process-compose.dev.settings.processes.redis;
      };
    };
  };
}
```

## Commands

```bash
# Start all dev services
nix run .#dev
# or
just dev

# Start with TUI
nix run .#dev -- --tui

# Start minimal stack
nix run .#minimal
```
