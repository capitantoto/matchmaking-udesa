"""Fix notebook to enforce strictly bipartite graph (heterosexual population)."""

import json

with open("matchmaking.ipynb") as f:
    nb = json.load(f)

cells = nb["cells"]


def set_src(cell, src):
    lines = src.strip("\n").split("\n")
    cell["source"] = [l + "\n" for l in lines[:-1]] + [lines[-1]]
    if cell["cell_type"] == "code":
        cell["outputs"] = []
        cell["execution_count"] = None


# ── Cell 3: define groups early ───────────────────────────────────────────────
set_src(cells[3], r'''N_USERS = 200
N_DIMS = 6
DIM_NAMES = ["belleza", "poder_adq", "extroversion", "intelectualidad", "aventura", "romanticismo"]

# Grupos: modelo heterosexual → grafo bipartito estricto
# Grupo A: usuarios 0..99  |  Grupo B: usuarios 100..199
group_a = list(range(0, N_USERS // 2))
group_b = list(range(N_USERS // 2, N_USERS))
group_a_set = set(group_a)
group_b_set = set(group_b)


def opposite_group(i):
    """Devuelve el grupo opuesto al usuario i."""
    return group_b if i in group_a_set else group_a


# --- Características (lo que cada usuario "es") ---
raw_feat = np.random.exponential(1, (N_USERS, N_DIMS))
feat_directions = raw_feat / np.linalg.norm(raw_feat, axis=1, keepdims=True)
feat_magnitudes = np.random.lognormal(mean=0.0, sigma=0.5, size=N_USERS)
features = feat_directions * feat_magnitudes[:, np.newaxis]

# --- Preferencias (lo que cada usuario busca) ---
universal_pref = np.array([0.45, 0.35, 0.05, 0.05, 0.05, 0.05])
universal_pref = universal_pref / np.linalg.norm(universal_pref)

personal_pref = np.abs(features + 0.5 * np.random.randn(N_USERS, N_DIMS))
alpha = np.random.beta(2, 3, N_USERS)
mixed = alpha[:, np.newaxis] * universal_pref + (1 - alpha[:, np.newaxis]) * personal_pref
preferences = mixed / np.linalg.norm(mixed, axis=1, keepdims=True)

print(f"Usuarios: {N_USERS}, Dimensiones: {N_DIMS}")
print(f"Grupo A: {len(group_a)} usuarios | Grupo B: {len(group_b)} usuarios")
print(f"Modelo: heterosexual → grafo bipartito (sin aristas intra-grupo)")
print(f"\nDistribución de norma de características:")
print(f"  Media: {np.linalg.norm(features, axis=1).mean():.2f}, "
      f"Std: {np.linalg.norm(features, axis=1).std():.2f}")''')

# ── Cell 4: zero out same-group P_dir/P_mut ───────────────────────────────────
set_src(cells[4], r'''def p_directional(i, j):
    """P(i -> j): probabilidad de que i apruebe a j.

    Solo tiene sentido para pares cruzados (i en grupo A, j en grupo B o viceversa).
    """
    score = np.dot(preferences[i], features[j])
    return expit(2.5 * score - 2.5)


def p_mutual_true(i, j, correlation=0.15):
    """P(i <-> j): probabilidad mutua real (ground truth)."""
    p_ij = p_directional(i, j)
    p_ji = p_directional(j, i)
    product = p_ij * p_ji
    corr_term = correlation * min(p_ij, p_ji)
    return np.clip(product + corr_term, 0, 1)


# Calcular probabilidades solo para pares cruzados (grafo bipartito)
P_dir = np.zeros((N_USERS, N_USERS))
P_mut = np.zeros((N_USERS, N_USERS))

for i in group_a:
    for j in group_b:
        P_dir[i, j] = p_directional(i, j)
        P_dir[j, i] = p_directional(j, i)
        P_mut[i, j] = p_mutual_true(i, j)
        P_mut[j, i] = P_mut[i, j]

# Verificar: las probabilidades intra-grupo deben ser 0
assert P_dir[group_a[0], group_a[1]] == 0, "Error: arista intra-grupo detectada"

# Atractivo universal: correlación norma ↔ aprobaciones recibidas (solo del grupo opuesto)
feat_norms = np.linalg.norm(features, axis=1)
avg_p_received_a = P_dir[group_b, :][:, group_a].mean(axis=0)  # recibe grupo A
avg_p_received_b = P_dir[group_a, :][:, group_b].mean(axis=0)  # recibe grupo B
avg_p_received = np.concatenate([avg_p_received_a, avg_p_received_b])
corr_norm_attractiveness = np.corrcoef(feat_norms, avg_p_received)[0, 1]

print(f"P direccional — media: {P_dir[P_dir > 0].mean():.3f}, std: {P_dir[P_dir > 0].std():.3f}")
print(f"P mutua real  — media: {P_mut[P_mut > 0].mean():.3f}, std: {P_mut[P_mut > 0].std():.3f}")
print(f"\nCorrelación norma ↔ atractivo recibido: {corr_norm_attractiveness:.3f}")''')

# ── Cell 5: observations from opposite group only ─────────────────────────────
set_src(cells[5], r'''# Generar observaciones históricas (accept/reject)
# En dating heterosexual, cada usuario ve candidatos del grupo opuesto
N_SHOWN = 20
observations = []

for i in range(N_USERS):
    candidates = np.random.choice(opposite_group(i), size=N_SHOWN, replace=False)
    for j in candidates:
        p = p_directional(i, j)
        accepted = np.random.rand() < p
        observations.append({
            "user_i": i,
            "user_j": j,
            "accepted": int(accepted),
            "p_true": p,
        })

df_obs = pd.DataFrame(observations)
print(f"Observaciones generadas: {len(df_obs)}")
print(f"Tasa de aceptación: {df_obs['accepted'].mean():.1%}")
print(f"Pares únicos observados (siempre cruzados): {df_obs[['user_i','user_j']].nunique().sum()}")
df_obs.head()''')

# ── Cell 11: estimate only cross-group pairs ─────────────────────────────────
set_src(cells[11], r'''# Estimar P_mutua: producto de direccionales vs. realidad
# Solo estimamos pares cruzados (grafo bipartito)

def estimate_all_directional(model):
    """Estimar P(i -> j) para todos los pares cruzados, vectorizado."""
    pairs = []
    indices = []
    for i in group_a:
        for j in group_b:
            pairs.append(build_pair_features(i, j))
            indices.append((i, j))
        # También j->i
    for j in group_b:
        for i in group_a:
            pairs.append(build_pair_features(j, i))
            indices.append((j, i))

    X_all = np.array(pairs)
    probs = model.predict_proba(X_all)[:, 1]

    P_est = np.zeros((N_USERS, N_USERS))
    for (i, j), p in zip(indices, probs):
        P_est[i, j] = p
    return P_est


P_dir_est = estimate_all_directional(gbt)

# Estimar P_mutua como producto de direccionales (solo pares cruzados)
P_mut_est = np.zeros((N_USERS, N_USERS))
for i in group_a:
    for j in group_b:
        P_mut_est[i, j] = P_dir_est[i, j] * P_dir_est[j, i]
        P_mut_est[j, i] = P_mut_est[i, j]

# Verificar estructura bipartita
assert P_mut_est[group_a[0], group_a[1]] == 0, "Error: probabilidad intra-grupo no nula"

# Comparar con ground truth (solo pares cruzados)
cross_i = [i for i in group_a for j in group_b]
cross_j = [j for i in group_a for j in group_b]
p_mut_real = np.array([P_mut[i, j] for i, j in zip(cross_i, cross_j)])
p_mut_pred = np.array([P_mut_est[i, j] for i, j in zip(cross_i, cross_j)])

fig, ax = plt.subplots(figsize=(8, 8))
ax.scatter(p_mut_real, p_mut_pred, alpha=0.3, s=10)
ax.plot([0, 1], [0, 1], "--", color="red")
ax.set_xlabel("P mutua real")
ax.set_ylabel("P mutua estimada (producto)")
ax.set_title("P mutua real vs. estimada — solo pares cruzados")
ax.grid(True, alpha=0.3)
fig.tight_layout()
plt.show()

corr = np.corrcoef(p_mut_real, p_mut_pred)[0, 1]
print(f"Correlación: {corr:.3f}")
print(f"Sesgo medio (est - real): {(p_mut_pred - p_mut_real).mean():.4f}")''')

# ── Cell 17: remove redundant group definitions ───────────────────────────────
set_src(cells[17], r'''# Grupos ya definidos en la sección 1 (group_a, group_b)
# Construir rankings usando P_dir_est (ya calculada vectorizadamente)
prefs_a = {}
for i in group_a:
    scores = [(j, P_dir_est[i, j]) for j in group_b]
    scores.sort(key=lambda x: -x[1])
    prefs_a[i] = [j for j, _ in scores]

prefs_b = {}
for j in group_b:
    scores = [(i, P_dir_est[j, i]) for i in group_a]
    scores.sort(key=lambda x: -x[1])
    prefs_b[j] = [i for i, _ in scores]

print(f"Grupo A: {len(group_a)} usuarios, Grupo B: {len(group_b)} usuarios")
print(f"Ejemplo ranking de usuario 0: {prefs_a[0][:5]}... (top 5)")''')

# ── Cell 21: G_full strictly bipartite ───────────────────────────────────────
set_src(cells[21], r'''# Max weight matching sobre el grafo BIPARTITO completo
# Solo aristas cruzadas (grupo A ↔ grupo B)
G_full = nx.Graph()
G_full.add_nodes_from(range(N_USERS))
for i in group_a:
    for j in group_b:
        G_full.add_edge(i, j, weight=P_mut_est[i, j])

t0 = time.time()
mwm_matching = nx.max_weight_matching(G_full, maxcardinality=True)
t_mwm = time.time() - t0

mwm_weight = sum(P_mut_est[i, j] for i, j in mwm_matching)
print(f"Max Weight Matching (bipartito): {len(mwm_matching)} pares, peso total = {mwm_weight:.3f}, tiempo = {t_mwm:.4f}s")
# Nota: sobre grafo bipartito, max weight matching = linear_sum_assignment (ambos óptimos)''')

# ── Cell 24: greedy with groups argument ─────────────────────────────────────
set_src(cells[24], r'''# Greedy matching: agregar aristas de mayor a menor peso
def greedy_matching(P_matrix, ga, gb):
    """Matching greedy bipartito: solo considera aristas cruzadas entre ga y gb."""
    edges = [(P_matrix[i, j], i, j) for i in ga for j in gb]
    edges.sort(reverse=True)

    matched = set()
    matching = set()
    for w, i, j in edges:
        if i not in matched and j not in matched:
            matching.add((i, j))
            matched.add(i)
            matched.add(j)
    return matching


t0 = time.time()
greedy_match = greedy_matching(P_mut_est, group_a, group_b)
t_greedy = time.time() - t0

greedy_weight = sum(P_mut_est[i, j] for i, j in greedy_match)
print(f"Greedy Matching (bipartito): {len(greedy_match)} pares, peso total = {greedy_weight:.3f}, tiempo = {t_greedy:.4f}s")''')

# ── Cell 26: brute force — no group changes needed (already uses bf_group_a/b)─

# ── Cell 29: small comparison — fix greedy call ──────────────────────────────
set_src(cells[29], r'''# Comparación completa: todos los algoritmos sobre 20 usuarios
N_SMALL = N_BF * 2  # = 20

# 1. Gale-Shapley
prefs_a_s = {}
for i in bf_group_a:
    scores = [(j, P_dir_est[i, j]) for j in bf_group_b]
    scores.sort(key=lambda x: -x[1])
    prefs_a_s[i] = [j for j, _ in scores]
prefs_b_s = {}
for j in bf_group_b:
    scores = [(i, P_dir_est[j, i]) for i in bf_group_a]
    scores.sort(key=lambda x: -x[1])
    prefs_b_s[j] = [i for i, _ in scores]

t0 = time.time()
gs_s = gale_shapley(prefs_a_s, prefs_b_s)
t_gs_s = time.time() - t0
gs_s_weight = sum(P_mut_est[i, j] for i, j in gs_s.items())

# 2. Greedy (bipartito)
t0 = time.time()
greedy_s = greedy_matching(P_mut_est, bf_group_a, bf_group_b)
t_greedy_s = time.time() - t0
greedy_s_weight = sum(P_mut_est[i, j] for i, j in greedy_s)

# 3. Max Weight (bipartito)
G_small = nx.Graph()
G_small.add_nodes_from(bf_group_a + bf_group_b)
for i in bf_group_a:
    for j in bf_group_b:
        G_small.add_edge(i, j, weight=P_mut_est[i, j])
t0 = time.time()
mwm_s = nx.max_weight_matching(G_small, maxcardinality=True)
t_mwm_s = time.time() - t0
mwm_s_weight = sum(P_mut_est[i, j] for i, j in mwm_s)

# 4. Scipy bipartito
cost_s = np.array([[-P_mut_est[i, j] for j in bf_group_b] for i in bf_group_a])
t0 = time.time()
row_s, col_s = linear_sum_assignment(cost_s)
t_scipy_s = time.time() - t0
scipy_s = {bf_group_a[ii]: bf_group_b[jj] for ii, jj in zip(row_s, col_s)}
scipy_s_weight = sum(P_mut_est[i, j] for i, j in scipy_s.items())

# 5. Fuerza bruta (ya calculada)
ref_weight = scipy_s_weight

results_small = pd.DataFrame({
    "Algoritmo": ["Gale-Shapley", "Greedy", "Max Weight", "Scipy bipartito", "Fuerza bruta"],
    "Pares": [len(gs_s), len(greedy_s), len(mwm_s), len(scipy_s), len(bf_matching)],
    "Peso total": [gs_s_weight, greedy_s_weight, mwm_s_weight, scipy_s_weight, bf_weight],
    "Tiempo (s)": [t_gs_s, t_greedy_s, t_mwm_s, t_scipy_s, t_brute],
})
results_small["% del óptimo (bipartito)"] = (results_small["Peso total"] / ref_weight * 100).round(1)

print(f"Comparación sobre {N_SMALL} usuarios (grafo bipartito estricto):")
print(f"Nota: Max Weight y Scipy deben coincidir (ambos óptimos para bipartito)")
results_small''')

# ── Cells 35 (pred vs real): fix greedy and G_full_real ──────────────────────
set_src(cells[35], r'''# --- Correr los mismos algoritmos sobre P_mut (ground truth) ---

# 1. Gale-Shapley sobre ground truth
prefs_a_real = {}
for i in group_a:
    scores = [(j, P_dir[i, j]) for j in group_b]
    scores.sort(key=lambda x: -x[1])
    prefs_a_real[i] = [j for j, _ in scores]
prefs_b_real = {}
for j in group_b:
    scores = [(i, P_dir[j, i]) for i in group_a]
    scores.sort(key=lambda x: -x[1])
    prefs_b_real[j] = [i for i, _ in scores]
gs_matching_real = gale_shapley(prefs_a_real, prefs_b_real)

# 2. Greedy sobre ground truth (bipartito)
greedy_match_real = greedy_matching(P_mut, group_a, group_b)

# 3. Max weight matching sobre ground truth (bipartito)
G_full_real = nx.Graph()
G_full_real.add_nodes_from(range(N_USERS))
for i in group_a:
    for j in group_b:
        G_full_real.add_edge(i, j, weight=P_mut[i, j])
mwm_matching_real = nx.max_weight_matching(G_full_real, maxcardinality=True)

# 4. Scipy bipartito sobre ground truth
cost_matrix_real = np.array([[-P_mut[i, j] for j in group_b] for i in group_a])
row_ind_r, col_ind_r = linear_sum_assignment(cost_matrix_real)
scipy_matching_real = {group_a[ii]: group_b[jj] for ii, jj in zip(row_ind_r, col_ind_r)}

# --- Evaluar cada matching con ambas métricas ---
def eval_matching(matching, P_est, P_real):
    if isinstance(matching, dict):
        pairs = list(matching.items())
    else:
        pairs = list(matching)
    w_est = sum(P_est[i, j] for i, j in pairs)
    w_real = sum(P_real[i, j] for i, j in pairs)
    return w_est, w_real

algo_names = ["Gale-Shapley", "Greedy", "Max Weight", "Scipy bipartito"]
matchings_pred = [gs_matching, greedy_match, mwm_matching, scipy_matching]
matchings_real = [gs_matching_real, greedy_match_real, mwm_matching_real, scipy_matching_real]

rows = []
for name, m_pred, m_real in zip(algo_names, matchings_pred, matchings_real):
    w_est_pred, w_real_pred = eval_matching(m_pred, P_mut_est, P_mut)
    w_est_real, w_real_real = eval_matching(m_real, P_mut_est, P_mut)
    rows.append({
        "Algoritmo": name, "Optimizado sobre": "Predicciones",
        "Peso (pred)": round(w_est_pred, 3), "Peso (real)": round(w_real_pred, 3),
        "Brecha %": round((w_est_pred - w_real_pred) / w_real_pred * 100, 1),
    })
    rows.append({
        "Algoritmo": name, "Optimizado sobre": "Ground truth",
        "Peso (pred)": round(w_est_real, 3), "Peso (real)": round(w_real_real, 3),
        "Brecha %": round((w_est_real - w_real_real) / w_real_real * 100, 1),
    })

df_comparison = pd.DataFrame(rows)
print("Predicciones vs. Ground Truth por algoritmo (grafo bipartito):\n")
print(df_comparison.to_string(index=False))''')

with open("matchmaking.ipynb", "w") as f:
    json.dump(nb, f, indent=1, ensure_ascii=False)

print("Done")
