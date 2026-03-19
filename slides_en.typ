#import "@preview/touying:0.6.2": *

#import themes.metropolis: *

#let handout-mode = sys.inputs.at("handout", default: "false") == "true"
#show: metropolis-theme.with(
  config-common(handout: handout-mode),
  footer: [Matchmaking — UdeSA 2026],
)
#show link: set text(blue)
#show link: underline
#set text(font: "Fira Sans", weight: "light", size: 20pt, lang: "en")
#set strong(delta: 100)
#set par(justify: true)

// =============================================================================
// SECTION 1: Title
// =============================================================================

#title-slide(
  title: "Si nos organizamos, nos enamoramos todos",
  subtitle: [Data Science and decision-making --- in dating applications],
  author: [Gonzalo Barrera Borla],
  extra: [March 18, 2026 — 19:30 \
    MCD10 — Applications of data science in the private sector \
    Instructor: Pablo Mislej — Universidad de San Andrés],
)

// =============================================================================
// SECTION 1b: Speaker
// =============================================================================

== Who am I?

#v(1fr)

#text(size: 28pt)[
  #set par(leading: 1.2em)
  *Gonzalo Barrera Borla* \
  B.A. Economics — FCE, UBA \
  (almost) M.S. Statistics — FCEyN, UBA \
  Data Scientist at *Sitch*
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
    - Dating app with *AI-powered* matchmaking
    - No swiping: the AI learns your preferences and suggests candidates with *context*
    - Profiles reviewed by real people
    - When there's a mutual match, the AI introduces both — and steps aside

    #v(0.5em)
    #link("https://download.joinsitch.com/")[download.joinsitch.com]
  ],
  image("img/sitch-logo.webp", height: 5em),
)

// =============================================================================
// SECTION 2: DS in the wild
// =============================================================================

= Data Science "in the wild"

== Prediction is not enough

- In school we learn to *estimate* and *predict*
- In practice, we need to *make decisions* with those predictions
- The objective function is often complex — it's not just "maximize expected value"

#pause

Three domains where this is clear:

+ *Adtech*: Which ad do I show?
+ *Horse racing*: How much do I bet?
+ *Matchmaking*: Which pairs do I present?

// =============================================================================
// SECTION 2a: Adtech
// =============================================================================

== Adtech: the problem

Simplified: 2 clients competing for the same audience

- *Client A*: high CPC (\$2.0), moderate CTR (~15%)
- *Client B*: low CPC (\$0.8), high CTR (~25%)
- Both have limited daily budgets

*Objective*: maximize total revenue

$ max sum_i "cpc"_i times "clicks"_i quad "s.t." quad sum_t "cpc"_i times x_(i,t) <= B_i $

#text(size: 16pt)[
- $x_(i,t) in {0,1}$: show client $i$'s ad on impression $t$?
- $B_i$: daily budget for client $i$
- $"clicks"_i = sum_t x_(i,t) times "ctr"_(i,t)$: expected clicks
]

== Adtech: what happens in practice?

#image("img/adtech.svg")

#pagebreak()

When $"ctr"_A times "cpc"_A > "ctr"_B times "cpc"_B$ consistently, A captures nearly all inventory and B under-spends its budget.

#pause

The general optimal bidding problem under budget constraints can be solved via Lagrange duality @pita2019.

// =============================================================================
// SECTION 2b: Horse Racing
// =============================================================================

== Horse racing: Kelly Criterion

The optimal fraction maximizes the *expected logarithmic growth* of capital @kelly1956:

$ K = frac("edge", "odds" - 1) quad "where" quad "edge" = c times "odds" - 1 $

#text(size: 16pt)[
- $K$: fraction of capital to bet ($K < 0$ → don't bet)
- $c$: estimated probability of winning (our model)
- $"odds"$: gross payout per \$1 bet (stake included)
- $"edge" < 0$: unfavorable game; $= 0$: fair game; $> 0$: bet $K$
]

#pause

*Warning* @benter1994: overestimating $c$ pushes $K$ upward — betting too much can cause *negative capital growth*.

== Horse racing: long-run consequences

Kelly maximizes the *expected log growth rate* per bet:

$ G(K) = c dot ln(1 + ("odds" - 1) dot K) + (1 - c) dot ln(1 - K) $

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
        [*$K$*], [*$c$ est.*], [*$G$/bet*], [*×200 bets*],
      ),
      [6.25%], [25%], [+0.74%], [×4.4],
      [12.5%], [30%], [+0.12%], [×1.3],
      [37.5%], [50%], [−12.3%], [ruin],
    )
    #text(size: 13pt)[c real = 25%, odds = 5]
  ],
)

// =============================================================================
// SECTION 3: Matchmaking
// =============================================================================

= Matchmaking

== The matchmaking problem

We must decide which profiles to show each user _every day_.

It is an *iterated* problem:
  - today's state depends on yesterday's state.
  - it's not _that_ important to solve it "one-shot"
#pause

Multiple divergent objectives:
- Maximize user engagement (#math.arrow.double show aspirational candidates)
- Maximize matches formed (#math.arrow.double show realistic candidates)

#pause

- Maximize growth (#math.arrow.double don't charge / "freemium" model)
- Maximize gross/net revenue (#math.arrow.double paywall)

#pagebreak()

- *We want* to estimate $P(A arrow.l.r B)$: probability of _mutual match_
#pause
- *We can* estimate $P(A arrow.r B)$: probability that A approves of B

#pause

*Dilemma*: probabilities are *asymmetric*.


Everyone wants Brad Pitt / Penélope Cruz ... #pause but they don't want everyone back.

== Directional vs. mutual probabilities

The true mutual probability has a correlation term: people who "offer" what others seek tend to "seek" similar things themselves.

$ P(A arrow.l.r B) != P(A arrow.r B) times P(B arrow.r A) $

#pause

But estimating $P(A arrow.l.r B)$ is harder than just $P(A arrow.r B)$, so we can assume
$ P(A arrow.l.r B) &approx P(A arrow.r B) times P(B arrow.r A) quad $

#pause

And estimate conditional probabilities with a single estimator:

$ P(A arrow.l.r B |  A arrow.r B ) = P(B arrow.r A) $

#pagebreak()

When making _decisions_ with the model, this interpretability is very useful...  #pause *even if it's wrong!*.

#v(0.5em)
#align(right)[
  #text(size: 16pt, style: "italic")[
    "All models are wrong, but some are useful." — Box #cite(<box1976>)
  ]
]

== Gale-Shapley: Stable Matching

Classic algorithm @gale1962; #link("https://www.nobelprize.org/prizes/economic-sciences/2012/popular-information/")[Nobel Prize in Economics 2012] (Shapley & Roth)

#text(size: 16pt)[
+ Each A proposes to their top available candidate
+ Each B tentatively accepts the best proposer; rejects the rest
+ Rejected As propose to their next candidate
+ Repeat until everyone is paired
]

Guarantees *stability*: no rejected pair would both prefer to switch to each other.

#pause

*Problems in dating*:
- Requires "tentatively accepting" candidates — doesn't apply
- Optimizes stability, not global welfare
- The stable matching can be very unequal \
  #text(size: 16pt, style: "italic")[The _proposing_ side gets their best stable partner; the _receiving_ side gets their worst.]

== Greedy Matching

+ Sort edges by $P(A arrow.l.r B)$ descending
+ Add edge if both nodes are free
+ Guarantees in theory $>= 1/2$ of optimal (_1/2-approximation_) #footnote[#pause but in practice it's usually much better.]

#pause

*Simple and intuitive*, but can "spend" highly-demanded nodes on good-but-not-optimal pairs

== Maximum Weight Matching

- Weighted complete graph: edge weight = $P(A arrow.l.r B)$
- Find the matching that maximizes total weight

#pause

*Advantage*: maximizes global welfare

*Counterintuitive insight*: the globally optimal matching may NOT include the pair with the highest individual probability

#pause

#text(size: 16pt)[For bipartite graphs: *Hungarian algorithm* @kuhn1955 — O($n^3$), exact. \
For general graphs: Edmonds' blossom algorithm (slower, not needed here).]

== Brute force with `scipy.minimize`

- Generic formulation: relaxed combinatorial optimization
- Flexible — the objective function can be changed easily
- Few iterations needed (50–100 usually suffice), but *each iteration is expensive*

#pause

*Trade-off*: approaches the optimum but doesn't guarantee it, and is slower

#pause

#text(size: 16pt)[
  Why not simply enumerate all possible matchings? For $n = 500$ users per group:
  #table(
    columns: (auto, auto, auto),
    inset: 6pt,
    align: (left, center, left),
    table.header([*Method*], [*Operations*], [*Feasible?*]),
    [Hungarian],   [$500^3 approx 1.25 times 10^8$], [Yes — seconds],
    [Exhaustive],  [$500! approx 10^{1134}$],         [No — the universe has $approx 10^{80}$ atoms],
  )
]

== Comparing approaches

#table(
  columns: (1fr, 1fr, 1fr, 1fr),
  inset: 8pt,
  align: (left, center, center, center),
  table.header(
    [*Algorithm*], [*Optimizes*], [*Optimal?*], [*Practical?*],
  ),
  [Gale-Shapley], [Stability], [Yes (stab.)], [Hard in dating],
  [Greedy], [Local welfare], [$>= 1/2$ opt.], [Yes, very fast],
  [Max Weight], [Global welfare], [Yes], [Yes],
  [Brute force], [Configurable], [Approx.], [Slow],
)

#pause

#align(center)[_Let's look at the code..._]

// =============================================================================
// SECTION 4: Results (backup if live demo is not possible)
// =============================================================================

= Results

== Synthetic data

- *1000 users*, 6 dimensions (beauty, wealth, extraversion, intellect, adventure, romance)
- Features with variable norm — some users have "more of everything" ($r_"norm" = 0.92$ with received attractiveness)
- Normalized preferences (pure direction) with a universal attractiveness component
- AUC $approx 0.74$ with Logistic Regression and Gradient Boosted Trees

== Main comparison (1000 users)

#table(
  columns: (2fr, 1fr, 1fr, 1fr, 1fr),
  inset: 7pt,
  align: (left, center, center, center, center),
  table.header(
    [*Algorithm*], [*Pairs*], [*Weight*], [*Time*], [*% optimal*],
  ),
  [Gale-Shapley],    [500], [137.8], [20ms],  [91.2%],
  [Greedy],          [500], [142.9], [148ms], [94.6%],
  [Max Weight],      [500], [151.1], [107s],  [100%],
  [Scipy bipartite], [500], [151.1], [13ms],  [100%],
)

== Full comparison (40 users)

Max Weight, Scipy and Brute force agree (all optimal); GS loses ~5%.

#table(
  columns: (2fr, 1fr, 1fr, 1fr, 1fr),
  inset: 7pt,
  align: (left, center, center, center, center),
  table.header(
    [*Algorithm*], [*Pairs*], [*Weight*], [*Time*], [*% optimal*],
  ),
  [Gale-Shapley],    [20], [4.432], [< 0.1ms], [94.6%],
  [Greedy],          [20], [4.485], [< 0.1ms], [95.7%],
  [Max Weight],      [20], [4.687], [6ms],      [100%],
  [Scipy bipartite], [20], [4.687], [< 0.1ms], [100%],
  [Brute force],     [20], [4.687], [7.3s],     [100%],
)

== Matchings in the graph — Gale-Shapley

#image("img/matching_gs.svg", width: 100%)

== Matchings in the graph — Greedy

#image("img/matching_greedy.svg", width: 100%)

== Matchings in the graph — Max Weight

#image("img/matching_mwm.svg", width: 100%)

== Predictions vs. Reality

#image("img/pred_vs_real_comparison.svg", width: 100%)

#text(size: 16pt)[Real optimum = what we'd get with the true probabilities in hand (Scipy on $P_"mut"$).]

#pause

#table(
  columns: (2fr, 1fr, 1fr, 1fr),
  inset: 7pt,
  align: (left, center, center, center),
  table.header([*Algorithm*], [*Est. weight*], [*Real weight*], [*% optimal*]),
  [Gale-Shapley],    [137.8], [150.6], [89.4%],
  [Greedy],          [142.9], [*153.2*], [*91.0%*],
  [Max Weight],      [*151.1*], [148.8], [88.4%],
  [Scipy bipartite], [*151.1*], [148.8], [88.4%],
)

#pause

*Paradox*: Max Weight maximizes _estimated_ weight but achieves the lowest _real_ weight. \ Greedy, more conservative, outperforms all in effective terms.

== Key takeaways

+ The matching that maximizes global welfare may exclude the pair with the highest individual probability.

+ More "ambitious" algorithms are more fragile to estimation errors.

#pause

*This is the essence of decision-making in data science*: optimize the whole system, not each component in isolation — but stay aware of the quality of your estimates.

// =============================================================================
// References
// =============================================================================

#focus-slide[
  #show link: set text(white)

  #text(size: 42pt)[*Thank you!*]

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

= References

== Bibliography

#text(size: 13pt)[
  #set par(leading: 0.8em)
  #bibliography("bib/references.bib", style: "apa", title: none)
]
