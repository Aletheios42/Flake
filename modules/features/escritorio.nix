{ pkgs, lib, config, ... }:
let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot-wayland";
    runtimeInputs = [ pkgs.grim pkgs.slurp ];
    text = builtins.readFile (pkgs.replaceVars ../scripts/screenshot-wayland.sh {
      carpeta_pantallazo = "/home/aletheios42/Multimedia/Imagenes/Pantallazos";
    });
  };
  toggle-record = pkgs.writeShellApplication {
    name = "toggle-record-wayland";
    runtimeInputs = [ pkgs.wf-recorder pkgs.slurp ];
    text = builtins.readFile (pkgs.replaceVars ../scripts/toggle-record-wayland.sh {
      carpeta_grabaciones = "/home/aletheios42/Multimedia/Videos/Grabaciones";
    });
  };
in
{
  options.escritorio = {
    enable = lib.mkEnableOption "activar sway o niri";
    tailing = lib.mkOption {
      type = lib.types.enum [ "sway" "niri" ];
      default = "sway";
      description = "Activa sway o niri";
    };
  };

  config = lib.mkIf (config.escritorio.enable) (lib.mkMerge [
    {
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-gtk ];
      };
    }
    (lib.mkIf (config.escritorio.tailing == "sway") {
      programs.sway.enable = true;
      programs.waybar.enable = true;
      programs.sway.extraPackages = [
        pkgs.rofi pkgs.swaylock pkgs.wl-clipboard pkgs.brightnessctl
        screenshot toggle-record
      ];
      environment.etc."sway/config".text = ''
      font pango:monospace 8.000000
      floating_modifier Mod4

      default_border normal 2
      default_floating_border normal 4
      hide_edge_borders none
      focus_wrapping no
      focus_follows_mouse yes
      focus_on_window_activation smart
      mouse_warping output
      workspace_layout default
      workspace_auto_back_and_forth no

      client.focused #4c7899 #285577 #ffffff #2e9ef4 #285577
      client.focused_inactive #333333 #5f676a #ffffff #484e50 #5f676a
      client.unfocused #333333 #222222 #888888 #292d2e #222222
      client.urgent #2f343a #900000 #ffffff #900000 #900000
      client.placeholder #000000 #0c0c0c #ffffff #000000 #0c0c0c
      client.background #ffffff

      bindsym Mod4+0 workspace number 10
      bindsym Mod4+1 workspace number 1
      bindsym Mod4+2 workspace number 2
      bindsym Mod4+3 workspace number 3
      bindsym Mod4+4 workspace number 4
      bindsym Mod4+5 workspace number 5
      bindsym Mod4+6 workspace number 6
      bindsym Mod4+7 workspace number 7
      bindsym Mod4+8 workspace number 8
      bindsym Mod4+9 workspace number 9
      bindsym Mod4+Escape exec swaylock -f -c 000000
      bindsym Mod4+Print exec screenshot-wayland
      bindsym Mod4+Return exec kitty
      bindsym Mod4+f fullscreen toggle
      bindsym Mod4+e layout toggle split

      bindsym Mod4+Shift+0 move container to workspace number 10
      bindsym Mod4+Shift+1 move container to workspace number 1
      bindsym Mod4+Shift+2 move container to workspace number 2
      bindsym Mod4+Shift+3 move container to workspace number 3
      bindsym Mod4+Shift+4 move container to workspace number 4
      bindsym Mod4+Shift+5 move container to workspace number 5
      bindsym Mod4+Shift+6 move container to workspace number 6
      bindsym Mod4+Shift+7 move container to workspace number 7
      bindsym Mod4+Shift+8 move container to workspace number 8
      bindsym Mod4+Shift+9 move container to workspace number 9

      bindsym Mod4+Shift+Down move down
      bindsym Mod4+Shift+Left move left
      bindsym Mod4+Shift+Right move right
      bindsym Mod4+Shift+Up move up
      bindsym Mod4+Down focus down
      bindsym Mod4+Left focus left

      bindsym Mod4+Shift+c reload
      bindsym Mod4+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'

      bindsym Mod4+Shift+h move left
      bindsym Mod4+Shift+j move down
      bindsym Mod4+Shift+k move up
      bindsym Mod4+Shift+l move right
      bindsym Mod4+Shift+minus move scratchpad
      bindsym Mod4+Shift+q kill
      bindsym Mod4+Shift+space floating toggle
      bindsym Mod4+Up focus up
      bindsym Mod4+a focus parent
      bindsym Mod4+b splith
      bindsym Mod4+v splitv
      bindsym Mod4+d exec rofi -show drun
      bindsym Mod4+h focus left
      bindsym Mod4+j focus down
      bindsym Mod4+k focus up
      bindsym Mod4+l focus right
      bindsym Mod4+minus scratchpad show
      bindsym Mod4+r mode resize
      bindsym Mod4+s layout stacking
      bindsym Mod4+shift+Print exec toggle-record-wayland
      bindsym Mod4+space focus mode_toggle
      bindsym Mod4+w layout tabbed

      bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-
      bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%+
      bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
      bindsym XF86MonBrightnessUp exec brightnessctl set +5%

      input "type:keyboard" {
        repeat_delay 250
        repeat_rate 50
        xkb_layout es
      }

      output "*" {
        bg #000000 solid_color
      }

      mode "resize" {
        bindsym Down resize grow height 10 px
        bindsym Escape mode default
        bindsym Left resize shrink width 10 px
        bindsym Return mode default
        bindsym Right resize grow width 10 px
        bindsym Up resize shrink height 10 px
        bindsym h resize shrink width 10 px
        bindsym j resize grow height 10 px
        bindsym k resize shrink height 10 px
        bindsym l resize grow width 10 px
      }

      exec "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE; systemctl --user reset-failed && systemctl --user start sway-session.target && swaymsg -mt subscribe '[]' || true && systemctl --user stop sway-session.target"
      '';
    })
    (lib.mkIf (config.escritorio.tailing == "niri") {
      programs.niri.enable = true;
    })
  ]);
}
