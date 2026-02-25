# Declarative network and DNS management
#
# DNS: NextDNS via macOS native Encrypted DNS profile (DoH)
# The .mobileconfig profile is generated from lib/config/network.nix SSOT.
# macOS requires user approval for profile installation (one-time).
# On every activation: verifies profile is installed, clears manual DNS,
# removes stale network services.
{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    concatMapStringsSep
    ;
  cfg = config.modules.darwin.network;
  networkConfig = import ../../lib/config/network.nix { inherit lib; };
  nextdns = networkConfig.dns.nextdns;

  # URL-encode the device name for the DoH endpoint
  encodedDeviceName = builtins.replaceStrings [ " " ] [ "%20" ] nextdns.deviceName;

  profileIdentifier = "io.nextdns.${nextdns.configId}.profile";

  # Generate the .mobileconfig XML for NextDNS encrypted DNS
  mobileconfig = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>PayloadContent</key>
      <array>
        <dict>
          <key>DNSSettings</key>
          <dict>
            <key>DNSProtocol</key>
            <string>HTTPS</string>
            <key>ServerURL</key>
            <string>https://apple.dns.nextdns.io/${nextdns.configId}/${encodedDeviceName}</string>
          </dict>
          <key>OnDemandRules</key>
          <array>
            <dict>
              <key>Action</key>
              <string>EvaluateConnection</string>
              <key>ActionParameters</key>
              <array>
                <dict>
                  <key>DomainAction</key>
                  <string>NeverConnect</string>
                  <key>Domains</key>
                  <array>
                    <string>captive.apple.com</string>
                  </array>
                </dict>
              </array>
            </dict>
            <dict>
              <key>Action</key>
              <string>Connect</string>
            </dict>
          </array>
          <key>PayloadDisplayName</key>
          <string>NextDNS (${nextdns.configId})</string>
          <key>PayloadIdentifier</key>
          <string>${profileIdentifier}.dnsSettings.managed</string>
          <key>PayloadOrganization</key>
          <string>NextDNS</string>
          <key>PayloadType</key>
          <string>com.apple.dnsSettings.managed</string>
          <key>PayloadUUID</key>
          <string>A1E2F262-DB73-40F6-BD22-2E42A43A3C94.${nextdns.configId}.dnsSettings.managed</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
        </dict>
      </array>
      <key>PayloadDescription</key>
      <string>Enables NextDNS encrypted DNS (DoH) on all networks. Managed by nix-darwin.</string>
      <key>PayloadDisplayName</key>
      <string>NextDNS (${nextdns.configId})</string>
      <key>PayloadIdentifier</key>
      <string>${profileIdentifier}</string>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>A1E2F262-DB73-40F6-BD22-2E42A43A3C94.${nextdns.configId}</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
    </dict>
    </plist>
  '';
in
{
  options.modules.darwin.network = {
    enable = mkEnableOption "Network and DNS management";

    primaryInterface = mkOption {
      type = types.str;
      default = "Wi-Fi";
      description = "Primary network interface";
    };

    removeStaleServices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Network services to remove if they exist";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      echo "Configuring network..."

      # Remove stale network services (idempotent)
      ${concatMapStringsSep "\n" (svc: ''
        if /usr/sbin/networksetup -listallnetworkservices 2>/dev/null | grep -q "^${svc}$"; then
          echo "  Removing stale network service: ${svc}"
          /usr/sbin/networksetup -removenetworkservice "${svc}" 2>/dev/null || true
        fi
      '') cfg.removeStaleServices}

      # Verify NextDNS encrypted DNS profile is installed
      if /usr/bin/profiles show -type configuration 2>/dev/null | grep -q "${profileIdentifier}"; then
        echo "  NextDNS profile installed (${nextdns.configId}, ${nextdns.deviceName})"
      else
        echo "  WARNING: NextDNS profile not installed!"
        echo "  Generating profile and opening for installation..."
        profile_path="/tmp/nextdns-${nextdns.configId}.mobileconfig"
        cat > "$profile_path" << 'PROFILE_EOF'
      ${mobileconfig}
      PROFILE_EOF
        /usr/bin/open "$profile_path"
        echo "  → Approve the profile in System Settings > Privacy & Security > Profiles"
      fi

      # Clear manual DNS servers — NextDNS profile handles DNS via DoH
      current_dns=$(/usr/sbin/networksetup -getdnsservers "${cfg.primaryInterface}" 2>/dev/null)
      if [ "$current_dns" != "There aren't any DNS Servers set on ${cfg.primaryInterface}." ]; then
        echo "  Clearing manual DNS on ${cfg.primaryInterface} (NextDNS profile handles DNS)"
        /usr/sbin/networksetup -setdnsservers "${cfg.primaryInterface}" empty
      fi

      # Flush DNS cache
      /usr/bin/dscacheutil -flushcache 2>/dev/null || true
      /usr/bin/killall -HUP mDNSResponder 2>/dev/null || true
    '';
  };
}
