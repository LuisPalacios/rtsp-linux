#!/bin/bash
set -euo pipefail

TAG="compila_rtsp"
SRC_DIR="/root/rtsp-linux-master"
KEYS_DIR="/root/keys-kernel-modules"
MOD_DIR="/lib/modules/$(uname -r)"
BUILD_CERTS="${MOD_DIR}/build/certs"
SCRIPT_SIGN="${MOD_DIR}/build/scripts/sign-file"
KEY_PRIV="${KEYS_DIR}/signing_key.priv"
KEY_PEM="${KEYS_DIR}/signing_key.pem"

log() {
    logger --tag "$TAG" "$1"
    echo "[${TAG}] $1"
}

fail() {
    logger --tag "$TAG" --priority err "ERROR: $1"
    echo "[${TAG}] ERROR: $1" >&2
    exit 1
}

log "Inicio de compilación y firma del módulo RTSP"

[[ -d "$SRC_DIR" ]]     || fail "$SRC_DIR no existe"
[[ -f "$KEY_PRIV" ]]    || fail "Clave privada no encontrada en $KEYS_DIR"
[[ -f "$KEY_PEM" ]]     || fail "Clave pública no encontrada en $KEYS_DIR"
[[ -x "$SCRIPT_SIGN" ]] || fail "sign-file no ejecutable: $SCRIPT_SIGN"

cd "$SRC_DIR"

log "make clean..."
make clean

log "Compilando con make..."
make

log "Copiando claves al directorio de build del kernel..."
cp "$KEY_PRIV" "$BUILD_CERTS"
cp "$KEY_PEM" "$BUILD_CERTS"

for MODULE in nf_conntrack_rtsp.ko nf_nat_rtsp.ko; do
    [[ -f "$MODULE" ]] || fail "Módulo $MODULE no encontrado tras la compilación"
    log "Firmando $MODULE..."
    "$SCRIPT_SIGN" sha256 "$KEY_PRIV" "$KEY_PEM" "$MODULE"
done

log "Instalando módulos..."
make modules_install

log "Ejecutando depmod..."
depmod -a

log "Cargando módulo nf_nat_rtsp con modprobe..."
modprobe nf_nat_rtsp

log "Finalizado con éxito"