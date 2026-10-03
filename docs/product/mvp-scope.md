# HealthGoals — MVP Scope

**Estado:** Alcance cerrado para el MVP  
**Fecha:** Octubre de 2026  
**Versión objetivo:** MVP / 1.0 inicial

---

# 1. Objetivo

El MVP de HealthGoals debe validar una única hipótesis:

> **Una persona con Apple Watch y semanas variables obtiene valor de perseguir un objetivo semanal flexible, entendiendo cómo va respecto a su propio ritmo y qué le queda, sin tener que cumplir el mismo objetivo todos los días.**

El MVP no pretende demostrar todavía:

- viabilidad económica a escala;
- escalabilidad;
- coaching;
- personalización avanzada;
- inteligencia artificial;
- breadth de métricas.

Debe validar el core loop:

> **Baseline y patrón semanal → Objetivo → Progreso respecto al ritmo personal → Gap → Nueva semana**

Las **ocho semanas hasta TestFlight** son una referencia tentativa para este proyecto personal, sin compromiso rígido ni prisa. No se fija una fecha de entrega ni se reinicia el plazo. La infraestructura reusable se mantiene mínima. El objetivo es terminar, publicar y aprovechar el aprendizaje para otros productos del portfolio.

---

# 2. Usuario objetivo

El MVP está diseñado principalmente para:

> **Una persona con iPhone y Apple Watch que quiere moverse más o ser más constante con su actividad, pero no sigue un plan deportivo profesional y no quiere registrar manualmente sus hábitos.**

No necesitamos servir inicialmente a todos los usuarios de HealthKit.

La compatibilidad confirmada por César es **iOS 26 e iPadOS 26 como mínimo, iPhone e iPad y todas las orientaciones**. El diseño y la validación deben contemplar adaptación a ambos dispositivos y cambios de orientación. Cualquier limitación técnica real de plataforma debe registrarse antes de afirmar cobertura. Este soporte no añade sincronización multidispositivo al MVP.

El idioma de la app sigue pendiente de confirmación; el español es una propuesta, no una decisión aprobada.

---

# 3. Intenciones soportadas

Durante onboarding, el usuario podrá indicar qué quiere mejorar.

Opciones iniciales:

- **Caminar más** → objetivo principal de pasos semanales.
- **Moverme más** → objetivo principal de actividad semanal, medida en energía activa.

Después, el usuario puede añadir un objetivo de la otra métrica, hasta un máximo de dos. La selección cambia realmente la propuesta; la constancia es un resultado esperado del uso.

No habrá campo de texto libre en el MVP.

No utilizaremos Foundation Models para interpretar intención.

---

# 4. Métricas soportadas

El MVP soportará únicamente dos tipos de objetivo.

## Pasos semanales

HealthKit:

`HKQuantityTypeIdentifier.stepCount`

Ejemplo:

> 42.000 pasos / semana

## Actividad semanal

HealthKit:

`HKQuantityTypeIdentifier.activeEnergyBurned`

Se presentará al usuario principalmente como:

> Actividad

Ejemplo:

> 4.200 kcal activas / semana

No se utilizará esta métrica para recomendar pérdida de peso o consumo calórico.

---

# 5. Flujo principal

## 5.1 Selección de intención

El usuario selecciona qué quiere mejorar.

Ejemplo:

> Quiero moverme más.

---

## 5.2 Explicación de HealthKit

Antes de solicitar permisos explicaremos:

- qué información necesitamos;
- para qué la utilizaremos;
- que HealthGoals no modifica sus datos de salud;
- que los datos permanecen en el dispositivo.

---

## 5.3 Autorización

Solicitaremos acceso de lectura únicamente a los datos necesarios para el MVP.

Inicialmente:

- pasos;
- energía activa.

Debemos soportar correctamente:

- autorización completa;
- histórico limitado;
- datos insuficientes;
- ausencia de Apple Watch;
- acceso no disponible.

Nunca mostraremos `0` como si fuese un dato real cuando simplemente no podamos leer información suficiente.

---

# 6. Baseline

Después de obtener acceso, HealthGoals analizará:

> las últimas cuatro semanas como mínimo.

Cuando exista acceso a más histórico, podrá utilizar hasta ocho semanas.

Para cada métrica obtendremos un baseline semanal representativo.

Ejemplo:

> Últimas cuatro semanas
>
> Pasos: ~38.500 / semana  
> Actividad: ~3.900 kcal activas / semana

El baseline debe poder manejar semanas atípicas razonablemente.

También obtendremos, por métrica, el patrón habitual de distribución de actividad entre los días de la semana. Ese patrón sirve para interpretar el ritmo actual; no obliga a repetir la misma distribución.

La implementación exacta del baseline, del patrón y de la suficiencia de historial se definirá en la Issue correspondiente y se verificará con tests. No se fijan aquí porcentajes de progresión ni umbrales de datos suficientes.

---

# 7. Propuesta de objetivos

A partir del baseline, HealthGoals propondrá como máximo:

> **dos objetivos semanales.**

La intención determina la métrica principal; la segunda se añade por elección del usuario.

Ejemplo:

> Tu actividad reciente:
>
> 38.500 pasos  
> 3.900 kcal activas
>
> Te proponemos:
>
> **42.000 pasos**
>
> **4.200 kcal activas**

Cada propuesta debe incluir una explicación sencilla.

Por ejemplo:

> “Durante las últimas semanas has caminado aproximadamente 38.500 pasos semanales. Empezaremos con un objetivo ligeramente superior.”

---

# 8. Control del usuario

El usuario podrá:

- aceptar un objetivo;
- editar su valor;
- eliminarlo;
- mantener solo uno de los dos objetivos.

HealthGoals nunca incrementará automáticamente un objetivo.

---

# 9. Progresión inicial

El MVP debe utilizar reglas conservadoras.

Principio:

> **consistencia antes que ambición.**

No necesitamos optimizar todavía el algoritmo de progresión.

La propuesta inicial debe ayudar a empezar. La hipótesis principal se valida mediante la utilidad de la semana flexible, la interpretación del ritmo personal y la consulta del restante.

Las reglas exactas deberán ser:

- deterministas;
- testeables;
- explicables.

---

# 10. Pantalla principal

La Home debe responder inmediatamente:

> **¿Cómo voy esta semana y qué me queda?**

Ejemplo:

## Vas a tu ritmo esta semana

**Pasos**

32.400 / 42.000

Te quedan:

**9.600 pasos**

~3.200/día hasta el domingo

---

**Actividad**

3.150 / 4.200 kcal

Te quedan:

**1.050 kcal activas**

~350/día hasta el domingo

---

No necesitamos un dashboard complejo.

La Home debe priorizar:

1. estado respecto al ritmo personal;
2. progreso;
3. gap y reparto diario orientativo.

---

# 11. Estado semanal

El MVP puede utilizar estados sencillos.

Por ejemplo:

- **Vas a tu ritmo**
- **Necesitas recuperar algo de ritmo**
- **Estás cerca**
- **Objetivo completado**

El estado de ritmo compara el progreso con el patrón histórico del usuario para esa métrica y ese momento de la semana. No se deduce exclusivamente del porcentaje de días transcurridos ni del reparto uniforme entre siete días.

Por ejemplo, si el usuario suele concentrar actividad durante el fin de semana, llevar menos de la mitad del objetivo el jueves no implica por sí solo ir retrasado.

La lógica debe ser determinista y explicable. La Issue de implementación concretará cómo trata el día en curso y los umbrales de cada estado. Si no hay historial suficiente para estimar el patrón, se comunica esa limitación y no se presenta un estado personalizado como conocido.

No utilizaremos IA para decidir el estado.

El wording no debe generar culpa ni presentar un mal día como fracaso.

---

# 12. Gap

Para cada objetivo calcularemos:

> `máximo(0, objetivo − progreso actual)`

Y cuando tenga sentido:

> `gap / días restantes`

Ejemplo:

> Te quedan 9.600 pasos.

Con tres días restantes:

> ~3.200 pasos/día.

La división diaria es informativa y no determina el estado de ritmo personal.

No significa que el usuario deba repartir exactamente la actividad de esa manera.

---

# 13. Actualización y seguimiento

El progreso se actualizará mediante HealthKit.

No prometeremos tiempo real.

La interfaz deberá poder mostrar:

> Última actualización: 18:42

cuando sea relevante.

El producto debe tolerar:

- latencia de sincronización del Watch;
- actualizaciones en background;
- aplicación cerrada;
- datos temporalmente inaccesibles.

## Notificación local opcional

El MVP incluye una notificación local de seguimiento semanal, por ejemplo a mitad de semana:

> **Así va tu semana**
> Mira cómo estás avanzando y qué te queda.

No muestra pasos, energía activa ni otros valores de salud. El usuario elige si la activa y puede desactivarla desde Ajustes. No requiere backend. El momento exacto y las reglas de programación se concretarán en la Issue correspondiente.

---

# 14. Fin de semana

Al finalizar la semana mostraremos un resumen sencillo.

Ejemplo:

> **Semana completada**
>
> Pasos  
> 44.230 / 42.000 ✓
>
> Actividad  
> 4.340 / 4.200 kcal ✓

Después preguntaremos:

> **¿Quieres mantener estos objetivos otra semana?**

Opciones:

- Mantener
- Ajustar

El MVP no propone todavía automáticamente aumentar los objetivos después de cada semana.

---

# 15. Widget

El MVP incluirá al menos un widget sencillo.

Su trabajo es responder sin abrir la aplicación:

> ¿Qué me queda?

Ejemplo:

> **HealthGoals**
>
> 8.200 pasos restantes  
> 620 kcal activas restantes
>
> 3 días

No necesitamos inicialmente múltiples familias de widgets ni personalización avanzada.

---

# 16. Persistencia

Los objetivos y configuración vivirán únicamente en el dispositivo.

MVP:

- sin backend;
- sin cuenta;
- sin login;
- sin CloudKit.

App y Widget podrán compartir el estado necesario mediante App Group.

---

# 17. Privacidad

Principios obligatorios:

- no enviar valores de HealthKit a servidores;
- no utilizar datos de salud para publicidad;
- no compartir datos de salud con terceros;
- no almacenar datos de salud innecesariamente;
- no utilizar analytics que incluyan pasos, energía activa u otros valores HealthKit.

El futuro plan de validación concretará el método de medición y su compatibilidad con la persistencia local y la ausencia de backend del MVP. Esta lista no autoriza añadir un SDK ni un servicio de analytics.

Podemos evaluar señales de producto como:

- onboarding completado;
- objetivo propuesto;
- objetivo editado;
- objetivo aceptado;
- Home consultada;
- widget añadido;
- nueva semana iniciada.

Nunca junto a valores de salud.

---

# 18. Fuera del MVP

No forman parte de esta versión:

- workouts por semana;
- minutos de ejercicio;
- distancia;
- peso;
- pérdida de peso;
- calorías ingeridas;
- nutrición;
- sueño;
- HRV;
- VO₂ max;
- recuperación;
- readiness;
- frecuencia cardíaca;
- planes de entrenamiento;
- recomendaciones deportivas;
- streaks;
- badges;
- gamificación;
- amigos;
- social;
- rankings;
- challenges;
- Apple Watch app;
- Live Activities;
- Foundation Models;
- conversación con IA;
- App Intents;
- Siri;
- CloudKit;
- backend;
- cuentas;
- sincronización multidispositivo;
- publicidad.

Estas exclusiones son deliberadas.

---

# 19. Pantallas mínimas

El producto necesita inicialmente:

## Onboarding

- bienvenida;
- selección de intención;
- explicación de HealthKit;
- autorización;
- análisis de baseline;
- propuesta de objetivos;
- aceptación/edición.

## Home

- estado semanal;
- progreso de pasos;
- progreso de actividad;
- gap;
- días restantes.

## Editar objetivos

Permitir modificar los valores aceptados.

## Resumen semanal

Resultado de la semana y decisión sobre la siguiente.

## Ajustes

Como mínimo:

- privacidad;
- gestión de HealthKit;
- activar o desactivar el seguimiento semanal;
- información sobre los objetivos;
- disclaimer de bienestar.

---

# 20. Estados especiales

El MVP debe contemplar explícitamente:

## Datos insuficientes

> No tenemos todavía suficiente actividad para proponerte un objetivo basado en tu historial.

Podemos permitir al usuario configurar uno manualmente.

## Sin Apple Watch

La experiencia puede degradarse.

Los pasos pueden seguir estando disponibles, pero energía activa puede no tener la misma calidad o disponibilidad.

El MVP se diseñará principalmente para usuarios con Apple Watch.

## Histórico limitado

Si solo hay histórico reciente disponible, utilizaremos el periodo disponible.

La propuesta debe reflejar que el análisis se basa en menos histórico.

## Datos no actualizados

No mostrar ceros falsos.

Mostrar último estado conocido.

---

# 21. Criterios de éxito

Las siguientes son preguntas de validación, no métricas ya instrumentadas. Se definirán cohortes de TestFlight, método de medición, definiciones de uso recurrente y umbrales de decisión en un futuro `docs/product/validation-plan.md`. No se inventan valores para cerrar la tarea.

El MVP debe ayudarnos a responder:

## ¿Acepta el usuario nuestra propuesta?

Medir:

> % de objetivos aceptados sin grandes modificaciones.

Una tasa alta indicaría que el baseline y la propuesta resultan razonables.

---

## ¿Consulta el gap?

Medir:

> usuarios que vuelven a consultar el progreso durante la semana.

Especialmente después del onboarding.

---

## ¿El widget aporta valor?

Medir:

> % de usuarios activos que añaden el widget.

---

## ¿Continúa otra semana?

Esta es la señal principal.

Medir:

> % de usuarios que mantienen al menos un objetivo activo en semana 2 y semana 4.

El comportamiento que buscamos no es:

> instalar → mirar datos → borrar.

Buscamos:

> definir objetivo → consultar semana → comenzar otra semana.

---

# 22. Monetización

La decisión inicial es **pago único desde el lanzamiento comercial**. La distribución en TestFlight permite validar el uso antes de publicar.

El precio y el mecanismo de cobro quedan pendientes de una decisión explícita en la Issue correspondiente. Esta decisión sustituye la hipótesis anterior de decidir una oferta gratuita/premium después de validar el uso recurrente.

No introduciremos publicidad. El éxito de esta primera app no exige sustituir un salario: buscamos publicar un producto útil, comprobar su monetización y aprender para el portfolio.

---

# 23. Kill criteria

Deberemos cuestionar seriamente el producto si, tras probarlo con usuarios reales:

- la mayoría sustituye completamente los objetivos propuestos;
- el gap no provoca consultas recurrentes;
- los usuarios prefieren simplemente Apple Fitness;
- la energía activa resulta demasiado confusa como concepto;
- los datos de HealthKit generan errores frecuentes que destruyen la confianza;
- la mayoría no mantiene el producto activo más allá de las primeras semanas.

El objetivo del MVP no es demostrar que nuestra idea es correcta.

Es comprobar rápidamente si merece convertirse en un producto mayor. El plan de validación deberá convertir estas señales en condiciones observables antes de tomar una decisión de continuar, ajustar o abandonar.

---

# 24. Definition of MVP

HealthGoals MVP está completo cuando un usuario puede:

1. instalar la app;
2. seleccionar qué quiere mejorar;
3. conectar HealthKit;
4. obtener un baseline basado en actividad real;
5. recibir una propuesta de objetivos semanales;
6. aceptar o editar esos objetivos;
7. ver automáticamente su progreso;
8. entender su progreso respecto a su patrón semanal cuando el historial lo permita, y saber exactamente qué le queda durante la semana;
9. consultar ese gap desde un widget;
10. completar una semana;
11. mantener o ajustar sus objetivos para la siguiente;
12. activar o desactivar una notificación local semanal sin datos de salud.

La entrega debe aportar evidencia de aceptación y checks para el SHA actual, revisión independiente y validación de César en dispositivo real para HealthKit, permisos, sincronización con Apple Watch, background y WidgetKit. No basta con CI verde para dar esas integraciones por verificadas.

La salida a TestFlight toma las ocho semanas como referencia tentativa, sin compromiso rígido ni prisa; la publicación comercial requiere resolver el precio y mecanismo de pago único. Completar el loop y validar la hipótesis de producto son resultados distintos.

Si ese loop funciona y genera uso recurrente, tendremos evidencia para ampliar el producto.

Si no, añadir más métricas o inteligencia no solucionará el problema.
