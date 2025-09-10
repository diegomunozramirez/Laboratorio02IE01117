#!/usr/bin/env bash
# ejercicio1.sh
# Uso: sudo ./ejercicio1.sh <usuario> <grupo> <ruta_archivo>
# Ejemplo: sudo ./ejercicio1.sh diego devs /home/diego/texto.txt

set -euo pipefail

log() { echo "[$(date +'%F %T')] $*"; }
err() { echo "[$(date +'%F %T')] ERROR: $*" >&2; }

# 1) Verificar root
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  err "Este script debe ejecutarse como root."
  exit 1
fi

# 2) Validar parámetros
if [[ $# -ne 3 ]]; then
  err "Uso: $0 <usuario> <grupo> <ruta_archivo>"
  exit 1
fi

USUARIO="$1"
GRUPO="$2"
ARCHIVO="$3"

# 3) Verificar existencia del archivo
if [[ ! -e "$ARCHIVO" ]]; then
  err "El archivo '$ARCHIVO' no existe. Terminando."
  exit 1
fi

# 4) Crear grupo si no existe
if getent group "$GRUPO" >/dev/null 2>&1; then
  log "El grupo '$GRUPO' ya existe."
else
  log "Creando grupo '$GRUPO'..."
  groupadd "$GRUPO"
  log "Grupo '$GRUPO' creado."
fi

# 5) Crear usuario si no existe; si existe, agregarlo al grupo
if id -u "$USUARIO" >/dev/null 2>&1; then
  log "El usuario '$USUARIO' ya existe. Agregándolo al grupo '$GRUPO'..."
  usermod -a -G "$GRUPO" "$USUARIO"
  log "Usuario '$USUARIO' agregado al grupo '$GRUPO'."
else
  log "Creando usuario '$USUARIO' con grupo primario '$GRUPO'..."
  useradd -m -g "$GRUPO" "$USUARIO"
  log "Usuario '$USUARIO' creado."
fi

# 6) Cambiar propietario y grupo del archivo
log "Cambiando propietario y grupo de '$ARCHIVO' a '$USUARIO:$GRUPO'..."
chown "$USUARIO:$GRUPO" "$ARCHIVO"

# 7) Permisos: usuario rwx (7), grupo r-- (4), otros --- (0) => 740
log "Aplicando permisos 740 a '$ARCHIVO' (u=rwx,g=r,o=)..."
chmod 740 "$ARCHIVO"

log "Listo. Revisa: ls -l '$ARCHIVO'"
