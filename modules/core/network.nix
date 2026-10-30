{
  pkgs,
  host,
  options,
  ...
}: {
  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";
    timeServers = options.networking.timeServers.default ++ ["pool.ntp.org"];
    firewall = {
      enable = true;
      checkReversePath = "loose";
      trustedInterfaces = ["tailscale0"];
      allowedTCPPorts = [
        22
        # nicotine-plus / qbittorrent
        59010
        59011
      ];
      allowedUDPPorts = [
        59010
        59011
      ];
    };
    extraHosts = ''
      127.0.0.1 lmlicenses.wip4.adobe.com
      127.0.0.1 lm.licenses.adobe.com
      127.0.0.1 na1r.services.adobe.com
      127.0.0.1 hlrcv.stage.adobe.com
      127.0.0.1 practivate.adobe.com
      127.0.0.1 activate.adobe.com
    '';
  };

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
