# Novedades en TR4W 4.148

*Consolidado por característica en todas las versiones 4.148.x. Generado a partir de RELEASE_NOTES.md — no editar a mano; volver a ejecutar la habilidad `monthly-changes` para actualizar.*

## Control de Radio

- La configuración de radio de red es más fiable: cada modelo ahora tiene el puerto de red predeterminado y el comportamiento de descubrimiento correctos, y cambiar entre modelos (por ejemplo, IC-7760 → K4) ya no deja un puerto obsoleto. (#1028)
- **Encuentra tu radio en la red automáticamente**: un nuevo botón "Descubrir" en el diálogo de configuración de Radio 1 / Radio 2 escanea tu red local y rellena la dirección IP de la radio por ti. Funciona para las radios de red Elecraft K4 e Icom, y ahora encuentra una radio en cualquier subred en la que se encuentre tu PC. (#853)
- **Puerto de red predeterminado correcto por radio**: cuando eliges un tipo de radio de red, TR4W rellena previamente el puerto TCP correcto para ese modelo (K4, FlexRadio, Kenwood TS-890/TS-990, Icom) para que no tengas que buscarlo. (#968)
- **Configuración más limpia**: dejar un puerto de red en blanco ya no genera un error confuso de "declaración inválida", y una radio sin dirección establecida ya no inunda el registro con reintentos de conexión.
- **El botón Restablecer de la ventana de configuración de la radio ahora restablece completamente el formulario** — borrando la dirección IP y el puerto TCP, configurando RTS/DTR del manipulador a APAGADO, y restaurando el nombre de la radio a su valor predeterminado — el botón **Cerrar** ahora está etiquetado como **Cancelar**, y al cerrar con la **X** se pregunta antes de descartar los cambios no aplicados.

## Control de Radio — Kenwood TS-890 por LAN

- La banda y el modo que se muestran en TR4W ahora siguen a la radio. Anteriormente, solo la frecuencia seguía al equipo; la visualización de la banda, la tabla de bandas y el modo no se actualizaban al cambiar de banda en la radio (y al inicio podía mostrar NONSSB). (#959)
- Ahora se muestra el desplazamiento RIT/XIT (la cantidad real de desplazamiento del clarificador), no solo el estado de encendido/apagado.
- Cuando cambias el VFO operativo de la radio (A/B), TR4W ahora lo sigue correctamente — los modos por VFO ya no aparecen intercambiados, la ventana principal sigue la frecuencia/banda/modo del VFO de recepción, y la ventana de Radio 1 resalta el VFO activo.
- El CW enviado al TS-890 a través de CAT ya no se rellena con ceros, lo que también corrige la longitud de manipulación informada.
- Conectarse a una radio a través de una VPN ya no agota el tiempo de espera — la ventana de conexión era demasiado corta para el apretón de manos ligeramente más largo de una VPN, por lo que un equipo que funcionaba en la red local informaba "Tiempo de espera de conexión agotado" a través de VPN. (#959)

## SO2R / Modo de Radio

- **Una configuración de modo de radio**: las antiguas y conflictivas opciones "Modo de Radio Única" y "Modo de Dos Radios" son ahora una única configuración **MODO DE DOS RADIOS** (VERDADERO = dos radios / SO2R, FALSO = radio única). Los archivos de configuración existentes todavía se cargan — y si ambas configuraciones antiguas están presentes, MODO DE DOS RADIOS ahora prevalece, por lo que una línea sobrante perdida no puede ponerte silenciosamente en el modo incorrecto. (#965)

## Mapa de Bandas

- Hacer doble clic en un spot ya no borra ocasionalmente la indicativa que acaba de cargar en la ventana de indicativas. (Esto solo aparecía con "saltar a S&P al sintonizar" / AUTO S&P habilitado.) (#1048)
- **Resaltado del mapa de bandas de dos radios restaurado**: en modo de dos radios, el mapa de bandas vuelve a resaltar la banda de la radio inactiva (búsqueda y selección) y pone en gris la banda de la radio en funcionamiento — el comportamiento SO2R de antes de la 4.147. (#960)

## CW

- Configurar **`CW ENABLE = FALSE` ahora realmente mantiene el CW apagado** al inicio — la pantalla y la manipulación coinciden, sin necesidad de alternar CW apagado y luego encendido (Alt-K) dos veces. (#1047)
- Presiona **`=` para reenviar exactamente lo último que enviaste** en CW.
- La habilitación/deshabilitación/conmutación de CW ahora se comporta de manera consistente (controlada por un único interruptor interno). (#380)

## Digital / FT8 / WSJT-X

- En un modo digital (por ejemplo, FT8 a través de WSJT-X), **escribir una indicativa ya no manipula CW**. (#1040)
- **La banda sigue a WSJT-X cuando no tienes equipo conectado**: si no hay radio configurada en TR4W, cambiar de banda en WSJT-X ahora mueve TR4W a la banda correspondiente (el indicador de banda, la fila de totales y el mapa de bandas se actualizan). Con una radio conectada, nada cambia. (#978)
- **Registro de contactos de WSJT-X de nuevo**: un cambio reciente había detenido el registro de contactos registrados por WSJT-X (FT8/FT4, ARRL-DIGI, etc.) en TR4W. Ahora se registran correctamente. (#975)
- **Operador ahora registrado en contactos de WSJT-X**: los QSO de WSJT-X ahora rellenan la columna de operador / ID de computadora al igual que los contactos registrados manualmente.
- **Alerta de discrepancia de operador**: si el operador configurado en WSJT-X difiere del operador configurado en TR4W, recibirás una advertencia intermitente en pantalla y un pitido cuando se registre el contacto, para que puedas corregir el que esté mal. Un operador en blanco en WSJT-X no lo activará. (#977)

## DX Cluster

- **Copiar/pegar funciona en el campo de comandos**: Ctrl-V (pegar), Ctrl-C (copiar) y Ctrl-X (cortar) ahora funcionan mientras se escribe un comando de clúster; anteriormente solo funcionaba clic derecho → Pegar. (#23)
- **La conexión ya no congela TR4W**: la conexión del clúster se ejecuta en segundo plano, por lo que conectarse a un host lento o inalcanzable ya no bloquea el programa. Obtiene retroalimentación inmediata: "Conectando a host:puerto", el botón Conectar se atenúa y Desconectar se habilita, y un claro "No se pudo conectar a host:puerto" si falla (la razón técnica completa se guarda en el registro).
- **Se corrigió un bloqueo** que podía ocurrir al mostrar un mensaje de error de conexión largo.
- **Pulido**: los mensajes de estado ya no son verdes y Congelar se desactiva cada vez que se conecta, por lo que siempre regresa a los puntos activos. Una nueva configuración **DEBUG TELNET** registra el tráfico del clúster para la resolución de problemas.
- **Inserte la información de su estación en los comandos del clúster automáticamente**: las líneas en su `cluster_commands.txt` ahora pueden contener marcadores como `{MY_CALL}`, `{MY_STATE}`, `{MY_GRID}`, `{BAND}`, `{FREQ}`, `{DATE}` o `{TIME}` (y más). Cuando elige el comando desde el botón **Comandos** de la ventana del clúster, el marcador se reemplaza con el valor actual antes de enviar el comando, por lo que un archivo de comandos funciona sin importar quién esté operando o en qué banda se encuentre. Pase el cursor sobre un comando para previsualizar exactamente lo que se enviará. Para incluir una llave literal en un comando, duplíquela (`{{` o `}}`). (#973)

## Control del Rotador

- **Soporte PSTRotator**: un nuevo tipo de rotador, **PSTROTATOR**, apunta su antena a través de PSTRotator por la red. Configure TIPO_ROTADOR = PSTROTATOR y DIRECCIÓN_IP_PSTROTATOR / PUERTO_UDP (por defecto 127.0.0.1 : 12000). (#732)
- **Giro de ruta larga**: **Alt-Ctrl-P** gira el rotador a la ruta larga; **Ctrl-P** todavía gira a la ruta corta. (#20)
- Con el registro de depuración en TRACE, los comandos exactos enviados al rotador ahora se registran para la resolución de problemas. (#989)

## Teclas de Función

- Ahora puede **hacer clic derecho en una tecla de función para editar el mensaje de esa tecla** directamente; elige el mensaje correcto de CQ o Búsqueda y Salto para su modo actual. (#1001)
- Hacer clic derecho en una tecla de función mientras se mantiene presionada **Alt o Ctrl** ya no muestra un menú espurio. (#1007)

## Enviar desde el Teclado

- Se corrigió un **diálogo de Entrada de Teclado que podía abrirse duplicado o negarse a cerrarse**. (#1006)

## Búsqueda y Salto

- La etiqueta de envío de llamada F1 muestra **"Llamada" en lugar de "DE+Llamada" cuando DE está deshabilitado** (`DE ENABLE = FALSE`). (#1012)

## Entrada de Datos / Intercambio

- Cuando un intercambio que escribe **no se puede analizar, el cursor ahora se coloca justo después de la parte que no entendió**, para que pueda corregirlo sin tener que buscarlo. (#1010)
- **Error de QTH doméstico más claro**: cuando una sección/QTH ingresada no se reconoce para un concurso doméstico, el mensaje ahora dice **"Sección ARRL no válida"** en lugar de un aviso genérico y mal escrito.

## Cabrillo y Exportación de Registro

- Si el intercambio de un concurso no es manejado por el generador de Cabrillo, esa línea ahora se **marca con un marcador de error (y se registra) en lugar de escribirse en blanco**, para que no pase desapercibida. (#1043)
- La **exportación CSV ya no escribe líneas duplicadas perdidas** para registros omitidos, eliminados o no-QSO.
- **Las opciones de categoría coinciden con la especificación Cabrillo actual**: los menús desplegables de categoría de concurso se actualizan: Transmisor ofrece **DOS**, Modo agrega **FM**, Tiempo agrega **8-HORAS**, Superposición elimina OVER-50 y agrega **YOUTH** y **YL**, y Estación agrega **DISTRIBUTED**, **ROVER-LIMITED**, **ROVER-UNLIMITED** y **EXPLORER**. (#976)
- **Las categorías de Estación, Tiempo y Superposición ahora se mantienen**: la Categoría de Estación es ahora un menú desplegable, y sus elecciones de Tiempo y Superposición se recuerdan la próxima vez que abra el Resumen de Cabrillo; anteriormente no se guardaban.
- **OK cierra el diálogo de exportación**: hacer clic en **OK** en el Resumen de Cabrillo ahora finaliza la exportación y cierra el diálogo. Anteriormente, una exportación exitosa dejaba el diálogo abierto, por lo que tenía que hacer clic en Cancelar para salir.

## VHF

- ARRL Enero, Junio y Septiembre VHF ahora producen el **intercambio RST + grid** adecuado en el archivo Cabrillo.

## Informes y Puntuación

- **Nombres de concursos amigables**: la hoja de resumen y el informe de puntuación ahora muestran un nombre de concurso legible entre paréntesis junto al concurso, para aproximadamente 130 concursos. (#967)

## Concursos

- **Concurso TESLA renombrado a HF-TESLA**: el TESLA Memorial HF CW Contest ahora aparece como **HF-TESLA**, con el nombre Cabrillo correcto. (#745)

## Ventana de Registro

- La **fila inferior de la ventana de registro ya no se corta**; se muestra completamente con un borde limpio, en cada configuración de número de fila. (#1046)

## Pantalla

- Un **mensaje de error de intercambio atascado** (por ejemplo, una clase de Field Day incorrecta) ahora se borra una vez que registra el QSO corregido. (#1030)

## Recuperación de Bloqueos

- **El archivo de reinicio se guarda nuevamente después de cada QSO.** La configuración **ACTUALIZAR ARCHIVO DE REINICIO HABILITADO**, que discretamente no hacía nada durante años, ahora funciona y está **activada por defecto**, por lo que después de un apagado inesperado TR4W restaura más de su estado operativo más reciente. Configure `UPDATE RESTART FILE ENABLE = FALSE` si prefiere que solo guarde al cambiar de operador, cargar registro y salir. (#950)

## Archivos de Configuración

- **`#` ahora funciona como comentario**: puede deshabilitar una línea en un archivo de configuración comenzándola con `#` (además del existente `;`). Anteriormente, una línea que comenzaba con `#` producía un "error en el archivo de configuración".

## Múltiples Operadores / Redes

- Mientras el servidor de red no está accesible, el registro **ya no se llena con mensajes repetidos de "intentando / error al conectar"**. (#1041)

## Conexión Paralela (LPT)

- El instalador ya no incluye inpout32.dll, el componente que varios motores antivirus marcaron como "driver vulnerable", que es lo que causaba que algunos navegadores y herramientas antivirus bloquearan la descarga. Las conexiones serial, USB y de red, así como el control del equipo, no se ven afectadas en absoluto. Si utiliza conexión directa por puerto paralelo (LPT), pedal, manipulador o salida de datos de banda, ahora debe proporcionar usted mismo inpout32.dll: descárguelo de highrez.co.uk y colóquelo en la misma carpeta que tr4w.exe. Si tiene un puerto LPT configurado pero el archivo no está presente, TR4W ahora muestra un recordatorio y sigue ejecutándose, en lugar de fallar al iniciarse.

## Verificación Parcial Súper

- La base de datos de indicativos incluida (TRMASTER.DTA) se ha actualizado nuevamente para ofrecer mejores sugerencias de Super Check Partial mientras escribe.

## Usabilidad

- **Los archivos previsualizados se abren en su editor de texto predeterminado**: las previsualizaciones de registro/resumen/Cabrillo/ADIF (y el archivo de historial) ahora se abren en el editor que haya configurado para archivos .txt (Notepad++, VS Code, etc.), en lugar de siempre en el Bloc de notas. (#986)
- Se corrigió un error tipográfico en la ventana emergente del número de QSO (Ctrl-/ → Información adicional): decía "QSO nuber" y ahora dice "QSO number". (#962)

## Traducciones

- **Español**: refinamientos de traducción. (#992)

## Datos Incluidos

- La **lista de clúster DX (TRCLUSTER.DAT) se actualiza en cada compilación mensual**, y una copia nueva se envía con esta versión. (#391)

## Bajo el Capó / Para Colaboradores

- Continuación de la eliminación de ensamblado en línea heredado en el código de radio, formato y utilidades para la migración a Delphi 12 / 64 bits; sin cambios en la transmisión. (#997)
- El script de lanzamiento mensual es más robusto: un comando MonthlyBuild de un solo paso, etiquetado reforzado que no puede etiquetar una compilación obsoleta y una corrección a un error interno que hacía que el script de lanzamiento se colgara.