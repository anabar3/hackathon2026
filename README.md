# BoardMee

BoardMee no es solo una aplicación de notas o de marcadores; es una extensión de tu curiosidad que cobra vida cuando sales a la calle. Inspirada por la nostalgia del **StreetPass** de Nintendo y respondiendo al reto de **Kelea** de centralizar el conocimiento personal, hemos creado el primer **Cerebro Digital Social**.


## El Concepto: De StreetPass a tu Cerebro Digital

Nuestra visión surge de una pregunta: _¿Qué pasaría si pudieras hojear los libros, canciones e ideas que inspiran a la persona que acaba de cruzar el semáforo junto a ti?_

1.  **El Legado de StreetPass:** Recuperamos esa sensación de "descubrimiento pasivo" donde tu dispositivo trabaja por ti en segundo plano, encontrando conexiones invisibles sin que tengas que sacar el móvil del bolsillo.
2.  **El "Cerebro Digital" de Kelea:** Adoptamos el reto de crear un sistema robusto donde centralizar todo lo que te importa. Pero en BoardMee, este cerebro no es una isla; es un nodo en una red física y humana.


## ¿Cómo funciona?

BoardMee utiliza **Bluetooth Low Energy (BLE)** para crear una red efímera de conocimiento a tu alrededor.

- **Organiza:** Crea "boards" con links, imágenes, notas de voz o documentos. Tu conocimiento está siempre ordenado y a mano.
- **Descubre:** Al caminar por la ciudad ("Street"), tu app detecta a otros usuarios. Sus boards públicos aparecen en tu feed automáticamente.
- **Captura:** ¿Has visto algo increíble en el board de un desconocido? Impórtalo a tu propio inbox con un solo botón. La inspiración fluye de persona a persona.


## Arquitectura Técnica

Hemos construido una solución de alta fidelidad utilizando tecnologías de vanguardia:

- **Flutter (Core):** Una experiencia fluida y reactiva diseñada para Android.
- **Supabase (Backend):** Gestión de datos en tiempo real con políticas de seguridad **RLS** que garantizan que tus boards privados sigan siendo solo tuyos.
- **BLE Dual-Stack:** Utilizamos `flutter_blue_plus` y `flutter_ble_peripheral` para que tu móvil escanee y se anuncie simultáneamente sin agotar la batería.
- **Cerebro con IA:** Integración con **Groq** para procesar, resumir y dar sentido a la montaña de información que guardas.
- **Background Intelligence:** Un servicio persistente que mantiene viva la red social incluso con la pantalla apagada.


