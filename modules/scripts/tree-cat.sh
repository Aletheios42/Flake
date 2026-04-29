#!/usr/bin/env bash

COPY_TO_CLIPBOARD=false
C_GREEN="\e[1;32m"
C_BLUE="\e[1;34m"
C_YELLOW="\e[1;33m"
C_RED="\e[1;31m"
C_RESET="\e[0m"
TREE_COLOR="-C" 

mostrar_ayuda() {
    echo -e "${C_GREEN}Uso:${C_RESET} $0 [opciones]"
    echo ""
    echo -e "${C_BLUE}Descripción:${C_RESET}"
    echo "  Muestra el árbol de directorios y concatena el contenido de los archivos,"
    echo "  permitiendo excluir múltiples patrones (carpetas o archivos)."
    echo ""
    echo -e "${C_BLUE}Opciones:${C_RESET}"
    echo "  -h, --help        Muestra este mensaje de ayuda."
    echo "  -e, --exclude     Patrón a ignorar. Se puede usar varias veces."
    echo "  -c, --copy        Copia la salida directamente al portapapeles (requiere wl-copy)."
    echo "                    Ejemplo: -e \"node_modules\" -e \"*.log\""
    echo ""
    echo -e "${C_YELLOW}Nota:${C_RESET} 'fd' ignora automáticamente lo que esté en tu .gitignore."
    echo -e "${C_YELLOW}Nota:${C_RESET} Recuerda escribir tus patrones entre comillas para evitar globing."
    exit 0
}

EXCLUDE_TREE=""
EXCLUDE_FD=()

if [[ "$#" -eq 0 ]]; then
    : 
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            mostrar_ayuda
            ;;
        -c|--copy)
            COPY_TO_CLIPBOARD=true
            # Si vamos a copiar, forzamos desactivar colores para que no haya basura
            C_BLUE=""
            C_RESET=""
            TREE_COLOR="-n"
            ;;
        -e|--exclude)
            if [ -n "$2" ]; then
                if [ -z "$EXCLUDE_TREE" ]; then
                    EXCLUDE_TREE="$2"
                else
                    EXCLUDE_TREE="$EXCLUDE_TREE|$2"
                fi
                EXCLUDE_FD+=("-E" "$2")
                shift
            else
                echo -e "${C_RED}Error:${C_RESET} La opción -e requiere un argumento."
                exit 1
            fi
            ;;
        *)
            echo -e "${C_RED}Opción desconocida:${C_RESET} $1"
            mostrar_ayuda
            ;;
    esac
    shift
done

generar_salida() {
    
    if [ -n "$EXCLUDE_TREE" ]; then
        tree --charset=utf8 $TREE_COLOR -I "$EXCLUDE_TREE"
    else
        tree --charset=utf8 $TREE_COLOR
    fi

    echo -e "\n--- CONTENIDO DE ARCHIVOS ---"

    fd -t f "${EXCLUDE_FD[@]}" | while read -r f; do
        echo -e "\n${C_BLUE}=== $f ===${C_RESET}\n"
        cat "$f"
        echo -e "\n----------------------------"
    done
}

if [ "$COPY_TO_CLIPBOARD" = true ]; then
    generar_salida | wl-copy --type text/plain
    echo -e "${C_GREEN}¡Contenido copiado al portapapeles exitosamente!${C_RESET} (Listo para Ctrl+V)"
else
    generar_salida
fi
