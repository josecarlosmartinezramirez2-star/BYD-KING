# BYD King 2025 (DiLink): interfaz y apps

Herramientas y plan para personalizar la pantalla del BYD King **sin tocar** bus CAN,
clima, luces, puertas ni firmware.

## Plan elegido

| Qué | Cómo | Estado |
|---|---|---|
| Interfaz nueva | [Kinex](https://kinex.lexwah.com/) como pantalla de inicio (soporta vertical) | Script listo |
| Fondos | Estilos de Kinex: claro, oscuro Default o Jet black | Incluido en Kinex |
| Estadísticas de viaje | [BYD Trip Stats](https://github.com/angoikon/byd-trip-stats) + datos de viaje de Kinex | Script listo |
| Velocímetro y tablero | Velocímetro en vivo de Kinex en la pantalla central; tablero de Kinex si el auto lo permite | Script listo |
| CarPlay vertical | Descartado | — |

## Pasos (en la Mac, en la misma WiFi que el auto)

```bash
chmod +x byd-conectar.sh byd-apps.sh
./byd-conectar.sh                 # 1. diagnóstico: encuentra el auto y guarda la conexión
./byd-apps.sh instalar kinex      # 2. interfaz nueva
./byd-apps.sh instalar viajes     # 3. estadísticas de viaje
./byd-apps.sh tablero             # 4. velocímetro de Kinex en el tablero
```

Para deshacer:

```bash
./byd-apps.sh quitar kinex        # regresa a la pantalla de inicio de BYD
./byd-apps.sh quitar viajes
```

### 1. Diagnóstico (`byd-conectar.sh`)

Instala `adb` con Homebrew si falta, busca el auto (puerto 5555), se conecta y deja en `~/BYD/`:

| Archivo | Contenido |
|---|---|
| `pantalla.png` | Captura de la pantalla del auto |
| `getprop.txt` | Propiedades del sistema (versión de Android y DiLink) |
| `paquetes.txt` | Apps instaladas hoy, para poder revertir cambios |
| `launcher-original.txt` | Pantalla de inicio de BYD, para regresar a ella |
| `serial.txt` | Conexión que usa `byd-apps.sh` |

Solo lee datos (`getprop`, `wm size`, `pm list packages`, `screencap`).

Si no encuentra el puerto 5555, la depuración ADB por red no está activa. Hay que activarla en
el auto siguiendo el paso 1 de la [guía de Kinex](https://kinex.lexwah.com/#install) (código en
la app Teléfono, clave a partir del IMEI y menú Test Tool). BYD la bloqueó en firmwares
posteriores a 2407 y en DiLink 5 ([ahmada3mar/BYD](https://github.com/ahmada3mar/BYD)).
No es oficial y puede afectar la garantía.

### 2. Interfaz: Kinex (`byd-apps.sh instalar kinex`)

Descarga la última versión de [kinex-dist](https://github.com/lexwah/kinex-dist/releases),
la instala y la abre. Después, en Settings de Kinex:

- **Default Launcher:** para que sea la pantalla de inicio.
- **Dark mode style:** Default (azulado) o Jet black.
- **Instrument cluster dashboard:** tablero personalizado (ver paso 4).

A tener en cuenta:
- El King (Qin Plus) no está en su lista de modelos probados; está hecho para DiLink 3.
- Es de código cerrado y pide muchos permisos (contactos, micrófono, cámara, ubicación),
  propios de un launcher con teléfono, voz y cámaras.
- Trae botones de puertas, ventanas y cajuela, y su propio CarPlay: no se usan.
- Kinex dibuja su propio fondo; no acepta imágenes. Con la interfaz de BYD se usan los temas
  de fábrica.

### 3. Viajes: BYD Trip Stats (`byd-apps.sh instalar viajes`)

Elige la versión DiLink 3 (Android 10-11) o DiLink 5 (Android 12+) según el auto. Registra
viajes, consumo de gasolina y electricidad (tiene desglose para híbridos) y cargas. Es de
código abierto. En la pantalla del auto:

- Elegir el modelo; si el King no aparece, no forzar otro.
- Tocar **Authorize** y luego **Allow**: la app usa ADB del propio auto para seguir activa.
- Dejar apagado el acceso remoto (web companion) si no se usa.

### 4. Velocímetro (`byd-apps.sh tablero`)

Kinex dibuja su tablero como una pantalla más de Android. El script lista las pantallas que ve
Android (solo lectura):

- **Una sola pantalla:** el tablero del King es un equipo aparte y solo se cambiaría modificando
  su firmware, que no se toca. Queda el velocímetro en vivo de Kinex en la pantalla central.
- **Dos o más:** abre Kinex para activar **Instrument cluster dashboard** en Settings. Probar
  estacionado y confirmar que la velocidad y los testigos de fábrica siguen visibles. Para
  regresar al tablero de fábrica, desactivarlo o apagar y prender el auto.

## Calidad de sonido

El King 2024-2025 trae 6 bocinas según [Autocosmos](https://noticias.autocosmos.com.mx/2024/04/17/el-byd-king-dm-i-ya-esta-en-mexico-un-sedan-hibrido-enchufable-a-precio-de-prius)
(el 2027 sube a 8). El software mejora poco; la mejora grande es de hardware.

Gratis, desde hoy:
1. Escuchar por CarPlay con cable en lugar de Bluetooth.
2. Calidad máxima en la app de música (Spotify "Muy alta", Apple Music sin pérdida) y canciones
   descargadas.
3. Un solo ecualizador: el del auto en plano y el del iPhone apagado, sin efectos de sonido.
4. Balance y fader centrados al asiento del conductor.

Hardware, de menor a mayor costo (con un instalador de audio, en el cableado de bocinas, no en
el bus CAN): material insonorizante en puertas, bocinas delanteras de componentes, procesador DSP
con amplificador y subwoofer. Referencia: [Rapid Radio](https://www.rapidradio.co.nz/pages/audio-upgrades-byd).

## Lo que no se toca

- Firmware del tablero: muestra velocidad y testigos de seguridad.
- Sonido exterior AVAS (aviso a peatones), Engine Sound y sonido de arranque.
- Root, ROM modificada, desbloqueo de región o actualizaciones de firmware.
- Funciones de control del auto de cualquier app (puertas, ventanas, clima, luces).

## Seguridad

ADB por red da control del sistema a cualquiera en la misma WiFi o en el hotspot del auto.
**Apágala al terminar** y no instales APK de fuentes desconocidas
([Sesame Disk](https://sesamedisk.com/community-modding-byd-android-head-unit/)).
