# HealthGoals — Primera propuesta de experiencia del MVP

Estado: dirección UX aprobada por César y wireframes cerrados tras los ajustes del 4 de octubre. Las decisiones del motor, edición y datos aún pendientes no quedan aprobadas por este cierre. Fecha: 4 de octubre de 2026. [Issue #12](https://github.com/cesarg88/HealthGoals/issues/12). Fuentes leídas en `develop` integrado `d0c855e58b3099d58f10ae279382ecb620701ea2`: [One-Pager](../product/one-pager.md), [MVP Scope](../product/mvp-scope.md), README y AGENTS.

[Figma editable](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13): flujo, wireframes, estados/adaptación y elementos reutilizables. Figma será la referencia visual; este documento registra comportamiento, estados y preguntas. Todo dato mostrado es ficticio. Los ejemplos numéricos no son reglas del motor.

## 1. Síntesis y límite

El producto transforma actividad observada en un objetivo semanal controlado por la persona, interpreta el progreso respecto a su patrón histórico y traduce el restante. La unidad de éxito es una semana flexible y el regreso a otra semana. Diseñamos para personas con iPhone y Apple Watch, no para rendimiento deportivo. Sin registro manual de actividad, cuentas, coaching, streaks o nuevas métricas.

Caminar más selecciona Pasos como principal; Moverme más selecciona Actividad, con kcal activas como unidad secundaria. Solo se añade la otra métrica por elección. La primera propuesta muestra un único objetivo. La Home prioriza estado por métrica, progreso y restante; la Home no muestra reparto lineal ni cuota diaria. La explicación del ritmo es secundaria y se abre a petición; el estado personal y el restante semanal siguen visibles.

Compatibilidad aprobada: iOS/iPadOS 26, iPhone/iPad y todas orientaciones, EN/ES. Documentación española; textos ingleses son contenido de interfaz para localización. Las ocho semanas son una referencia tentativa, sin compromiso rígido ni prisa, como recoge el producto integrado y confirma Product en su revisión del 4 de octubre. D10 queda resuelta; no se requiere otra confirmación ni se fija una fecha. La simplicidad sigue siendo un criterio de diseño.

## 2. Recorrido completo propuesto

1. Primera apertura → S01 bienvenida e intención. Dos opciones excluyentes; continuar deshabilitado hasta seleccionar. Volver permite cambiar sin guardar un objetivo.
2. S02 contexto HealthKit → CTA Conectar con Salud → autorización nativa. Solicitar lectura de pasos y energía activa; explicar uso y almacenamiento local. La autorización del sistema no es una pantalla propia rediseñada.
3. Al regresar → S03 análisis: carga indeterminada, sin porcentaje ni promesa de duración. Solicitud completada no equivale a permiso de lectura concedido.
4. Consulta con información apta → S03 baseline y propuesta juntos: periodo real, estimación semanal, explicación y objetivo editable. Ajustar abre S05; aceptar activa únicamente los objetivos elegidos. Antes de aceptar se explica que la primera semana es la semana actual completa, contando la actividad accesible desde el lunes y sin prorratear el objetivo (D02 confirmada).
5. Opcional Añadir Actividad/Pasos → segunda sección en S03 o S05, con su propio historial/propuesta/estado. No repetir onboarding ni activar automáticamente.
6. Primera aceptación → onboarding completado → S04 Home. Las aperturas posteriores van a Home, no reinician la bienvenida ni la autorización. Consultas posteriores actualizan los datos locales; el objetivo no aumenta solo.
7. Durante la semana → S04 permanece como destino de apertura, widget y notificación. Ajustar abre S05. Explicación del ritmo se expande en la tarjeta, sin pantalla analítica adicional.
8. Al terminar el intervalo semanal → el objetivo continúa automáticamente con el mismo valor para la nueva semana, sin confirmación ni incremento. S06 es un resumen no bloqueante con resultados por métrica, incluidos parciales/desconocidos; su CTA principal es Ver esta semana y el secundario Ajustar. El resumen no es un paso necesario para activar el seguimiento de la nueva semana (D03 confirmada). El efecto temporal concreto de una edición sigue D04.
9. Nueva semana → S04 con un intervalo nuevo y datos de esa semana, nunca el acumulado anterior. Repetición de 6–8 durante semanas 2 y 4; sin historial navegable nuevo.
10. S07 Ajustes desde Home: Salud, privacidad, información de objetivos, bienestar y aviso opcional. Volver conserva Home y objetivo.

### Caminos alternativos y reentrada

- Capacidad no disponible observada → estado de S02 con explicación y Reintentar; no activar una promesa de seguimiento. Volver a intención permitido.
- Solicitud/consulta falla → error recuperable en la misma superficie, conservar intención/propuesta y último estado válido; reintentar explícitamente, sin bucle de prompts.
- No hay datos accesibles → S03 explica que puede faltar información o acceso y ofrece Revisar acceso y Reintentar. Nunca afirma «denegaste el permiso».
- Histórico reducido pero utilizable según motor → S03 indica periodo real. Si no permite patrón, S04 conserva progreso/gap y dice «Todavía no podemos estimar tu ritmo habitual».
- Sin baseline apto → S03 sin número recomendado. Configurar manualmente es una alternativa pendiente D05; si se aprueba, reutiliza S05 y no pide registros de actividad.
- Datos de una métrica solamente → avanzar con la métrica disponible si elegida; no sustituir la intención principal silenciosamente. Si principal no disponible y otra sí, ofrecer cambio explícito a la otra intención.
- Posible actividad incompleta → texto sobre disponibilidad de la métrica; no inferir ausencia de Watch. Los pasos pueden seguir disponibles.
- Error durante semana activa → S04 mantiene snapshot de la misma semana con aviso/fecha. Sin snapshot de esa semana, muestra desconocido. Reintentar no rejuvenece el timestamp.
- Cerrar durante onboarding → retomar la etapa pendiente. Product confirma este comportamiento: no repetir etapas completadas ni crear un objetivo por reabrir. Ingeniería debe preservarlo o escalar una limitación real; no es una alternativa de UX pendiente.
- Eliminar el último objetivo → propuesta pendiente D04: Home sin objetivo y CTA Elegir objetivo. Reutilizar solo la selección de intención de S01 y la propuesta S03; no reiniciar el onboarding completo, repetir bienvenida ni volver a pedir autorización por eliminar un objetivo. La recuperación de acceso, si procede por su estado observado, es independiente. No mostrar un cero de progreso ni una propuesta automática nueva.

## 3. Inventario cerrado de superficies

Siete superficies propias, una autorización del sistema, un widget y una notificación. Las filas siguientes incluyen estados dentro de la misma pantalla; no son pantallas adicionales.

| ID y nombre | Propósito e información principal | CTA principal | CTA secundaria | Entrada | Salida | Estados especiales |
| --- | --- | --- | --- | --- | --- | --- |
| S01 Bienvenida e intención | Promesa breve, semana flexible; Caminar más/Pasos o Moverme más/Actividad | Continuar | Ninguna | Primera apertura; etapa pendiente; solo selección al elegir objetivo tras eliminar último (D04) | S02 durante onboarding; S03 al elegir otro objetivo con contexto ya completado | Sin selección; selección única; variante sin bienvenida/permisos para usuario con onboarding completado |
| S02 Conectar con Salud | Qué lee, para qué, solo lectura y dispositivo | Conectar con Salud; Reintentar si capacidad/error | Volver; Revisar acceso cuando pertinente | S01; recuperación desde S03/S07 | Autorización nativa → S03; volver S01 | Disponible; no disponible observado; solicitud en curso/error; sin afirmar acceso concedido |
| S03 Tu punto de partida | Análisis, periodo observado, baseline, propuesta explicada por métrica | Usar este objetivo / Usar estos objetivos | Ajustar; Añadir otra métrica; Reintentar/Revisar acceso en vacío | S02/autorización; S05 cancelar/guardar borrador | S05 o S04 tras aceptación | Carga; suficiente; limitado; insuficiente; métrica sin datos; propuesta pendiente; error |
| S04 Esta semana (Home) | Intervalo, estado por métrica, progreso, restante y días; sin reparto diario | Ajustar objetivo como acción disponible; consulta no exige CTA | Ajustes; Cómo interpretamos tu ritmo; resumen disponible | Aceptación, aperturas, widget/aviso, fin de edición | S05, S06, S07, S01 sin objetivos | Un/dos objetivos; estados diferentes; ritmo desconocido; completado; dato antiguo/desconocido; semana nueva; error |
| S05 Ajustar objetivo (hoja) | Valor semanal, unidad, periodo de efecto explícito; baseline como contexto | Aplicar / Guardar cambios, según origen | Cancelar; Eliminar objetivo activo con confirmación | S03, S04, S06; configuración manual solo si D05 aprobado | Pantalla origen; S04 vacío tras última eliminación si D04 aprobado | Borrador; valor vacío/no válido; sin cambios; persistencia falla; confirmación eliminar; segunda métrica |
| S06 Tu semana | Fechas, resultado por objetivo, completo/parcial/desconocido; objetivo ya continúa automáticamente con igual valor | Ver esta semana | Ajustar | Resumen accesible desde Home tras fin de intervalo; no bloquea nueva semana | S04 actual o S05 | Ambos/uno/ninguno completos; dato incompleto; sin confirmación para continuar |
| S07 Ajustes | Salud, privacidad, objetivos, bienestar; aviso opcional y estado real del permiso | Activar aviso (solicita permiso del sistema) | Desactivar; Revisar acceso; Volver | S04/S02 recuperación | Sistema o regreso a S04 | Aviso desactivado, solicitud, permitido, no permitido observado; sin datos; no hay selector de idioma aprobado |
| X01 Autorización de Salud (sistema) | Panel nativo; no recrear controles propios | Acción del sistema | Acción del sistema | S02 | S03 o error S02 | Solicitud finalizada/cancelada/error según contrato técnico, sin concluir lectura |
| W01 Widget mediano único | Restante de uno/dos objetivos y días; estado por métrica cuando cabe | Pulsar → S04 | Ninguna | Instalación por sistema | S04 | Sin objetivo; dato antiguo/desconocido; completado; nueva semana no consultada |
| N01 Aviso semanal opcional | «Así va tu semana / Mira cómo estás avanzando y qué te queda» | Pulsar → S04 | Controles del sistema | Opt-in S07 y programación pendiente | S04; resumen accesible sin bloquear el seguimiento | Desactivado; permiso no permitido; desactivar cancela avisos programados; sin valores de salud |

No habrá pantalla de resultado de permiso, dashboard histórico, catálogo de hábitos ni pantallas separadas para cada error. Privacidad/bienestar se expanden como secciones de S07 o contenido informativo local reutilizable, sin nuevos destinos de producto.

## 4. Matriz de estados para ingeniería

Son dimensiones combinables por métrica, no un enum lineal. Baseline y patrón tienen suficiencia propia; la existencia de una muestra no demuestra cobertura. Los límites los decide Product y los entrega el motor.

| Estado/dimensión | Evidencia necesaria | Representación / datos | Acción y transición |
| --- | --- | --- | --- |
| HealthKit disponible | Capacidad runtime verdadera | S02 ofrece conectar, sin prometer historial | Solicitar → en curso |
| HealthKit no disponible | Capacidad runtime falsa | S02 explica indisponibilidad actual | Reintentar capacidad; volver; no objetivo rastreable ficticio |
| Acceso solicitado | Operación nativa iniciada/finalizada | Mostrar proceso; finalizar no implica lectura autorizada | Consultar tras resultado; error recuperable si falla |
| Acceso parcial (solo descripción operativa) | Consultas útiles de una métrica, no otra | Tarjeta disponible y otra sin datos accesibles; nunca «permiso parcial» como certeza | Conservar disponible; revisar/reintentar otra o cambio explícito |
| Datos suficientes | Motor indica suficiencia para propósito y periodo | Mostrar solo baseline, progreso o patrón habilitado | Proponer/calcular según propósito |
| Datos insuficientes | Motor no puede producir baseline/patrón/progreso confiable | Mensaje específico del propósito; sin cifra inventada | Reintentar/revisar; manual solo D05 |
| Histórico limitado | Periodo observado menor al preferido y motor admite estimación | «Basado en X semanas»; sin asumir patrón apto | Aceptar propuesta si realmente emitida |
| Sin Watch / actividad incompleta | Ausencia de Watch solo si contrato fiable la conoce; disponibilidad/cobertura por separado | «No tenemos suficiente información de Actividad»; sin diagnosticar dispositivo de consulta vacía | Seguir con Pasos elegido; revisar información |
| Baseline calculado | Valor, métrica, periodo y explicación del motor | S03 actividad reciente; estimación, no cifra clínica | Propuesta pendiente/lista |
| Propuesta pendiente | No hay valor de propuesta todavía | Carga o insuficiencia, no CTA de aceptar activo | Resultado → propuesta lista; fallo → error |
| Propuesta lista | Valor válido y origen explicado | S03 aceptar, ajustar y añadir otra métrica | Aceptar → activo; ajustar → borrador |
| Objetivo activo | Valor aceptado persistido y ámbito semanal | S04; métrica principal primero | Consulta/edición/fin de semana |
| Datos recientes | Snapshot válido del intervalo actual, según política pendiente | Progreso/restante; actualización neutral | Nuevos datos recalculan; no tiempo real prometido |
| Datos temporalmente no actualizados | Snapshot previo actual + consulta fallida o criterio freshness explícito | Aviso «Mostramos la última información disponible», fecha original; ritmo «según estos datos» | Reintentar; conservar snapshot sin actualizar fecha ficticia |
| Sin snapshot de semana actual | No hay acumulado válido de ese intervalo | «Todavía no hay información disponible de esta semana»; restante desconocido | Consultar; nunca usar acumulado de semana pasada |
| Cero válido | Agregado cero con cobertura suficiente según contrato, no consulta vacía | 0 / objetivo y gap calculable | Actualización normal |
| Ritmo conocido | Patrón apto y evaluación del motor por métrica | A tu ritmo / Por delante / Necesitas algo más de actividad | Explicación breve; no umbrales UI |
| Ritmo desconocido | Patrón insuficiente aunque progreso sea válido | Progreso y restante; «Todavía no podemos estimar tu ritmo habitual» | Consulta futura puede habilitar patrón |
| Objetivo completado | Progreso válido ≥ objetivo | «Objetivo completado», restante 0; cifra real puede superar objetivo, barra limitada visualmente | Mantener hasta cierre; no aumentar objetivo |
| Semana terminada | Intervalo terminó según calendario/zona confirmados | S06 por métrica, neutral si incompleto/desconocido | Continuación automática con igual valor; consultar resumen o ajustar, sin bloquear seguimiento |
| Error recuperable | Error de solicitud, consulta, análisis o guardado | Aviso en contexto, sin borrar información aceptada | Reintentar misma operación; cancelar edición restaura origen |
| Sin objetivos | Eliminación del último tras onboarding completo | S04 vacío propuesto; no métricas falsas | Elegir objetivo → selección reutilizada y propuesta, sin reiniciar onboarding; estado vacío/eliminación pendiente D04 |

Prioridad visual propuesta: integridad/edad del dato → completado si dato válido → ritmo conocido → ritmo desconocido. Un error de la segunda métrica no borra la primera. No hay estado global «A tu ritmo» si contradice una tarjeta. Home puede titular «Esta semana» y mostrar ambos estados.

### Contrato observable de HealthKit

Contrato consultado a ingeniería. `isHealthDataAvailable()` se evalúa en runtime, también en iPad; no excluir por modelo. No garantizamos mismo historial entre dispositivos ni sincronización propia. [Documentación Apple](https://developer.apple.com/documentation/healthkit/hkhealthstore/ishealthdataavailable%28%29).

El permiso de lectura concedido/denegado no es observable por tipo; `authorizationStatus` describe escritura. Una solicitud finalizada y una consulta vacía no acreditan concesión/denegación. Usar «No encontramos datos accesibles», no «Has denegado el permiso». [Autorización HealthKit](https://developer.apple.com/documentation/HealthKit/authorizing-access-to-health-data).

`lastSuccessfulQueryAt` es consulta terminada, no sincronización del Watch; `lastAvailableSampleEndAt` es muestra observada, no hora garantizada de última actividad. Propuesta de copy: «Consultado a las 18:42» si esa es la evidencia; «Información disponible hasta…» solo cuando el motor garantiza ese significado. Nunca «Watch sincronizado». Cache mínima por métrica e intervalo semanal; no reutilizar acumulado entre semanas ni guardar historial innecesario. Política de revocación/cache/freshness pendiente de Issue técnica.

## 5. Decisiones UX propuestas

- S01 reúne bienvenida e intención; S03 reúne baseline y propuesta. Se elimina navegación que no aporta decisiones.
- Estado junto a cada métrica; con un objetivo puede dominar la cabecera. Con dos, cabecera neutral y estados independientes.
- Orden dentro de tarjeta: estado → progreso numérico y barra simple → restante destacado. Sin reparto diario en Home. Probar si el restante necesita más peso que la barra; no añadir gráficas para compensar falta de claridad.
- No mostrar reparto lineal por día en ninguna variante de Home, tampoco EN/iPad/modo oscuro o con dos objetivos. El restante semanal mantiene su utilidad sin una cuota diaria.
- Explicación de baseline siempre visible y corta; explicación del ritmo secundaria y contraída por defecto, bajo «Cómo interpretamos tu ritmo». No ocupa la cabecera ni repite un párrafo educativo en la Home. El estado de ritmo sigue junto a su métrica. No atribuir la propuesta a IA ni asegurar objetivo óptimo.
- Edición numérica directa con unidad visible y teclado apropiado; no slider difícil de precisar. Aplicar no acepta un borrador del onboarding: vuelve a S03, donde el usuario acepta.
- Eliminar requiere confirmar alcance; Cancelar preserva objetivo. Rangos/valores válidos los determina Product; no inventar mínimos o máximos.
- Notificaciones desactivadas inicialmente como propuesta; opt-in en Ajustes tras conocer la Home. Sin interstitial obligatorio ni salud en texto.
- Widget mediano único: restante de una o dos métricas, días y estado individual cuando disponible. Tap abre Home; sin controles de edición ni múltiples tamaños en esta entrega.

## 6. Adaptación, accesibilidad y contenido

iPhone compacto y ventanas estrechas: una columna desplazable, sin números truncados. Paisaje: misma secuencia con menos altura; acciones accesibles mediante scroll y teclado sin tapar Aplicar. iPad ancho: columna de contexto y objetivos al lado cuando ambas caben; dos métricas no se fuerzan en paralelo si texto ampliado/ventana estrecha. Onboarding centrado con anchura legible. S05 hoja adaptativa, no pantalla rígida de móvil estirada. Sin breakpoint arbitrario como requisito del producto: probar ancho efectivo y contenido.

Texto escalable, sin altura fija en tarjetas o botones con copy largo; orden VoiceOver: métrica, estado, progreso, restante y acciones; la explicación secundaria se lee solo al expandirla. La barra es decorativa si repite la frase accesible. Color nunca es única señal. Objetivos táctiles propuestos de al menos 44 pt; contraste y foco se comprobarán en alta fidelidad y dispositivo, no se declaran validados por wireframes. Movimiento reducido compatible; animaciones no necesarias para comprender.

Los wireframes usan SF Pro y neutros, con modos Claro/Oscuro para probar jerarquía, no branding final. El kit iOS26 fue descubierto pero importar el botón falló por permisos; los elementos locales son esquemáticos, no copia de Apple Fitness. No hay iconos reconstruidos ni UI rasterizada.

Números, fechas, plurales y unidades deben formatearse según región; no concatenar traducciones. `32.400` en es-ES / `32,400` en en-US son ejemplos regionales, no formato fijo por idioma. Mostrar intervalo completo si cambian mes/año. La definición de días restantes y semana es D01, no decisión del diseñador. Idioma del sistema sin selector es recomendación D06.

| Uso | Español | Inglés |
| --- | --- | --- |
| Promesa | Tu actividad, a tu ritmo | Your activity, at your own pace |
| Intenciones | Caminar más — Pasos semanales / Moverme más — Actividad semanal | Walk more — Weekly steps / Move more — Weekly activity |
| Salud | Tus datos permanecen en este dispositivo | Your data stays on this device |
| Baseline | Media de las últimas 4 semanas: 38.500 pasos/semana | Average over the last 4 weeks: 38,500 steps/week |
| Propuesta | Para empezar, te proponemos 40.000 pasos por semana. Puedes ajustarlo. | Start with 40,000 steps a week. You can adjust it. |
| Ritmo | A tu ritmo / Por delante de tu ritmo habitual / Necesitas algo más de actividad | On track for your usual pace / Ahead of your usual pace / A little more activity would help |
| Sin patrón | Todavía no podemos estimar tu ritmo habitual | We can’t estimate your usual pace yet |
| Restante | Te quedan 7.600 pasos esta semana | 7,600 steps left this week |
| Explicación secundaria | Cómo interpretamos tu ritmo | How we interpret your pace |
| Sin datos | No encontramos datos accesibles de Actividad | We couldn’t find accessible Activity data |
| Dato anterior | Mostramos la última información disponible | Showing the latest available information |
| Resumen | Tu semana / Ver esta semana / Ajustar | Your week / View this week / Adjust |
| Continuidad | Tu objetivo continúa automáticamente con el mismo valor | Your goal continues automatically at the same value |
| Primera semana | Contamos la actividad desde el lunes, aunque empieces hoy. El objetivo no se prorratea. | We count activity from Monday, even if you start today. Your goal is not prorated. |
| Notificación | Así va tu semana / Mira cómo estás avanzando y qué te queda | Your week so far / Check your progress and what’s left |

## 7. Preguntas y contradicciones reales

No bloquean exploración reversible; sí impiden cerrar un handoff implementable de esos comportamientos.

| ID | Decisión pendiente | Recomendación y motivo | Responsable |
| --- | --- | --- | --- |
| D01 | Zona horaria, momento de corte semanal, día en curso y cambios de calendario | La primera semana desde lunes ya está confirmada; concretar los detalles temporales antes de validar cifras/días o programar aviso | Product + ingeniería |
| D04 | Efecto de editar/eliminar en semana activa; último objetivo | Recomendar efecto explícito en semana actual sin alterar actividad observada; último eliminado devuelve vacío con Elegir objetivo; confirmar historia del resumen | Product |
| D05 | Configuración manual sin baseline, no garantizada por scope | Permitir solo si progreso puede observarse; patrón desconocido. Sin datos actuales, no prometer seguimiento | Product |
| D06 | Selección de idioma | Sistema y ajustes de idioma de iOS; sin selector propio, pendiente confirmación | Product |
| D07 | Cuándo dato antiguo pierde estado de ritmo; etiquetas de consulta/dato | Marcar antigüedad y no presentar ritmo como actual; reglas freshness no son umbrales UX inventados | Product + ingeniería |
| D08 | Baseline mínimo 4 semanas vs histórico limitado utilizable | Motor debe distinguir mínimo preferido, suficiencia real y patrón; no inventar porcentaje de subida ni asumir media aritmética | Product |
| D09 | Horario del aviso y cierre visible con datos tardíos | Aviso opcional único sin datos; resumen reconoce datos incompletos y no cierra falsamente como éxito | Product + ingeniería |

D10 resuelta: ocho semanas tentativas, sin compromiso rígido ni prisa. La revisión de Product del 4 de octubre confirma la fuente integrada; no se vuelve a solicitar confirmación del plazo. Product confirma también el onboarding solo hasta la primera aceptación, la reanudación de etapas pendientes y Home en aperturas posteriores. César confirma después D02 (semana actual completa desde lunes, sin prorrateo) y D03 (continuidad automática con igual valor y sin confirmación). D04–D05 siguen pendientes.

Las consultas a César se secuencian: primero detalles de calendario/zona aún abiertos; después histórico insuficiente/objetivo y edición. Arranque D02 y continuidad D03 están cerrados. El inventario de pendientes conserva contexto, no es un cuestionario simultáneo.

También queda por definir el rango permitido y tratamiento de decimales al editar energía activa. Los ejemplos 38.500→40.000 son demostraciones, no política de progresión aprobada.

## 8. Validación de esta propuesta

Recorridos reproducibles con datos ficticios:

1. Caminar → Salud → 4 semanas aptas → 38.500 baseline / 40.000 propuesta → editar → cancelar → aceptar → Home de Pasos. Verificar principal y no activar Actividad.
2. Moverme → Actividad principal → añadir Pasos → Home con estados distintos. Verificar que cabecera no declara ambos «A tu ritmo».
3. Consulta vacía → mensaje sin datos accesibles, sin permiso denegado ni cero. Reintento no reinicia onboarding.
4. Progreso apto sin patrón → restante visible, ritmo desconocido; no regla lineal.
5. Consulta falla tras snapshot válido → dato anterior con fecha original; nueva semana sin snapshot → desconocido, no acumulado anterior.
6. 40.600 / 40.000 → completado, restante 0 y cifra real preservada; sin badges ni aumento.
7. Semana termina con objetivo parcial → nueva semana sigue automáticamente con el mismo objetivo → resumen neutral opcional → Ver esta semana/Ajustar. No pedir Mantener ni exigir abrir el resumen para seguir. La aplicación temporal de la edición sigue D04.
8. Revisar en ventana estrecha/paisaje/iPad y texto ampliado/EN: scroll, unidad legible, acciones accesibles. Figma ilustra composición, no valida runtime.
9. Widget refleja uno/dos objetivos, antigüedad y ausencia de datos; pulsar vuelve Home. Aviso opt-in sin valores sensibles; desactivar cancela programación.

Ejecutado: lectura de fuentes integradas, identidad App y Figma Full comprobadas, inspección de estructura de Figma y revisión visual según evidencia de entrega; `git diff --check` y checks documentales/kit se registrarán en PR. Pendiente: revisión César/Product, decisiones D01 y D04–D09, revisión independiente de SHA y CI. No aplicable a esta PR: compilación de app, permisos reales, VoiceOver/Dynamic Type ejecutados, Watch/background/widget real y TestFlight. No se declara resuelta la hipótesis por wireframes.

## 9. Enlaces de revisión y evidencia visual

- [Flujo completo](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13?node-id=5-2).
- [Wireframes principales](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13?node-id=4-2).
- [Home de un objetivo](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13?node-id=4-41).
- [Dos objetivos con estados distintos](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13?node-id=6-39).
- [Estados y adaptación](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13?node-id=6-140).
- [Widget mediano](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13?node-id=6-82).
- [iPad/paisaje](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13?node-id=6-88).

Inspección ejecutada: composición principal inicial con 126 descendientes (10 frames, 95 textos, 21 instancias), estados iniciales con 105 (10 frames, 79 textos, 16 instancias); fuentes SF Pro, sin rellenos de imagen. Se revisaron capturas de composición y corrigieron solapamientos multilineales y anchuras del ejemplo EN estrecho. Hay tres componentes locales esquemáticos y seis variables neutras en Claro/Oscuro. La propuesta es editable por capas, no una imagen de UI.

Los wireframes son estáticos. Un intento de enlaces de navegación fue rechazado porque los destinos están agrupados bajo una composición; no se presenta como prototipo interactivo terminado. El recorrido y las transiciones están documentados en el flujo. Notas técnicas dentro de los wireframes son anotaciones de revisión, no copy final de la app. La tarjeta de valor en S05 representa un campo numérico, no un botón de selección. El widget W01 del recorrido expresa intención; el nodo mediano de estados muestra su tamaño/composición propuesta.

No todos los estados de la matriz tienen una pantalla ilustrada; los casos representativos solicitados sí están cubiertos. La matriz es el contrato propuesto para completar estados antes de implementación, sujeto a decisiones Product.

Revisión de coherencia Product (4 de octubre): D10 resuelta, onboarding de primera aceptación/reanudación aclarado y reelección tras último objetivo separada del onboarding. Flujo Figma `5:2` actualizado y captura revisada sin solapamientos; D02 queda confirmada por el encargo posterior de César; la recomendación histórica no prevalece sobre la decisión actual. Esta actualización exige nueva revisión y CI sobre el nuevo SHA.

## 10. Cierre de wireframes por César (4 de octubre)

Dirección general aprobada; seis ajustes completados antes de alta fidelidad: sin reparto diario en Home, explicación del ritmo secundaria, S06 con continuidad automática, S04 con dos objetivos simultáneos opcionales, etiquetas S01 «Caminar más / Pasos semanales» y «Moverme más / Actividad semanal» adoptadas como elección de diseño (no wording obligatorio), y primera semana actual completa con actividad desde el lunes sin prorrateo.

El estado dual conserva la Home de un objetivo: la segunda métrica sigue optativa. [Home dual principal](https://www.figma.com/design/dAffHzxDalwnkz5jkBXA13?node-id=4-123). Al confirmar el primer objetivo a mitad de semana, no se empieza un intervalo móvil de siete días ni se reduce la meta por los días restantes. D01 aún concreta zona horaria/cambio temporal y el motor define cómo obtiene datos aptos.

Este cierre autoriza preparar la siguiente fase visual, sin aprobar algoritmos pendientes, implementación, merge o publicación. Los documentos fuente aún deben sincronizarse por Product con las decisiones recientes; el encargo directo de César prevalece sobre el anterior reparto Home y CTA Mantener. Ingeniería y Product han sido informados.

Validación del cierre: composiciones Figma principal, estados y flujo revisadas tras los ajustes; Home principal/dual y variantes sin texto diario. Composición principal final: 136 descendientes (10 frames, 102 textos, 24 instancias), SF Pro, sin imágenes; estado dual principal con CTA Ajustar objetivos y explicación secundaria. El detalle explicativo es una entrada contraída, no prototipo funcional. `git diff --check` ejecutado sin errores.
