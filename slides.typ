#import "@preview/touying:0.6.2": *

#import themes.metropolis: *

#show: metropolis-theme.with(
  footer: [Matchmaking — UdeSA 2026]
)
#show link: set text(blue)
#show link: underline
#set text(font: "Fira Sans", weight: "light", size: 20pt, lang: "es")
#set strong(delta: 100)
#set par(justify: true)

// =============================================================================
// SECCIÓN 1: Presentación
// =============================================================================

#title-slide(
  author: [Gonzalo Barrera Borla \ Lic. Economía — MS Estadística \ _Rol actual, Empresa_],
  title: "Data Science y Toma de Decisiones: Matchmaking",
)

// =============================================================================
// SECCIÓN 2: DS in the wild
// =============================================================================

= Data Science "in the wild"

== No basta con predecir

- En la facultad nos enseñan a *estimar* y *predecir*
- En la práctica, hay que *tomar decisiones* con esas predicciones
- La función objetivo suele ser compleja — no es solo "maximizar valor esperado"

#pause

Tres ejemplos de dominios donde esto es evidente:

+ *Adtech*: ¿Qué aviso muestro?
+ *Carreras de caballos*: ¿Por quién apuesto?
+ *Matchmaking*: ¿Qué parejas presento?

// =============================================================================
// SECCIÓN 2a: Adtech
// =============================================================================

== Adtech: el problema

Simplificación: 2 clientes compitiendo por el mismo público

- *Cliente A*: CPC alto (\$2.0), CTR moderado (~15%)
- *Cliente B*: CPC bajo (\$0.8), CTR alto (~25%)
- Ambos tienen presupuesto diario limitado

*Objetivo*: maximizar ganancia total

$ max sum_i "cpc"_i times "clicks"_i quad "s.a." quad sum_t "cpc"_i times x_(i,t) <= B_i $

== Adtech: ¿qué pasa en la práctica?

#image("img/adtech.svg")

Cuando $"ctr"_A times "cpc"_A > "ctr"_B times "cpc"_B$ consistentemente, A se lleva casi todo el inventario y B sub-ejecuta su presupuesto.

// =============================================================================
// SECCIÓN 2b: Horse Racing
// =============================================================================

== Carreras de caballos: Kelly Criterion

¿Cuánto apostar si creemos conocer la probabilidad de ganar? #link("https://doi.org/10.1002/j.1538-7305.1956.tb03809.x")[(Kelly, 1956)]

$ K = frac("ventaja", "dividendo" - 1) quad "donde" quad "ventaja" = c times "dividendo" - 1 $

#text(size: 16pt)[
- $K$: fracción del capital a apostar
- $c$: probabilidad estimada de ganar (nuestro modelo)
- $"dividendo"$: pago bruto por \$1 apostado (incluye la apuesta)
- $"ventaja" = 0$: juego justo → no apostar; $"ventaja" > 0$: apostar proporcionalmente
]

#pause

*Problema*: las probabilidades son _interdependientes_ (algún caballo siempre gana) y _estimadas_ con error.

== Carreras: sensibilidad a la estimación

#image("img/kelly.svg")

Sobreestimar la ventaja por más de un factor de 2 causa *crecimiento negativo* del capital — y es fácil hacerlo en la práctica. #link("https://gwern.net/doc/statistics/decision/1994-benter.pdf")[(Benter, 1994)]

// =============================================================================
// SECCIÓN 3: Matchmaking
// =============================================================================

= Matchmaking

== El problema del matchmaking

- Plataforma de dating: hay que decidir qué perfiles mostrarle a cada usuario
- Podemos estimar $P(A arrow.r B)$: probabilidad de que A apruebe a B
- Queremos estimar $P(A arrow.l.r B)$: probabilidad de _match mutuo_

#pause

*El dilema*: todos quieren a Brad Pitt / Penélope Cruz...

...pero BP/PC no van a querer a todos.

== Probabilidades direccionales vs. mutuas

$ P(A arrow.r B) &: "qué tan bien B cumple las preferencias de A" $

$ P(A arrow.l.r B) &approx P(A arrow.r B) times P(B arrow.r A) quad "(aprox.)" $

#pause

Pero la probabilidad mutua real tiene un término de correlación: la gente que "ofrece" lo que otros buscan, tiende a "buscar" cosas similares.

$ P(A arrow.l.r B) != P(A arrow.r B) times P(B arrow.r A) $

== Gale-Shapley: Stable Matching

- Algoritmo clásico (Nobel 2012, Shapley & Roth)
- Garantiza *estabilidad*: no hay par que prefiera cambiarse mutuamente

#pause

*Problema en dating*:
- Requiere "aprobar temporariamente" candidatos — no aplica
- Optimiza estabilidad, no bienestar global
- El matching estable puede ser muy desigual

== Greedy Matching

- Ordenar aristas por $P(A arrow.l.r B)$ descendente
- Agregar si ambos nodos están libres
- Garantiza $>= 1/2$ del óptimo (_1/2-aproximación_)

#pause

*Simple e intuitivo*, pero puede "gastar" nodos muy demandados en pares buenos-pero-no-óptimos

== Maximum Weight Matching

- Grafo completo ponderado: peso de cada arista = $P(A arrow.l.r B)$
- Encontrar el matching que maximiza la suma total de pesos

#pause

*Ventaja*: maximiza bienestar global

*Insight contraintuitivo*: el matching óptimo global puede NO incluir el par con mayor probabilidad individual

== Fuerza bruta con `scipy.minimize`

- Formulación genérica: optimización combinatoria relajada
- Flexible — se puede cambiar la función objetivo fácilmente
- Límite de iteraciones ($approx 1000$) para que sea práctico

#pause

*Trade-off*: se acerca al óptimo pero no lo garantiza, y es más lento

== Comparación de enfoques

#table(
  columns: (auto, auto, auto, auto),
  inset: 8pt,
  align: (left, center, center, center),
  table.header(
    [*Algoritmo*], [*Optimiza*], [*Óptimo?*], [*Práctico?*],
  ),
  [Gale-Shapley], [Estabilidad], [Sí (estab.)], [Difícil en dating],
  [Greedy], [Bienestar local], [$>= 1/2$ óptimo], [Sí, muy rápido],
  [Max Weight], [Bienestar global], [Sí], [Sí],
  [Fuerza bruta], [Configurable], [Aprox.], [Lento],
)

#pause

#align(center)[_Vamos al código..._]

// =============================================================================
// SECCIÓN 4: Resultados (respaldo si no se puede correr en vivo)
// =============================================================================

= Resultados

== Datos sintéticos

- 100 usuarios, 6 dimensiones (belleza, poder adq., extroversión, intelectualidad, aventura, romanticismo)
- Características con norma variable — algunos tienen "más de todo"
- Preferencias normalizadas (dirección pura) con componente de atractivo universal
- Probabilidades estimadas con Logistic Regression y Gradient Boosted Trees

== Comparación de algoritmos

// Estos gráficos se generan desde el notebook
// #image("img/matching_comparison_table.svg")
// #image("img/matching_graph.svg")

_Slides de respaldo — se llenan con output del notebook_

== Predicciones vs. Realidad

¿Qué pasa si optimizamos con predicciones imperfectas?

#pause

- Todos los algoritmos pierden valor real al usar predicciones
- Pero la pérdida *no es uniforme*:
  - *Greedy*: ~15% de pérdida (el más robusto)
  - *Max Weight*: ~26% de pérdida (el más sensible)

#pause

*Paradoja*: el algoritmo óptimo _en teoría_ es el que más sufre con predicciones imperfectas, porque confía más en los pesos exactos.

== Insights principales

+ El matching que maximiza el bienestar global puede dejar afuera al par con mayor probabilidad individual.

+ Los algoritmos más "ambiciosos" son más frágiles ante errores de estimación.

#pause

*Esto es la esencia de la toma de decisiones en data science*: optimizar el sistema completo, no cada componente por separado — pero siendo consciente de la calidad de nuestras estimaciones.

