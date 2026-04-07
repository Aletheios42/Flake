{ pkgs, carpeta_grabaciones, carpeta_pantallazo, ... }:
{
    screenshot-x11 = pkgs.writeShellApplication {
        name = "screenshot-x11";
        runtimeInputs = [ pkgs.maim ];
        text = builtins.readFile (pkgs.replaceVars ./screenshot-x11.sh {
            carpeta_pantallazo = carpeta_pantallazo; 
        });
    };

    toggle-record-x11 = pkgs.writeShellApplication {
        name = "toggle-record-x11";
        runtimeInputs = [ pkgs.ffmpeg-full pkgs.slop ];
        text = builtins.readFile (pkgs.replaceVars ./toggle-record-x11.sh {
            carpeta_grabaciones = carpeta_grabaciones;
        });
    };

    screenshot-wayland = pkgs.writeShellApplication {
        name = "screenshot-wayland";
        runtimeInputs = [ pkgs.grim pkgs.slurp ];
        text = builtins.readFile (pkgs.replaceVars ./screenshot-wayland.sh {
            carpeta_pantallazo = carpeta_pantallazo; 
        });
    };

    toggle-record-wayland = pkgs.writeShellApplication {
        name = "toggle-record-wayland";
        runtimeInputs = [ pkgs.wf-recorder pkgs.slurp ];
        text = builtins.readFile (pkgs.replaceVars ./toggle-record-wayland.sh {
            carpeta_grabaciones = carpeta_grabaciones; 
        });
    };

  tree-cat = pkgs.writeShellApplication {
    name = "tree-cat";
    runtimeInputs = [ pkgs.tree ];
    text = builtins.readFile ./tree-cat.sh;
  };
}
