#!/usr/bin/env bash
# bootstrap-verify — Verifica que el bootstrap se completo correctamente
#
# Comprueba: /persist montado, SSH host key persistida, age key correcta, SOPS secrets

set -euo pipefail

HOSTNAME=""
TARGET_IP=""
SSH_PORT="22"
SSH_KEY=""

usage() {
  cat <<EOF
Uso: bootstrap-verify <hostname> <target_ip> [opciones]

Verifica que el host recien instalado funciona correctamente:
  - /persist montado (impermanence activo)
  - SSH host key copiada a /persist/etc/ssh/
  - Age key derivada coincide con la esperada
  - SOPS secrets descifrados

Opciones:
  --port <puerto>         Puerto SSH del host instalado (default: 22)
  --ssh-key <path>        SSH host key local para comparar age key (opcional)
  --help                  Muestra esta ayuda

Ejemplo:
  bootstrap-verify server2 192.168.1.100 --port 1234
  bootstrap-verify server2 192.168.1.100 --port 1234 --ssh-key /tmp/bootstrap-server2/ssh_host_ed25519_key
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) SSH_PORT="$2"; shift 2 ;;
    --ssh-key) SSH_KEY="$2"; shift 2 ;;
    --help|-h) usage ;;
    -*) echo "ERROR: Opcion desconocida: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$HOSTNAME" ]]; then HOSTNAME="$1"
      elif [[ -z "$TARGET_IP" ]]; then TARGET_IP="$1"
      else echo "ERROR: Demasiados argumentos" >&2; exit 1; fi
      shift ;;
  esac
done

if [[ -z "$HOSTNAME" ]]; then echo "ERROR: Falta hostname" >&2; exit 1; fi
if [[ -z "$TARGET_IP" ]]; then echo "ERROR: Falta target_ip" >&2; exit 1; fi

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

# Esperar a que el host este accesible
echo "Esperando a que ${TARGET_IP}:${SSH_PORT} este accesible..."
RETRIES=0
while ! ssh "${SSH_OPTS[@]}" -o ConnectTimeout=5 -p "$SSH_PORT" "root@$TARGET_IP" "echo ok" 2>/dev/null; do
  RETRIES=$((RETRIES + 1))
  if [[ $RETRIES -ge 60 ]]; then
    echo "ERROR: Timeout (5 min) esperando al host" >&2
    exit 1
  fi
  printf "."
  sleep 5
done
echo ""
echo "OK: Host accesible"
echo ""

# Funcion helper para SSH
remote() {
  ssh "${SSH_OPTS[@]}" -p "$SSH_PORT" "root@$TARGET_IP" "$@" 2>/dev/null
}

echo "=== Verificaciones para $HOSTNAME ==="
echo ""
PASS=0
FAIL=0

# 1. /persist montado
echo -n "[1/4] /persist montado: "
if remote "mountpoint -q /persist"; then
  echo "OK"
  PASS=$((PASS + 1))
else
  echo "FALLO"
  FAIL=$((FAIL + 1))
fi

# 2. SSH host key persistida
echo -n "[2/4] SSH host key en /persist/etc/ssh/: "
if remote "[[ -f /persist/etc/ssh/ssh_host_ed25519_key ]]"; then
  echo "OK"
  PASS=$((PASS + 1))
else
  echo "NO ENCONTRADA - intentando copia manual..."
  if remote "mkdir -p /persist/etc/ssh && cp /etc/ssh/ssh_host_ed25519_key* /persist/etc/ssh/ && chmod 600 /persist/etc/ssh/ssh_host_ed25519_key"; then
    echo "  Copiado manualmente: OK"
    PASS=$((PASS + 1))
  else
    echo "  FALLO al copiar"
    FAIL=$((FAIL + 1))
  fi
fi

# 3. Age key derivada
echo -n "[3/4] Age key derivada: "
REMOTE_PUBKEY=$(remote "cat /etc/ssh/ssh_host_ed25519_key.pub")
if [[ -n "$REMOTE_PUBKEY" ]]; then
  REMOTE_AGE=$(echo "$REMOTE_PUBKEY" | ssh-to-age)
  if [[ -n "$SSH_KEY" ]] && [[ -f "${SSH_KEY}.pub" ]]; then
    LOCAL_AGE=$(ssh-to-age -i "${SSH_KEY}.pub")
    if [[ "$REMOTE_AGE" == "$LOCAL_AGE" ]]; then
      echo "OK (coincide: $REMOTE_AGE)"
      PASS=$((PASS + 1))
    else
      echo "FALLO - keys no coinciden!"
      echo "  Esperada (local):  $LOCAL_AGE"
      echo "  Encontrada (host): $REMOTE_AGE"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "OK ($REMOTE_AGE)"
    PASS=$((PASS + 1))
  fi
else
  echo "FALLO - no se pudo leer SSH public key del host"
  FAIL=$((FAIL + 1))
fi

# 4. SOPS secrets
echo -n "[4/4] SOPS secrets: "
SECRETS_COUNT=$(remote "ls /run/secrets/ 2>/dev/null | wc -l" || echo "0")
if [[ "$SECRETS_COUNT" -gt 0 ]]; then
  echo "OK ($SECRETS_COUNT secrets descifrados en /run/secrets/)"
  PASS=$((PASS + 1))
else
  echo "AVISO - 0 secrets en /run/secrets/ (normal si no has definido secrets aun)"
  PASS=$((PASS + 1))
fi

# Resumen
echo ""
echo "=== Resultado: $PASS OK, $FAIL FALLO ==="
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo "Bootstrap de $HOSTNAME completado correctamente."
  echo ""
  echo "Puedes borrar la SSH host key local si ya no la necesitas:"
  if [[ -n "$SSH_KEY" ]]; then echo "  rm $SSH_KEY ${SSH_KEY}.pub"; fi
  echo ""
  echo "Para aplicar cambios futuros:"
  echo "  ssh -p $SSH_PORT root@$TARGET_IP nixos-rebuild switch"
else
  echo "Hay fallos. Revisa los errores arriba e intenta resolverlos manualmente."
  exit 1
fi
