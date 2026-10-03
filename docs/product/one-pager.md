# HealthGoals — One-Pager

**Estado:** Definición de producto cerrada para el MVP  
**Fecha:** Octubre de 2026  
**Nombre:** Provisional

---

## Product Vision

HealthKit contiene información continua sobre la actividad real de una persona, especialmente cuando utiliza Apple Watch.

Sin embargo, la mayoría de productos se concentran en responder:

> ¿Qué has hecho?

HealthGoals quiere responder una pregunta diferente:

> **¿Qué quieres mejorar, dónde estás ahora y qué necesitas hacer desde hoy para conseguir tu objetivo?**

La visión es convertir los datos pasivos que ya existen en el ecosistema Apple en un sistema sencillo de objetivos personales que requiera el mínimo esfuerzo manual posible.

El usuario no debería tener que mantener otro habit tracker ni interpretar continuamente métricas, gráficas y dashboards.

HealthGoals utiliza lo que el dispositivo ya sabe para transformar actividad pasada y presente en progreso accionable.

---

# The concept

El usuario comienza expresando una intención sencilla.

Por ejemplo:

> “Quiero moverme más.”

> “Quiero caminar más.”

La intención determina el objetivo principal:

- **Caminar más** → pasos semanales.
- **Moverme más** → actividad semanal, medida en energía activa.

El usuario puede añadir después el objetivo de la otra métrica, hasta un máximo de dos. La constancia es un resultado que buscamos, no una intención adicional del onboarding.

Con permiso del usuario, HealthGoals analiza su historial reciente de HealthKit para entender cuál es su nivel de actividad habitual.

El producto no empieza preguntando:

> ¿Cuántos pasos quieres hacer?

o:

> ¿Cuántas calorías activas quieres quemar?

Primero intenta entender el punto de partida real.

Por ejemplo:

> Durante las últimas cuatro semanas:
>
> - has caminado una media de 38.500 pasos por semana;
> - has generado una media de 3.900 kcal de energía activa por semana.

A partir de ese baseline, HealthGoals propone uno o dos objetivos semanales sencillos y alcanzables.

Por ejemplo:

> Para empezar te proponemos:
>
> - 42.000 pasos por semana;
> - 4.200 kcal de actividad por semana.

El usuario mantiene siempre el control.

Puede:

- aceptar;
- ajustar;
- eliminar un objetivo;
- mantener únicamente el objetivo que le interese.

Una vez aceptados los objetivos, el seguimiento comienza automáticamente utilizando HealthKit.

---

# The Core Loop

HealthGoals se apoya en un loop recurrente.

## 1. Intención

El usuario indica qué quiere mejorar.

> “Quiero moverme más.”

## 2. Baseline

HealthGoals analiza las últimas 4–8 semanas de actividad disponible en HealthKit.

El objetivo es comprender:

> ¿Qué está haciendo realmente esta persona actualmente?

## 3. Plan

HealthGoals propone uno o dos objetivos semanales basados en ese comportamiento reciente.

Los objetivos deben ser:

- sencillos;
- conservadores;
- explicables;
- editables.

El usuario decide si quiere aceptarlos.

## 4. Progress

HealthKit actualiza automáticamente el progreso. HealthGoals compara ese avance con cómo suele distribuir el usuario su actividad entre los días de la semana.

El estado semanal responde a **cómo voy respecto a mi propio ritmo**, sin asumir que todos los días deben aportar la misma actividad. Por ejemplo, una persona que concentra actividad en el fin de semana puede estar a su ritmo el jueves aunque haya completado menos que una proporción lineal de siete días.

Este patrón se calcula por métrica con reglas explícitas, explicables y testeables. Si el historial no permite estimarlo, la aplicación debe comunicar esa limitación.

El usuario no tiene que registrar:

> “Hoy me he movido.”

El dispositivo ya lo sabe.

## 5. Gap

HealthGoals calcula continuamente la diferencia entre:

> lo que has hecho

y:

> lo que quieres conseguir esta semana.

Ejemplo:

> 31.400 / 42.000 pasos  
> 3.050 / 4.200 kcal activas

## 6. Next action

El producto no se limita a mostrar porcentajes o barras.

Debe responder:

> **¿Qué significa esto para el resto de mi semana?**

Por ejemplo:

> Te quedan:
>
> - 10.600 pasos;
> - 1.150 kcal activas.

Si quedan tres días:

> Aproximadamente:
>
> - 3.530 pasos diarios;
> - 383 kcal activas diarias.

No se trata de una prescripción.

Es una traducción matemática del objetivo restante.

## 7. Adapt

Cada vez que HealthKit incorpora nueva actividad, el gap se recalcula.

Si el sábado el usuario camina mucho más de lo habitual, lo que necesita durante el domingo se reduce automáticamente.

Al comenzar una nueva semana, el loop vuelve a empezar.

---

# Value Proposition

## The promise

> **Dime qué quieres mejorar. HealthGoals utilizará la actividad que tu iPhone y Apple Watch ya conocen para ayudarte a establecer objetivos semanales razonables y decirte automáticamente cómo vas y qué te queda para cumplirlos.**

---

# Para el usuario

## No necesito inventarme mis objetivos

HealthGoals utiliza mi comportamiento reciente como contexto.

No parte de números arbitrarios.

## No necesito registrar mi actividad manualmente

Si HealthKit ya conoce el dato, HealthGoals no debería preguntármelo otra vez.

## Puedo mejorar de la manera que quiera

HealthGoals mide actividad, pero no prescribe cómo conseguirla.

El usuario puede alcanzar su objetivo:

- caminando;
- bailando;
- haciendo deporte;
- jugando;
- realizando tareas domésticas;
- desplazándose;
- o simplemente teniendo una semana más activa.

## Sé cómo voy

El producto muestra progreso respecto a un objetivo concreto.

## Sé qué me queda

HealthGoals no termina en:

> “74 % completado.”

Debe poder decir:

> “Te quedan 10.600 pasos esta semana.”

## Mis días pueden ser diferentes

El producto prioriza flexibilidad semanal.

Un día sedentario no significa necesariamente que el objetivo esté perdido.

El usuario puede compensar actividad entre diferentes días de la semana.

---

# Diferencia respecto a un fitness dashboard

Un dashboard tradicional suele seguir:

> dato → visualización

HealthGoals sigue:

> **intención → baseline → objetivo → progreso → gap → acción**

Los datos no son el producto.

Son la materia prima.

---

# Principio central

> **HealthGoals mide actividad, no prescribe cómo conseguirla.**

La aplicación ayuda al usuario a establecer y seguir resultados de actividad medibles.

No decide qué ejercicio concreto debe realizar.

No crea planes de entrenamiento.

No intenta actuar como entrenador personal.

---

# Métricas iniciales

La primera versión se concentrará en dos métricas.

## Pasos semanales

HealthKit:

`stepCount`

Permite medir movimiento cotidiano de forma sencilla y comprensible.

## Energía activa semanal

HealthKit:

`activeEnergyBurned`

Representa la actividad física realizada durante la semana independientemente de si procede de un entrenamiento formal.

En interfaz se presentará principalmente como:

> **Actividad**

y secundariamente mediante su unidad:

> kcal activas

El objetivo no es utilizar calorías para dieta o pérdida de peso, sino disponer de una medida común de actividad.

El número de entrenamientos por semana queda fuera del MVP. Es una posible primera expansión después de validar esta experiencia, no un compromiso de la versión inicial.

---

# Target user inicial

El usuario inicial es:

> **Una persona con iPhone y Apple Watch que quiere moverse más o mantener una vida más activa, pero que no sigue necesariamente un plan deportivo estructurado ni quiere registrar manualmente su comportamiento.**

Probablemente:

- no es atleta;
- no necesita métricas deportivas avanzadas;
- tiene semanas variables;
- quiere mejorar su consistencia;
- ya genera datos automáticamente mediante Apple Watch;
- quiere una experiencia más sencilla que un dashboard de fitness avanzado.

---

# Usuarios que no son el target inicial

HealthGoals no se diseñará inicialmente para:

- atletas de rendimiento;
- corredores con programas estructurados;
- culturistas;
- personas en rehabilitación;
- usuarios con objetivos médicos;
- usuarios que necesitan planes de entrenamiento;
- personas que buscan planificación nutricional.

Estos usuarios pueden necesitar productos más especializados.

---

# Goal Engine

Una pieza central del producto será el motor que transforma:

> baseline → propuesta de objetivo

No debe funcionar como una caja negra.

Los objetivos deben ser:

- explicables;
- conservadores;
- reproducibles;
- modificables;
- testeables.

Ejemplo:

> Durante las últimas cuatro semanas has caminado una media de aproximadamente 38.500 pasos semanales.
>
> Te proponemos comenzar con 42.000.

El usuario debe poder entender por qué recibe esa propuesta.

El motor también utiliza el patrón histórico de actividad por día de la semana para interpretar el progreso. Su valor principal es ayudar a entender la semana flexible, el ritmo personal y el restante; la propuesta de un número inicial no constituye por sí sola la diferenciación.

HealthGoals no debe responder:

> “La IA ha determinado que este objetivo es óptimo.”

---

# Filosofía de progresión

El objetivo inicial no debe representar un salto agresivo respecto al comportamiento reciente.

HealthGoals priorizará:

> consistencia antes que ambición.

La aplicación puede proponer pequeñas progresiones cuando exista suficiente evidencia de que el usuario está manteniendo cómodamente su objetivo.

Nunca debe aumentar automáticamente un objetivo sin consentimiento.

---

# Papel de la IA

La IA no forma parte del núcleo del MVP.

En el futuro, Foundation Models podría interpretar frases como:

> “Últimamente estoy demasiado parado y quiero moverme más.”

y convertirlas en una intención estructurada.

Pero la lógica que determina los objetivos seguirá basada en reglas explícitas y datos observables.

La inteligencia del producto no depende de un LLM.

---

# Product Principles

## Zero logging whenever possible

Si HealthKit conoce el dato, no volver a pedírselo al usuario.

## Explain everything

Toda propuesta de objetivo debe poder explicar de dónde procede.

## User owns the goal

HealthGoals propone.

El usuario decide.

## Progress, not perfection

Un mal día no equivale a fracaso.

No utilizaremos streaks punitivas.

## Flexible weeks

Los días pueden ser diferentes.

La semana es la unidad principal del producto porque permite compensar actividad entre días.

## Action over analytics

Antes de añadir cualquier gráfica debemos preguntar:

> ¿Ayuda esto al usuario a saber qué hacer?

Si no, probablemente no pertenece al producto.

## Activity, not workouts

Moverse importa aunque el usuario nunca pulse “Start Workout”.

## Privacy by default

Los datos de salud son especialmente sensibles.

La arquitectura debe minimizar su movimiento y almacenamiento.

---

# Native Apple advantage

HealthGoals debe sentirse como un producto creado específicamente para el ecosistema Apple.

## HealthKit

Fuente principal de datos.

## Apple Watch

Fuente fundamental de actividad pasiva y energía activa.

HealthGoals puede funcionar parcialmente sin él, pero la primera experiencia estará diseñada principalmente para usuarios con Apple Watch.

## WidgetKit

El widget puede convertirse en una superficie central del producto.

Por ejemplo:

> **Vas bien**
>
> 8.200 pasos restantes  
> 620 kcal activas restantes

## App Intents

Potencial evolución para consultas como:

> “¿Cómo voy esta semana?”

No forma parte necesariamente del MVP inicial.

## Foundation Models

Potencial evolución para interpretar intención en lenguaje natural.

No necesario para validar el producto.

---

# Lo que HealthGoals NO es

HealthGoals no es:

- otro Apple Health;
- otro dashboard fitness;
- una aplicación médica;
- una aplicación de dieta;
- un contador de calorías ingeridas;
- un entrenador personal;
- un generador de rutinas;
- un habit tracker manual;
- una red social;
- una aplicación de streaks;
- una aplicación centrada en pérdida de peso.

Su trabajo es más pequeño:

> **convertir actividad pasiva en objetivos semanales comprensibles y mantener al usuario informado de cómo va y de qué le queda por hacer.**

---

# Core Experience

Ejemplo:

El usuario elige:

> **Quiero moverme más.**

Su objetivo principal será Actividad. En este ejemplo también añade Pasos.

HealthGoals analiza cuatro semanas.

Resultado:

> Tu actividad reciente:
>
> 38.500 pasos/semana  
> 3.900 kcal activas/semana

Propuesta:

> Para empezar:
>
> 42.000 pasos/semana  
> 4.200 kcal activas/semana

El usuario acepta.

El jueves:

> **Vas a tu ritmo esta semana**
>
> Pasos  
> 26.800 / 42.000
>
> Actividad  
> 2.650 / 4.200 kcal
>
> Quedan cuatro días.
>
> **Te queda:**
>
> 15.200 pasos  
> 1.550 kcal activas

El sábado, después de un día muy activo:

> **Estás cerca**
>
> Te quedan:
>
> 3.900 pasos  
> 310 kcal activas

El domingo:

> **Objetivo completado**
>
> 44.230 / 42.000 pasos  
> 4.340 / 4.200 kcal activas

Nueva semana:

> ¿Quieres mantener estos objetivos?

---

# Monetización y entrega

La decisión inicial es **pago único desde el lanzamiento comercial**, sin publicidad. El precio y el mecanismo de cobro se concretarán en la Issue correspondiente antes de implementarlos.

El objetivo es terminar el MVP, publicarlo y utilizar lo aprendido para siguientes productos del portfolio. Sustituir un salario no es el criterio de éxito de esta primera app.

Las **ocho semanas hasta TestFlight** son una referencia tentativa para este proyecto personal, sin compromiso rígido ni prisa. No se fija una fecha de entrega ni se reinicia el plazo. La preparación de infraestructura se mantiene mínima y se demuestra con entregas reales.

La compatibilidad confirmada por César es **iOS 26 e iPadOS 26 como mínimo, iPhone e iPad y todas las orientaciones**. El diseño y la validación deben contemplar adaptación a ambos dispositivos y cambios de orientación, registrando las limitaciones técnicas reales antes de afirmar cobertura. El idioma de la app sigue pendiente de confirmación.

La infraestructura se demuestra con entregas reales: Issue, implementación, PR, revisión independiente del SHA actual, CI y validación humana cuando corresponda. Las integraciones con HealthKit, permisos, Apple Watch, background y widgets requieren validación de César en dispositivo real.

---

# Seguimiento y validación

El MVP incluye una notificación local opcional de seguimiento semanal, por ejemplo a mitad de semana. Invita a consultar el progreso sin mostrar datos de salud en la notificación. El usuario puede desactivarla.

El plan de validación se definirá después en `docs/product/validation-plan.md`: cohortes de TestFlight, método de medición, uso recurrente y umbrales para continuar, ajustar o abandonar. No se fijan porcentajes arbitrarios ni se presupone una herramienta de analytics.

---

# Principal riesgo

El principal riesgo no es técnico.

Es que el usuario considere:

> “Apple Fitness ya me da suficiente información.”

La hipótesis que debemos validar es:

> **Una persona con Apple Watch y semanas variables obtiene valor de perseguir un objetivo semanal flexible, entendiendo cómo va respecto a su propio ritmo y qué le queda, sin tener que cumplir el mismo objetivo todos los días.**

La diferenciación propuesta es **semana flexible + ritmo personal + restante**. Las métricas y la propuesta inicial basada en historial son medios para esa experiencia, no evidencia de que el producto esté validado.

---

# Core Loop

> **Intención → Baseline → Plan → Progress → Gap → Adapt**

Toda nueva feature deberá justificar cómo mejora alguna parte de este loop.

Si no lo hace, probablemente no pertenece al producto.
