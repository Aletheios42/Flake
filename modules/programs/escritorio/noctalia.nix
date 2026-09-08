{ config, lib, pkgs, ... }:
let
  home = "${config.users.users.${config.usuarioPrincipal}.home}";

  noctaliaSettings = (pkgs.formats.toml { }).generate "noctalia-settings.toml" {
    theme = {
      name = "Catppuccin Mocha";
      dark = true;
      accent = {
        primary = "#cba6f7"; secondary = "#89b4fa"; tertiary = "#94e2d5";
        error = "#f38ba8"; warning = "#fab387"; success = "#a6e3a1"; info = "#89dceb";
      };
      background = {
        base = "#1e1e2e"; mantle = "#181825"; crust = "#11111b";
        surface0 = "#313244"; surface1 = "#45475a"; surface2 = "#585b70";
      };
      text = { primary = "#cdd6f4"; secondary = "#a6adc8"; tertiary = "#9399b2"; inverse = "#45475a"; };
      overlay = { overlay0 = "#6c7086"; overlay1 = "#7f849c"; overlay2 = "#9399b2"; };
      misc = {
        rosewater = "#f5e0dc"; flamingo = "#f2cdcd"; pink = "#f5c2e7"; mauve = "#cba6f7";
        red = "#f38ba8"; maroon = "#eba0ac"; peach = "#fab387"; yellow = "#f9e2af";
        green = "#a6e3a1"; teal = "#94e2d5"; sky = "#89dceb"; sapphire = "#74c7ec";
        blue = "#89b4fa"; lavender = "#b4befe";
      };
    };

    bar = [
      {
        position = "top";
        height = 36;
        spacing = 8;
        margin = { top = 6; bottom = 0; left = 8; right = 8; };
        padding = { top = 4; bottom = 4; left = 12; right = 12; };
        transparency = {
          enabled = true;
          opacity = 0.85;
          unfocused_opacity = 0.50;
          blur = true;
          blur_strength = 10;
        };
        auto_hide = false;
        hide_on_fullscreen = true;
        font = { family = "JetBrainsMono Nerd Font"; size = 13; weight = "bold"; };
        widgets = {
          start = [
            { type = "launcher_button"; icon = "󰣇"; label = ""; tooltip = "Applications"; }
            { type = "workspaces"; show_labels = false; active_color = "#cba6f7"; inactive_color = "#6c7086"; urgent_color = "#f38ba8"; }
          ];
          center = [
            { type = "clock"; format = "󰥔  %H:%M"; tooltip_format = "󰃭  %A, %d de %B"; timezone = "local"; }
          ];
          end = [
            { type = "media"; show_artist = true; show_title = true; max_length = 40; truncation = "end"; }
            { type = "system_tray"; icon_size = 18; spacing = 6; }
            { type = "notifications_button"; icon = "󰂚"; show_count = true; }
            { type = "clipboard_button"; icon = "󰅌"; tooltip = "Clipboard"; }
            { type = "network"; icon_wifi = "󰖩"; icon_ethernet = "󰈀"; icon_disconnected = "󰖪"; }
            { type = "bluetooth"; icon_on = "󰂯"; icon_off = "󰂲"; icon_connected = "󰂱"; }
            { type = "volume"; icon_high = "󰕾"; icon_medium = "󰖀"; icon_low = "󰕿"; icon_muted = "󰝟"; show_percentage = true; }
            { type = "brightness"; icon = "󰃠"; show_percentage = true; }
            { type = "battery"; icon_charging = "󰂄"; icon_full = "󰁹"; icon_high = "󰂂"; icon_medium = "󰂀"; icon_low = "󰁺"; icon_critical = "󰁻"; show_percentage = true; }
            { type = "control_center_button"; icon = "󰒓"; }
            { type = "session_button"; icon = "󰐥"; }
          ];
        };
      }
    ];

    wallpaper = {
      enabled = true;
      fill_mode = "crop";
      default = { path = "${../../../resources/fondo.jpg}"; };
    };

    modules = {
      notifications = {
        enabled = true; position = "top-right"; max_visible = 4; timeout = 5000;
        animation = "slide"; corner_radius = 12; padding = 12; width = 380;
        font = { family = "JetBrainsMono Nerd Font"; size = 12; };
        do_not_disturb = { enabled = false; icon = "󰂛"; };
        actions = { enabled = true; buttons = [ "default" "close" ]; };
      };
      launcher = {
        enabled = true; width = 600; height = 400; position = "center";
        placeholder = "Buscar aplicaciones...";
        font = { family = "JetBrainsMono Nerd Font"; title_size = 16; body_size = 13; };
        blur = { enabled = true; strength = 8; };
        transparency = { enabled = true; opacity = 0.90; };
        corner_radius = 16; show_categories = true; show_description = true;
      };
      lock_screen = {
        enabled = true;
        blur = { enabled = true; strength = 12; };
        tint = { enabled = true; color = "#1e1e2e"; opacity = 0.5; };
        clock = {
          enabled = true;
          font = { family = "JetBrainsMono Nerd Font"; time_size = 64; date_size = 18; };
          time_format = "%H:%M"; date_format = "%A, %d de %B";
        };
        user_avatar = { enabled = true; size = 96; border_color = "#cba6f7"; };
        input = {
          font = { family = "JetBrainsMono Nerd Font"; size = 14; };
          placeholder = "Contraseña"; corner_radius = 12;
          border_color = "#45475a"; active_border_color = "#cba6f7";
        };
        idle_timeout = 300;
      };
      clipboard = {
        enabled = true; history_size = 50; position = "center"; width = 500; height = 400;
        blur = { enabled = true; strength = 8; };
        transparency = { enabled = true; opacity = 0.90; };
        corner_radius = 16;
        font = { family = "JetBrainsMono Nerd Font"; size = 13; };
        item_height = 40; placeholder = "Historial vacío"; search_placeholder = "Buscar...";
      };
      osd = {
        enabled = true; position = "top-center"; duration = 1500; animation = "fade";
        corner_radius = 14;
        padding = { top = 10; bottom = 10; left = 20; right = 20; };
        font = { family = "JetBrainsMono Nerd Font"; size = 13; };
        volume = { enabled = true; };
        brightness = { enabled = true; };
        keyboard_layout = { enabled = true; };
      };
      control_center = {
        enabled = true; position = "right"; width = 380;
        blur = { enabled = true; strength = 10; };
        transparency = { opacity = 0.88; };
        corner_radius = 16;
        font = { family = "JetBrainsMono Nerd Font"; size = 12; };
        sliders = [ "volume" "brightness" ];
        toggles = [ "wifi" "bluetooth" "do_not_disturb" "night_light" "airplane_mode" ];
        shortcuts = [
          { label = "Wi-Fi"; icon = "󰖩"; action = "network"; }
          { label = "Bluetooth"; icon = "󰂯"; action = "bluetooth"; }
          { label = "Pantalla"; icon = "󰍹"; action = "display"; }
          { label = "Audio"; icon = "󰋋"; action = "audio"; }
          { label = "Notificaciones"; icon = "󰂚"; action = "notifications"; }
        ];
      };
      system_monitor = {
        enabled = true; update_interval = 1000; corner_radius = 12;
        blur = { enabled = true; strength = 8; };
        transparency = { enabled = true; opacity = 0.88; };
        font = { family = "JetBrainsMono Nerd Font"; size = 11; };
        show_cpu = true; show_memory = true; show_network = true; show_disks = true; show_processes = true;
      };
      dock = { enabled = false; };
    };
  };
in
{
  options.escritorio.noctalia = lib.mkEnableOption "Activa noctalia (shell/bar)";

  config = lib.mkIf config.escritorio.noctalia {
    services.upower.enable = true;
    userPackages.noctalia = [ pkgs.noctalia ];
    programs.noctalia.systemd.target = "graphical-session.target";
    programs.noctalia.recommendedServices.enable = true;

    system.activationScripts.noctaliaConfig = {
      text = ''
        mkdir -p ${home}/.local/state/noctalia
        ln -sf ${noctaliaSettings} ${home}/.local/state/noctalia/settings.toml
        chown -R ${config.usuarioPrincipal}:users ${home}/.local/state/noctalia
      '';
    };
    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          { directory = ".local/share/noctalia"; mode = "0755"; }
          { directory = ".local/state/noctalia"; mode = "0755"; }
          { directory = ".cache/noctalia"; mode = "0755"; }
        ];
      };
  };
}
