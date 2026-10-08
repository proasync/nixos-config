{ ... }:

# Dev servers the phone reaches over the LAN:
#   8081 = Expo/Metro (JS bundle), 4300 = training API (sign-in + sync).
# Imported by home-desktop and proasync-laptop only. work-desktop leaves the
# office LAN closed; the phone reaches it over Tailscale instead (tailscale0
# is trusted in modules/remote-access.nix).

{
  networking.firewall.allowedTCPPorts = [ 8081 4300 ];
}
