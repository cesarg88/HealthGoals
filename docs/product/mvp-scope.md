# HealthGoals — MVP Scope

**Estado:** Scope inicial  
**Fecha:** Octubre de 2026  
**Versión objetivo:** MVP / 1.0 inicial

---

# 1. Objetivo

El MVP de HealthGoals debe validar una única hipótesis:

> **Un usuario obtiene valor recurrente cuando HealthGoals utiliza automáticamente sus datos de actividad para establecer objetivos semanales razonables, mostrar su progreso y decirle exactamente qué le queda para completarlos.**

El MVP no pretende demostrar todavía:

- monetización;
- escalabilidad;
- coaching;
- personalización avanzada;
- inteligencia artificial;
- breadth de métricas.

Debe validar el core loop:

> **Baseline → Objetivo → Progress → Gap → Nueva semana**

---

# 2. Usuario objetivo

El MVP está diseñado principalmente para:

> **Una persona con iPhone y Apple Watch que quiere moverse más o ser más constante con su actividad, pero no sigue un plan deportivo profesional y no quiere registrar manualmente sus hábitos.**

No necesitamos servir inicialmente a todos los usuarios de HealthKit.

---

# 3. Intenciones soportadas

Durante onboarding, el usuario podrá indicar qué quiere mejorar.

Opciones iniciales:

- **Moverme más**
- **Caminar más**
- **Ser más activo**
- **Ser más constante con mi actividad**

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

La implementación exacta de cálculo se definirá en arquitectura y tests.

---

# 7. Propuesta de objetivos

A partir del baseline, HealthGoals propondrá como máximo:

> **dos objetivos semanales.**

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

Necesitamos comprobar si el concepto de:

> baseline → propuesta razonable

es útil.

Las reglas exactas deberán ser:

- deterministas;
- testeables;
- explicables.

---

# 10. Pantalla principal

La Home debe responder inmediatamente:

> **¿Cómo voy esta semana y qué me queda?**

Ejemplo:

## Vas bien esta semana

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

1. estado;
2. progreso;
3. gap.

---

# 11. Estado semanal

El MVP puede utilizar estados sencillos.

Por ejemplo:

- **Vas bien**
- **Necesitas recuperar algo de ritmo**
- **Estás cerca**
- **Objetivo completado**

La lógica debe ser determinista y explicable.

No utilizaremos IA para decidir el estado.

El wording no debe generar culpa ni presentar un mal día como fracaso.

---

# 12. Gap

Para cada objetivo calcularemos:

> `objetivo − progreso actual`

Y cuando tenga sentido:

> `gap / días restantes`

Ejemplo:

> Te quedan 9.600 pasos.

Con tres días restantes:

> ~3.200 pasos/día.

La división diaria es informativa.

No significa que el usuario deba repartir exactamente la actividad de esa manera.

---

# 13. Actualización

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

Podemos medir eventos de producto como:

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

Si el usuario solo concede acceso reciente, utilizaremos el periodo disponible.

La propuesta debe reflejar que el análisis se basa en menos histórico.

## Datos no actualizados

No mostrar ceros falsos.

Mostrar último estado conocido.

---

# 21. Criterios de éxito

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

No forma parte de la validación principal del MVP.

No introduciremos publicidad.

El producto debe diseñarse para permitir posteriormente una oferta:

- gratuita;
- premium mediante compra única.

La decisión exacta se tomará después de validar que existe uso recurrente.

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

Es comprobar rápidamente si merece convertirse en un producto mayor.

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
8. saber exactamente qué le queda durante la semana;
9. consultar ese gap desde un widget;
10. completar una semana;
11. mantener o ajustar sus objetivos para la siguiente.

Si ese loop funciona y genera uso recurrente, tendremos evidencia para ampliar el producto.

Si no, añadir más métricas o inteligencia no solucionará el problema.