{ pkgs, lib, config, ... }:
let
  user = config.usuarioPrincipal;
  home = config.users.users.${config.usuarioPrincipal}.home;
in
{
  options.ai.llama = {
    fim = {
      enable = lib.mkEnableOption "llama-server FIM (siempre on, modelo ligero)";
      host   = lib.mkOption { type = lib.types.str; default = "127.0.0.1"; };
      port   = lib.mkOption { type = lib.types.port; default = 8080; };
      model  = lib.mkOption { type = lib.types.str; default = "qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"; };
    };
    work = {
      enable = lib.mkEnableOption "llama-server trabajo (toggle manual via systemctl)";
      host   = lib.mkOption { type = lib.types.str; default = "127.0.0.1"; };
      port   = lib.mkOption { type = lib.types.port; default = 8081; };
      model  = lib.mkOption { type = lib.types.str; default = "qwen2.5-coder-7b-instruct-q4_k_m.gguf"; description = "Modelo por defecto para el symlink ~/models/work-model.gguf"; };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.ai.llama.fim.enable || config.ai.llama.work.enable) {
      users.users.${user}.linger = true;
      userPackages.ai = [ pkgs.llama-cpp ];
      environment.persistence."/persist".users.${config.usuarioPrincipal} =
        lib.mkIf (config.impermanencia.enable) {
          directories = [{ directory = "/models" ; mode = "0750"; }];
        };
    })

    (lib.mkIf config.ai.llama.fim.enable {
      systemd.user.services.llama-server-fim = {
        description = "llama.cpp FIM server (lightweight, toggle via systemctl)";
        wantedBy    = [];
        after       = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.llama-cpp}/bin/llama-server"
            + " --host ${config.ai.llama.fim.host}"
            + " --port ${toString config.ai.llama.fim.port}"
            + " --model ${home}/models/${config.ai.llama.fim.model}"
            + " --ctx-size 2048"
            + " --n-predict -1";
          Restart         = "always";
          RestartSec      = "5s";
          ExecStartPre    = "${pkgs.coreutils}/bin/test -f ${home}/models/${config.ai.llama.fim.model}";
        };
      };
    })

    (lib.mkIf config.ai.llama.work.enable {
      systemd.user.services.llama-server-work = {
        description = "llama.cpp work server (heavy, toggle via systemctl)";
        wantedBy    = [];
        after       = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.llama-cpp}/bin/llama-server"
            + " --host ${config.ai.llama.work.host}"
            + " --port ${toString config.ai.llama.work.port}"
            + " --model ${home}/models/work-model.gguf"
            + " --ctx-size 8192"
            + " --n-predict -1"
            + " --cont-batching";
          Restart         = "on-failure";
          RestartSec      = "5s";
          ExecStartPre    = "${pkgs.coreutils}/bin/test -f ${home}/models/work-model.gguf";
        };
      };

      system.activationScripts.llama-work-symlink = {
        deps = [ "users" ];
        text = ''
          if [ ! -L ${home}/models/work-model.gguf ]; then
            ln -sf ${home}/models/${config.ai.llama.work.model} ${home}/models/work-model.gguf
            ${pkgs.coreutils}/bin/chown -h ${user}:${user} ${home}/models/work-model.gguf
          fi
        '';
      };
    })
  ];
}
