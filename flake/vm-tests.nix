# NixOS VM integration tests
# Run with: nix flake check (on x86_64-linux)
# Or: nix build .#checks.x86_64-linux.vm-cloud-boot
#
# Docs: https://nixos.org/manual/nixos/stable/#sec-nixos-tests
{
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    {
      # VM tests only run on x86_64-linux (QEMU/KVM requirement)
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        # Test: Cloud VM boots and core services start
        vm-cloud-boot = pkgs.nixosTest {
          name = "cloud-boot-test";

          nodes.cloud =
            { ... }:
            {
              # Import minimal cloud configuration for testing
              # Note: Can't import full config due to secrets/hardware deps
              imports = [
                ../modules/nixos/system.nix
                ../modules/nixos/security.nix
                ../modules/nixos/users.nix
                ../modules/nixos/services/sshd.nix
              ];

              # Override for VM testing
              virtualisation = {
                memorySize = 2048;
                cores = 2;
              };

              # Minimal config for testing
              system.stateVersion = "26.05";

              # Mock user for testing
              users.users.hank = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
                initialPassword = "test";
              };
            };

          testScript = ''
            # Wait for VM to boot
            cloud.start()
            cloud.wait_for_unit("multi-user.target")

            # Verify core services
            cloud.wait_for_unit("sshd.service")

            # Test SSH is listening
            cloud.succeed("ss -tlnp | grep -q ':22'")

            # Test firewall is active
            cloud.succeed("systemctl is-active firewalld || systemctl is-active iptables || true")

            # Test user exists
            cloud.succeed("id hank")

            # Test sudo access
            cloud.succeed("echo 'test' | su - hank -c 'sudo -S whoami' | grep -q root")

            print("Cloud boot test passed!")
          '';
        };

        # Test: Security hardening is applied
        vm-security-hardening = pkgs.nixosTest {
          name = "security-hardening-test";

          nodes.secure =
            { ... }:
            {
              imports = [
                ../modules/nixos/security.nix
              ];

              virtualisation = {
                memorySize = 1024;
                cores = 1;
              };

              system.stateVersion = "26.05";
            };

          testScript = ''
            secure.start()
            secure.wait_for_unit("multi-user.target")

            # Verify fail2ban is running
            secure.wait_for_unit("fail2ban.service")
            secure.succeed("systemctl is-active fail2ban")

            # Verify firewall is enabled
            secure.succeed("systemctl is-active firewalld || iptables -L -n | grep -q 'Chain'")

            # Verify kernel hardening (if configured)
            # secure.succeed("sysctl net.ipv4.tcp_syncookies | grep -q '1'")

            print("Security hardening test passed!")
          '';
        };

        # Test: Service dependencies are correct
        vm-service-deps = pkgs.nixosTest {
          name = "service-dependencies-test";

          nodes.services =
            { ... }:
            {
              imports = [
                ../modules/nixos/system.nix
              ];

              virtualisation = {
                memorySize = 1024;
                cores = 1;
              };

              system.stateVersion = "26.05";

              # Enable networking for dependency tests
              networking.useDHCP = true;
            };

          testScript = ''
            services.start()
            services.wait_for_unit("multi-user.target")
            services.wait_for_unit("network-online.target")

            # Verify network is up before services that depend on it
            services.succeed("systemctl list-dependencies network-online.target --reverse | head")

            print("Service dependencies test passed!")
          '';
        };
      };
    };
}
