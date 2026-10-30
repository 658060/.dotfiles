-- Hyprland configuration (native Lua — ADR-0005)
--
-- This is the bulk of the config you actually design: settings, animations,
-- keybinds, window rules. It is a plain .lua file (LSP, highlighting, no Nix
-- string-escaping), loaded by ~/.config/hypr/hyprland.lua via require("config").
--
-- Nix-derived, host-specific values (accent colors, monitors, default browser/
-- terminal, GPU hardware tweaks, wallpaper path) live in the generated companion
-- module `vars.lua` and are pulled in here. Edit those in
-- modules/home/hyprland/config.nix, not here.
--
-- When the host has `designMode = true`, this file is symlinked from the working
-- tree, so edits + `hyprctl reload` apply with no rebuild.

local vars = require("vars")

-- ── Startup ──────────────────────────────────────────────────────────────
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("killall -q awww-daemon;sleep .5 && awww-daemon")
  hl.exec_cmd("killall -q waybar;sleep .5 && waybar")
  hl.exec_cmd("killall -q swaync;sleep .5 && swaync")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("lxqt-policykit-agent")
  hl.exec_cmd("pypr &")
  hl.exec_cmd("sleep 1.5 && awww img " .. vars.wallpaper)
end)

-- ── Environment variables ─────────────────────────────────────────────────
hl.env("NIXOS_OZONE_WL",                    "1")
hl.env("NIXPKGS_ALLOW_UNFREE",              "1")
hl.env("XDG_CURRENT_DESKTOP",               "Hyprland")
hl.env("XDG_SESSION_TYPE",                  "wayland")
hl.env("XDG_SESSION_DESKTOP",               "Hyprland")
hl.env("GDK_BACKEND",                       "wayland,x11")
hl.env("CLUTTER_BACKEND",                   "wayland")
hl.env("QT_QPA_PLATFORM",                   "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",       "1")
hl.env("SDL_VIDEODRIVER",                   "x11")
hl.env("MOZ_ENABLE_WAYLAND",                "1")
-- Nvidia
--hl.env("LIBVA_DRIVER_NAME",                 "nvidia")
--hl.env("__GLX_VENDOR_LIBRARY_NAME",         "Nvidia")
--hl.env("__GL_VRR_ALLOWED",                  "1")
--hl.env("WLR_NO_HARDWARE_CURSORS",           "1")
--hl.env("WLR_DRM_NO_ATOMIC",                 "1")
--hl.env("ELECTRON_OZONE_PLATFORM_HINT",      "auto")

-- ── Monitors ─────────────────────────────────────────────────────────────
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
for _, m in ipairs(vars.monitors) do
  hl.monitor({ output = m.output, mode = m.mode, position = m.position, scale = m.scale, transform = m.transform, bitdepth = 10, cm = m.colorPreset})
end

-- ── Settings ─────────────────────────────────────────────────────────────
hl.config({
  general = {
    gaps_in            = 6,
    gaps_out           = 8,
    border_size        = 2,
    resize_on_border   = true,
    layout             = "dwindle",
    col = {
      active_border   = { colors = { "rgba(" .. vars.accent1 .. "ff)", "rgba(" .. vars.accent0 .. "ff)" }, angle = 45 },
      inactive_border = vars.inactiveBorder,
    },
  },
  input = {
    kb_layout  = "us",
    kb_variant = vars.kbVariant,
    kb_options = "grp:alt_caps_toggle,caps:super",
    numlock_by_default = true,
    repeat_delay       = 300,
    follow_mouse       = 1,
    sensitivity        = 0,
    touchpad = {
      natural_scroll       = true,
      disable_while_typing = true,
      scroll_factor        = 0.8,
    },
  },
  misc = {
    layers_hog_keyboard_focus  = true,
    initial_workspace_tracking = 0,
    mouse_move_enables_dpms    = true,
    key_press_enables_dpms     = false,
    disable_splash_rendering   = true,
    disable_hyprland_logo      = true,
  },
  dwindle = {
    preserve_split = true,
  },
  decoration = {
    rounding = 10,
    blur = {
      enabled           = true,
      size              = 5,
      passes            = 3,
      ignore_opacity    = false,
      new_optimizations = true,
    },
    shadow = {
      enabled      = true,
      range        = 4,
      render_power = 3,
      color        = 0xee1a1a1a,
    },
  },
  binds = {
    workspace_back_and_forth = true,
    allow_workspace_cycles   = true,
  },
})

-- ── Animations ───────────────────────────────────────────────────────────
hl.curve("wind",   { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.05} } })
hl.curve("winIn",  { type = "bezier", points = { {0.1,  1.1},  {0.1,  1.1 } } })
hl.curve("winOut", { type = "bezier", points = { {0.3, -0.3},  {0,    1   } } })
hl.curve("liner",  { type = "bezier", points = { {1,    1  },  {1,    1   } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 6,  bezier = "wind",    style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6,  bezier = "winIn",   style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,  bezier = "winOut",  style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,  bezier = "wind",    style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 1,  bezier = "liner"                   })
hl.animation({ leaf = "fade",        enabled = true, speed = 10, bezier = "default"                 })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,  bezier = "wind"                    })

-- ── Host-specific hardware settings ──────────────────────────────────────
for section, opts in pairs(vars.hardware) do
  hl.config({ [section] = opts })
end

-- ── Keybinds ─────────────────────────────────────────────────────────────
-- Described binds: one source for both the compositor binds and the rofi cheat
-- sheet (`list-keybinds`). Native lua binds are opaque to `hyprctl binds` (they
-- serialise as `__lua`), so these `h` strings are the only description source.
-- Each row is { k = keys, d = dispatch, h = help }.
local keybinds = {
  -- Applications
  { k = "SUPER + Return",         d = hl.dsp.exec_cmd(vars.terminal),                                    h = "Terminal" },
  { k = "SUPER + SHIFT + Return", d = hl.dsp.exec_cmd("pypr toggle term"),                               h = "Dropdown terminal" },
  { k = "SUPER + D",              d = hl.dsp.exec_cmd("rofi-launcher"),                                  h = "App launcher" },
  { k = "SUPER + SHIFT + W",      d = hl.dsp.exec_cmd("web-search"),                                     h = "Web search" },
  { k = "SUPER + ALT + W",        d = hl.dsp.exec_cmd("wallsetter-visual"),                              h = "Wallpaper picker" },
  { k = "SUPER + SHIFT + N",      d = hl.dsp.exec_cmd("swaync-client -rs"),                              h = "Reload notifications" },
  { k = "SUPER + W",              d = hl.dsp.exec_cmd(vars.browser),                                     h = "Browser" },
  { k = "SUPER + E",              d = hl.dsp.exec_cmd("emopicker9000"),                                  h = "Emoji picker" },
  { k = "SUPER + S",              d = hl.dsp.exec_cmd("screenshootin"),                                  h = "Screenshot" },
  { k = "SUPER + SHIFT + D",      d = hl.dsp.exec_cmd("vesktop --enable-features=WebRTCPipeWireCapturer"), h = "Discord" },
  { k = "SUPER + O",              d = hl.dsp.exec_cmd("obs"),                                            h = "OBS" },
  { k = "SUPER + C",              d = hl.dsp.exec_cmd("hyprpicker -a"),                                  h = "Color picker" },
  { k = "SUPER + G",              d = hl.dsp.exec_cmd("gamemode"),                                       h = "Toggle gamemode" },
  { k = "SUPER + T",              d = hl.dsp.exec_cmd("thunar"),                                         h = "File manager" },
  { k = "SUPER + SHIFT + T",      d = hl.dsp.exec_cmd("pypr toggle thunar"),                             h = "Dropdown file manager" },
  { k = "SUPER + M",              d = hl.dsp.exec_cmd("pavucontrol"),                                    h = "Audio mixer" },
  { k = "SUPER + P",              d = hl.dsp.exec_cmd("pypr toggle volume"),                             h = "Volume panel" },
  -- Window management
  { k = "SUPER + Q",              d = hl.dsp.window.close(),                                             h = "Close window" },
  { k = "SUPER + SHIFT + P",      d = hl.dsp.layout("dwindle:toggle_pseudo"),                            h = "Toggle pseudo-tile" },
  { k = "SUPER + SHIFT + I",      d = hl.dsp.layout("dwindle:toggle_split"),                             h = "Toggle split direction" },
  { k = "SUPER + F",              d = hl.dsp.window.fullscreen(),                                        h = "Fullscreen" },
  { k = "SUPER + CTRL + B",       d = hl.dsp.exec_cmd("pkill -SIGUSR1 waybar || waybar"),                h = "Toggle waybar" },
  { k = "SUPER + CTRL + F",       d = hl.dsp.window.float({ action = "toggle" }),                        h = "Toggle floating" },
  { k = "SUPER + CTRL + C",       d = hl.dsp.exit(),                                                     h = "Exit Hyprland" },
  -- Move window (vim motions)
  { k = "SUPER + CTRL + H",       d = hl.dsp.window.move({ direction = "left"  }),                       h = "Move window left" },
  { k = "SUPER + CTRL + L",       d = hl.dsp.window.move({ direction = "right" }),                       h = "Move window right" },
  { k = "SUPER + CTRL + K",       d = hl.dsp.window.move({ direction = "up"    }),                       h = "Move window up" },
  { k = "SUPER + CTRL + J",       d = hl.dsp.window.move({ direction = "down"  }),                       h = "Move window down" },
  -- Resize window (vim motions)
  { k = "SUPER + SHIFT + H",      d = hl.dsp.window.resize({ x = -30, y = 0   }),                        h = "Resize window left" },
  { k = "SUPER + SHIFT + L",      d = hl.dsp.window.resize({ x =  30, y = 0   }),                        h = "Resize window right" },
  { k = "SUPER + SHIFT + K",      d = hl.dsp.window.resize({ x = 0,   y = -30 }),                        h = "Resize window up" },
  { k = "SUPER + SHIFT + J",      d = hl.dsp.window.resize({ x = 0,   y =  30 }),                        h = "Resize window down" },
  -- Focus (vim motions)
  { k = "SUPER + H",              d = hl.dsp.focus({ direction = "left"  }),                             h = "Focus left" },
  { k = "SUPER + L",              d = hl.dsp.focus({ direction = "right" }),                             h = "Focus right" },
  { k = "SUPER + K",              d = hl.dsp.focus({ direction = "up"    }),                             h = "Focus up" },
  { k = "SUPER + J",              d = hl.dsp.focus({ direction = "down"  }),                             h = "Focus down" },
}
for _, b in ipairs(keybinds) do hl.bind(b.k, b.d) end
-- Move windows (arrow keys)
hl.bind("SUPER + CTRL + left",    hl.dsp.window.move({ direction = "left"  }))
hl.bind("SUPER + CTRL + right",   hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + CTRL + up",      hl.dsp.window.move({ direction = "up"    }))
hl.bind("SUPER + CTRL + down",    hl.dsp.window.move({ direction = "down"  }))
-- Resize windows (arrow keys)
hl.bind("SUPER + SHIFT + left",   hl.dsp.window.resize({ x = -30, y = 0   }))
hl.bind("SUPER + SHIFT + right",  hl.dsp.window.resize({ x =  30, y = 0   }))
hl.bind("SUPER + SHIFT + up",     hl.dsp.window.resize({ x = 0,   y = -30 }))
hl.bind("SUPER + SHIFT + down",   hl.dsp.window.resize({ x = 0,   y =  30 }))
-- Focus (arrow keys)
hl.bind("SUPER + left",           hl.dsp.focus({ direction = "left"  }))
hl.bind("SUPER + right",          hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up",             hl.dsp.focus({ direction = "up"    }))
hl.bind("SUPER + down",           hl.dsp.focus({ direction = "down"  }))
-- Workspace focus
hl.bind("SUPER + code:10",        hl.dsp.focus({ workspace = 1  }))
hl.bind("SUPER + code:11",        hl.dsp.focus({ workspace = 2  }))
hl.bind("SUPER + code:12",        hl.dsp.focus({ workspace = 3  }))
hl.bind("SUPER + code:13",        hl.dsp.focus({ workspace = 4  }))
hl.bind("SUPER + code:14",        hl.dsp.focus({ workspace = 5  }))
hl.bind("SUPER + code:15",        hl.dsp.focus({ workspace = 6  }))
hl.bind("SUPER + code:16",        hl.dsp.focus({ workspace = 7  }))
hl.bind("SUPER + code:17",        hl.dsp.focus({ workspace = 8  }))
hl.bind("SUPER + code:18",        hl.dsp.focus({ workspace = 9  }))
hl.bind("SUPER + code:19",        hl.dsp.focus({ workspace = 10 }))
hl.bind("SUPER + CTRL + SPACE",   hl.dsp.window.move({ workspace = "special" }))
hl.bind("SUPER + SPACE",          hl.dsp.workspace.toggle_special())
-- Move window to workspace
hl.bind("SUPER + SHIFT + code:10", hl.dsp.window.move({ workspace = 1  }))
hl.bind("SUPER + SHIFT + code:11", hl.dsp.window.move({ workspace = 2  }))
hl.bind("SUPER + SHIFT + code:12", hl.dsp.window.move({ workspace = 3  }))
hl.bind("SUPER + SHIFT + code:13", hl.dsp.window.move({ workspace = 4  }))
hl.bind("SUPER + SHIFT + code:14", hl.dsp.window.move({ workspace = 5  }))
hl.bind("SUPER + SHIFT + code:15", hl.dsp.window.move({ workspace = 6  }))
hl.bind("SUPER + SHIFT + code:16", hl.dsp.window.move({ workspace = 7  }))
hl.bind("SUPER + SHIFT + code:17", hl.dsp.window.move({ workspace = 8  }))
hl.bind("SUPER + SHIFT + code:18", hl.dsp.window.move({ workspace = 9  }))
hl.bind("SUPER + SHIFT + code:19", hl.dsp.window.move({ workspace = 10 }))
-- Move window to workspace silently
hl.bind("SUPER + CTRL + code:10",  hl.dsp.window.move({ workspace = 1,  follow = false }))
hl.bind("SUPER + CTRL + code:11",  hl.dsp.window.move({ workspace = 2,  follow = false }))
hl.bind("SUPER + CTRL + code:12",  hl.dsp.window.move({ workspace = 3,  follow = false }))
hl.bind("SUPER + CTRL + code:13",  hl.dsp.window.move({ workspace = 4,  follow = false }))
hl.bind("SUPER + CTRL + code:14",  hl.dsp.window.move({ workspace = 5,  follow = false }))
hl.bind("SUPER + CTRL + code:15",  hl.dsp.window.move({ workspace = 6,  follow = false }))
hl.bind("SUPER + CTRL + code:16",  hl.dsp.window.move({ workspace = 7,  follow = false }))
hl.bind("SUPER + CTRL + code:17",  hl.dsp.window.move({ workspace = 8,  follow = false }))
hl.bind("SUPER + CTRL + code:18",  hl.dsp.window.move({ workspace = 9,  follow = false }))
hl.bind("SUPER + CTRL + code:19",  hl.dsp.window.move({ workspace = 10, follow = false }))
-- Scroll through workspaces
hl.bind("SUPER + mouse_down",      hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",        hl.dsp.focus({ workspace = "e-1" }))
-- Window cycling
hl.bind("ALT + Tab",               hl.dsp.window.cycle_next())
hl.bind("ALT + Tab",               hl.dsp.window.bring_to_top())
-- Media keys
hl.bind("XF86AudioRaiseVolume",    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume",    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute",           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioPlay",           hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPause",          hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext",           hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev",           hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86MonBrightnessDown",   hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("XF86MonBrightnessUp",     hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("SUPER + Prior",           hl.dsp.exec_cmd("ddcutil --bus 12 setvcp 10 + 10 & ddcutil --bus 11 setvcp 10 + 23 & ddcutil --bus 9 setvcp 10 + 23"))
hl.bind("SUPER + Next",            hl.dsp.exec_cmd("ddcutil --bus 12 setvcp 10 - 10 & ddcutil --bus 11 setvcp 10 - 23 & ddcutil --bus 9 setvcp 10 - 23"))
-- Mouse binds
hl.bind("SUPER + mouse:272",       hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273",       hl.dsp.window.resize(), { mouse = true })

-- ── Keybind cheat sheet ──────────────────────────────────────────────────
-- SUPER + / opens the sheet in rofi. The file below is regenerated on every
-- load/`hyprctl reload` from the described `keybinds` table plus these summary
-- rows for the repetitive literal binds (workspaces, arrows, media). Keep these
-- rows in sync when the literal binds change; the described binds are automatic.
hl.bind("SUPER + slash", hl.dsp.exec_cmd("list-keybinds"))

local keybinds_help = {
  { k = "SUPER + /",               h = "This cheat sheet" },
  { k = "SUPER + [1-0]",           h = "Focus workspace 1-10" },
  { k = "SUPER + SHIFT + [1-0]",   h = "Move window to workspace" },
  { k = "SUPER + CTRL + [1-0]",    h = "Move window to workspace (silent)" },
  { k = "SUPER + SPACE",           h = "Toggle special workspace" },
  { k = "SUPER + CTRL + SPACE",    h = "Move window to special workspace" },
  { k = "SUPER + arrows",          h = "Focus (same as h/j/k/l)" },
  { k = "SUPER + scroll",          h = "Cycle workspaces" },
  { k = "ALT + Tab",               h = "Cycle windows" },
  { k = "SUPER + drag / rclick",   h = "Move / resize floating window" },
  { k = "Media / brightness keys", h = "Volume, playback, backlight" },
}

do
  local home = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
  local f = io.open(home .. "/hypr-keybinds.txt", "w")
  if f then
    for _, b in ipairs(keybinds) do
      f:write(string.format("%-30s  %s\n", b.k, b.h))
    end
    for _, b in ipairs(keybinds_help) do
      f:write(string.format("%-30s  %s\n", b.k, b.h))
    end
    f:close()
  end
end

-- ── Window rules ─────────────────────────────────────────────────────────
-- Tag assignments
hl.window_rule({ name = "windowrule-1",  tag = "+file-manager",
  match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" } })
hl.window_rule({ name = "windowrule-2",  tag = "+terminal",
  match = { class = "^(Alacritty|kitty|kitty-dropterm)$" } })
hl.window_rule({ name = "windowrule-3",  tag = "+browser",
  match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" } })
hl.window_rule({ name = "windowrule-4",  tag = "+browser",
  match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$" } })
hl.window_rule({ name = "windowrule-5",  tag = "+browser",
  match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" } })
hl.window_rule({ name = "windowrule-6",  tag = "+browser",
  match = { class = "^([Zz]en(-browser)?(-beta)?)$" } })
hl.window_rule({ name = "windowrule-7",  tag = "+browser",
  match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" } })
hl.window_rule({ name = "windowrule-8",  tag = "+projects",
  match = { class = "^(codium|codium-url-handler|VSCodium)$" } })
hl.window_rule({ name = "windowrule-9",  tag = "+projects",
  match = { class = "^(VSCode|code-url-handler)$" } })
hl.window_rule({ name = "windowrule-10", tag = "+im",
  match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" } })
hl.window_rule({ name = "windowrule-11", tag = "+im", center = true, float = true,
  size = { "monitor_w*0.6", "monitor_h*0.7" },
  match = { class = "^([Ff]erdium)$" } })
hl.window_rule({ name = "windowrule-12", tag = "+im",
  match = { class = "^([Ww]hatsapp-for-linux)$" } })
hl.window_rule({ name = "windowrule-13", tag = "+im",
  match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" } })
hl.window_rule({ name = "windowrule-14", tag = "+im",
  match = { class = "^(teams-for-linux)$" } })
hl.window_rule({ name = "windowrule-15", tag = "+games",
  match = { class = "^(gamescope)$" } })
hl.window_rule({ name = "windowrule-16", tag = "+games",
  match = { class = "^(steam_app_d+)$" } })
hl.window_rule({ name = "windowrule-17", tag = "+gamestore",
  match = { class = "^([Ss]team)$" } })
hl.window_rule({ name = "windowrule-18", tag = "+gamestore",
  match = { title = "^([Ll]utris)$" } })
hl.window_rule({ name = "windowrule-19", tag = "+gamestore",
  match = { class = "^(com.heroicgameslauncher.hgl)$" } })
hl.window_rule({ name = "windowrule-20", tag = "+settings",
  match = { class = "^(gnome-disks|wihotspot(-gui)?)$" } })
hl.window_rule({ name = "windowrule-21", tag = "+settings",
  match = { class = "^([Rr]ofi)$" } })
hl.window_rule({ name = "windowrule-22", tag = "+settings",
  match = { class = "^(file-roller|org.gnome.FileRoller)$" } })
hl.window_rule({ name = "windowrule-23", tag = "+settings",
  match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" } })
hl.window_rule({ name = "windowrule-24", tag = "+settings", center = true,
  match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" } })
hl.window_rule({ name = "windowrule-25", tag = "+settings",
  match = { class = "^(nwg-look|qt5ct|qt6ct|[Yy]ad)$" } })
hl.window_rule({ name = "windowrule-26", tag = "+settings",
  match = { class = "(xdg-desktop-portal-gtk)" } })
-- Picture-in-Picture
hl.window_rule({ name = "windowrule-27",
  move = { "monitor_w*0.72", "monitor_h*0.07" }, float = true,
  opacity = "0.95 0.75", pin = true, keep_aspect_ratio = true,
  match = { title = "^(Picture-in-Picture)$" } })
-- Thunar dialogs (float non-main windows)
hl.window_rule({ name = "windowrule-28", center = true, float = true,
  match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" } })
-- Authentication dialogs
hl.window_rule({ name = "windowrule-29", center = true, float = true,
  match = { title = "^(Authentication Required)$" } })
-- Idle inhibit for fullscreen
hl.window_rule({ name = "windowrule-30", idle_inhibit = "fullscreen",
  match = { class = "^(*)$" } })
hl.window_rule({ name = "windowrule-31", idle_inhibit = "fullscreen",
  match = { title = "^(*)$" } })
hl.window_rule({ name = "windowrule-32", idle_inhibit = "fullscreen",
  match = { fullscreen = 1 } })
-- Float + size settings windows
hl.window_rule({ name = "windowrule-33", float = true,
  size = { "monitor_w*0.7", "monitor_h*0.7" },
  opacity = "0.8 0.7",
  match = { tag = "settings*" } })
hl.window_rule({ name = "windowrule-34", float = true,
  match = { class = "^(mpv|com.github.rafostar.Clapper)$" } })
hl.window_rule({ name = "windowrule-35", float = true,
  match = { class = "(codium|codium-url-handler|VSCodium)",
            title = "negative:(.*codium.*|.*VSCodium.*)" } })
hl.window_rule({ name = "windowrule-36", float = true,
  match = { class = "^(com.heroicgameslauncher.hgl)$",
            title = "negative:(Heroic Games Launcher)" } })
hl.window_rule({ name = "windowrule-37", float = true,
  match = { class = "^([Ss]team)$",
            title = "negative:^([Ss]team)$" } })
hl.window_rule({ name = "windowrule-38", float = true,
  size = { "monitor_w*0.7", "monitor_h*0.6" },
  match = { initial_title = "(Add Folder to Workspace)" } })
hl.window_rule({ name = "windowrule-39", float = true,
  size = { "monitor_w*0.7", "monitor_h*0.6" },
  match = { initial_title = "(Open Files)" } })
hl.window_rule({ name = "windowrule-40", float = true,
  match = { initial_title = "(wants to save)" } })
-- Opacity by tag
hl.window_rule({ name = "windowrule-41",
  opacity = "1.0 1.0",  match = { tag = "browser*"      } })
hl.window_rule({ name = "windowrule-42",
  opacity = "0.9 0.8",  match = { tag = "projects*"     } })
hl.window_rule({ name = "windowrule-43",
  opacity = "0.94 0.86", match = { tag = "im*"           } })
hl.window_rule({ name = "windowrule-44",
  opacity = "0.9 0.8",  match = { tag = "file-manager*" } })
hl.window_rule({ name = "windowrule-45",
  opacity = "0.8 0.7",  match = { tag = "terminal*"     } })
hl.window_rule({ name = "windowrule-46",
  opacity = "0.8 0.7",
  match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" } })
hl.window_rule({ name = "windowrule-47",
  opacity = "0.9 0.8",
  match = { class = "^(seahorse)$" } })
-- Games: no blur, force fullscreen
hl.window_rule({ name = "windowrule-48", no_blur = true, fullscreen = true,
  match = { tag = "games*" } })
-- Workspace assignments
hl.window_rule({ name = "windowrule-49", workspace = 2, match = { tag = "browser"   } })
hl.window_rule({ name = "windowrule-50", workspace = 5, match = { tag = "games"     } })
hl.window_rule({ name = "windowrule-51", workspace = 5, match = { tag = "gamestore" } })
hl.window_rule({ name = "windowrule-52", workspace = 7, match = { tag = "im"        } })
