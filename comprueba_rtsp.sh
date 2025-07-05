#!/bin/bash
set -euo pipefail

TAG="comprueba_rtsp"
MODULE="nf_nat_rtsp"
SRC_DIR="/root/rtsp-linux-master"
SCRIPT="${SRC_DIR}/compila_e_instala.sh"

log() {
    logger --tag "$TAG" "$1"
    echo "[${TAG}] $1"
}

fail() {
    logger --tag "$TAG" --priority err "ERROR: $1"
    echo "[${TAG}] ERROR: $1" >&2
    exit 1
}

log "Comprobando si el módulo $MODULE está cargado..."

if lsmod | awk '{print $1}' | grep -q "^${MODULE}$"; then
    log "El módulo $MODULE ya está cargado."
    exit 0
fi

log "El módulo $MODULE no está cargado. Procediendo a compilar e instalar."

[[ -x "$SCRIPT" ]] || fail "Script $SCRIPT no encontrado o no ejecutable"

if "$SCRIPT"; then
    log "Compilación e instalación completada con éxito."
else
    fail "Fallo al ejecutar $SCRIPT"
fi
