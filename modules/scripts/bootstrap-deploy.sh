#!/usr/bin/env bash
# bootstrap-deploy — Deploy NixOS via nixos-anywhere con disko + inyeccion de SSH host key
#
# Requiere:
#   - SSH host key generada con bootstrap-keygen
#   - .sops.yaml actualizado con la age key derivada
#   - Secrets re-encriptados y commiteados
#   - Target accesible via SSH (live ISO / rescue mode)

set -euo pipefail

HOSTNAME=""
TARGET_IP=""
SSH_PORT="22"
FLAKE_REF=""
SSH_KEY=""
BUILD_ON_REMOTE=""

usage() {
  cat <<EOF
Uso: bootstrap-deploy <hostname> <target_ip> --ssh-key <path> [opciones]

Ejecuta nixos-anywhere para instalar NixOS en el host destino.
Particiona el disco con disko e inyecta la SSH host key via --extra-files.

Opciones:
  --ssh-key <path>        Path a ssh_host_ed25519_key (de bootstrap-keygen) [OBLIGATORIO]
  --port <puerto>         Puerto SSH del target live ISO (default: 22)
  --flake <ref>           Flake ref (default: auto-detect flake local desde \$PWD)
  --build-on-remote       Build en el target en vez de local
  --help                  Muestra esta ayuda

Ejemplos:
  bootstrap-deploy server1 192.168.1.100 --ssh-key /tmp/bootstrap-server1/ssh_host_ed25519_key
  bootstrap-deploy server2 10.0.0.5 --ssh-key ~/.ssh/server2_host --flake github:user/repo
  bootstrap-deploy machine 192.168.1.50 --ssh-key /tmp/bootstrap-machine/ssh_host_ed25519_key --build-on-remote
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh-key) SSH_KEY="$2"; shift 2 ;;
    --port) SSH_PORT="$2"; shift 2 ;;
    --flake) FLAKE_REF="$2"; shift 2 ;;
    --build-on-remote) BUILD_ON_REMOTE="--build-on-remote"; shift ;;
    --help|-h) usage ;;
    -*) echo "ERROR: Opcion desconocida: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$HOSTNAME" ]]; then HOSTNAME="$1"
      elif [[ -z "$TARGET_IP" ]]; then TARGET_IP="$1"
      else echo "ERROR: Demasiados argumentos" >&2; exit 1; fi
      shift ;;
  esac
done

# Validaciones
if [[ -z "$HOSTNAME" ]]; then echo "ERROR: Falta hostname" >&2; exit 1; fi
if [[ -z "$TARGET_IP" ]]; then echo "ERROR: Falta target_ip" >&2; exit 1; fi
if [[ -z "$SSH_KEY" ]]; then echo "ERROR: Falta --ssh-key <path>. Genera una con: bootstrap-keygen $HOSTNAME" >&2; exit 1; fi
if [[ ! -f "$SSH_KEY" ]]; then echo "ERROR: No existe SSH key: $SSH_KEY" >&2; exit 1; fi
if [[ ! -f "${SSH_KEY}.pub" ]]; then echo "ERROR: No existe SSH pub key: ${SSH_KEY}.pub" >&2; exit 1; fi

# Auto-detect flake ref si no se paso
if [[ -z "$FLAKE_REF" ]]; then
  DIR="$PWD"
  while [[ ! -f "$DIR/flake.nix" ]] && [[ "$DIR" != "/" ]]; do
    DIR="$(dirname "$DIR")"
  done
  if [[ -f "$DIR/flake.nix" ]]; then
    FLAKE_REF="$DIR"
  else
    echo "ERROR: No se encontro flake.nix. Usa --flake <ref>" >&2
    exit 1
  fi
fi

echo "=== Bootstrap Deploy ==="
echo ""
echo "  Host:    $HOSTNAME"
echo "  Target:  root@${TARGET_IP}:${SSH_PORT}"
echo "  Flake:   ${FLAKE_REF}#${HOSTNAME}"
echo "  SSH key: $SSH_KEY"
echo ""

# Verificar acceso SSH al target
echo "Verificando acceso SSH al target (live ISO)..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
     -p "$SSH_PORT" "root@$TARGET_IP" "echo ok" 2>/dev/null; then
  echo "ERROR: No se puede conectar via SSH a root@${TARGET_IP}:${SSH_PORT}" >&2
  echo "  Asegurate de que el target esta en live ISO con SSH habilitado y root accesible." >&2
  exit 1
fi
echo "OK: Acceso SSH confirmado."
echo ""

# Preparar extra-files con la SSH host key
# Se copia a ambas rutas:
#   /etc/ssh/          → para el primer boot (antes de impermanence)
#   /persist/etc/ssh/  → para que sobreviva al wipe de impermanence
EXTRA_FILES=$(mktemp -d)
trap 'rm -rf "$EXTRA_FILES"' EXIT

mkdir -p "$EXTRA_FILES/etc/ssh"
mkdir -p "$EXTRA_FILES/persist/etc/ssh"
cp "$SSH_KEY" "$EXTRA_FILES/etc/ssh/ssh_host_ed25519_key"
cp "${SSH_KEY}.pub" "$EXTRA_FILES/etc/ssh/ssh_host_ed25519_key.pub"
cp "$SSH_KEY" "$EXTRA_FILES/persist/etc/ssh/ssh_host_ed25519_key"
cp "${SSH_KEY}.pub" "$EXTRA_FILES/persist/etc/ssh/ssh_host_ed25519_key.pub"
chmod 600 "$EXTRA_FILES/etc/ssh/ssh_host_ed25519_key"
chmod 600 "$EXTRA_FILES/persist/etc/ssh/ssh_host_ed25519_key"
chmod 644 "$EXTRA_FILES/etc/ssh/ssh_host_ed25519_key.pub"
chmod 644 "$EXTRA_FILES/persist/etc/ssh/ssh_host_ed25519_key.pub"

# Pedir passphrase LUKS interactivamente
echo "Introduce la passphrase para LUKS (encriptacion de disco):"
read -rs LUKS_PASS
echo ""
if [[ -z "$LUKS_PASS" ]]; then echo "ERROR: Passphrase vacia no permitida" >&2; exit 1; fi

# Archivo temporal con passphrase
LUKS_FILE=$(mktemp)
trap 'rm -rf "$EXTRA_FILES" "$LUKS_FILE"' EXIT
echo -n "$LUKS_PASS" > "$LUKS_FILE"
chmod 600 "$LUKS_FILE"

# Ejecutar nixos-anywhere
echo "Ejecutando nixos-anywhere..."
echo "  (particionado con disko + instalacion + inyeccion SSH host key)"
echo ""

# shellcheck disable=SC2086
nix run github:nix-community/nixos-anywhere -- \
  --flake "${FLAKE_REF}#${HOSTNAME}" \
  --target-host "root@${TARGET_IP}" \
  --ssh-port "$SSH_PORT" \
  --extra-files "$EXTRA_FILES" \
  --disk-encryption-keys /tmp/disk.key "$LUKS_FILE" \
  $BUILD_ON_REMOTE

echo ""
echo "=== Deploy completado ==="
echo ""
echo "El host se reiniciara automaticamente."
echo "La SSH host key ha sido inyectada en /etc/ssh/ del target."
echo "El activationScript de impermanence la copiara a /persist/etc/ssh/."
echo ""
echo "Siguiente paso (espera ~30-60s al reboot):"
echo "  bootstrap-verify $HOSTNAME $TARGET_IP --port <puerto_ssh_configurado>"
echo ""
echo "NOTA: El puerto SSH post-install puede diferir del live ISO."
echo "      Revisa mi_ssh.servidor.puertos en la config del host."
echo ""
