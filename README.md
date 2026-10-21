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

**Elegido: Kinex.** El King (Qin Plus) no está en su lista de modelos probados; "puede funcionar",
pero hay que confirmarlo con la versión de DiLink que reporte el diagnóstico.

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

### Calidad de sonido

El King 2024-2025 trae 6 bocinas según [Autocosmos](https://noticias.autocosmos.com.mx/2024/04/17/el-byd-king-dm-i-ya-esta-en-mexico-un-sedan-hibrido-enchufable-a-precio-de-prius)
(el 2027 sube a 8). El software mejora poco; la mejora grande es de hardware.

Gratis, desde hoy:
1. Escuchar por CarPlay con cable en lugar de Bluetooth.
2. Calidad máxima en la app de música (Spotify "Muy alta", Apple Music sin pérdida) y canciones
   descargadas, para que la señal del celular no baje la calidad.
3. Un solo ecualizador: el del auto en plano para empezar y el del iPhone apagado (o al revés),
   sin efectos de sonido ni realce de graves. Si distorsiona a volumen alto, bajar graves.
4. Balance y fader centrados al asiento del conductor.

Hardware, de menor a mayor costo (con un instalador de audio, conectado al cableado de bocinas,
no al bus CAN):
1. Material insonorizante en las puertas delanteras.
2. Bocinas delanteras de componentes (tweeter + woofer).
3. Procesador DSP con amplificador: corrige tiempos y ecualización de cada bocina. Es lo que más
   acerca al sonido "lo mejor posible".
4. Subwoofer.

Referencia de paquetes por niveles: [Rapid Radio](https://www.rapidradio.co.nz/pages/audio-upgrades-byd).
Conviene preguntar a BYD cómo afecta a la garantía.

### Sonidos de puertas y seguros

[Door Sound](https://github.com/wheregoes/byd-apps) cambia los sonidos interiores de puertas,
cajuela, seguros y ventanas. Solo **lee** si una puerta se abre o se cierra; no las controla.
Está probado en DiLink 3 (Dolphin), en un Song Pro
[no sonaba con la app cerrada](https://github.com/wheregoes/byd-apps/issues/5) y no funciona en
DiLink 5.

No se toca:
- El sonido exterior AVAS (aviso a peatones, obligatorio por seguridad).
- Engine Sound, que escribe ajustes en el vehículo.
- El sonido de arranque, que está en la partición del sistema y requiere root.

### Tablero (velocímetro)

El cuadro de 8.8" es un equipo aparte de la pantalla central. No hay herramientas de la
comunidad para rediseñarlo, y hacerlo implicaría modificar su firmware. No se toca: muestra
velocidad y testigos de seguridad. Lo posible:
- Los estilos de fábrica, si el King los trae (otros BYD tienen "clásico" y "minimalista", con
  modo claro y oscuro, en el [manual del Seal](https://www.bydauto.ie/assets/1/owners/owners-manuals/byd-seal-owners-manual-right-hand-drive-en.pdf)).
- Navegación en el tablero: solo en DiLink 5.x con apps como DiPlay.

### Más cosas

| Qué | Requisito |
|---|---|
| Spotify, YouTube Music, Waze o Google Maps directo en la pantalla (en vertical) | Instalar APK |
| Video (YouTube, Netflix) solo con el auto estacionado o cargando | Instalar APK |
| Tamaño de letra e íconos de toda la interfaz (`wm density`, reversible) | ADB |
| Fondos y temas de fábrica | Nada |
| Estadísticas de viajes y consumo (solo lectura) | ADB |

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
