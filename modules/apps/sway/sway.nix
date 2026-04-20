{ pkgs, lib, ... }:
let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot-wayland";
    runtimeInputs = [ pkgs.grim pkgs.slurp ];
    text = builtins.readFile (pkgs.replaceVars ./scripts/screenshot-wayland.sh {
      carpeta_pantallazo = "/home/aletheios42/Multimedia/Imagenes/Pantallazos";
    });
  };
  toggle-record = pkgs.writeShellApplication {
    name = "toggle-record-wayland";
    runtimeInputs = [ pkgs.wf-recorder pkgs.slurp ];
    text = builtins.readFile (pkgs.replaceVars ./scripts/toggle-record-wayland.sh {
      carpeta_grabaciones = "/home/aletheios42/Multimedia/Videos/Grabaciones";
    });
  };
in
{
  programs.sway.enable = true;
  programs.waybar.enable = true;
  programs.sway.extraPackages = [
    pkgs.rofi pkgs.swaylock pkgs.wl-clipboard pkgs.brightnessctl
    screenshot toggle-record
  ];

  environment.etc."sway/config".text = ''
    set $mod Mod4
    set $terminal kitty
    set $menu rofi -show drun

    input type:keyboard {
        xkb_layout es
        repeat_delay 250
        repeat_rate 50
    }

    output * bg #000000 solid_color

    bar {
        status_command ${pkgs.waybar}/bin/waybar
    }

    bindsym $mod+Return exec $terminal
    bindsym $mod+d exec $menu

    bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%+
    bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-
    bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

    bindsym XF86MonBrightnessUp exec brightnessctl set +5%
    bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

    bindsym $mod+Escape exec swaylock -f -c 000000

    bindsym $mod+Print exec screenshot-wayland
    bindsym $mod+Shift+Print exec toggle-record-wayland
  '';
}
