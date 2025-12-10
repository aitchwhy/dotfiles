---
name: terranix-patterns
description: Terranix patterns for pure Nix to Terraform JSON to OpenTofu. GCP Cloud Run, Cloud SQL.
allowed-tools: Read, Write, Edit, Bash
---

## Philosophy: Pure Nix for Infrastructure

Terranix generates Terraform JSON from pure Nix expressions.
The effectful apply happens via OpenTofu.

```
Nix Expression (PURE)
        |
    terranix
        |
Terraform JSON (PURE)
        |
  OpenTofu apply (EFFECTFUL)
        |
   Cloud Resources
```

## Project Setup

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    terranix.url = "github:terranix/terranix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-linux" ];

      perSystem = { pkgs, system, ... }: let
        terranix = inputs.terranix.lib.terranixConfiguration {
          inherit system;
          modules = [ ./infra/main.nix ];
        };
      in {
        # Generate Terraform JSON
        packages.terraform-config = terranix;

        # Apply script
        apps.tf-apply = {
          type = "app";
          program = toString (pkgs.writeShellScript "tf-apply" ''
            set -euo pipefail
            ${pkgs.opentofu}/bin/tofu init
            ${pkgs.opentofu}/bin/tofu apply
          '');
        };

        # Plan script
        apps.tf-plan = {
          type = "app";
          program = toString (pkgs.writeShellScript "tf-plan" ''
            set -euo pipefail
            ${pkgs.opentofu}/bin/tofu init
            ${pkgs.opentofu}/bin/tofu plan
          '');
        };

        # DevShell with tools
        devShells.infra = pkgs.mkShell {
          packages = with pkgs; [
            opentofu
            google-cloud-sdk
          ];
        };
      };
    };
}
```

## Main Configuration

```nix
# infra/main.nix
{ config, lib, ... }:
{
  imports = [
    ./providers.nix
    ./gcp/cloud-run.nix
    ./gcp/cloud-sql.nix
    ./gcp/pubsub.nix
    ./gcp/secrets.nix
  ];

  # Project-wide configuration
  config = {
    _module.args = {
      projectId = "ember-production";
      region = "us-central1";
      environment = "production";
    };
  };
}
```

## Provider Configuration

```nix
# infra/providers.nix
{ lib, ... }:
{
  terraform.required_providers = {
    google = {
      source = "hashicorp/google";
      version = "~> 5.0";
    };
    google-beta = {
      source = "hashicorp/google-beta";
      version = "~> 5.0";
    };
  };

  provider.google = {
    project = "\${var.project_id}";
    region = "\${var.region}";
  };

  variable.project_id = {
    type = "string";
    description = "GCP Project ID";
  };

  variable.region = {
    type = "string";
    default = "us-central1";
  };
}
```

## Cloud Run Service

```nix
# infra/gcp/cloud-run.nix
{ config, lib, projectId, region, ... }:
let
  services = {
    api = {
      image = "gcr.io/${projectId}/ember-api:latest";
      cpu = "1000m";
      memory = "512Mi";
      minInstances = 1;
      maxInstances = 10;
      env = {
        DATABASE_URL = { fromSecret = "database-url"; };
        REDIS_URL = { fromSecret = "redis-url"; };
        NODE_ENV = "production";
      };
    };

    web = {
      image = "gcr.io/${projectId}/ember-web:latest";
      cpu = "500m";
      memory = "256Mi";
      minInstances = 1;
      maxInstances = 5;
      env = {
        API_URL = "https://api.ember.dev";
      };
    };
  };

  mkCloudRunService = name: cfg: {
    resource.google_cloud_run_v2_service.${name} = {
      inherit name;
      location = region;

      template = {
        containers = [{
          image = cfg.image;

          resources.limits = {
            cpu = cfg.cpu;
            memory = cfg.memory;
          };

          env = lib.mapAttrsToList (envName: envValue:
            if builtins.isAttrs envValue && envValue ? fromSecret
            then {
              name = envName;
              value_source.secret_key_ref = {
                secret = envValue.fromSecret;
                version = "latest";
              };
            }
            else {
              name = envName;
              value = envValue;
            }
          ) cfg.env;
        }];

        scaling = {
          min_instance_count = cfg.minInstances;
          max_instance_count = cfg.maxInstances;
        };
      };

      traffic = [{
        type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST";
        percent = 100;
      }];
    };

    # Allow public access
    resource.google_cloud_run_service_iam_member."${name}_public" = {
      location = region;
      service = "\${google_cloud_run_v2_service.${name}.name}";
      role = "roles/run.invoker";
      member = "allUsers";
    };
  };
in
{
  config = lib.mkMerge (lib.mapAttrsToList mkCloudRunService services);
}
```

## Cloud SQL Database

```nix
# infra/gcp/cloud-sql.nix
{ config, lib, projectId, region, ... }:
{
  resource.google_sql_database_instance.main = {
    name = "ember-postgres";
    region = region;
    database_version = "POSTGRES_15";

    settings = {
      tier = "db-custom-2-4096";

      ip_configuration = {
        ipv4_enabled = false;
        private_network = "\${google_compute_network.main.id}";
      };

      backup_configuration = {
        enabled = true;
        point_in_time_recovery_enabled = true;
        start_time = "03:00";
      };

      maintenance_window = {
        day = 7;  # Sunday
        hour = 4; # 4 AM
      };

      database_flags = [
        { name = "log_min_duration_statement"; value = "1000"; }
        { name = "max_connections"; value = "100"; }
      ];
    };

    deletion_protection = true;
  };

  resource.google_sql_database.ember = {
    name = "ember";
    instance = "\${google_sql_database_instance.main.name}";
  };

  resource.google_sql_user.app = {
    name = "ember-app";
    instance = "\${google_sql_database_instance.main.name}";
    password = "\${random_password.db_password.result}";
  };

  resource.random_password.db_password = {
    length = 32;
    special = true;
  };

  # Store in Secret Manager
  resource.google_secret_manager_secret.database_url = {
    secret_id = "database-url";
    replication.auto = {};
  };

  resource.google_secret_manager_secret_version.database_url = {
    secret = "\${google_secret_manager_secret.database_url.id}";
    secret_data = "postgresql://\${google_sql_user.app.name}:\${random_password.db_password.result}@/ember?host=/cloudsql/\${google_sql_database_instance.main.connection_name}";
  };
}
```

## Pub/Sub Topics

```nix
# infra/gcp/pubsub.nix
{ config, lib, projectId, ... }:
let
  topics = {
    user-events = {
      subscriptions = [
        { name = "analytics"; ackDeadline = 60; }
        { name = "notifications"; ackDeadline = 30; }
      ];
    };

    order-events = {
      subscriptions = [
        { name = "fulfillment"; ackDeadline = 120; }
        { name = "inventory"; ackDeadline = 60; }
      ];
      deadLetterTopic = "order-events-dlq";
    };
  };

  mkTopic = name: cfg: {
    resource.google_pubsub_topic.${name} = {
      inherit name;
      message_retention_duration = "604800s"; # 7 days
    };
  } // lib.optionalAttrs (cfg ? subscriptions) {
    resource.google_pubsub_subscription = lib.listToAttrs (map (sub: {
      name = "${name}-${sub.name}";
      value = {
        name = "${name}-${sub.name}";
        topic = "\${google_pubsub_topic.${name}.name}";
        ack_deadline_seconds = sub.ackDeadline;

        retry_policy = {
          minimum_backoff = "10s";
          maximum_backoff = "600s";
        };

        expiration_policy.ttl = "";  # Never expire

        dead_letter_policy = lib.optionalAttrs (cfg ? deadLetterTopic) {
          dead_letter_topic = "\${google_pubsub_topic.${cfg.deadLetterTopic}.id}";
          max_delivery_attempts = 5;
        };
      };
    }) cfg.subscriptions);
  };
in
{
  config = lib.mkMerge (lib.mapAttrsToList mkTopic topics);
}
```

## Workflow

### Generate and Apply

```bash
# Generate Terraform JSON
nix build .#terraform-config
cat result/config.tf.json | jq

# Initialize and plan
nix run .#tf-plan

# Apply changes
nix run .#tf-apply

# Or manually
cd infra
cp $(nix build ..#terraform-config --print-out-paths)/config.tf.json .
tofu init
tofu plan
tofu apply
```

### justfile Commands

```just
# Generate Terraform config from Terranix
tf-gen:
    nix build .#terraform-config
    cp result/config.tf.json infra/

# Terraform plan
tf-plan: tf-gen
    cd infra && tofu plan

# Terraform apply
tf-apply: tf-gen
    cd infra && tofu apply
```

## CI Drift Detection

```yaml
# .github/workflows/infra.yml
name: Infrastructure

on:
  pull_request:
    paths:
      - "infra/**"
      - "flake.nix"
      - "flake.lock"

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main

      - name: Generate Terraform config
        run: nix build .#terraform-config

      - name: Setup OpenTofu
        uses: opentofu/setup-opentofu@v1

      - name: Terraform Init
        run: |
          cp result/config.tf.json infra/
          cd infra
          tofu init

      - name: Terraform Plan
        run: |
          cd infra
          tofu plan -no-color
        env:
          GOOGLE_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
```

## State Management

```nix
# infra/backend.nix
{
  terraform.backend.gcs = {
    bucket = "ember-terraform-state";
    prefix = "production";
  };
}
```

## Key Benefits

| Benefit | Explanation |
|---------|-------------|
| **Purity** | Terraform JSON is deterministically generated from Nix |
| **Type Safety** | NixOS module system catches errors at evaluation time |
| **Composability** | Reusable modules with proper abstraction |
| **Reproducibility** | `flake.lock` pins exact Terranix version |
| **Testability** | Nix expressions can be evaluated without cloud access |

## Anti-Patterns (BANNED)

```nix
# WRONG: Hand-written HCL
# Never write Terraform HCL directly - always generate from Nix

# WRONG: Hardcoded values
resource.google_cloud_run_v2_service.api = {
  image = "gcr.io/my-project/api:latest";  # Hardcoded!
};

# CORRECT: Parameterized
{ projectId, ... }:
resource.google_cloud_run_v2_service.api = {
  image = "gcr.io/${projectId}/api:latest";
};
```

```nix
# WRONG: No deletion protection
resource.google_sql_database_instance.main = {
  name = "production-db";
  # Missing deletion_protection!
};

# CORRECT: Always protect critical resources
resource.google_sql_database_instance.main = {
  name = "production-db";
  deletion_protection = true;
};
```

## File Structure

```
infra/
├── main.nix           # Entry point
├── providers.nix      # Provider configuration
├── backend.nix        # State backend
├── gcp/
│   ├── cloud-run.nix  # Cloud Run services
│   ├── cloud-sql.nix  # Cloud SQL database
│   ├── pubsub.nix     # Pub/Sub topics
│   ├── secrets.nix    # Secret Manager
│   └── network.nix    # VPC configuration
└── config.tf.json     # Generated (gitignored)
```
