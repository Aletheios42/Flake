#!/usr/bin/env bash
# DESC: Muestra los scripts custom disponibles en el sistema con sus descripciones

set -euo pipefail

BOLD='\033[1m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BOLD}Scripts disponibles${RESET}"
echo "─────────────────────────────────────────────"

# Lista los scripts custom y extrae su descripción del comentario # DESC:
for script in rfv tree-cat screenshot-wayland toggle-record-wayland ai-download-models ai-transcribe ai-help forge; do
  if command -v "$script" &>/dev/null; then
    src=$(command -v "$script")
    desc=$(grep -m1 '# DESC:' "$src" 2>/dev/null | sed 's/.*# DESC: //' || echo "—")
    printf "  ${CYAN}%-30s${RESET} %s\n" "$script" "$desc"
  fi
done

echo ""
echo -e "${BOLD}Herramientas AI${RESET}"
echo "─────────────────────────────────────────────"
command -v opencode   &>/dev/null && echo -e "  ${CYAN}opencode${RESET}                       Agente AI de coding (opencode.ai)"
command -v engram     &>/dev/null && echo -e "  ${CYAN}engram${RESET}                         Memoria persistente para agentes AI"
command -v squeez     &>/dev/null && echo -e "  ${CYAN}squeez${RESET}                         Compresor de tokens para AI CLIs"
command -v llama-server &>/dev/null && echo -e "  ${CYAN}llama-server${RESET}                   Servidor de inferencia local (llama.cpp)"
command -v whisper    &>/dev/null && echo -e "  ${CYAN}whisper${RESET}                        Transcripción de voz (whisper.cpp)"

echo ""
echo -e "${BOLD}Herramientas git${RESET}"
echo "─────────────────────────────────────────────"
command -v forge &>/dev/null && echo -e "  ${CYAN}forge${RESET}                          CLI para GitHub/GitLab/Gitea/Forgejo"

echo ""
echo -e "Usa ${BOLD}<comando> --help${RESET} para más información sobre cada herramienta."
