{ config, ... }:

# Remote access between our own machines: Tailscale mesh VPN + SSH that is
# reachable ONLY over the tailnet. Imported by hosts that should be reachable
# (proasync-laptop, work-desktop).
#
# One-time per machine after the first switch:
#   sudo tailscale up      (browser login — same account as the other devices)
# MagicDNS then gives stable names: `ssh proasync@work-desktop` from anywhere.

{
  services.tailscale.enable = true;
  networking.firewall = {
    # Trust the tailnet interface (it's only ever our own devices)…
    trustedInterfaces = [ "tailscale0" ];
    # …and allow Tailscale's WireGuard port for direct (non-relayed) links.
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # openFirewall = false keeps port 22 closed on every real network
  # (home/work/café); tailscale0 being trusted is the sole way in.
  # Keys-only, no root, no passwords.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Keys allowed to log in as proasync (in addition to ~/.ssh/authorized_keys).
  # Public keys only — this one is also published at github.com/proasync.keys.
  users.users.proasync.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILA3JqWRlAjdBcHD54sS4jKQcE644orgmHLh0V7fxgif andreas@pagodalog.com"   # proasync-laptop
  ];
}
