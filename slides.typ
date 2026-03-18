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
  title: "Si nos organizamos, nos enamoramos todos",
  subtitle: [Data Science y toma de decisiones --- en aplicaciones de citas],
  author: [Gonzalo Barrera Borla],
  extra: [18 de marzo de 2026 — 19:30 \
    MCD10 — Sem. de aplicaciones de ciencia de datos al ámbito privado \
    Docente: Pablo Mislej — Universidad de San Andrés],
)

// =============================================================================
// SECCIÓN 1b: Orador
// =============================================================================

== ¿Quién soy?

#v(1fr)

#text(size: 28pt)[
  #set par(leading: 1.2em)
  *Gonzalo Barrera Borla* \
  Lic. en Economía — FCE, UBA \
  (casi) Mg. en Estadística — FCEyN, UBA \
  Data Scientist en *Sitch*
]

#v(2fr)

#grid(
  columns: (1fr, 1fr),
  gutter: 3em,
  align: center + horizon,
  image("img/UBA-logo.svg", height: 6em),
  image("img/sitch-logo.webp", height: 6em),
)

#v(1fr)

== Sitch

#grid(
  columns: (3fr, 1fr),
  gutter: 2em,
  align: horizon,
  [
    - App de dating con matchmaking por *IA*
    - Sin swipe: la IA aprende tus preferencias y propone candidatos con *contexto*
    - Perfiles revisados por personas reales
    - Cuando hay match mutuo, la IA presenta a los dos — y se retira

    #v(0.5em)
    #link("https://download.joinsitch.com/")[download.joinsitch.com]
  ],
  image("img/sitch-logo.webp", height: 5em),
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

#text(size: 16pt)[
- $x_(i,t) in {0,1}$: ¿se muestra el aviso del cliente $i$ en la impresión $t$?
- $B_i$: presupuesto diario del cliente $i$
- $"clicks"_i = sum_t x_(i,t) times "ctr"_(i,t)$: clics esperados (en valor esperado)
]

== Adtech: ¿qué pasa en la práctica?

#image("img/adtech.svg")

Cuando $"ctr"_A times "cpc"_A > "ctr"_B times "cpc"_B$ consistentemente, A se lleva casi todo el inventario y B sub-ejecuta su presupuesto.

El problema general de bidding óptimo bajo restricciones de presupuesto tiene solución via dualidad de Lagrange @pita2019.

// =============================================================================
// SECCIÓN 2b: Horse Racing
// =============================================================================

== Carreras de caballos: Kelly Criterion

La fracción óptima maximiza el *crecimiento logarítmico esperado* del capital @kelly1956:

$ K = frac("ventaja", "dividendo" - 1) quad "donde" quad "ventaja" = c times "dividendo" - 1 $

#text(size: 16pt)[
- $K$: fracción del capital a apostar ($K < 0$ → no apostar)
- $c$: probabilidad estimada de ganar (nuestro modelo)
- $"dividendo"$: pago bruto por \$1 apostado (incluye la apuesta)
- $"ventaja" < 0$: juego desfavorable; $= 0$: juego justo; $> 0$: apostar $K$
]

#pause

*Advertencia* @benter1994: sobreestimar $c$ desplaza $K$ hacia arriba — apostar demasiado puede causar *crecimiento negativo* del capital.

== Carreras: consecuencias a largo plazo

Kelly maximiza la *tasa de crecimiento logarítmico esperada* por apuesta:

$ G(K) = c dot ln(1 + ("dividendo" - 1) dot K) + (1 - c) dot ln(1 - K) $

#grid(
  columns: (2fr, 1fr),
  gutter: 1.5em,
  align: horizon,
  image("img/kelly.svg"),
  [
    #table(
      columns: (auto, auto, auto, auto),
      inset: 7pt,
      align: center,
      table.header(
        [*$K$*], [*$c$ est.*], [*$G$/ap.*], [*×200 ap.*],
      ),
      [6.25%], [25%], [+0.74%], [×4.4],
      [12.5%], [30%], [+0.12%], [×1.3],
      [37.5%], [50%], [−12.3%], [ruina],
    )
    #text(size: 13pt)[c real = 25%, dividendo = 5]
  ],
)

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

La probabilidad mutua real tiene un término de correlación: la gente que "ofrece" lo que otros buscan, tiende a "buscar" cosas similares.

$ P(A arrow.l.r B) != P(A arrow.r B) times P(B arrow.r A) $

#pause

Pero estimar $P(A arrow.l.r B)$ es más difícil que sólo $P(A arrow.r B)$, así que podemos asumir
$ P(A arrow.l.r B) &approx P(A arrow.r B) times P(B arrow.r A) quad $

#pause

Y estimar probabilidades condicionales con un único estimador:

$ P(A arrow.l.r B |  A arrow.r B ) = P(B arrow.r A) $

#pagebreak()

Cuando hay que tomar _decisiones_ con el modelo, esta interpretabilidad es muy útil...  #pause *¡aunque sea incorrecta!*.

#v(0.5em)
#align(right)[
  #text(size: 16pt, style: "italic")[
    "All models are wrong, but some are useful." — Box #cite(<box1976>)
  ]
]

== Gale-Shapley: Stable Matching

Algoritmo clásico @gale1962; #link("https://www.nobelprize.org/prizes/economic-sciences/2012/popular-information/")[Nobel de Economía 2012] (Shapley & Roth)

#text(size: 16pt)[
+ Cada A propone a su candidata favorita libre
+ Cada B acepta _provisoriamente_ al mejor proponente; rechaza al resto
+ Los rechazados proponen a su siguiente candidata
+ Repetir hasta que nadie quede sin pareja
]

Garantiza *estabilidad*: ningún par rechazado se preferiría mutuamente al par asignado.

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

- *500 usuarios*, 6 dimensiones (belleza, poder adq., extroversión, intelectualidad, aventura, romanticismo)
- Características con norma variable — algunos tienen "más de todo" ($r_"norma" = 0.92$ con atractivo recibido)
- Preferencias normalizadas (dirección pura) con componente de atractivo universal
- AUC $approx 0.74$ con Logistic Regression y Gradient Boosted Trees

== Comparación principal (500 usuarios)

#table(
  columns: (2fr, 1fr, 1fr, 1fr, 1fr),
  inset: 7pt,
  align: (left, center, center, center, center),
  table.header(
    [*Algoritmo*], [*Pares*], [*Peso*], [*Tiempo*], [*% óptimo*],
  ),
  [Gale-Shapley],    [250], [70.8], [4ms],   [92.2%],
  [Greedy],          [250], [72.9], [26ms],  [94.9%],
  [Max Weight],      [250], [76.8], [12.3s], [100%],
  [Scipy bipartito], [250], [76.8], [3ms],   [100%],
)

== Comparación completa (30 usuarios)

Max Weight, Scipy y Fuerza bruta coinciden (todos óptimos); GS pierde ~6%.

#table(
  columns: (2fr, 1fr, 1fr, 1fr, 1fr),
  inset: 7pt,
  align: (left, center, center, center, center),
  table.header(
    [*Algoritmo*], [*Pares*], [*Peso*], [*Tiempo*], [*% óptimo*],
  ),
  [Gale-Shapley],    [15], [2.600], [< 0.1ms], [94.1%],
  [Greedy],          [15], [2.752], [< 0.1ms], [99.6%],
  [Max Weight],      [15], [2.763], [3ms],      [100%],
  [Scipy bipartito], [15], [2.763], [< 0.1ms], [100%],
  [Fuerza bruta],    [15], [2.763], [2.1s],     [100%],
)

== Matchings en el grafo — Gale-Shapley

#align(center)[#image("img/matching_gs.svg", height: 80%)]

== Matchings en el grafo — Greedy

#align(center)[#image("img/matching_greedy.svg", height: 80%)]

== Matchings en el grafo — Max Weight

#align(center)[#image("img/matching_mwm.svg", height: 80%)]

== Predicciones vs. Realidad

#image("img/pred_vs_real_comparison.svg")

== Predicciones vs. Realidad — Pérdida

Con 500 usuarios (grafo bipartito, heterosexual):

- *Gale-Shapley*: pierde ~7% de valor real
- *Greedy*: pierde ~6%
- *Max Weight / Scipy*: pierde ~11%

#pause

*Paradoja*: el óptimo global es el más frágil ante estimaciones imperfectas.

== Insights principales

+ El matching que maximiza el bienestar global puede dejar afuera al par con mayor probabilidad individual.

+ Los algoritmos más "ambiciosos" son más frágiles ante errores de estimación.

#pause

*Esto es la esencia de la toma de decisiones en data science*: optimizar el sistema completo, no cada componente por separado — pero siendo consciente de la calidad de nuestras estimaciones.

// =============================================================================
// Referencias
// =============================================================================

#focus-slide[
  #show link: set text(white)

  #text(size: 42pt)[*¡Muchas gracias!*]

  #v(2em)

  #grid(
    columns: (1.8em, auto),
    gutter: (1.2em, 0.9em),
    align: horizon,
    image("img/x-logo.svg",        height: 1.4em),
    text(size: 22pt)[#link("https://twitter.com/capitantoto")[\@capitantoto]],
    image("img/github-logo.svg",   height: 1.4em),
    text(size: 22pt)[#link("https://github.com/capitantoto")[github.com/capitantoto]],
    image("img/linkedin-logo.svg", height: 1.4em),
    text(size: 22pt)[#link("https://ar.linkedin.com/in/gonzalo-barrera-borla-4a6b3711")[gonzalo-barrera-borla]],
  )
]

// =============================================================================

= Referencias

== Bibliografía

#text(size: 13pt)[
  #set par(leading: 0.8em)
  #bibliography("bib/references.bib", style: "apa", title: none)
]
