# Validación de baseline real en iPhone

> Guía histórica de su entrega. Para el onboarding vigente desde #29 (selección de una o ambas métricas, autorización solo de los tipos elegidos y just-in-time al añadir), usar [selección y autorización por métrica](metric-selection.md). Las observaciones físicas antiguas no acreditan un SHA posterior ni el nuevo recorrido; los casos de edición, eliminación y ritmo siguen siendo referencias de regresión.

Esta guía comprueba la segunda vertical de [Issue #18](https://github.com/cesarg88/HealthGoals/issues/18): intención → autorización → lectura real → media semanal. CI y los fakes de tests no demuestran que Salud del dispositivo entregue datos accesibles. La aceptación física corresponde a César; no registrar cifras personales, capturas de Salud ni datos médicos en GitHub.

## Preparación

- Usar el checkout y SHA del candidato indicado en la PR, abrir `HealthGoals.xcodeproj` y elegir scheme `HealthGoals`.
- El proyecto ya configura Team `4A669F9FP4`, bundle `com.example.HealthGoals` y firma automática; comprobar acceso de la cuenta local según la [guía de onboarding](onboarding-healthkit.md). Mantener únicamente la capacidad HealthKit básica; no activar background ni permisos de escritura.
- Conectar un iPhone con iOS 26 o posterior y ejecutar. No copiar certificados/perfiles al repositorio.
- Para elegir de nuevo intención, eliminar y reinstalar la app. Esto reinicia las preferencias de onboarding, pero iOS puede conservar decisiones previas de autorización: no esperar necesariamente otro panel nativo. No existe reset oculto ni inyección de datos ficticios en producción.
- Para obtener baseline hacen falta cantidades accesibles de la métrica en cada uno de los cuatro períodos de siete días. Tener alguna actividad no garantiza que los cuatro estén disponibles. No crear registros personales o fixtures dentro de Salud para demostrar aceptación.

## Recorrido real

1. Instalar y ejecutar el candidato. Si se conserva S03 de la entrega anterior, debe consultar directamente; reinstalar para empezar el recorrido desde S01.
2. Elegir **Caminar más**, continuar a Salud y finalizar la solicitud nativa si iOS la presenta.
3. Llegar a **Tu punto de partida**: observar «Analizando tu actividad reciente…» si la duración lo permite, seguido de media real en pasos por semana o insuficiencia neutral. Loading no incluye progreso ni tiempo inventados. Una respuesta rápida puede impedir observar el estado transitorio; no alargarla artificialmente.
4. Si aparece baseline, comprobar que es razonablemente coherente con la actividad reciente en Salud siguiendo la sección de comparación. No enviar el valor. Si alguno de los cuatro períodos no tiene cantidad accesible, comprobar el mensaje neutral y **Reintentar**; no debe afirmar permiso denegado, falta de Watch o inactividad.
5. Eliminar/reinstalar para repetir con **Moverme más**. El panel nativo puede reaparecer o conservar decisiones: ambos comportamientos dependen de iOS.
6. Cuando existan cantidades accesibles en los cuatro períodos, comprobar baseline de energía activa en **kcal activas / semana**. Salud puede mostrar energía con otra unidad; comparar kcal, no kilojulios ni energía total/en reposo. Si faltan cantidades accesibles, comprobar insuficiencia y reintento.
7. Cuando iOS lo permita, limitar/revocar lectura de la métrica elegida desde Salud o Ajustes. Volver a HealthGoals y repetir una consulta: ante un estado con reintento, pulsarlo; si ya hay baseline, cerrar completamente y abrir de nuevo. La entrega no observa cambios de permisos en background ni infiere su estado.
8. Si ya no hay cantidades accesibles suficientes, comprobar el mensaje neutral. No debe aparecer «permiso denegado» ni una sugerencia basada en conocer el permiso READ. Si iOS sigue proporcionando agregados suficientes dentro del alcance permitido, un resultado disponible también es correcto; revocar no es una garantía de error técnico ni un mecanismo para conocer READ.
9. Cerrar completamente la app en S03, también durante loading si se alcanza a observar. Abrirla de nuevo.
10. Comprobar una nueva consulta y su resultado, conservando intención/etapa y sin nueva solicitud de autorización automática. La cifra puede coincidir: no se exige un valor diferente como prueba de recarga. Durante la misma sesión, reaparecer la vista comparte una consulta en curso y no repite automáticamente una ya completada. Los datos permanecen solo en memoria, nunca en UserDefaults.
11. Probar español e inglés con ajustes nativos de idioma del sistema/app. Comprobar separadores, números enteros y unidades traducidas; no hay selector de idioma propio. Pasos y kcal conservan precisión interna y se redondean únicamente al mostrar.
12. Probar Light/Dark, texto aumentado razonablemente, VoiceOver y landscape. La tarjeta debe seguir legible y el botón de reintento accesible, sin cifras cortadas. En iPad, cuando esté disponible, comprobar la columna adaptable; no es necesario reconstruir un layout por dispositivo.

## Cómo comparar con Salud

La app usa **los 28 días naturales completos anteriores al inicio local de hoy**, con calendario/zona local actuales. Excluye el día parcial de hoy. Divide la ventana desde el día más antiguo en cuatro bloques consecutivos de siete días; calcula la media aritmética de esos cuatro acumulados.

Para contrastar, identificar en Salud los días de esa misma ventana y la misma métrica/unidad. Si resulta practicable, contrastar privadamente el total de esos días dividido entre cuatro. No comparar directamente con la media diaria de Salud ni con cuatro semanas de lunes a domingo: la ventana móvil de HealthGoals puede empezar en otro día. No convertir «una semana sin cantidad accesible» en cero. El redondeo final a entero puede dar pequeñas diferencias visuales.

La consulta usa `.cumulativeSum` de HealthKit, sin sumar muestras crudas ni agregados independientes por fuente. El sistema gestiona la combinación de fuentes. La prioridad de fuentes, sincronización de Watch/iPhone, registros incorporados después y la presentación de Salud pueden afectar una comparación. La app no detecta Watch ni acredita cobertura diaria: cuatro cantidades semanales presentes son el criterio v1, incluso cuando una cantidad presente vale cero.

HealthKit divide sus estadísticas con ancla de inicio local e intervalos de siete días de calendario. La app verifica que las fechas devueltas coinciden exactamente con sus cuatro bloques; si no, muestra error recuperable en lugar de aceptar una ventana desplazada. Las duraciones reales pueden variar en cambios de horario. Viajes y reglas de semana activa no quedan definidos por esta entrega.

Si no se puede reproducir una comparación exacta, informar «coherente/no coherente/no comprobable» y describir la limitación sin publicar cantidades. No afirmar equivalencia exacta con los gráficos de Salud ni inventar evidencia.

## Error técnico y reintento

Un error real de consulta debe mostrar mensaje recuperable y **Reintentar**, conservando intención y S03. HealthKit no disponible también se trata como error recuperable de lectura. El dispositivo bloqueado o disponibilidad del almacén pueden condicionar consultas según iOS; no prometer que produzcan un error reproducible en todos los equipos. No modificar entitlements, introducir fallos o usar datos falsos en producción para forzarlo.

Si el caso no puede reproducirse razonablemente en el iPhone, indicarlo como no reproducible. Los tests de la pequeña abstracción de lectura cubren fallo/reintento, insuficiencia, valores disponibles y exclusión de consultas simultáneas. No sustituyen el acceso real en hardware.

## Reporte sin datos personales

César puede registrar únicamente:

- SHA instalado y versión de iOS.
- Pasos: baseline coherente / no coherente / insuficiente / no comprobable.
- Actividad: baseline coherente / no coherente / insuficiente / no comprobable.
- Insuficiencia neutral y reintento: correcto / incorrecto / no reproducible.
- Restauración sin prompt automático: correcta / incorrecta.
- EN/ES, Light/Dark, texto y accesibilidad: correcto / incidencias de interfaz sin datos de salud.
- Error técnico/reintento: correcto / incorrecto / no reproducible.

Estado al entregar el candidato: validación física **pendiente** hasta el reporte de César. La siguiente entrega será baseline → propuesta de objetivo y requiere un nuevo encargo; aquí no hay objetivo, ajuste, aceptación ni Home.
