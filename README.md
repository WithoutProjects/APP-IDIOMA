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

## Qué hay ahora (v0.2)

- **Bienvenida**: nombre, ciudad, trabajo, idioma (English / Italiano), objetivo y minutos al día. Con eso se construyen las primeras frases.
- **Inicio**: racha, XP, energía, botón Continuar con el nivel y la unidad actuales, y la lista de la unidad en curso.
- **Recorrido A0–C2**: todos los niveles, unidades, lecciones, bosses y exámenes, con el progreso de cada unidad.
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
  Content/    recorrido completo (curriculum.json) y ejercicios de la Unidad 1
  Store/      perfil y progreso (UserDefaults)
  Theme/      colores Lego: raíz azul, terminación naranja, tiempo verde, conectores morado
  Views/      pantallas
HablaBaseTests/  tests del motor y de la Lección 1
```
