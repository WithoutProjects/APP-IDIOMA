# HablaBase

App para aprender español (iOS, SwiftUI). El diseño completo está en la guía maestra de HablaBase.

## Abrir en Xcode

1. Clona el repositorio y abre `HablaBase.xcodeproj` (hace falta Xcode 16 o posterior).
2. Elige un simulador de iPhone y pulsa Run (⌘R).
3. Los tests del motor se lanzan con ⌘U.

Si Xcode pide un equipo de firma para instalar en un iPhone real, elige tu cuenta en *Signing & Capabilities*.

## El recorrido (A0 → C2)

Todo el camino está en [`HablaBase/Content/curriculum.json`](HablaBase/Content/curriculum.json): 8 niveles, 56 unidades y 281 lecciones. Cada unidad acaba con un boss (una escena con el tutor) y cada nivel con un examen oral.

| Nivel | MCER | Nombre | Unidades |
| --- | --- | --- | --- |
| 1 | A0–A1 | Arranque | 6 |
| 2 | A1–A2 | Motor | 7 |
| 3 | A2 | Memoria | 7 |
| 4 | A2–B1 | Historia | 8 |
| 5 | B1–B2 | Fluidez | 8 |
| 6 | B2 | Matiz | 7 |
| 7 | C1 | Dominio | 7 |
| 8 | C2 | Maestría | 6 |

La app lee ese archivo para dibujar la ruta. Para cambiar el orden o los títulos basta con editar el JSON; los ejercicios de cada lección se añaden en `Content/`.

## Qué hay ahora (v0.5)

- **Bienvenida**: nombre, ciudad, trabajo, idioma (English / Italiano / Українська / Deutsch / Français / Português / 中文), objetivo y minutos al día.
- **Inicio**: racha, XP, energía, botón Continuar con el nivel y la unidad actuales, y la unidad en curso.
- **Recorrido A0–C2**: todos los niveles, unidades, lecciones, bosses, tests y exámenes, con el progreso de cada unidad.
- **Formato de lección**: explicación, 2 ejercicios, siguiente explicación, 2 ejercicios… y un bloque final que lo mezcla todo. Cada bloque tiene como máximo 15 preguntas, contando los fallos que se repiten al final.
- **Vocabulario primero**: cada palabra nueva se presenta en slides (palabra y traducción) y luego se une con su traducción antes de usarla en un ejercicio. Un test automático comprueba que ninguna lección usa palabras sin presentar.
- **Lección 1, Yo, tú, él**: las terminaciones de yo, tú y él/ella con Lego Snap y huecos para escribir el verbo, y un mix final.
- **Lección 2, Me presento**: frases con tus datos (Sentence Builder) y una frase final escrita con *y*.
- **Unidades 1 a 34 completas** (A0–B2): 170 lecciones y 34 bosses. Las lecciones 1 y 2 están en `Content/Unit1.swift`; el resto en `Content/lessons-u{n}.json`, con el formato y las reglas en `docs/content-format.md`. `python3 tools/validate_content.py` comprueba que ninguna lección usa una palabra antes de presentarla, el máximo de 15 preguntas y que cada ejercicio tiene solución. El plan de vocabulario está en `docs/vocab-plan.json`.
- **Apuntes**: explicaciones y vocabulario de la unidad actual y de las anteriores.
- **Hablar**: dices en voz alta frases de tus lecciones y ves qué palabras se han entendido; la app te avisa de las que conviene pronunciar más claro (reconocimiento de voz en el iPhone).
- **Escribir o decir**: en los ejercicios de completar, construir frases y traducir puedes elegir entre escribir la respuesta o decirla en voz alta. La app recuerda tu elección.
- **Test de unidad**: 10 preguntas sin explicaciones. Con 8 aciertos la unidad (y todo lo anterior) queda superada, así quien ya sabe español puede avanzar rápido. Se genera con preguntas de todas las lecciones de la unidad.
- **Conjugation Lab**: dos botones. *Repasar tablas* (tabla del presente que se ilumina con el dominio y banco Lego) y *Jugar* (Parejas: unir cada verbo con su persona; los demás juegos se abren por nivel).
- **Progreso guardado en el teléfono**: se guarda en un archivo de la app después de cada cambio, sobrevive a las actualizaciones y entra en la copia de seguridad del iPhone. Está detrás de `ProgressStorage`, así que más adelante se puede añadir una cuenta en la nube (por ejemplo Supabase) sin tocar el resto.

## Para no perderse y seguir motivado

- **Ver explicación**: en cada ejercicio un botón reabre la explicación de ese punto sin perder el ejercicio.
- **Pista en dos pasos**: primero la raíz (azul) o el comienzo de la frase, después la terminación o un trozo más. No quita corazones, solo da menos XP.
- **«Hoy vas a aprender a decir…» / «Ya puedes decir…»**: cada lección empieza con su frase objetivo y termina con las frases que has dicho, con audio en español (voz del iPhone, sin internet).
- **Tocar una palabra para ver su traducción**: solo las palabras ya presentadas en las diapositivas.
- **Minirepaso si te atascas**: dos fallos seguidos en el mismo punto muestran la regla con un ejemplo y una pregunta gemela más fácil. No quita corazones.
- **Corazones que no castigan**: los fallos al escribir quitan un corazón, la «Segunda oportunidad» lo devuelve, se rellenan cada día y nunca bloquean. Con 0 aparece «Recupera tus corazones», un repaso de tus errores.

## Preparada para la App Store

- **Idiomas**: toda la app (botones, explicaciones, pistas y traducciones) está en el idioma nativo del usuario, el que elige en el perfil (English / Italiano / Українська / Deutsch / Français / Português / 中文, por defecto el del iPhone). Los textos de la interfaz están en `Localizable.xcstrings`.
- **Privacidad**: sin cuentas, sin anuncios, sin seguimiento; todo se guarda en el teléfono. `PrivacyInfo.xcprivacy` lo declara. En App Store Connect la etiqueta de privacidad es «Datos no recopilados».
- **Solo lo que funciona**: la pestaña Talk y los minijuegos que aún no existen no se muestran; cuando alguien termina las lecciones disponibles ve una tarjeta «Estás al día» en lugar de botones desactivados.
- **Accesibilidad**: VoiceOver lee el estado de cada paso (hecho, siguiente, bloqueado), los textos crecen con el tamaño de letra del sistema y las bandejas de piezas pasan a otra línea si no caben.
- **Icono provisional** (`hablo` en un bocadillo) y `ITSAppUsesNonExemptEncryption = NO`, así que no hay que contestar la pregunta de cifrado en cada subida.
- **Pendiente antes de publicar**: tu equipo de desarrollo en Signing & Capabilities, confirmar el bundle ID `com.withoutprojects.hablabase` y el nombre en la tienda, un icono diseñado si quieres sustituir el provisional, capturas de pantalla, una URL de política de privacidad y más unidades (ahora llegan hasta la 34).

## Estructura

```
HablaBase/
  App/        punto de entrada y pestañas
  Engine/     conjugador, corrector y modelos de lección (sin UI, con tests)
  Content/    recorrido completo (curriculum.json) y ejercicios de la Unidad 1
  Store/      perfil y progreso (archivo JSON en el teléfono)
  Theme/      colores Lego: raíz azul, terminación naranja, tiempo verde, conectores morado
  Views/      pantallas
HablaBaseTests/  tests del motor y de la Lección 1
```
