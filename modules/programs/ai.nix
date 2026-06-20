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

      echo "Descargando whisper-small..."
      curl -L -C - -o "$MODELS_DIR/whisper-small.bin" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"

      echo "Modelos descargados en $MODELS_DIR"
    '';
  };

  aiTranscribe = pkgs.writeShellApplication {
    # DESC: Graba audio del micrófono, transcribe con whisper y copia al portapapeles
    name = "ai-transcribe";
    runtimeInputs = [ pkgs.whisper-cpp pkgs.sox pkgs.wl-clipboard pkgs.coreutils ];
    text = ''
      MODELS_DIR="${home}/models"
      TMP_AUDIO="/tmp/ai-transcribe-$$.wav"

      echo "Grabando... Ctrl+C para parar" >&2
      sox -d -r 16000 -c 1 "$TMP_AUDIO" trim 0 30 2>/dev/null || true

      if [ -f "$TMP_AUDIO" ]; then
        whisper-cpp --model "$MODELS_DIR/whisper-small.bin" \
                    --output-txt --no-timestamps \
                    "$TMP_AUDIO" >/dev/null 2>&1
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
        echo "No se grabó audio" >&2
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
      port   = lib.mkOption {
        type    = lib.types.port;
        default = 8080;
        description = "Puerto del servidor llama.cpp";
      };
      model  = lib.mkOption {
        type    = lib.types.str;
        default = "qwen2.5-coder-7b-instruct-q4_k_m.gguf";
        description = "Nombre del archivo GGUF en ~/models/";
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
      # bedrock_token se mantiene en sops como backup pero opencode lo lee de auth.json (via /connect)

      myImpermanence.users.${user}.directories = [
        ".config/opencode"
        ".local/share/opencode"
        ".local/state/opencode"
      ];

      system.activationScripts.opencode-config = {
        deps = [ "setupSecrets" "users" "opencode-squeez-setup" ];
        text = ''
          oc_key=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."opencode/opencode_go_key".path} 2>/dev/null || echo "CHANGE_ME")

          mkdir -p ${home}/.config/opencode/agents

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
                "options": { "region": "us-east-1" }
              }${lib.optionalString config.ai.llama.serve ''
              ,
              "llama.cpp": {
                "npm": "@ai-sdk/openai-compatible",
                "name": "llama-server (local)",
                "options": { "baseURL": "http://127.0.0.1:${toString config.ai.llama.port}/v1", "apiKey": "llama-local" },
                "models": {
                  "${config.ai.llama.model}": {
                    "name": "Qwen2.5-Coder 7B (local)",
                    "limit": { "context": 4096, "output": 4096 }
                  }
                }
              }''}
            },
            "mcp": {
              ${mcpEntries}
            }${lib.optionalString config.ai.llama.serve ''
            ,
            "acp": {
              "model": {
                "provider": "llama.cpp",
                "model": "${config.ai.llama.model}"
              }
            }''}
          }
          ENDCONFIG

          ${pkgs.coreutils}/bin/cat > ${home}/.config/opencode/agents/qa.md << 'AGENT'
          ---
          description: Agente QA — analiza el código buscando bugs, edge cases y problemas de testing. Sugiere tests y estrategias de cobertura.
          mode: subagent
          temperature: 0.1
          permission:
            edit: deny
            bash:
              "*": deny
              "pytest *": allow
              "cargo test *": allow
              "go test *": allow
              "npm test *": allow
              "bun test *": allow
          ---

          Eres un experto en QA y testing. Tu objetivo es encontrar fallos antes de que lleguen a producción.

          Analiza el código desde la perspectiva de:
          - Bugs potenciales y edge cases no cubiertos
          - Casos de error y manejo de excepciones
          - Cobertura de tests existentes
          - Propuestas de tests nuevos (unitarios, integración, e2e)
          - Condiciones de carrera y problemas de concurrencia
          AGENT

          ${pkgs.coreutils}/bin/cat > ${home}/.config/opencode/agents/documentacion.md << 'AGENT'
          ---
          description: Agente documentación — escribe y mantiene documentación técnica clara y precisa.
          mode: subagent
          temperature: 0.3
          permission:
            bash: deny
          ---

          Eres un escritor técnico experto. Creas documentación clara, bien estructurada y mantenible.

          Cuando documentes:
          - Explica el "por qué", no solo el "qué"
          - Usa ejemplos concretos y código real
          - Sigue el estilo del proyecto existente
          - Crea READMEs, docstrings, comentarios y guías
          - Mantén la documentación sincronizada con el código
          AGENT

          ${pkgs.coreutils}/bin/cat > ${home}/.config/opencode/agents/arquitecto.md << 'AGENT'
          ---
          description: Agente arquitecto — diseña y analiza la estructura del sistema, patrones y decisiones técnicas.
          mode: subagent
          temperature: 0.2
          permission:
            edit: deny
            bash: deny
          ---

          Eres un arquitecto de software senior. Analizas y diseñas sistemas con visión a largo plazo.

          Tu enfoque:
          - Evalúa trade-offs entre distintos enfoques
          - Identifica problemas estructurales y deuda técnica
          - Propone patrones de diseño apropiados al contexto
          - Considera escalabilidad, mantenibilidad y rendimiento
          - Justifica cada decisión técnica con razonamiento claro
          AGENT

          ${pkgs.coreutils}/bin/cat > ${home}/.config/opencode/agents/navegante.md << 'AGENT'
          ---
          description: Agente navegante — investiga documentación, APIs y recursos externos en la web.
          mode: subagent
          temperature: 0.3
          permission:
            edit: deny
            bash: deny
            webfetch: allow
            websearch: allow
          ---

          Eres un investigador técnico especializado en encontrar información relevante y actualizada.

          Cuando investigues:
          - Busca en documentación oficial primero
          - Verifica fechas y versiones de los recursos
          - Compara varias fuentes antes de concluir
          - Resume los hallazgos de forma accionable
          - Cita las fuentes con URLs concretas
          AGENT

          ${pkgs.coreutils}/bin/cat > ${home}/.config/opencode/agents/abogado.md << 'AGENT'
          ---
          description: Agente abogado del diablo — critica activamente las soluciones propuestas buscando problemas y alternativas.
          mode: subagent
          temperature: 0.6
          permission:
            edit: deny
            bash: deny
          ---

          Tu rol es encontrar todo lo que puede salir mal en una solución propuesta.

          Actúa como un crítico constructivo y riguroso:
          - Identifica asunciones incorrectas o no verificadas
          - Señala casos extremos que la solución no maneja
          - Propone alternativas que podrían ser mejores
          - Cuestiona la complejidad innecesaria
          - Busca problemas de seguridad, rendimiento o mantenibilidad
          - Sé directo y específico, no genérico
          AGENT

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
      userPackages.ai = [ pkgs.llama-cpp aiDownloadModels ];

      myImpermanence.users.${user}.directories = [ "models" ];

      # Servicio systemd de usuario para llama-server
      systemd.user.services.llama-server = lib.mkIf config.ai.llama.serve {
        description = "llama.cpp inference server (OpenAI-compatible)";
        wantedBy    = [ "default.target" ];
        after       = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.llama-cpp}/bin/llama-server"
            + " --model ${home}/models/${config.ai.llama.model}"
            + " --port ${toString config.ai.llama.port}"
            + " --ctx-size 4096"
            + " --n-predict -1"
            + " --log-disable";
          Restart         = "on-failure";
          RestartSec      = "5s";
          ExecStartPre    = "${pkgs.coreutils}/bin/test -f ${home}/models/${config.ai.llama.model}";
        };
      };
    })

    (lib.mkIf config.ai.whisper.enable {
      userPackages.ai = [ pkgs.whisper-cpp pkgs.sox aiTranscribe ];
    })

  ]);
}
