# Diseño: Notebook de Matchmaking para Charla Universitaria

## Contexto

Charla de 1h20 (45min presentación + 25min preguntas) en una universidad (UdeSA) sobre el trabajo diario de un data scientist en una plataforma de matchmaking. Enfoque estadístico. El notebook es para presentar en vivo y entregar después; no se usa interactivamente por los estudiantes.

### Tema central

Dos etapas del trabajo:
1. **Estimación de probabilidades** de aceptación de candidatos propuestos y la probabilidad de aceptación mutua (y su estimación a partir de probabilidades "direccionadas").
2. **Toma de decisiones**: qué emparejamientos hacer a partir de esos datos — elegir función objetivo del caso de negocio y optimizar.

### Puntos pedagógicos clave

- La probabilidad mutua != producto de probabilidades direccionales, pero como aproximación puede servir.
- Para la toma de decisiones no se enseña casi nada en la facultad.
- Stable matching (Gale-Shapley) es bien conocido pero difícil de aplicar en la práctica (no se pueden "aprobar temporariamente" los candidatos).
- Maximum weight matching en grafos como alternativa teórica.
- Fuerza bruta con scipy.minimize como método genérico.
- El matching óptimo global puede NO incluir el par con mayor probabilidad individual (contraintuitivo).

## Parámetros

- **Dominio**: Dating
- **Usuarios**: 100
- **Dimensiones**: 6
- **Idioma notebook**: Español (markdown, comentarios, títulos). Variables en inglés.
- **Dependencias**: Cualquier lib, pero para cada uso de libs especializadas incluir implementación alternativa con libs comunes (numpy, pandas, sklearn, scipy, networkx, matplotlib).

## Estructura del Notebook

### Sección 1: Generación de datos sintéticos

- 100 usuarios con 6 dimensiones: edad (normalizada), extroversión, deportividad, intelectualidad, aventura, romanticismo — todas en [0,1].
- Cada usuario tiene un **vector de características** (lo que "es") y un **vector de preferencias** (lo que busca).
- Probabilidad direccional P(A→B): función ground truth que mide qué tan bien B cumple las preferencias de A (distancia ponderada entre preferencias de A y características de B, pasada por sigmoide).
- Probabilidad mutua real P(A↔B): NO es simplemente P(A→B)·P(B→A) — incluye un término de correlación (la gente que ofrece lo que otros buscan también tiende a buscar cosas similares). Así la diferencia P_mutua vs. producto aparece naturalmente.
- Generar observaciones de matcheos históricos (aceptar/rechazar) a partir de estas probabilidades para tener training data.

### Sección 2: Estimación de probabilidades

- **Logistic Regression**: features = diferencia/interacción entre características y preferencias. Mostrar coeficientes, interpretabilidad.
- **Gradient Boosted Trees** (sklearn GBT): mismas features, mostrar que mejora performance pero pierde interpretabilidad.
- Comparar ambos modelos (AUC, calibración).
- Discusión: P_mutua estimada como producto de P_direccionales vs. estimada directamente. Mostrar que el producto es una aproximación razonable pero sesgada.

### Sección 3: Construcción del grafo de matching

- Con las probabilidades estimadas, construir el grafo completo ponderado de 100 usuarios.
- Peso de cada arista = P_mutua estimada.
- Visualización del grafo (subconjunto de ~20 nodos para que se vea).

### Sección 4: Algoritmos de matching — comparación

1. **Gale-Shapley (stable matching)**: Implementación propia + `matching` lib. Rankings derivados de las probabilidades. Mostrar el resultado y explicar por qué no optimiza bienestar global sino estabilidad.
2. **Maximum weight matching (óptimo)**: `networkx.max_weight_matching`. Maximiza la suma de pesos. Implementación alternativa con scipy (formulación como problema de asignación).
3. **Fuerza bruta con scipy.minimize**: Formulación como optimización combinatoria relajada, con límite de iteraciones (e.g., maxiter=1000). Mostrar que se acerca pero no llega al óptimo, y tarda más.

### Sección 5: Comparación de resultados

- Tabla comparativa: peso total del matching, tiempo de ejecución, número de pares.
- Gale-Shapley vs. max weight matching: mostrar que stable matching puede sacrificar bienestar global. Mostrar pares que están en uno y no en otro.
- Brute force vs. óptimo: mostrar el gap de optimalidad y el costo en tiempo.
- Visualización: grafos con los matchings coloreados.
