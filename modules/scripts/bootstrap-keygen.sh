#!/usr/bin/env bash
# bootstrap-keygen — Genera SSH ed25519 host key y deriva age public key para SOPS
#
# La age public key derivada se debe registrar en .sops.yaml para que
# sops-nix pueda descifrar secrets en el host destino usando useSshKey=true.

set -euo pipefail

HOSTNAME=""
OUTPUT_DIR=""

usage() {
  cat <<EOF
Uso: bootstrap-keygen <hostname> [opciones]

Genera una SSH ed25519 host key para un nuevo host y deriva la age public key
necesaria para configurar SOPS (useSshKey = true).

Opciones:
  --output <path>    Directorio donde guardar la key (default: /tmp/bootstrap-<hostname>)
  --help             Muestra esta ayuda

Ejemplo:
  bootstrap-keygen server2
  bootstrap-keygen server2 --output ~/.ssh/hosts/server2
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --help|-h) usage ;;
    -*) echo "ERROR: Opcion desconocida: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$HOSTNAME" ]]; then
        HOSTNAME="$1"
      else
        echo "ERROR: Demasiados argumentos" >&2; exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$HOSTNAME" ]]; then echo "ERROR: Falta hostname. Uso: bootstrap-keygen <hostname>" >&2; exit 1; fi

# Default output
if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="/tmp/bootstrap-${HOSTNAME}"
fi

mkdir -p "$OUTPUT_DIR"
KEY_PATH="$OUTPUT_DIR/ssh_host_ed25519_key"

# Si ya existe, mostrar info y salir
if [[ -f "$KEY_PATH" ]]; then
  echo "AVISO: Ya existe una key en $KEY_PATH"
  echo ""
  echo "Age public key:"
  ssh-to-age -i "${KEY_PATH}.pub"
  exit 0
fi

# Generar key
echo "Generando SSH ed25519 host key para $HOSTNAME..."
ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "${HOSTNAME} host key" -q
chmod 600 "$KEY_PATH"
chmod 644 "${KEY_PATH}.pub"

# Derivar age key
AGE_PUBKEY=$(ssh-to-age -i "${KEY_PATH}.pub")

echo ""
echo "=== KEY GENERADA ==="
echo ""
echo "  SSH private key: $KEY_PATH"
echo "  SSH public key:  ${KEY_PATH}.pub"
echo "  Age public key:  $AGE_PUBKEY"
echo ""
echo "=== SIGUIENTE PASO ==="
echo ""
echo "1. Anade a .sops.yaml bajo 'keys:':"
echo ""
echo "   - &${HOSTNAME} ${AGE_PUBKEY}"
echo ""
echo "2. Anade (o verifica) una creation_rule:"
echo ""
echo "   creation_rules:"
echo "     - path_regex: secrets/${HOSTNAME}\\.yaml\$"
echo "       key_groups:"
echo "         - age:"
echo "             - *admin"
echo "             - *${HOSTNAME}"
echo ""
echo "3. Crea o re-encripta secrets:"
echo ""
echo "   sops secrets/${HOSTNAME}.yaml             # crear nuevo"
echo "   sops updatekeys secrets/${HOSTNAME}.yaml  # re-encriptar existente"
echo ""
echo "4. Commit + push:"
echo ""
echo "   git add .sops.yaml secrets/${HOSTNAME}.yaml"
echo "   git commit -m 'bootstrap: add ${HOSTNAME} age key'"
echo "   git push"
echo ""
echo "5. Deploy:"
echo ""
echo "   bootstrap-deploy ${HOSTNAME} <ip_target> --ssh-key ${KEY_PATH}"
echo ""
