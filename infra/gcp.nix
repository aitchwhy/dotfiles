# Google Cloud Infrastructure as Code via Terranix
# Generates Terraform JSON for managing GCP resources
#
# Usage:
#   just tf-gen    # Generate config.tf.json
#   just tf-plan   # Plan changes
#   just tf-apply  # Apply changes
#
# Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs
{ ... }:
{
  # Terraform configuration
  terraform = {
    required_version = ">= 1.0";

    required_providers = {
      google = {
        source = "hashicorp/google";
        version = "~> 5.0";
      };
    };

    # Remote state via GCS (recommended for team collaboration)
    # backend.gcs = {
    #   bucket = "cloud-infra-480717-tfstate";
    #   prefix = "nixos/cloud";
    # };
  };

  # Google Cloud provider
  provider.google = {
    project = "\${var.project_id}";
    region = "\${var.region}";
    zone = "\${var.zone}";
    # Credentials: GOOGLE_APPLICATION_CREDENTIALS environment variable
    # Or via sops: gcloud auth application-default login
  };

  # Variables
  variable = {
    project_id = {
      type = "string";
      default = "cloud-infra-480717";
      description = "GCP project ID";
    };

    region = {
      type = "string";
      default = "us-central1";
      description = "GCP region";
    };

    zone = {
      type = "string";
      default = "us-central1-a";
      description = "GCP zone";
    };

    machine_type = {
      type = "string";
      default = "e2-standard-4"; # 4 vCPU, 16GB RAM (~$100/mo)
      description = "GCE machine type";
    };

    disk_size = {
      type = "number";
      default = 100; # GB
      description = "Boot disk size in GB";
    };
  };

  # VPC Network (use default for simplicity)
  # resource.google_compute_network.nixos = {
  #   name = "nixos-network";
  #   auto_create_subnetworks = true;
  # };

  # Firewall Rules
  resource.google_compute_firewall = {
    # SSH access (for initial setup and emergencies)
    allow-ssh = {
      name = "allow-ssh";
      network = "default";
      description = "Allow SSH from anywhere";

      allow = {
        protocol = "tcp";
        ports = [ "22" ];
      };

      source_ranges = [ "0.0.0.0/0" ];
      target_tags = [ "ssh" ];
    };

    # Tailscale WireGuard (primary access method)
    allow-tailscale = {
      name = "allow-tailscale";
      network = "default";
      description = "Allow Tailscale WireGuard UDP";

      allow = {
        protocol = "udp";
        ports = [ "41641" ];
      };

      source_ranges = [ "0.0.0.0/0" ];
      target_tags = [ "tailscale" ];
    };

    # ICMP for network diagnostics
    allow-icmp = {
      name = "allow-icmp";
      network = "default";
      description = "Allow ICMP (ping)";

      allow = {
        protocol = "icmp";
      };

      source_ranges = [ "0.0.0.0/0" ];
      target_tags = [ "nixos" ];
    };
  };

  # Static External IP
  resource.google_compute_address.cloud = {
    name = "cloud-nixos-ip";
    region = "\${var.region}";
    description = "Static IP for NixOS cloud instance";
  };

  # Main Compute Engine Instance
  resource.google_compute_instance.cloud = {
    name = "cloud-nixos";
    machine_type = "\${var.machine_type}";
    zone = "\${var.zone}";

    # Boot Disk
    boot_disk = {
      initialize_params = {
        # NixOS requires custom image or nixos-anywhere provisioning
        # Start with Debian, then run nixos-anywhere
        image = "debian-cloud/debian-12";
        size = "\${var.disk_size}";
        type = "pd-ssd";
        labels = {
          os = "nixos";
          managed-by = "terranix";
        };
      };
      auto_delete = true;
    };

    # Network Configuration
    network_interface = {
      network = "default";
      access_config = {
        nat_ip = "\${google_compute_address.cloud.address}";
      };
    };

    # Metadata
    metadata = {
      enable-oslogin = "FALSE"; # Use SSH keys instead
      # SSH key for initial access (nixos-anywhere)
      # ssh-keys = "hank:ssh-ed25519 AAAA... hank@mbp";
    };

    # Instance Tags (for firewall rules)
    tags = [
      "nixos"
      "tailscale"
      "ssh"
    ];

    # Labels for organization
    labels = {
      environment = "production";
      managed-by = "terranix";
      os = "nixos";
    };

    # Scheduling
    scheduling = {
      automatic_restart = true;
      on_host_maintenance = "MIGRATE";
      preemptible = false; # Set true for spot pricing (~70% cheaper)
    };

    # Service Account
    service_account = {
      email = "\${google_service_account.cloud.email}";
      scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
        "https://www.googleapis.com/auth/logging.write"
        "https://www.googleapis.com/auth/monitoring.write"
      ];
    };

    # Lifecycle - prevent accidental destruction
    lifecycle = {
      prevent_destroy = true;
    };

    # Shielded VM (security hardening)
    shielded_instance_config = {
      enable_secure_boot = false; # NixOS needs custom boot
      enable_vtpm = true;
      enable_integrity_monitoring = true;
    };
  };

  # Service Account for Cloud Monitoring/Logging
  resource.google_service_account.cloud = {
    account_id = "nixos-cloud-vm";
    display_name = "NixOS Cloud VM Service Account";
    description = "Service account for Cloud Monitoring and Logging";
  };

  # IAM Bindings for Monitoring
  resource.google_project_iam_member = {
    monitoring-writer = {
      project = "\${var.project_id}";
      role = "roles/monitoring.metricWriter";
      member = "serviceAccount:\${google_service_account.cloud.email}";
    };

    logging-writer = {
      project = "\${var.project_id}";
      role = "roles/logging.logWriter";
      member = "serviceAccount:\${google_service_account.cloud.email}";
    };
  };

  # Outputs
  output = {
    instance_id = {
      value = "\${google_compute_instance.cloud.instance_id}";
      description = "GCE instance ID";
    };

    instance_name = {
      value = "\${google_compute_instance.cloud.name}";
      description = "GCE instance name";
    };

    instance_ip = {
      value = "\${google_compute_address.cloud.address}";
      description = "Static external IPv4 address";
    };

    instance_internal_ip = {
      value = "\${google_compute_instance.cloud.network_interface[0].network_ip}";
      description = "Internal IPv4 address";
    };

    ssh_command = {
      value = "ssh hank@\${google_compute_address.cloud.address}";
      description = "SSH command to connect";
    };

    nixos_anywhere_command = {
      value = "nix run github:nix-community/nixos-anywhere -- --flake .#cloud root@\${google_compute_address.cloud.address}";
      description = "nixos-anywhere deployment command";
    };

    tailscale_note = {
      value = "After Tailscale setup, connect via: ssh hank@cloud";
      description = "Tailscale connection info";
    };

    project_id = {
      value = "\${var.project_id}";
      description = "GCP project ID";
    };

    zone = {
      value = "\${var.zone}";
      description = "GCE zone";
    };
  };
}
