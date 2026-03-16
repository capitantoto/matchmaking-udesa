"""Genera gráficos para las slides de la charla."""

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

IMG_DIR = Path(__file__).parent.parent / "img"
IMG_DIR.mkdir(exist_ok=True)

plt.rcParams.update({
    "figure.figsize": (10, 6),
    "font.size": 16,
    "axes.titlesize": 20,
    "axes.labelsize": 18,
    "lines.linewidth": 2.5,
    "figure.facecolor": "white",
})


def plot_kelly():
    """Kelly criterion: fracción óptima vs. probabilidad estimada.

    f* = (b*p - q) / b  donde q = 1-p, b = odds (pago neto por unidad apostada).
    Ejemplo: caballo con odds 4:1 (b=4), prob real ~20%.
    """
    b = 4  # odds 4:1
    p = np.linspace(0.01, 0.99, 500)
    q = 1 - p
    f_star = (b * p - q) / b
    f_star = np.clip(f_star, 0, None)  # no apostar fracción negativa

    fig, ax = plt.subplots()
    ax.plot(p, f_star, color="#2196F3", label=r"$f^* = \frac{bp - q}{b}$, $b=4$")
    ax.set_xlabel("Probabilidad estimada $\\hat{p}$")
    ax.set_ylabel("Fracción óptima de apuesta $f^*$")
    ax.set_title("Kelly Criterion — Sensibilidad a la estimación")

    # Marcar p_real = 0.20
    p_real = 0.20
    f_real = max((b * p_real - (1 - p_real)) / b, 0)
    ax.plot(p_real, f_real, "o", color="#4CAF50", markersize=12, zorder=5)
    ax.annotate(
        f"Real: p={p_real:.0%}, f*={f_real:.0%}",
        xy=(p_real, f_real),
        xytext=(p_real + 0.08, f_real + 0.12),
        fontsize=14,
        arrowprops=dict(arrowstyle="->", color="#4CAF50"),
        color="#4CAF50",
    )

    # Marcar p_sobreestimada = 0.30
    p_over = 0.30
    f_over = max((b * p_over - (1 - p_over)) / b, 0)
    ax.plot(p_over, f_over, "o", color="#F44336", markersize=12, zorder=5)
    ax.annotate(
        f"Sobreestimada: p={p_over:.0%}, f*={f_over:.0%}",
        xy=(p_over, f_over),
        xytext=(p_over + 0.06, f_over + 0.10),
        fontsize=14,
        arrowprops=dict(arrowstyle="->", color="#F44336"),
        color="#F44336",
    )

    # Flecha entre ambos puntos
    ax.annotate(
        "",
        xy=(p_over, f_over),
        xytext=(p_real, f_real),
        arrowprops=dict(arrowstyle="<->", color="#FF9800", lw=2),
    )
    ax.text(
        (p_real + p_over) / 2,
        (f_real + f_over) / 2 - 0.03,
        f"Δf* = {f_over - f_real:.0%}",
        fontsize=13,
        ha="center",
        color="#FF9800",
        fontweight="bold",
    )

    ax.axhline(0, color="gray", linewidth=0.5)
    ax.set_xlim(0, 0.7)
    ax.set_ylim(-0.02, 0.65)
    ax.legend(fontsize=14)
    ax.grid(True, alpha=0.3)
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

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    # Panel izquierdo: valor por impresión de cada cliente
    x = np.arange(n_slots)
    ax1.bar(x, valor_a, alpha=0.7, label=f"Cliente A (CPC=${cpc_a:.1f})", color="#2196F3")
    ax1.bar(x, -valor_b, alpha=0.7, label=f"Cliente B (CPC=${cpc_b:.1f})", color="#F44336")
    ax1.axhline(0, color="gray", linewidth=0.5)
    ax1.set_xlabel("Slot de inventario (ordenado)")
    ax1.set_ylabel("Valor esperado por impresión ($)")
    ax1.set_title("CTR × CPC por slot")
    ax1.legend(fontsize=12)
    ax1.grid(True, alpha=0.3, axis="y")

    # Panel derecho: asignación óptima greedy
    winner = np.where(valor_a >= valor_b, "A", "B")
    n_a = np.sum(winner == "A")
    n_b = np.sum(winner == "B")

    budget_a = 15.0  # presupuesto diario
    budget_b = 10.0

    # Sin restricción de presupuesto, A gana casi todo
    colors = ["#2196F3" if w == "A" else "#F44336" for w in winner]
    ax2.bar(x, np.where(winner == "A", valor_a, valor_b), color=colors, alpha=0.7)
    ax2.set_xlabel("Slot de inventario")
    ax2.set_ylabel("Valor del slot asignado ($)")
    ax2.set_title(f"Asignación greedy: A={n_a} slots, B={n_b} slots")

    ax2.text(
        0.5, 0.85,
        f"A domina {n_a}/{n_slots} slots\nB sub-ejecuta su presupuesto",
        transform=ax2.transAxes,
        fontsize=13,
        ha="center",
        bbox=dict(boxstyle="round,pad=0.3", facecolor="#FFF9C4", alpha=0.9),
    )
    ax2.grid(True, alpha=0.3, axis="y")

    fig.tight_layout()
    fig.savefig(IMG_DIR / "adtech.svg", bbox_inches="tight")
    plt.close(fig)
    print("✓ adtech.svg")


if __name__ == "__main__":
    plot_kelly()
    plot_adtech()
