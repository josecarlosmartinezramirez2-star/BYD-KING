#!/bin/bash
# Instala o quita en el BYD las apps del plan: Kinex (interfaz) y BYD Trip Stats (viajes).
# Antes hay que correr ./byd-conectar.sh, que guarda la conexión en ~/BYD.
#
# Uso:
#   ./byd-apps.sh instalar kinex     # interfaz nueva
#   ./byd-apps.sh instalar viajes    # estadísticas de viaje
#   ./byd-apps.sh quitar kinex       # regresa a la interfaz de BYD
#   ./byd-apps.sh quitar viajes

set -u

DESTINO="$HOME/BYD"

uso() {
  echo "Uso: $0 instalar|quitar kinex|viajes" >&2
  exit 1
}

[ $# -eq 2 ] || uso
accion=$1
app=$2

case $app in
  kinex)  PAQUETE=com.lexwah.kinex;  NOMBRE=Kinex ;;
  viajes) PAQUETE=com.byd.tripstats; NOMBRE="BYD Trip Stats" ;;
  *) uso ;;
esac

if [ ! -s "$DESTINO/serial.txt" ]; then
  echo "Primero corre ./byd-conectar.sh para encontrar el auto." >&2
  exit 1
fi
SERIAL=$(cat "$DESTINO/serial.txt")
adb connect "$SERIAL" >/dev/null
if [ "$(adb devices | awk -v s="$SERIAL" '$1==s {print $2}')" != "device" ]; then
  echo "No hay conexión con $SERIAL. Vuelve a correr ./byd-conectar.sh." >&2
  exit 1
fi

a() { adb -s "$SERIAL" "$@"; }
sdk=$(a shell getprop ro.build.version.sdk | tr -d '\r')
sdk=${sdk:-0}

if [ "$accion" = "quitar" ]; then
  a uninstall "$PAQUETE" || exit 1
  if [ "$app" = "kinex" ] && [ -s "$DESTINO/launcher-original.txt" ]; then
    a shell cmd package set-home-activity "$(cat "$DESTINO/launcher-original.txt")" >/dev/null 2>&1
  fi
  echo "$NOMBRE quitado."
  exit 0
fi
[ "$accion" = "instalar" ] || uso

case $app in
  kinex)
    if [ "$sdk" -lt 24 ]; then
      echo "Kinex necesita Android 7 o superior (el auto tiene API $sdk)." >&2
      exit 1
    fi
    url=https://github.com/lexwah/kinex-dist/releases/latest/download/kinex.apk
    ;;
  viajes)
    if [ "$sdk" -lt 29 ]; then
      echo "BYD Trip Stats necesita Android 10 o superior (el auto tiene API $sdk)." >&2
      exit 1
    fi
    # DiLink 3 y 4 son Android 10-11; DiLink 5 (Android 12+) tiene su propia versión
    if [ "$sdk" -ge 31 ]; then variante=dilink5; else variante=dilink3; fi
    url=$(curl -fsSL https://api.github.com/repos/angoikon/byd-trip-stats/releases/latest \
      | grep -o "https://[^\"]*$variante[^\"]*\.apk" | head -1)
    if [ -z "$url" ]; then
      echo "No se encontró el APK $variante en GitHub." >&2
      exit 1
    fi
    ;;
esac

mkdir -p "$DESTINO/apks"
apk="$DESTINO/apks/$app.apk"
echo "Descargando $NOMBRE…"
curl -fL --progress-bar -o "$apk" "$url" || exit 1
if [ "$(head -c 2 "$apk")" != "PK" ]; then
  echo "La descarga no es un APK válido: $apk" >&2
  exit 1
fi

echo "Instalando en el auto (puede tardar un par de minutos por WiFi)…"
if ! a install -r "$apk"; then
  echo "La instalación falló. Si el auto no permite apps de terceros, sigue el paso 1 de" >&2
  echo "https://kinex.lexwah.com/#install (activar depuración e instalación de apps)." >&2
  exit 1
fi
a shell monkey -p "$PAQUETE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
echo "$NOMBRE instalado y abierto en la pantalla del auto."
echo

case $app in
  kinex)
    cat <<EOF
En la pantalla del auto, dentro de Settings de Kinex:
  - Default Launcher: para que Kinex sea tu pantalla de inicio.
  - Dark mode style: fondo Default (azulado) o Jet black (negro profundo).
  - Instrument cluster dashboard: tablero personalizado (solo en modelos compatibles).
    Pruébalo estacionado y confirma que la velocidad y los testigos sigan visibles;
    apagar y prender el auto regresa el tablero de fábrica.
Para volver a la interfaz de BYD: $0 quitar kinex
EOF
    ;;
  viajes)
    cat <<EOF
En la pantalla del auto ($variante):
  - Elige tu modelo y deja que termine la configuración. Si el King no aparece, avísame.
  - Cuando lo pida, toca Authorize y luego Allow en el aviso del auto.
  - Deja apagado el acceso remoto (web companion) si no lo vas a usar.
Para quitarla: $0 quitar viajes
EOF
    ;;
esac
