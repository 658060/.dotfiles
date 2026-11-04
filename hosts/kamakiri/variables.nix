{
  # Host identity ( read by flake.nix to wire drivers + user )
  profile = "nvidia"; # driver bundle under ./profiles
  user = "lottie";
  sshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPxvLjTg/ZPIWQ8EgG8BOoBF7ZQTIPyERo0SPAkihEWa lottie@laptop2"
  ];

  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "658060";
  gitEmail = "31701136+658060@users.noreply.github.com";

  # Only keys that differ from the modules/core/variables.nix defaults.
  extraMonitorSettings = [
    { output = "DP-1"; mode = "1920x1080@144"; position = "auto"; scale = "1"; transform = "0"; }
    { output = "DP-3"; mode = "2560x1440@144"; position = "auto-left"; scale = "1"; transform = "0"; }
  ];
  extraHardwareSettings = {
    opengl = { nvidia_anti_flicker = 0; };
    debug  = { damage_tracking = 0; };
  };

  gamedev = true;
  gaming = true;
  texlive = true;
  silly = true;

  enableNFS = true;
}
