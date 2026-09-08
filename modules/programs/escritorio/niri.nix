{ pkgs, lib, config, ... }:
let
  binds = ''
    binds {
      // Aplicaciones
      Mod+Return { spawn "kitty"; }
      Mod+Print { spawn "kooha"; }

      // Ventanas
      Mod+Q { close-window; }
      Mod+F { fullscreen-window; }
      Mod+Space { switch-focus-between-floating-and-tiling; }
      Mod+n { spawn "noctalia" "msg" "bar-toggle"; }

      // Movimiento del foco
      Mod+H { focus-column-left; }
      Mod+J { focus-window-down; }
      Mod+K { focus-window-up; }
      Mod+L { focus-column-right; }
      Mod+Left { focus-column-left; }
      Mod+Down { focus-window-down; }
      Mod+Up { focus-window-up; }
      Mod+Right { focus-column-right; }

      // Mover ventanas
      Mod+Shift+H { move-column-left; }
      Mod+Shift+J { move-window-down; }
      Mod+Shift+K { move-window-up; }
      Mod+Shift+L { move-column-right; }
      Mod+Shift+Left { move-column-left; }
      Mod+Shift+Down { move-window-down; }
      Mod+Shift+Up { move-window-up; }
      Mod+Shift+Right { move-column-right; }

      // Monitores
      Mod+Ctrl+H { focus-monitor-left; }
      Mod+Ctrl+L { focus-monitor-right; }
      Mod+Ctrl+Shift+H { move-column-to-monitor-left; }
      Mod+Ctrl+Shift+L { move-column-to-monitor-right; }

      // Workspaces
      ${lib.concatMapStringsSep "\n      " (n: ''Mod+${toString n} { focus-workspace ${toString n}; }'') (lib.range 1 9)}
      Mod+0 { focus-workspace 10; }
      ${lib.concatMapStringsSep "\n      " (n: ''Mod+Shift+${toString n} { move-column-to-workspace ${toString n}; }'') (lib.range 1 9)}
      Mod+Shift+0 { move-column-to-workspace 10; }

      // Audio
      XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "3%+"; }
      XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "3%-"; }
      XF86AudioMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86AudioMicMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

      // Brillo
      XF86MonBrightnessUp { spawn "brightnessctl" "set" "+5%"; }
      XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
    }
  '';

  configKdl = ''
    // Generado por Nix. No editar a mano: /etc/niri/config.kdl (fallback de niri)
    prefer-no-csd

    input {
      keyboard {
        xkb {
          layout "es"
        }
        repeat-delay 250
        repeat-rate 50
      }

      focus-follows-mouse
    }

    layout {
      border {
        on
        width 2
        active-color "#4c7899"
        inactive-color "#333333"
      }

      focus-ring {
        off
      }
    }

    spawn-at-startup "${pkgs.dbus}/bin/dbus-update-activation-environment" "--systemd" "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "XDG_SESSION_TYPE" "NIXOS_OZONE_WL" "XCURSOR_THEME" "XCURSOR_SIZE"
    ${lib.optionalString config.escritorio.noctalia ''
      spawn-at-startup "noctalia"
      spawn-at-startup "sh" "-c" "sleep 2 && noctalia msg wallpaper-set /nix/store/pc3lfxmg4l7b45wwfdadr3zsknzjmcb7-source/resources/fondo.jpg"
    ''}

    ${binds}
  '';
in
{
  options.escritorio.niri = lib.mkEnableOption "Activa niri";

  config = lib.mkIf config.escritorio.niri {
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri;
    environment.etc."niri/config.kdl".text = configKdl;
    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          { directory = ".config/niri"; mode = "0755"; }
          { directory = ".cache/niri"; mode = "0755"; }
        ];
      };
  };
}
