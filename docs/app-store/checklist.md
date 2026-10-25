# Publicar Hablo en la App Store

Lo que ya está hecho en el código, y lo que solo puedes hacer tú (cuenta de Apple, firmas, textos de la tienda).

## Ya hecho

- Versión **1.0** (build 1). Para cada nueva subida, sube el número de *Build* en Xcode (General > Identity).
- Solo iPhone, en vertical, iOS 17 o posterior.
- `PrivacyInfo.xcprivacy`: sin seguimiento, sin datos recopilados; declara el uso de UserDefaults (motivo CA92.1).
- `ITSAppUsesNonExemptEncryption = NO`: no hay que contestar la pregunta de cifrado en cada subida.
- Textos de permisos (micrófono y reconocimiento de voz) en los 7 idiomas.
- Política de privacidad dentro de la app: Perfil > Privacidad.
- Ningún paso del camino se queda bloqueado: los exámenes de fin de nivel ya se pueden hacer (antes el camino se paraba al final del Nivel 1). Un test (`ReleaseTests`) lo comprueba.
- No se muestran pantallas a medio hacer: los juegos y unidades que no existen no aparecen, y al acabar el contenido sale «Estás al día».

## Lo que tienes que hacer tú

1. **Compilar y probar en Xcode** (⌘B y ⌘U). El código se escribe en la nube sin compilador de Swift, así que la primera compilación en tu Mac es la prueba de verdad. Si sale algún error, cópialo en el hilo y lo arreglo.
2. **Apple Developer Program** (99 €/año) si aún no lo tienes: developer.apple.com/programs.
3. **Firma**: en Xcode, target HablaBase > Signing & Capabilities > *Team*: tu equipo. Deja *Automatically manage signing* activado.
4. **Bundle ID**: ahora es `com.withoutprojects.hablabase`. Cámbialo si quieres otro; una vez publicado ya no se puede cambiar.
5. **Nombre en la tienda**: la app se llama «Hablo» (*Display Name* en Xcode ya es Hablo). En App Store Connect el nombre tiene que estar libre (máx. 30 caracteres): la ficha propone «Hablo: Learn Spanish». El proyecto y el target de Xcode siguen llamándose `HablaBase`; no se ven en ningún sitio.
6. **Icono**: el actual es provisional. Hace falta un PNG de 1024×1024 sin transparencia; sustituye `HablaBase/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
7. **Revisión de traducciones**: ucraniano, alemán, francés, portugués de Brasil y chino se tradujeron con IA. Antes de publicar en esos idiomas, que un nativo revise al menos la bienvenida, el Lab y las primeras unidades. Si no da tiempo, pídeme que oculte esos idiomas hasta que estén revisados: publicas en inglés e italiano y los añades en una actualización.
8. **Política de privacidad en una web**: App Store Connect pide una URL. Publica [`privacy-policy.md`](privacy-policy.md) (por ejemplo con GitHub Pages o Notion) y pon tu correo de contacto donde dice `[tu correo]`.
9. **URL de soporte**: obligatoria. Puede ser la misma página con un correo de contacto.
10. **App Store Connect** (appstoreconnect.apple.com): *Apps* > *+* > Nueva app, con el bundle ID de arriba. Rellena:
    - Categoría: Educación. Secundaria opcional: Referencia.
    - Clasificación por edades: responde «No» a todo; sale 4+.
    - Privacidad de la app: «Datos no recopilados».
    - Precio: gratis (o el que decidas).
    - Textos de la ficha: borrador en [`listing.md`](listing.md).
11. **Capturas de pantalla**: obligatorias para iPhone de 6,9" (1320×2868, p. ej. simulador iPhone 16 Pro Max). Entre 3 y 10. Ideas: el camino de unidades, una lección con las piezas Lego, el Lab con Contrarreloj, Caza de errores, Apuntes.
12. **Subir la build**: en Xcode, *Product > Archive* > *Distribute App* > *App Store Connect*. Luego elígela en la ficha y pulsa *Enviar para revisión*.
13. **TestFlight** (recomendado antes de enviar): invita a 2 o 3 personas que aprendan español y pídeles que terminen la Unidad 1.

## Para la revisión de Apple

En *Información para la revisión* puedes poner: «No login required. All progress is stored on the device. Speech recognition is optional and only used when the learner chooses to answer by voice.»
