#!/usr/bin/env bash
# ejercicio3.sh
# Uso: ./ejercicio3.sh <directorio_a_monitorear> [ruta_log]
# Ejemplo: ./ejercicio3.sh /home/diego/monitorear ./logs/cambios.log
#
# Requiere: inotifywait (paquete inotify-tools)

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <directorio_a_monitorear> [ruta_log]" >&2
  exit 1
fi

DIR="$1"
LOG="${2:-./logs/cambios_$(date +'%Y%m%d').log'}"

mkdir -p "$(dirname "$LOG")"

if ! command -v inotifywait >/dev/null 2>&1; then
  echo "ERROR: inotifywait no está instalado. Instala 'inotify-tools'." >&2
  exit 1
fi

if [[ ! -d "$DIR" ]]; then
  echo "ERROR: El directorio '$DIR' no existe." >&2
  exit 1
fi

echo "[$(date +'%F %T')] Iniciando monitoreo de '$DIR'. Log: $LOG"
echo "timestamp,event,path" >> "$LOG"

# -m: modo continuo
# -e: eventos a observar
# --format con fecha/hora
inotifywait -m -e create -e modify -e delete --timefmt "%F %T" \
  --format "%T,%e,%w%f" "$DIR" >> "$LOG"
