# HablaBase

App para aprender español (iOS, SwiftUI). El diseño completo está en la guía maestra de HablaBase.

## Abrir en Xcode

1. Clona el repositorio y abre `HablaBase.xcodeproj` (hace falta Xcode 16 o posterior).
2. Elige un simulador de iPhone y pulsa Run (⌘R).
3. Los tests del motor se lanzan con ⌘U.

Si Xcode pide un equipo de firma para instalar en un iPhone real, elige tu cuenta en *Signing & Capabilities*.

## Qué hay ahora (v0.1)

- **Bienvenida**: nombre, ciudad, trabajo, idioma (English / Italiano), objetivo y minutos al día. Con eso se construyen las primeras frases.
- **Inicio**: racha, XP, energía, botón Continuar y la ruta de la Unidad 1 (6 lecciones y el boss del mercado).
- **Lección 1, Me presento**: el ciclo Frame → Forge → Fire → Fix completo.
  - Frame: `habl- + -o = hablo`.
  - Forge: 6 Lego Snap (raíz azul + terminación naranja).
  - Fire: 5 Sentence Builder con los datos de la persona.
  - Fix: escribir las tres frases unidas con *y*; los fallos de la lección vuelven al final y devuelven energía.
- **Conjugation Lab**: heat-rack del presente (yo, tú, él/ella) que se ilumina con el dominio de cada forma, y banco Lego para jugar con las terminaciones.
- **Talk**: el boss y la conversación libre, bloqueados hasta que existan.

## Estructura

```
HablaBase/
  App/        punto de entrada y pestañas
  Engine/     conjugador, corrector y modelos de lección (sin UI, con tests)
  Content/    contenido de la Unidad 1
  Store/      perfil y progreso (UserDefaults)
  Theme/      colores Lego: raíz azul, terminación naranja, tiempo verde, conectores morado
  Views/      pantallas
HablaBaseTests/  tests del motor y de la Lección 1
```
