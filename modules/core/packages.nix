{
  config,
  pkgs,
  ...
}: {
  programs = {
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    virt-manager.enable = true;
    mtr.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; 
    [
      stdenv.cc.cc.lib
    ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs;
    [
      # kingler has some serious bugs
      # e.g. because names are changed, pokemon with different forms are just... not printable to the terminal
      # so `kingler name shaymin` doesn't work, and neither does `kingler name shaymin`
      # customPkgs.kingler
      # customPkgs.datacorn

      (agda.withPackages [
        agdaPackages._1lab
        agdaPackages.agda-categories
        agdaPackages.cubical
        agdaPackages.standard-library
      ])
      # fails to build 2025-11-15
      # ardour
      android-studio
      gradle
      jdk17
      amdgpu_top
      brightnessctl
      ddcutil
      claude-code # unfortunately needed for work
      clementine
      clock-rs
      dust
      libretro.swanstation
      # marked unsafe
      # element-desktop
      edopro # YGO simulator
      eza
      ffmpeg
      file-roller
      fzf
      # fails to build 2026-01-01
      # gemini-cli
      gimp
      gtop
      tuigreet
      hyprpicker
      handbrake
      icu
      imv
      inkscape
      killall
      krabby
      lc0
      libnotify
      libvirt
      lm_sensors
      # lmms
      lxqt.lxqt-policykit
      mask
      masklint
      mpv
      # mullvad-vpn
      nicotine-plus
      notes
      obs-studio
      opencode # for work
      outfox
      pavucontrol
      pciutils
      pcsx2
      
      # picard
      playerctl
      prusa-slicer
      qbittorrent-enhanced
      quickemu
      ripgrep
      scid-vs-pc
      socat
      stockfish
      unrar
      unzip
      usbutils
      v4l-utils
      vlc
      wget
      xrandr
      zoxide
    ]
    ++ lib.optionals config.variables.gaming [
      # TODO: move retroarch to ../home, add config
      cemu # wii u emu
      dolphin-emu # wii/gcn emu
      joycond
      joycond-cemuhook
      lumafly # HK mod manager
      melonds #nds emu
      osu-lazer-bin
      prismlauncher # minecraft launcher
      # # fails to build 2026-01-01
      # retroarch-full # generic emu
    ]
    ++ lib.optionals config.variables.gamedev [
      # broken 2026-01-01
      # aseprite
      godot
    ]
    ++ lib.optionals config.variables.music [
      # --- Utilities & Routing ---
      qpwgraph            # Visual patchbay for PipeWire
      pavucontrol         # Profile selection (Pro Audio mode)
      alsa-scarlett-gui   # Hardware mixer for Focusrite Scarlett (may require firmware)
      pipewire

      # --- DAWs ---
      ardour
      (pkgs.symlinkJoin {
        name = "reaper-pw-jack";
        paths = [ pkgs.reaper ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/reaper \
            --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
        '';
      })

      # --- Standalone Guitar Processors ---
      guitarix

      # --- Plugins (LV2/CLAP) ---
      neural-amp-modeler-lv2  # NAM: loads .nam files from https://tonehunt.org
      lsp-plugins             # Includes latency meter, compressors, IR loader
      calf
      dragonfly-reverb
      gxplugins-lv2
      kapitonov-plugins-pack  # Profile-based amp models (KPP)
      chow-centaur            # Klon Centaur emulation
      chow-phaser

      # --- Practice & Learning ---
      tuxguitar
      hydrogen

      # --- Windows VST Compatibility --- Does not work due to Meson and Wine have incompatabilities 
      yabridge
      yabridgectl
      wineWow64Packages.stable  # Use wineWow64Packages, as wineWowPackages is deprecated
    ]
    ++ lib.optionals config.variables.silly [
      cmatrix
      cowsay
      fortune-kind
      pipes-rs
    ];
}
