# Tokens visuales mínimos V1

La [Issue #50](https://github.com/montunolabs/HealthGoals/issues/50) traduce la [identidad visual V1 aprobada](../brand/brand-strategy.md#identidad-visual-v1-vigente-para-el-mvp) a roles utilizables en SwiftUI. La dependencia #49 está integrada mediante [PR #55](https://github.com/montunolabs/HealthGoals/pull/55), merge `dce611df92346f53e435d2fb832903034f3de6d5`.

## API y usos

[VisualColors.swift](../../HealthGoals/VisualColors.swift) expone nueve colores semánticos. Los valores y variantes Light/Dark viven en assets sRGB `Visual*.colorset`, con referencias tipadas generadas por Xcode. SwiftUI resuelve la apariencia desde el entorno de la vista; no hay selector, gestor de temas ni colores hex en las pantallas.

| Rol de VisualColors | Uso | Light | Dark | Base o ajuste técnico |
| --- | --- | --- | --- | --- |
| `background` | Fondo principal | `#FFF4E6` | `#2B1630` | Crema / Ciruela base. |
| `surface` | Superficie secundaria | `#FFD6C7` | `#3F2944` | Rubor base en claro; `#3F2944`, Ciruela aclarada para distinguir superficies en oscuro. |
| `text` | Texto principal | `#2B1630` | `#FFF4E6` | Ciruela / Crema base. |
| `secondaryText` | Texto secundario | `#6B576C` | `#D0BCCF` | `#6B576C` / `#D0BCCF`, variantes de Ciruela con contraste para explicaciones y fechas ya presentes en la app. |
| `accent` | Acción principal: texto o relleno | `#8A4C00` | `#FFB21E` | `#8A4C00` en claro: Caléndula oscurecida para texto de acciones sobre Crema y Rubor; Caléndula base en oscuro. |
| `secondaryAccent` | Acento secundario legible | `#A8321E` | `#FF7257` | `#A8321E` / `#FF7257`: Coral oscurecido en claro y aclarado en oscuro para texto sobre fondo y superficie. |
| `onAccent` | Texto sobre relleno accent | `#FFF4E6` | `#2B1630` | Crema / Ciruela base. Aplicar explícitamente al label de la acción prominente. |
| `celebration` | Acento de logro | `#FFB21E` | `#FFB21E` | Caléndula base en ambos modos; no usar como texto sobre superficies claras. |
| `onCelebration` | Texto sobre celebration | `#2B1630` | `#2B1630` | Ciruela base en ambos modos; no sustituir por text en oscuro ni por onAccent en claro. |

Los roles de fondo, superficie, texto principal/secundario y acción responden a repetición existente en Baseline, Home y edición. Celebration es el rol de logro solicitado por V1; no implementa animación ni cambia el estado completado. Los dos roles de texto sobre relleno evitan combinaciones ilegibles al invertir Light/Dark. No se añaden separadores, espaciados, radios, componentes de producto ni tokens de estados futuros.

Uso en futuras entregas de superficies:

```swift
Text("startingPoint.title")
    .font(.largeTitle.bold())
    .foregroundStyle(VisualColors.text)

Button(action: model.acceptGoal) {
    Text("goal.accept")
        .foregroundStyle(VisualColors.onAccent)
}
.buttonStyle(.borderedProminent)
.tint(VisualColors.accent)
```

Usar `accent` o `secondaryAccent` para acciones de texto sobre `background`/`surface`; `onAccent` solo sobre `accent`; `onCelebration` solo sobre `celebration`. Los roles no asignan significado funcional al color: no diagnostican estados de Salud ni sustituyen etiquetas accesibles. Opacidad, materiales, mezcla con otros fondos y estados deshabilitados requieren comprobar el resultado al adoptar cada superficie.

## Tipografía nativa

Continuar con SF Pro / fuente del sistema y estilos SwiftUI que ya se usan: `.largeTitle.bold()` para título principal, `.title3.weight(.semibold)` para métrica, `.headline` para encabezado breve, `.body` para contenido, `.subheadline` para explicación y `.footnote` para notas. No introducir `.custom`, `.serif`, tamaños fijos ni limitar Dynamic Type. No hace falta un wrapper tipográfico ni familias externas; las próximas Issues reutilizan estos estilos nativos.

## Contraste reproducible

Se comprueban las combinaciones indicadas con texto normal opaco y mínimo **4,5:1**, siguiendo [WCAG 2.2, contraste mínimo](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html). Valores orientativos redondeados a dos decimales; el test compara sin redondear.

| Texto / fondo | Light | Dark |
| --- | --- | --- |
| `text` / `background` | 15.34:1 | 15.34:1 |
| `text` / `surface` | 12.46:1 | 11.99:1 |
| `secondaryText` / `background` | 6.03:1 | 9.35:1 |
| `secondaryText` / `surface` | 4.90:1 | 7.31:1 |
| `accent` / `background` | 6.21:1 | 9.24:1 |
| `accent` / `surface` | 5.04:1 | 7.22:1 |
| `secondaryAccent` / `background` | 6.16:1 | 6.19:1 |
| `secondaryAccent` / `surface` | 5.00:1 | 4.84:1 |
| `onAccent` / `accent` | 6.21:1 | 9.24:1 |
| `onCelebration` / `celebration` | 9.24:1 | 9.24:1 |

[VisualColorsTests.swift](../../HealthGoalsTests/VisualColorsTests.swift) resuelve los colores reales de la API en entornos SwiftUI Light y Dark. Comprueba opacidad, las diez parejas y la inversión de luminosidad entre fondo/tinta. Usa `Color.Resolved.linearRed/linearGreen/linearBlue`, canales sRGB lineales de [Color.Resolved](https://developer.apple.com/documentation/swiftui/color/resolved); calcula luminancia relativa y `(Lmás clara + 0,05) / (Lmás oscura + 0,05)`. No valida solamente una copia de los hex de esta tabla. Se ejecuta en `make verify` junto con el resto de tests.

## Revisión y límites

Abrir `VisualColors.swift` en Xcode y mostrar el canvas: previews **V1 Light**, **V1 Dark** y ambas variantes **Accessibility** con `.accessibility3`. Muestran roles, acciones nativas y estilos de texto en una columna desplazable, sin alturas fijas para copy ni servicios/HealthKit. Sus textos ingleses son etiquetas técnicas del catálogo de revisión, no copy de producto. Los previews están acotados a Debug y no tienen ruta desde la app.

Esta entrega no aplica los roles a las pantallas existentes ni cambia sus assets anteriores, copy, navegación o comportamiento. Las Issues de superficies deben adoptar la API y verificar en la app real EN/ES, contraste final, Dynamic Type, VoiceOver y Reduce Motion cuando incorporen celebración. Los ratios y previews del catálogo no acreditan esos recorridos físicos ni accesibilidad completa de la app.
