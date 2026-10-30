{
  # Host identity ( read by flake.nix to wire drivers + user )
  profile = "amd";
  user = "daley";
  sshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPxvLjTg/ZPIWQ8EgG8BOoBF7ZQTIPyERo0SPAkihEWa lottie@laptop2"
  ];

  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "daleykeister-afk";
  gitEmail = "232945931+daleykeister-afk@users.noreply.github.com";

  # Only keys that differ from the modules/core/variables.nix defaults.
  extraMonitorSettings = [
    { output = "DP-3";     mode = "2560x1440@240";  position = "0x0";        scale = "1"; transform = "0"; colorPreset = "hdr";}
    { output = "DP-2";     mode = "2560x1440@144";  position = "2560x-510";  scale = "1"; transform = "1"; colorPreset = "auto";}
    { output = "HDMI-A-1"; mode = "2560x1440@144";  position = "-1440x-590"; scale = "1"; transform = "3"; colorPreset = "auto"; }
  ];
  defaultWallpaper = "847928.jpg";

  # variables which toggle packages
  gamedev = true;
  gaming = true;
  texlive = false;
  silly = true;
  music = true;

  # Enable NFS
  enableNFS = true;
}
