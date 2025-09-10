#!/usr/bin/env bash
# ejercicio2.sh
# Uso: ./ejercicio2.sh <comando y argumentos...>
# Ejemplos:
#   ./ejercicio2.sh sleep 5
#   ./ejercicio2.sh firefox
#   ./ejercicio2.sh bash -c 'yes > /dev/null'

set -euo pipefail

INTERVALO="${INTERVALO:-1}"   # segundos entre muestras (ajustable por variable de entorno)
OUTDIR="${OUTDIR:-./logs}"    # carpeta de salida (ajustable)
mkdir -p "$OUTDIR"

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <comando y argumentos...>" >&2
  exit 1
fi

TS="$(date +'%Y%m%d_%H%M%S')"
LOGCSV="$OUTDIR/monitoreo_${TS}.csv"
CMD_STR="$*"

echo "Comando a ejecutar: $CMD_STR"
echo "Muestreo cada ${INTERVALO}s. Log: $LOGCSV"
echo "timestamp_iso,elapsed_s,cpu_percent,mem_percent,rss_kb,vsz_kb" > "$LOGCSV"

# Lanzar el proceso en background y capturar PID
# shellcheck disable=SC2068
"$@" &
PID=$!

INICIO=$(date +%s)

# Función para saber si el PID sigue vivo
sigue_vivo() { kill -0 "$PID" 2>/dev/null; }

# Bucle de muestreo
while sigue_vivo; do
  AHORA=$(date +%s)
  ELAPSED=$((AHORA - INICIO))
  ISO="$(date +'%F %T')"

  # Obtener métricas del proceso
  # %cpu y %mem; rss (KB), vsz (KB)
  if OUT=$(ps -p "$PID" -o %cpu=,%mem=,rss=,vsz= 2>/dev/null); then
    CPU=$(awk '{print $1}' <<<"$OUT")
    MEM=$(awk '{print $2}' <<<"$OUT")
    RSS=$(awk '{print $3}' <<<"$OUT")
    VSZ=$(awk '{print $4}' <<<"$OUT")
    echo "$ISO,$ELAPSED,$CPU,$MEM,$RSS,$VSZ" >> "$LOGCSV"
  fi

  sleep "$INTERVALO"
done

echo "El proceso (PID $PID) finalizó. Generando gráficas con gnuplot..."

# Generar gráficas con gnuplot (CPU% y MEM%)
GNUPLOT_SCRIPT="$OUTDIR/plot_${TS}.gp"
PNG_CPU="$OUTDIR/cpu_${TS}.png"
PNG_MEM="$OUTDIR/mem_${TS}.png"

cat > "$GNUPLOT_SCRIPT" <<EOF
set datafile separator ","
set term pngcairo size 1280,720
set grid

# CPU
set output "${PNG_CPU}"
set title "Uso de CPU vs tiempo"
set xlabel "Tiempo (s)"
set ylabel "CPU (%)"
plot "${LOGCSV}" using 2:3 with lines title "CPU %"

# MEM
set output "${PNG_MEM}"
set title "Uso de Memoria vs tiempo"
set xlabel "Tiempo (s)"
set ylabel "Memoria (%)"
plot "${LOGCSV}" using 2:4 with lines title "MEM %"
EOF

if command -v gnuplot >/dev/null 2>&1; then
  gnuplot "$GNUPLOT_SCRIPT"
  echo "Gráficas generadas:"
  echo " - $PNG_CPU"
  echo " - $PNG_MEM"
else
  echo "ADVERTENCIA: gnuplot no está instalado. Instálalo y ejecuta:"
  echo "  gnuplot $GNUPLOT_SCRIPT"
fi

echo "Listo. Log CSV: $LOGCSV"
