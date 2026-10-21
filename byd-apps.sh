#!/bin/bash
# Instala o quita en el BYD las apps del plan: Kinex (interfaz), BYD Trip Stats (viajes) y
# Aurora Store (tienda para Spotify, Waze, etc.), y ajusta el tamaño de la interfaz.
# Antes hay que correr ./byd-conectar.sh, que guarda la conexión en ~/BYD.
#
# Uso:
#   ./byd-apps.sh instalar kinex     # interfaz nueva
#   ./byd-apps.sh instalar viajes    # estadísticas de viaje
#   ./byd-apps.sh instalar tienda    # tienda de apps (Spotify, Waze, Google Maps…)
#   ./byd-apps.sh tablero            # velocímetro de Kinex en el tablero, si el auto lo permite
#   ./byd-apps.sh escala 200         # letras e íconos más grandes (más alto = más grande)
#   ./byd-apps.sh escala normal      # tamaño de fábrica
#   ./byd-apps.sh quitar kinex       # regresa a la interfaz de BYD
#   ./byd-apps.sh quitar viajes|tienda

set -u

DESTINO="$HOME/BYD"
# adb descargado por byd-conectar.sh cuando no hay Homebrew
[ -x "$DESTINO/platform-tools/adb" ] && PATH="$DESTINO/platform-tools:$PATH"

uso() {
  echo "Uso: $0 instalar|quitar kinex|viajes|tienda" >&2
  echo "     $0 tablero" >&2
  echo "     $0 escala <100-400>|normal" >&2
  exit 1
}

accion=${1:-}
case $accion in
  instalar|quitar) [ $# -eq 2 ] || uso; app=$2 ;;
  tablero)         [ $# -eq 1 ] || uso; app=kinex ;;
  escala)          [ $# -eq 2 ] || uso; app=""; valor=$2 ;;
  *) uso ;;
esac

case $app in
  kinex)  PAQUETE=com.lexwah.kinex;  NOMBRE=Kinex ;;
  viajes) PAQUETE=com.byd.tripstats; NOMBRE="BYD Trip Stats" ;;
  tienda) PAQUETE=com.aurora.store;  NOMBRE="Aurora Store" ;;
  "")     [ "$accion" = "escala" ] || uso ;;
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

if [ "$accion" = "escala" ]; then
  case $valor in
    normal) a shell wm density reset ;;
    ""|*[!0-9]*) uso ;;
    *)
      if [ "$valor" -lt 100 ] || [ "$valor" -gt 400 ]; then
        echo "Usa un valor entre 100 y 400 (más alto = letras e íconos más grandes)." >&2
        exit 1
      fi
      a shell wm density "$valor"
      ;;
  esac
  a shell wm density | tr -d '\r'
  echo "Si algo se ve cortado, regresa al tamaño de fábrica: $0 escala normal"
  exit 0
fi

if [ "$accion" = "tablero" ]; then
  if ! a shell pm list packages "$PAQUETE" | grep -q "$PAQUETE"; then
    echo "Primero instala Kinex: $0 instalar kinex" >&2
    exit 1
  fi
  # Kinex dibuja su tablero como una pantalla más de Android. Si el tablero del auto no
  # aparece como pantalla, solo se cambiaría con firmware, y eso no se toca.
  pantallas=$(a shell dumpsys display | tr -d '\r' | grep 'DisplayDeviceInfo{' \
    | sed -nE 's/.*DisplayDeviceInfo\{"([^"]*)": uniqueId="([^"]*)", ([0-9]+ x [0-9]+).*, type ([A-Z_]+).*/\2|\1: \3 (\4)/p' \
    | sort -u)
  echo "Pantallas que ve Android:"
  echo "$pantallas" | cut -d'|' -f2- | sed 's/^/  - /'
  echo
  if [ "$(echo "$pantallas" | grep -c .)" -lt 2 ]; then
    cat <<EOF
El tablero no aparece como pantalla de Android: es un equipo aparte y solo se cambiaría
modificando su firmware, que no se toca. El velocímetro en vivo de Kinex sigue disponible
en la pantalla central.
EOF
    exit 0
  fi
  a shell monkey -p "$PAQUETE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  cat <<EOF
Android ve más de una pantalla, así que Kinex probablemente puede dibujar su velocímetro
en el tablero. Kinex quedó abierto; con el auto estacionado:
  1. Settings > Instrument cluster dashboard: actívalo y elige qué datos mostrar.
  2. Ajusta los márgenes en Settings si algo se corta o queda tapado.
  3. Confirma que la velocidad y los testigos de fábrica siguen visibles.
Para regresar al tablero de fábrica: desactívalo en Settings, o apaga y prende el auto.
EOF
  exit 0
fi

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
  tienda)
    if [ "$sdk" -lt 23 ]; then
      echo "Aurora Store necesita Android 6 o superior (el auto tiene API $sdk)." >&2
      exit 1
    fi
    codigo=$(curl -fsSL https://f-droid.org/api/v1/packages/com.aurora.store \
      | grep -o '"suggestedVersionCode":[0-9]*' | cut -d: -f2)
    if [ -z "$codigo" ]; then
      echo "No se pudo consultar la versión de Aurora Store en F-Droid." >&2
      exit 1
    fi
    url=https://f-droid.org/repo/com.aurora.store_$codigo.apk
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
rm -f "$apk"   # ya está en el auto; no ocupar espacio en la Mac
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
  tienda)
    if a shell pm list packages com.google.android.gms | grep -q com.google.android.gms; then
      google="El auto tiene servicios de Google: Google Maps y YouTube Music deberían funcionar."
    else
      google="El auto NO tiene servicios de Google: Spotify funciona; Google Maps y YouTube Music
  probablemente no abran y Waze puede fallar. Para navegar, Kinex trae su propio mapa."
    fi
    cat <<EOF
En la pantalla del auto, dentro de Aurora Store:
  - Elige "Sesión anónima" (no hace falta tu cuenta de Google).
  - Busca e instala: Spotify, Waze, Google Maps, YouTube Music.
  - Si al instalar sale un error de permisos, falta el paso del PackageInstaller de
    https://kinex.lexwah.com/#install
$google
Video (YouTube, Netflix): solo con el auto estacionado o cargando.
Para quitarla: $0 quitar tienda
EOF
    ;;
esac
