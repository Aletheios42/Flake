{ pkgs, lib, config, ... }:
{
  options.pkm = {
    enable = lib.mkEnableOption "Activo pkm";
    dir = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "ruta del baul de notas";
    };
    obsidian = lib.mkEnableOption "obsidian";
    zk = lib.mkEnableOption "activa zk";
  };

  config = lib.mkIf config.pkm.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = builtins.match "^/.*" config.pkm.dir != null;
          message = "pkm.dir debe ser una ruta absoluta.";
        }
      ];
    }
    {
      environment.persistence."/persist".users.${config.usuarioPrincipal} =
        lib.mkIf (config.pkm.enable) {
          directories = [{directory = "Documentos/Pkm"; mode = "0755";}];
        };
    }
    (lib.mkIf config.pkm.zk {
      userPackages.pkm = [ pkgs.pandoc pkgs.typst pkgs.zk ];
      environment.variables.ZK_NOTEBOOK_DIR = config.pkm.dir;
      system.activationScripts.zkConfig = ''
      mkdir -p /home/${config.usuarioPrincipal}/Documentos/Pkm/.zk
      cat > /home/${config.usuarioPrincipal}/Documentos/Pkm/.zk/config.toml <<'EOF'
      [note]
      filename = "{{slug title}}"
      template = "default.md"

      [format.markdown]
      link-format = "wiki"
      hashtags = false
      colon-tags = false
      multiword-tags = false

      [lsp]
      [lsp.diagnostics]
      # Report titles of wiki-links as hints.
      wiki-title = "hint"
      # Warn for dead links between notes.
      dead-link = "error"
      # Warn when notes link here without backlinks.
      missing-backlink = { level = "warning", position = "bottom" }
      EOF
      chown ${config.usuarioPrincipal}:users /home/${config.usuarioPrincipal}/Documentos/Pkm/.zk/config.toml
      '';
    })
    (lib.mkIf config.pkm.obsidian {
      userPackages.pkm = [ pkgs.obsidian ];
      environment.persistence."/persist".users.${config.usuarioPrincipal} =
        lib.mkIf (config.pkm.obsidian.enable) {
          directories = [{directory = ".config/obsidian"; mode = "0755";}];
        };
    })
  ]);
}
