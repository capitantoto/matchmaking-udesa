#import "@preview/touying:0.6.2": *

#import themes.metropolis: *

#show: metropolis-theme.with(
  footer: [Matchmaking — UdeSA 2026]
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
  author: [Gonzalo Barrera Borla \ B.A. Economics — M.S. Statistics \ _Current Role, Company_],
  title: "Data Science and Decision-Making: Matchmaking",
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
+ *Horse racing*: Which horse do I bet on?
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

== Adtech: what happens in practice?

#image("img/adtech.svg")

When $"ctr"_A times "cpc"_A > "ctr"_B times "cpc"_B$ consistently, A captures nearly all inventory and B under-spends its budget.

// =============================================================================
// SECTION 2b: Horse Racing
// =============================================================================

== Horse racing: Kelly Criterion

How much to bet when we think we know the probability of winning? #link("https://doi.org/10.1002/j.1538-7305.1956.tb03809.x")[(Kelly, 1956)]

$ K = frac("edge", "odds" - 1) quad "where" quad "edge" = c times "odds" - 1 $

#text(size: 16pt)[
- $K$: fraction of capital to bet
- $c$: estimated probability of winning (our model)
- $"odds"$: gross payout per \$1 bet (stake included)
- $"edge" = 0$: fair game → don't bet; $"edge" > 0$: bet proportionally
]

#pause

*Problem*: probabilities are _interdependent_ (some horse always wins) and _estimated_ with error.

== Horse racing: sensitivity to estimation

#image("img/kelly.svg")

Overestimating the edge by more than a factor of 2 causes *negative capital growth* — and it's easy to do in practice. #link("https://gwern.net/doc/statistics/decision/1994-benter.pdf")[(Benter, 1994)]

// =============================================================================
// SECTION 3: Matchmaking
// =============================================================================

= Matchmaking

== The matchmaking problem

- Dating platform: we must decide which profiles to show each user
- We can estimate $P(A arrow.r B)$: probability that A approves of B
- We want to estimate $P(A arrow.l.r B)$: probability of a _mutual match_

#pause

*The dilemma*: everyone wants Brad Pitt / Penélope Cruz...

...but BP/PC won't want everyone back.

== Directional vs. mutual probabilities

$ P(A arrow.r B) &: "how well B meets A's preferences" $

$ P(A arrow.l.r B) &approx P(A arrow.r B) times P(B arrow.r A) quad "(approx.)" $

#pause

But the true mutual probability has a correlation term: people who "offer" what others seek tend to "seek" similar things themselves.

$ P(A arrow.l.r B) != P(A arrow.r B) times P(B arrow.r A) $

== Gale-Shapley: Stable Matching

- Classic algorithm (Nobel 2012, Shapley & Roth)
- Guarantees *stability*: no pair would both prefer to switch to each other

#pause

*Problems in dating*:
- Requires "tentatively accepting" candidates — doesn't apply
- Optimizes stability, not global welfare
- The stable matching can be very unequal

== Greedy Matching

- Sort edges by $P(A arrow.l.r B)$ descending
- Add edge if both nodes are free
- Guarantees $>= 1/2$ of optimal (_1/2-approximation_)

#pause

*Simple and intuitive*, but can "spend" highly-demanded nodes on good-but-not-optimal pairs

== Maximum Weight Matching

- Weighted complete graph: edge weight = $P(A arrow.l.r B)$
- Find the matching that maximizes total weight

#pause

*Advantage*: maximizes global welfare

*Counterintuitive insight*: the globally optimal matching may NOT include the pair with the highest individual probability

== Brute force with `scipy.minimize`

- Generic formulation: relaxed combinatorial optimization
- Flexible — the objective function can be changed easily
- Iteration limit ($approx 1000$) to keep it practical

#pause

*Trade-off*: approaches the optimum but doesn't guarantee it, and is slower

== Comparing approaches

#table(
  columns: (auto, auto, auto, auto),
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

- *200 users*, 6 dimensions (beauty, wealth, extraversion, intellect, adventure, romance)
- Features with variable norm — some users have "more of everything" ($r_"norm" = 0.92$ with received attractiveness)
- Normalized preferences (pure direction) with a universal attractiveness component
- AUC $approx 0.74$ with Logistic Regression and Gradient Boosted Trees

== Main comparison (200 users)

#image("img/matching_bar_chart.svg")

== Full comparison (20 users)

#image("img/matching_results_small_table.svg")

Max Weight and Scipy bipartite agree (both optimal for bipartite graphs).
Brute force converges to the same optimum in $<0.2$s on 20 users.

== Matchings in the graph

#image("img/matching_comparison.svg")

== Predictions vs. Reality

#image("img/pred_vs_real_comparison.svg")

== Predictions vs. Reality — Loss

With 200 users (bipartite graph, heterosexual):

- *Gale-Shapley*: loses ~7% of real value
- *Greedy*: loses ~9%
- *Max Weight / Scipy*: loses ~16%

#pause

*Paradox*: the globally optimal algorithm is the most fragile to imperfect estimates.

== Key takeaways

+ The matching that maximizes global welfare may exclude the pair with the highest individual probability.

+ More "ambitious" algorithms are more fragile to estimation errors.

#pause

*This is the essence of decision-making in data science*: optimize the whole system, not each component in isolation — but stay aware of the quality of your estimates.
