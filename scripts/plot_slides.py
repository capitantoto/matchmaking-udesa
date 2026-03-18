"""Genera gráficos para las slides de la charla."""

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

IMG_DIR = Path(__file__).parent.parent / "img"
IMG_DIR.mkdir(exist_ok=True)

plt.rcParams.update({
    "figure.figsize": (10, 6),
    "font.size": 32,
    "axes.titlesize": 40,
    "axes.labelsize": 36,
    "lines.linewidth": 2.5,
    "figure.facecolor": "white",
})


def plot_kelly():
    """Kelly criterion — dos paneles: G(K) y trayectorias de capital.

    G(K) = c·ln(1 + (div-1)·K) + (1-c)·ln(1-K)  tasa de crecimiento log. esperada
    dividendo = 5, c_real = 0.25
    K values: 6.25% (óptimo), 12.5% (c_est=30%), 37.5% (c_est=50%)
    """
    dividendo = 5
    c_real = 0.25

    def G(K):
        return c_real * np.log(1 + (dividendo - 1) * K) + (1 - c_real) * np.log(1 - K)

    K_pts    = [0.0625,   0.125,   0.375  ]
    colors   = ["#4CAF50", "#FF9800", "#F44336"]
    g_vals   = [G(k) for k in K_pts]

    fig, ax1 = plt.subplots(figsize=(16, 9))

    # ── G(K) vs K ─────────────────────────────────────────────────────────────
    K_arr = np.linspace(1e-4, 0.52, 600)
    G_arr = np.array([G(k) * 100 for k in K_arr])   # % por apuesta

    ax1.fill_between(K_arr, G_arr, 0, where=(G_arr < 0),  alpha=0.12, color="red")
    ax1.fill_between(K_arr, G_arr, 0, where=(G_arr >= 0), alpha=0.10, color="green")
    ax1.axhline(0, color="gray", linewidth=0.8, linestyle="--", alpha=0.6)
    ax1.plot(K_arr, G_arr, color="#2196F3", linewidth=2.5)

    ann = [
        (K_pts[0], g_vals[0]*100, "K = 6.25% → G = +0.74%/ap.",  -0.05,  2.3),
        (K_pts[1], g_vals[1]*100, "K = 12.5% → G = +0.12%/ap.",   0.15,  0.5),
        (K_pts[2], g_vals[2]*100, "K = 37.5% → G = −12.3%/ap.",  -0.26,  6.5),
    ]
    for (K_val, G_pct, text, dx, dy), color in zip(ann, colors):
        ax1.plot(K_val, G_pct, "o", color=color, markersize=14, zorder=5)
        ax1.annotate(text, xy=(K_val, G_pct),
                     xytext=(K_val + dx, G_pct + dy),
                     fontsize=24, color=color,
                     arrowprops=dict(arrowstyle="->", color=color, lw=2.0))

    ax1.set_xlabel("Fracción apostada $K$")
    ax1.set_ylabel("$G(K)$  (% por apuesta)")
    ax1.set_title(f"Crecimiento esperado  (c = {c_real:.0%}, div = {dividendo})")
    ax1.set_xlim(0, 0.52)
    ax1.set_ylim(-20, 4)
    ax1.grid(True, alpha=0.3)

    fig.tight_layout()
    fig.savefig(IMG_DIR / "kelly.svg", bbox_inches="tight")
    plt.close(fig)
    print("✓ kelly.svg")


def plot_adtech():
    """Adtech: dos clientes compitiendo por el mismo inventario.

    Cliente A: CPC alto, CTR moderado → alto valor por impresión
    Cliente B: CPC bajo, CTR alto → menor valor por impresión
    Muestra qué pasa cuando uno domina consistentemente.
    """
    np.random.seed(42)
    n_slots = 50

    # Simular CTRs por slot (varían un poco por usuario/contexto)
    ctr_a = np.random.beta(3, 17, n_slots)  # ~15% promedio
    ctr_b = np.random.beta(5, 15, n_slots)  # ~25% promedio

    cpc_a = 2.0  # USD
    cpc_b = 0.8  # USD

    valor_a = ctr_a * cpc_a  # valor esperado por impresión
    valor_b = ctr_b * cpc_b

    # Ordenar por diferencia para visualizar
    order = np.argsort(valor_a - valor_b)
    valor_a = valor_a[order]
    valor_b = valor_b[order]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(24, 10))

    # Panel izquierdo: valor por impresión de cada cliente (grouped bars, ambos positivos)
    width = 0.4
    x = np.arange(n_slots)
    ax1.bar(x - width / 2, valor_a, width=width, alpha=0.8,
            label=f"A  CPC=${cpc_a:.1f}, CTR≈15%", color="#2196F3")
    ax1.bar(x + width / 2, valor_b, width=width, alpha=0.8,
            label=f"B  CPC=${cpc_b:.1f}, CTR≈25%", color="#F44336")
    ax1.set_xlabel("Slot de inventario")
    ax1.set_ylabel("Valor esperado ($)")
    ax1.set_title("Valor por impresión")
    ax1.legend()
    ax1.grid(True, alpha=0.3, axis="y")

    # Panel derecho: asignación óptima greedy
    winner = np.where(valor_a >= valor_b, "A", "B")
    n_a = np.sum(winner == "A")
    n_b = np.sum(winner == "B")

    # Sin restricción de presupuesto, A gana casi todo
    colors = ["#2196F3" if w == "A" else "#F44336" for w in winner]
    ax2.bar(x, np.where(winner == "A", valor_a, valor_b), color=colors, alpha=0.7)
    ax2.set_xlabel("Slot de inventario")
    ax2.set_ylabel("Valor asignado ($)")
    ax2.set_title(f"Asignación greedy: A={n_a} slots, B={n_b} slots")

    ax2.text(
        0.5, 0.85,
        f"A domina {n_a}/{n_slots} slots\nB sub-ejecuta su presupuesto",
        transform=ax2.transAxes,
        fontsize=28,
        ha="center",
        bbox=dict(boxstyle="round,pad=0.4", facecolor="#FFF9C4", alpha=0.9),
    )
    ax2.grid(True, alpha=0.3, axis="y")

    fig.tight_layout()
    fig.savefig(IMG_DIR / "adtech.svg", bbox_inches="tight")
    plt.close(fig)
    print("✓ adtech.svg")


if __name__ == "__main__":
    plot_kelly()
    plot_adtech()
