#!/usr/bin/env bash

tree && fd -t f | while read -r f; do echo ""; echo "=== $f ==="; echo ""; cat "$f"; done
# Función para mostrar la ayuda
mostrar_ayuda() {
    echo "Uso: $0 [opciones] [patrón_a_ignorar]"
    echo ""
    echo "Descripción:"
    echo "  Muestra el árbol de directorios y concatena el contenido de los archivos,"
    echo "  permitiendo excluir archivos o carpetas específicas."
    echo ""
    echo "Opciones:"
    echo "  -h, --help      Muestra este mensaje de ayuda."
    echo "  -e, --exclude   Patrón de archivos/carpetas a ignorar (ej: 'node_modules')."
    echo ""
    exit 0
}

# Configuración por defecto
EXCLUDE_PATTERN=""

# Manejo de argumentos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) mostrar_ayuda ;;
        -e|--exclude) EXCLUDE_PATTERN="$2"; shift ;;
        *) echo "Opción desconocida: $1"; mostrar_ayuda ;;
    esac
    shift
done

# 1. Mostrar el árbol (excluyendo el patrón si existe)
echo "--- ESTRUCTURA DEL PROYECTO ---"
if [ -n "$EXCLUDE_PATTERN" ]; then
    tree -I "$EXCLUDE_PATTERN"
else
    tree
fi

# 2. Listar y volcar contenido de archivos
# fd ignora por defecto lo que esté en .gitignore
# Añadimos el exclude dinámico si el usuario lo proporcionó
fd -t f ${EXCLUDE_PATTERN:+-E "$EXCLUDE_PATTERN"} | while read -r f; do
    echo -e "\n\e[1;34m=== $f ===\e[0m\n"  # El texto sale en azul para resaltar
    cat "$f"
    echo -e "\n----------------------------"
done
