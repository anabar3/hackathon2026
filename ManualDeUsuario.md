# Manual de Usuario — BoardMee

BoardMee es tu **cerebro digital social**: captura todo lo que te interesa, organízalo con ayuda de IA y descubre el conocimiento de la gente que se cruza contigo mediante Bluetooth Low Energy (BLE). Este manual te guía paso a paso por cada pantalla y flujo para que aproveches al máximo la experiencia.  

Para buildear la aplicación: flutter build apk

---

## 1. Requisitos previos
- Dispositivo Android con Bluetooth y permisos de ubicación habilitados para escaneo BLE en segundo plano.
- Conexión a internet para sincronizar con Supabase y usar la IA de Groq.
- Cuenta de usuario activa (se crea/inicia en la pantalla de login).

---

## 2. Primer inicio
1) **Login**: ingresa o crea cuenta.  
2) **Permisos**: al primer arranque verás `PermissionsScreen`; concede Bluetooth/ubicación para que el radar de proximidad funcione.  
3) **Servicio en segundo plano**: la app inicia un servicio persistente que mantiene el escaneo y el anuncio BLE incluso con la pantalla apagada.

---

## 3. Conceptos clave
- **Inbox**: bandeja de entrada universal donde “dumpeas” todo antes de clasificar.
- **Item**: cualquier contenido guardado (link, nota, imagen, audio, video, archivo).
- **Board (tablero)**: carpeta temática que puede tener subtableros y ser **pública** o **privada**.
- **Street**: radar de proximidad que muestra personas cercanas y gente con la que ya te cruzaste, ordenadas por compatibilidad e intereses compartidos.

---

## 4. Flujo base de experiencia
### 4.1 Captura sin fricción
- **Desde cualquier app**: comparte texto, enlaces, imágenes, audios o archivos al icono de BoardMee. Se guarda directo en el Inbox y ves un snackbar confirmando.
- **Dentro de BoardMee**: en `Inbox` toca **Añadir al Inbox** para abrir el modal rápido (`AddInboxScreen`) y pegar texto, enlaces o subir archivos.  

*Idea clave*: Interfaz rápida y sencilla, sin muchos obstáculos para poder hacer un "dumpeo" de información continuo y desde distintos sitios, para luego consultar más tarde y organizar a gusto del usuario.  


### 4.2 Organiza (a mano o con IA)
- **Sugerencias automáticas**: al abrir Inbox, la IA (Groq) analiza todo y propone:
  - Mover un item a un tablero existente.
  - Crear un tablero nuevo con nombre/descripción sugeridos y moverlo allí.
- **Aceptar / descartar**: cada sugerencia se muestra en una tarjeta. Confirma para ejecutar o descarta para ocultarla.
- **Mover manualmente**: botón `Mover` abre el selector de tableros (`BoardPickerScreen`). Elige uno y listo.
- **Eliminar**: desliza un item a la izquierda para borrarlo del Inbox.
  
*Idea clave*: Siempre mantiene las ideas de la IA como sugerencias, que el usuario puede aceptar o rechazar.

### 4.3 Crea tu estructura de Boards
- Desde `Dashboard` pulsa **Crear tablero** (o **Crear subtablero** desde un tablero abierto).
- Define título, descripción opcional, portada (imagen subida) y decide si será **Público**.
- Puedes fijar jerarquía: elegir tablero padre o dejarlo en el nivel raíz.
- Edita después título, descripción o portada en la vista **Editar tablero**.
- Cambia visibilidad con el switch público/privado; la app confirma el cambio.

*Idea clave*: una interfaz familiar, cómoda y rápida, a la vez que estética, donde siempre puedas encontrar lo que quieras.

### 4.4 Trabaja dentro de un Board
- Al seleccionar un tablero ves sus items y subtableros.  
- **Detalle de item**: abre para leer, editar título/descripcion, actualizar miniatura, borrar o generar resumen IA.
- **IA Resumen**:
  - **Item**: botón “AI summarize” crea un resumen y lo guarda en el item.
  - **Board**: “AI summarize board” produce un resumen global del tablero.
- **Sugerencias del tablero**: si hay recomendaciones pendientes, abre `BoardSuggestionsScreen` para aceptarlas o rechazarlas; se sincroniza al momento.

*Idea clave*: Aportar información de la manera más cómoda posible, tanto creando nuevos items y subtableros, como recibiendo ayuda de una IA que conecta puntos entre ideas y resume para facilitar la comprensión de la información.

### 4.5 Inbox ⇄ Boards
- Cada vez que mueves un item del Inbox a un Board, el contador del tablero se actualiza.  
- El Inbox queda limpio y tus boards mantienen el contexto temático.

---

## 5. Street: conocimiento en movimiento
1) **Escaneo continuo**: el servicio BLE detecta usuarios cercanos y anuncia tu presencia con tus tableros públicos.  
2) **Vista Street (DriftScreen)**:
   - **JUST NOW** muestra personas a tu alrededor en tiempo real.
   - **EARLIER** guarda a quienes te cruzaste antes (encuentros pasados).
   - Cada tarjeta indica intereses compartidos, bio, compatibilidad y tableros públicos ordenados por afinidad (IA compara tus boards con los suyos).
3) **Abrir persona**: toca una tarjeta para ver todos sus tableros públicos (`PersonBoardsScreen`).  
4) **Explorar tablero público**: entra a un tablero ajeno (`PublicBoardScreen`) para:
   - Revisar items y subtableros.
   - **Exportar** un item a tu Inbox en un toque (copias título, tipo, URL, tags).
   - **Sugerir** a la otra persona que añada uno de tus items en su tablero.

*Idea clave*: compartir es unilateral y ligero; nadie queda obligado. Se fomenta la compartición del conocimiento y de ideas, se da valor al componente humano y moral de la información. Además, se fomentan los encuentros en persona, facilitando inicios de conversaciones, matches de personas con gustos similares, o incluso revelando verdaderas posibilidades de negocio entre profesionales.

---

## 6. Perfil y permisos
- **Perfil**: muestra nombre, avatar, bio e intereses; se usa para calcular compatibilidad con otros.
- **Privacidad**: solo los tableros marcados como públicos viajan por BLE; tus tableros privados permanecen locales/sin anunciar.
- **Background**: si detienes el servicio en segundo plano o revocas permisos, Street dejará de detectar y ser detectado.

---

## 7. Consejos de uso
- Deja todo en el Inbox primero; procesa en bloque cuando tengas tiempo usando las sugerencias IA.
- Mantén pocos tableros públicos bien curados: son tu tarjeta de presentación al pasar junto a alguien.
- Usa portadas y descripciones claras: mejoran las sugerencias y los resúmenes automáticos.
- Revisa “Earlier” después de eventos o trayectos largos para no perder conexiones valiosas.

---

## 8. Solución rápida de problemas
- **No veo gente en Street**: confirma permisos de Bluetooth/ubicación y que el servicio de fondo esté activo.  
- **No se guardan portadas/archivos**: verifica conexión y espacio; vuelve a intentar.  
- **La IA no responde**: comprueba conexión; si persiste, reabre la app para relanzar el servicio de fondo.

---

