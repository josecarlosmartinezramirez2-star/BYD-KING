#!/bin/bash
# Conecta por ADB (WiFi) al BYD King (DiLink), muestra versiones y toma una captura.
# Solo lectura: getprop y screencap. No toca CAN, clima, luces, puertas ni firmware.
#
# Uso (en la Mac, en la misma WiFi que el auto):
#   ./byd-conectar.sh                 # busca el auto en la red local (puerto 5555)
#   ./byd-conectar.sh 192.168.1.50    # usa esa IP directamente

set -u

PUERTO=5555
DESTINO="$HOME/BYD"

# 1. adb (se instala con Homebrew si falta)
if ! command -v adb >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$b" ]; then eval "$("$b" shellenv)"; break; fi
    done
  fi
  if ! command -v brew >/dev/null 2>&1; then
    echo "No están adb ni Homebrew. Instala Homebrew (https://brew.sh) y vuelve a ejecutar." >&2
    exit 1
  fi
  echo "Instalando android-platform-tools…"
  brew install android-platform-tools || exit 1
fi
echo "adb: $(adb version | head -1)"

# 2. Buscar en la /24 de la Mac los equipos con el puerto 5555 abierto
buscar_auto() {
  local iface ip_mac base tmp i h
  iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
  ip_mac=$(ipconfig getifaddr "${iface:-en0}")
  if [ -z "$ip_mac" ]; then
    echo "No se pudo obtener la IP de la Mac (¿WiFi conectada?)." >&2
    return 1
  fi
  base=${ip_mac%.*}
  echo "Buscando puerto $PUERTO en $base.0/24 (Mac: $ip_mac)…" >&2
  tmp=$(mktemp -d)
  for i in $(seq 1 254); do
    h="$base.$i"
    [ "$h" = "$ip_mac" ] && continue
    ( nc -z -G 1 -w 1 "$h" "$PUERTO" >/dev/null 2>&1 && touch "$tmp/$h" ) &
  done
  wait
  ls "$tmp"
  rm -rf "$tmp"
}

if [ $# -ge 1 ]; then
  candidatos=$1
else
  candidatos=$(buscar_auto) || exit 1
fi
if [ -z "$candidatos" ]; then
  echo "Ningún equipo con el puerto $PUERTO abierto. Revisa que la depuración ADB por red" >&2
  echo "esté activa en el auto y que la WiFi no aísle a los clientes entre sí." >&2
  exit 1
fi
echo "Puerto $PUERTO abierto en: $(echo $candidatos)"

# 3. adb connect a cada candidato; se elige el que reporta fabricante BYD
estado() { adb devices | awk -v s="$1" '$1==s {print $2}'; }

SERIAL=""
PRIMERO=""
for h in $candidatos; do
  s="$h:$PUERTO"
  adb connect "$s"
  st=$(estado "$s")
  if [ "$st" = "unauthorized" ]; then
    echo "Acepta en la pantalla del auto el aviso de depuración USB (espero 30 s)…"
    for _ in $(seq 1 30); do
      sleep 1
      st=$(estado "$s")
      [ "$st" = "device" ] && break
    done
  fi
  if [ "$st" != "device" ]; then
    echo "$s: estado '${st:-sin conexión}', se omite."
    continue
  fi
  marca=$(adb -s "$s" shell getprop ro.product.manufacturer | tr -d '\r')
  echo "$s → $marca $(adb -s "$s" shell getprop ro.product.model | tr -d '\r')"
  [ -z "$PRIMERO" ] && PRIMERO=$s
  case $(echo "$marca" | tr '[:upper:]' '[:lower:]') in
    *byd*) SERIAL=$s; break ;;
  esac
done

if [ -z "$SERIAL" ]; then
  if [ -z "$PRIMERO" ]; then
    echo "No se pudo conectar a ningún equipo." >&2
    exit 1
  fi
  SERIAL=$PRIMERO
  echo "Aviso: ningún equipo reporta fabricante BYD; uso $SERIAL." >&2
fi

echo
adb devices

# 4. Versiones (getprop) y captura de pantalla
p() { adb -s "$SERIAL" shell getprop "$1" | tr -d '\r'; }

mkdir -p "$DESTINO"
adb -s "$SERIAL" shell getprop | tr -d '\r' > "$DESTINO/getprop.txt"

echo
echo "Equipo:      $(p ro.product.manufacturer) $(p ro.product.model)"
echo "Android:     $(p ro.build.version.release) (API $(p ro.build.version.sdk))"
echo "Build:       $(p ro.build.display.id)"
echo "Parche seg.: $(p ro.build.version.security_patch)"
echo "Pantalla:    $(adb -s "$SERIAL" shell wm size | tr -d '\r' | tr '\n' ' ')"
echo "Densidad:    $(adb -s "$SERIAL" shell wm density | tr -d '\r' | tr '\n' ' ')"

# Lista de apps instaladas como punto de partida, para poder revertir cambios después
adb -s "$SERIAL" shell pm list packages | tr -d '\r' | sort > "$DESTINO/paquetes.txt"
echo "Apps instaladas: $(wc -l < "$DESTINO/paquetes.txt" | tr -d ' ') (lista en $DESTINO/paquetes.txt)"
echo
echo "Propiedades BYD/DiLink (la versión de DiLink sale en alguna de estas):"
props_byd=$(grep -iE 'byd|dilink' "$DESTINO/getprop.txt" | head -40)
echo "${props_byd:-  (ninguna)}"
echo "Lista completa: $DESTINO/getprop.txt"

adb -s "$SERIAL" exec-out screencap -p > "$DESTINO/pantalla.png"
if [ -s "$DESTINO/pantalla.png" ] && head -c 8 "$DESTINO/pantalla.png" | grep -q PNG; then
  echo "Captura: $DESTINO/pantalla.png"
else
  echo "La captura falló o no es un PNG válido: $DESTINO/pantalla.png" >&2
  exit 1
fi
