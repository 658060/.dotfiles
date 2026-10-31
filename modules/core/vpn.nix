{pkgs, ...}: {
  services.mullvad-vpn = {
    enable = true;
    # package = pkgs.mullvad-vpn;
    gui.enable = true;
  };

  systemd.services.tailscale-mullvad = {
    description = "let tailscale through Mullvad's kill switch";
    after = ["mullvad-daemon.service" "tailscaled.service" "firewall.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.nftables}/bin/nft -f ${pkgs.writeText "ts-mullvad.nft" ''
        table inet ts-mullvad {
          chain prerouting {
            type filter hook prerouting priority -160; policy accept;
            iifname "tailscale0" ct mark set 0x00000f41
          }
          chain output {
            type filter hook output priority -160; policy accept;
            oifname "tailscale0" ct mark set 0x00000f41
          }
        }
      ''}";
      ExecStop = "${pkgs.nftables}/bin/nft delete table inet ts-mullvad";
    };
  };
}
