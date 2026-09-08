{ pkgs, lib, config, ... }:
let
  keybindings = ''
    # Terminal
    bind=SUPER,Return,spawn,kitty
    # Fullscreen
    bind=SUPER,F,togglefullscreen
    # Split / layout
    bind=SUPER,E,switch_layout
    # Focus
    bind=SUPER,H,focusdir,left
    bind=SUPER,J,focusdir,down
    bind=SUPER,K,focusdir,up
    bind=SUPER,L,focusdir,right
    bind=SUPER,Left,focusdir,left
    bind=SUPER,Down,focusdir,down
    bind=SUPER,Up,focusdir,up
    bind=SUPER,Right,focusdir,right
    # Move
    bind=SUPER+SHIFT,H,exchange_client,left
    bind=SUPER+SHIFT,J,exchange_client,down
    bind=SUPER+SHIFT,K,exchange_client,up
    bind=SUPER+SHIFT,L,exchange_client,right
    bind=SUPER+SHIFT,Left,exchange_client,left
    bind=SUPER+SHIFT,Down,exchange_client,down
    bind=SUPER+SHIFT,Up,exchange_client,up
    bind=SUPER+SHIFT,Right,exchange_client,right
    # Floating
    bind=SUPER+SHIFT,Space,togglefloating
    # Kill
    bind=SUPER+SHIFT,Q,killclient
    # Scratchpad
    bind=SUPER,Minus,toggle_scratchpad
    bind=SUPER+SHIFT,Minus,minimized
    # Layouts
    bind=SUPER,S,setlayout,tile
    bind=SUPER,W,setlayout,monocle
    # Resize
    bind=SUPER,R,setkeymode,resize
    # Screenshot
    bind=SUPER,Print,spawn,kooha
    # Audio
    bind=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%+
    bind=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-
    bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bind=NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    # Brightness
    bind=NONE,XF86MonBrightnessUp,spawn,brightnessctl set +5%
    bind=NONE,XF86MonBrightnessDown,spawn,brightnessctl set 5%-
    # Workspaces (tags)
    ${lib.concatMapStringsSep "\n" (n: "bind=SUPER,${toString n},view,${toString n}") (lib.range 1 9)}
    bind=SUPER,0,view,10
    ${lib.concatMapStringsSep "\n" (n: "bind=SUPER+SHIFT,${toString n},tag,${toString n}") (lib.range 1 9)}
    bind=SUPER+SHIFT,0,tag,10

    keymode=resize
    bind=NONE,Left,resizewin,-10,0
    bind=NONE,Right,resizewin,+10,0
    bind=NONE,Escape,setkeymode,default
  '';

  configConf = ''
    ### Input ###
    xkb_rules_layout=es
    repeat_delay=250
    repeat_rate=50
    sloppyfocus=1

    ### Appearance ###
    borderpx=2

    ### Startup ###
    exec-once=${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE
    ${lib.optionalString config.escritorio.noctalia ''
      exec-once=noctalia
      exec=sh -c 'sleep 2 && noctalia msg wallpaper-set /nix/store/pc3lfxmg4l7b45wwfdadr3zsknzjmcb7-source/resources/fondo.jpg'
    ''}

    ### Keybindings ###
    ${keybindings}
  '';
in
  {
  options.escritorio.mango = lib.mkEnableOption "Activa mango";
  config = lib.mkIf config.escritorio.mango {
    programs.mango.enable = true;
    environment.etc."mango/config.conf".text = configConf;
    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          { directory = ".config/mango"; mode = "0755"; }
          { directory = ".cache/mango"; mode = "0755"; }
        ];
      };
  };
}
