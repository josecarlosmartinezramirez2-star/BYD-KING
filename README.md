# BYD King 2025 (DiLink): interfaz y apps

Herramientas y plan para personalizar la pantalla del BYD King **sin tocar** bus CAN,
clima, luces, puertas ni firmware.

## 1. Diagnóstico (primer paso, en la Mac)

```bash
chmod +x byd-conectar.sh
./byd-conectar.sh              # busca el auto en la WiFi (puerto 5555)
./byd-conectar.sh 192.168.x.y  # o con la IP del auto
```

Instala `adb` con Homebrew si falta, busca el auto, se conecta y deja en `~/BYD/`:

| Archivo | Contenido |
|---|---|
| `pantalla.png` | Captura de la pantalla del auto |
| `getprop.txt` | Todas las propiedades del sistema (versión de Android y DiLink) |
| `paquetes.txt` | Apps instaladas hoy, para poder revertir cambios |

Además muestra la resolución y densidad de la pantalla, necesarias para diseñar una interfaz.
Solo ejecuta comandos de lectura (`getprop`, `wm size`, `pm list packages`, `screencap`).

Si no encuentra el puerto 5555 abierto, la depuración ADB por red no está activa. BYD la
bloqueó en firmwares posteriores a 2407 y en DiLink 5 ([ahmada3mar/BYD](https://github.com/ahmada3mar/BYD),
[BYDMate](https://github.com/AndyShaman/BYDMate/blob/main/README.en.md)). Los métodos de la
comunidad para reactivarla usan un menú oculto y un generador de claves a partir del IMEI.
No son oficiales y pueden afectar la garantía.

## 2. Lo que se puede cambiar y lo que sugiero

Todo depende de la versión de DiLink que reporte el diagnóstico. La mayoría de las
herramientas de la comunidad están probadas en **DiLink 3**; en DiLink 4 funcionan
parcialmente y en DiLink 5 casi nada.

### Interfaz nueva (launcher): recomendado

| Opción | Estado | Notas |
|---|---|---|
| [Kinex](https://kinex.lexwah.com/) | Gratis, DiLink 3 (DiLink 5 parcial) | **Soporta modo vertical** desde 0.0.9. Trae botones de puertas, ventanas y cajuela: no usarlos para respetar tus límites. |
| [ESMER·UI](https://github.com/akyuznet/ESMER-UI) | Código abierto, DiLink 3 | Pantalla de inicio libre con widgets. |
| [Kim Launcher](https://kimlauncher.pro/) | DiLink 3 | Solo horizontal. |
| Launcher propio | A la medida | Se puede construir una vez conocida la versión de Android, la resolución y si el auto permite instalar APK. |

Para volver atrás basta con desinstalar el launcher o elegir otra vez el de BYD como inicio.

### CarPlay en vertical: no es viable hoy

- BYD está quitando la pantalla giratoria de sus modelos nuevos porque "limitará el uso de
  aplicaciones"; la prensa señala a CarPlay y Android Auto como las más afectadas
  ([Motorpasión, nov 2025](https://www.motorpasion.com.mx/industria/pantalla-giratoria-byd-desaparece)).
  CarPlay de fábrica en BYD funciona en horizontal.
- [DiPlay](https://github.com/shihabal3amri/DiPlay) es un receptor de CarPlay no oficial que se
  instala en DiLink. No documenta modo vertical. Además usa una identidad de accesorio extraída
  del firmware de Carlinkit, así que Apple podría bloquearlo en cualquier actualización de iOS.
  No lo recomiendo.
- **Alternativa que sí funciona en vertical:** usar navegación nativa (Waze o Google Maps
  instalados en DiLink) con la pantalla vertical, y CarPlay en horizontal para música y llamadas.
  Para esto hay que poder instalar APK.

### Sonidos

- **Sí:** el ecualizador y los modos de audio de la configuración de fábrica.
- **Con reservas:** [Door Sound](https://github.com/wheregoes/byd-apps) cambia los sonidos
  interiores de puertas y seguros. Lee eventos de puertas a través del servicio de vehículo de
  BYD, lo que choca con tu regla de no tocar puertas. Solo está probado en DiLink 3.
- **No:** el sonido exterior AVAS (aviso a peatones, obligatorio por seguridad) y Engine Sound,
  que escribe ajustes en el vehículo.
- El sonido de arranque está en la partición del sistema; cambiarlo requiere root. No lo recomiendo.

### Lo que no conviene

- Root, ROM modificada, desbloqueo de región o cambios de firmware: pueden dejar la unidad
  inservible, cortar las actualizaciones OTA y anular la garantía. El desbloqueo de región suele
  revertirse solo cuando el auto se conecta con BYD.
- Apps que controlan el auto por ADB (por ejemplo, las funciones de control de
  [BYDMate](https://github.com/AndyShaman/BYDMate) o de Kinex): fuera de tus límites.

### Seguridad

ADB por red da control del sistema a cualquiera en la misma WiFi o en el hotspot del auto.
**Apágala al terminar** y no instales APK de fuentes desconocidas
([Sesame Disk](https://sesamedisk.com/community-modding-byd-android-head-unit/)).
