{ pkgs, lib, config, ... }:
let
  user = config.vars.usuarioPrincipal;
  home = config.vars.home;

  engram = pkgs.stdenv.mkDerivation {
    name = "engram-1.17.0";
    src = pkgs.fetchurl {
      url    = "https://github.com/Gentleman-Programming/engram/releases/download/v1.17.0/engram_1.17.0_linux_amd64.tar.gz";
      hash   = "sha256-FkIuxFlrpABwML1LWJ4TnVo0CeuEby/7GaFHyVPx4P4=";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      tar xzf $src
      cp engram $out/bin/engram
    '';
  };

  squeez = pkgs.stdenv.mkDerivation {
    name = "squeez-1.32.1";
    src = pkgs.fetchurl {
      url    = "https://github.com/claudioemmanuel/squeez/releases/download/v1.32.1/squeez-linux-x86_64";
      sha256 = "sha256-XVfAuA8rNPXcyYtzyx9whvISazdCKNejzgS3KbNmxtw=";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/squeez
      chmod +x $out/bin/squeez
    '';
  };

  mcpEntries = lib.concatStringsSep ",\n    " (
    lib.optional config.ai.opencode.engram.enable
      "\"engram\": {\"type\": \"local\", \"command\": [\"${engram}/bin/engram\", \"mcp\"]}"
    ++ lib.optional config.ai.opencode.context7.enable
      "\"context7\": {\"type\": \"remote\", \"url\": \"https://mcp.context7.com/mcp\"}"
    ++ lib.optional config.ai.opencode.squeez.enable
      "\"squeez\": {\"type\": \"local\", \"command\": [\"${squeez}/bin/squeez\", \"mcp\"]}"
  );

  aiDownloadModels = pkgs.writeShellApplication {
    name = "ai-download-models";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = ''
      MODELS_DIR="${home}/models"
      mkdir -p "$MODELS_DIR"

      echo "Descargando Qwen2.5-Coder-7B-Instruct Q4_K_M..."
      curl -L -C - -o "$MODELS_DIR/qwen2.5-coder-7b-instruct-q4_k_m.gguf" \
        "https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf"

      echo "Descargando Qwen2.5-Coder-1.5B-Instruct Q4_K_M..."
      curl -L -C - -o "$MODELS_DIR/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf" \
        "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"

      echo "Descargando whisper-small..."
      curl -L -C - -o "$MODELS_DIR/whisper-small.bin" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"

      echo "Modelos descargados en $MODELS_DIR"
    '';
  };

  aiTranscribe = pkgs.writeShellApplication {
    # DESC: Graba audio del micrófono, transcribe con whisper y copia al portapapeles
    # Uso: ai-transcribe          (graba hasta Ctrl+C o max 30s)
    #      ai-transcribe --stop   (para la grabación en curso desde otro proceso)
    name = "ai-transcribe";
    runtimeInputs = [ pkgs.whisper-cpp pkgs.pipewire pkgs.wl-clipboard pkgs.coreutils ];
    text = ''
      MODELS_DIR="${home}/models"
      TMP_AUDIO="/tmp/ai-transcribe.wav"
      PID_FILE="/tmp/ai-transcribe.pid"

      # --stop: para la grabación en curso
      if [ "''${1:-}" = "--stop" ]; then
        if [ -f "$PID_FILE" ]; then
          kill "$(cat "$PID_FILE")" 2>/dev/null || true
          rm -f "$PID_FILE"
        fi
        exit 0
      fi

      # Cleanup de grabaciones previas
      rm -f "$TMP_AUDIO" "''${TMP_AUDIO}.txt"

      echo "Grabando... (Ctrl+C o ai-transcribe --stop para parar)" >&2
      pw-cat --record --rate=16000 --channels=1 "$TMP_AUDIO" &
      REC_PID=$!
      echo "$REC_PID" > "$PID_FILE"
      wait "$REC_PID" 2>/dev/null || true
      rm -f "$PID_FILE"

      if [ -f "$TMP_AUDIO" ] && [ "$(stat -c%s "$TMP_AUDIO" 2>/dev/null)" -gt 1024 ]; then
        echo "Transcribiendo..." >&2
        whisper-cli --model "$MODELS_DIR/whisper-small.bin" \
                    --output-txt --no-timestamps \
                    "$TMP_AUDIO" 2>&1
        TEXT=$(cat "''${TMP_AUDIO}.txt" 2>/dev/null)
        rm -f "''${TMP_AUDIO}" "''${TMP_AUDIO}.txt"

        if [ -n "$TEXT" ]; then
          echo "$TEXT"
          printf "%s" "$TEXT" | wl-copy
          echo "Copiado al portapapeles" >&2
        else
          echo "No se pudo transcribir" >&2
          exit 1
        fi
      else
        echo "No se grabó audio (o el archivo está vacío)" >&2
        [ -f "$TMP_AUDIO" ] && rm -f "$TMP_AUDIO"
        exit 1
      fi
    '';
  };

in
{
  options.ai = {
    enable = lib.mkEnableOption "Activa el módulo de herramientas AI";

    opencode = {
      enable   = lib.mkEnableOption "Activa OpenCode";
      engram   = { enable = lib.mkEnableOption "Activa engram (memoria persistente MCP)"; };
      context7 = { enable = lib.mkEnableOption "Activa Context7 (búsqueda de docs MCP)"; };
      squeez   = { enable = lib.mkEnableOption "Activa squeez (compresor de tokens)"; };
    };

    llama = {
      enable = lib.mkEnableOption "Activa llama.cpp para inferencia local";
      serve  = lib.mkEnableOption "Activa llama-server como servicio systemd de usuario";
      host   = lib.mkOption {
        type    = lib.types.str;
        default = "";
        description = "Host al que se vincula llama-server";
      };
      port   = lib.mkOption {
        type    = lib.types.port;
        default = 0;
        description = "Puerto del servidor llama.cpp";
      };
      model  = lib.mkOption {
        type    = lib.types.str;
        default = "qwen2.5-coder-7b-instruct-q4_k_m.gguf";
        description = "Nombre del archivo GGUF en ~/models/";
      };
      completionServe = lib.mkEnableOption "Activa servidor de completado de código (modelo pequeño)";
      completionHost  = lib.mkOption {
        type    = lib.types.str;
        default = "";
        description = "Host para el servidor de completado";
      };
      completionPort  = lib.mkOption {
        type    = lib.types.port;
        default = 0;
        description = "Puerto para el servidor de completado de código";
      };
      completionModel = lib.mkOption {
        type    = lib.types.str;
        default = "qwen2.5-coder-1.5b-instruct-q4_k_m.gguf";
        description = "Nombre del archivo GGUF para completado en ~/models/";
      };
    };

    whisper = {
      enable = lib.mkEnableOption "Activa whisper-cpp para transcripción de voz";
      model  = lib.mkOption {
        type    = lib.types.str;
        default = "whisper-small.bin";
        description = "Nombre del archivo de modelo whisper en ~/models/";
      };
    };
  };

  config = lib.mkIf config.ai.enable (lib.mkMerge [

    (lib.mkIf config.ai.opencode.enable {
      assertions = [{
        assertion = config.mi_sops.enable;
        message = "ai.opencode requiere sops (mi_sops.enable) para las claves de proveedores";
      }];

      userPackages.ai = [ pkgs.opencode ];

      sops.secrets."opencode/opencode_go_key" = {};
      sops.secrets."opencode/bedrock_token" = {};

      myImpermanence.users.${user}.directories = [
        ".config/opencode"
        ".local/share/opencode"
        ".local/state/opencode"
      ];

      system.activationScripts.opencode-config = {
        deps = [ "setupSecrets" "users" "opencode-squeez-setup" ];
        text = ''
          oc_key=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."opencode/opencode_go_key".path} 2>/dev/null || echo "CHANGE_ME")
          bedrock_token=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."opencode/bedrock_token".path} 2>/dev/null || echo "")

          mkdir -p ${home}/.config/opencode/agents
          mkdir -p ${home}/.local/share/opencode

          # opencode.jsonc con todos los providers
          ${pkgs.coreutils}/bin/cat > ${home}/.config/opencode/opencode.jsonc << ENDCONFIG
          {
            "\$schema": "https://opencode.ai/config.json",
            "lsp": true,
            "autoupdate": false,
            "share": "disabled",
            "experimental": { "openTelemetry": false },
            "skills": {
              "urls": ["https://www.skills.sh/.well-known/skills/opencode/"]
            },
            "provider": {
              "opencode-go": {
                "options": { "apiKey": "$oc_key" }
              },
              "amazon-bedrock": {
                "options": { "region": "us-east-1", "apiKey": "$bedrock_token" }
              }${lib.optionalString config.ai.llama.serve ''
              ,
              "llama.cpp": {
                "npm": "@ai-sdk/openai-compatible",
                "name": "llama-server (local)",
                "options": { "baseURL": "http://${config.ai.llama.host}:${toString config.ai.llama.port}/v1", "apiKey": "llama-local" },
                "models": {
                  "${config.ai.llama.model}": {
                    "name": "Qwen2.5-Coder 7B (local)",
                    "limit": { "context": 4096, "output": 4096 }
                  }
                }
              }''}${lib.optionalString config.ai.llama.completionServe ''
              ,
              "llama.cpp-completion": {
                "npm": "@ai-sdk/openai-compatible",
                "name": "Qwen 1.5B (completado)",
                "options": { "baseURL": "http://${config.ai.llama.completionHost}:${toString config.ai.llama.completionPort}/v1", "apiKey": "llama-local" },
                "models": {
                  "${config.ai.llama.completionModel}": {
                    "name": "Qwen2.5-Coder 1.5B (completado)",
                    "limit": { "context": 2048, "output": 512 }
                  }
                }
              }''}
            },
            "mcp": {
              ${mcpEntries}
            }${lib.optionalString config.ai.llama.serve ''
            ,
            "model": "llama.cpp/${config.ai.llama.model}"''}
          }
          ENDCONFIG

          ${pkgs.coreutils}/bin/chown -R ${user}:${user} ${home}/.config/opencode
        '';
      };
    })

    (lib.mkIf config.ai.opencode.engram.enable {
      userPackages.ai = [ engram ];
      myImpermanence.users.${user}.directories = [ ".engram" ];
    })

    (lib.mkIf config.ai.opencode.squeez.enable {
      userPackages.ai = [ squeez ];

      system.activationScripts.opencode-squeez-setup = {
        deps = [ "users" ];
        text = ''
          if [ ! -f ${home}/.config/opencode/plugins/squeez.js ]; then
            mkdir -p ${home}/.config/opencode/plugins
            HOME=${home} ${squeez}/bin/squeez setup --host=opencode
            ${pkgs.coreutils}/bin/chown -R ${user}:${user} ${home}/.config/opencode
          fi
        '';
      };
    })

    (lib.mkIf config.ai.llama.enable {
      users.users.${user}.linger = true;
      userPackages.ai = [ pkgs.llama-cpp aiDownloadModels ];

      myImpermanence.users.${user}.directories = [ "models" ];

      # Servicio systemd de usuario para llama-server (modelo principal)
      systemd.user.services.llama-server = lib.mkIf config.ai.llama.serve {
        description = "llama.cpp inference server (OpenAI-compatible)";
        wantedBy    = [ "default.target" ];
        after       = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.llama-cpp}/bin/llama-server"
            + " --host ${config.ai.llama.host}"
            + " --port ${toString config.ai.llama.port}"
            + " --model ${home}/models/${config.ai.llama.model}"
            + " --ctx-size 4096"
            + " --n-predict -1";
          Restart         = "on-failure";
          RestartSec      = "5s";
          ExecStartPre    = "${pkgs.coreutils}/bin/test -f ${home}/models/${config.ai.llama.model}";
        };
      };

      # Servicio systemd de usuario para completado de código (modelo pequeño)
      systemd.user.services.llama-server-completion = lib.mkIf config.ai.llama.completionServe {
        description = "llama.cpp completion server (modelo pequeño)";
        wantedBy    = [ "default.target" ];
        after       = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.llama-cpp}/bin/llama-server"
            + " --host ${config.ai.llama.completionHost}"
            + " --port ${toString config.ai.llama.completionPort}"
            + " --model ${home}/models/${config.ai.llama.completionModel}"
            + " --ctx-size 2048"
            + " --n-predict -1";
          Restart         = "on-failure";
          RestartSec      = "5s";
          ExecStartPre    = "${pkgs.coreutils}/bin/test -f ${home}/models/${config.ai.llama.completionModel}";
        };
      };
    })

    (lib.mkIf config.ai.whisper.enable {
      userPackages.ai = [ pkgs.whisper-cpp pkgs.pipewire aiTranscribe ];
    })

  ]);
}
