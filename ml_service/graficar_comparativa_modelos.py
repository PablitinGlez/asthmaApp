import os
import matplotlib.pyplot as plt

# =============================================================================
# CONFIGURACION
# =============================================================================

GRAPHS_DIR = "ml_service/graphs"
os.makedirs(GRAPHS_DIR, exist_ok=True)

METRICAS = ["Accuracy", "Recall", "Precision", "F1-Score", "AUC"]

# Metricas oficiales de cada modelo (set de prueba real, particion 80-20, umbral 40%)
MODELOS = {
    "Random Forest":       [0.9760, 0.9354, 0.9490, 0.9422, 0.9924],
    "XGBoost":             [0.9745, 0.9378, 0.9400, 0.9389, 0.9923],
    "Gradient Boosting":   [0.9710, 0.9378, 0.9245, 0.9311, 0.9922],
    "SVM":                 [0.9665, 0.9258, 0.9149, 0.9203, 0.9869],
    "Decision Tree":       [0.9610, 0.9091, 0.9048, 0.9069, 0.9587],
    "KNN":                 [0.9465, 0.9450, 0.8246, 0.8807, 0.9799],
    "Regresion Logistica": [0.9460, 0.9426, 0.8243, 0.8795, 0.9850],
}

# Colores distintos y faciles de diferenciar para 7 lineas
COLORES = [
    "#E6194B",  # rojo
    "#3CB44B",  # verde
    "#4363D8",  # azul
    "#F58231",  # naranja
    "#911EB4",  # morado
    "#42D4F4",  # cian
    "#F032E6",  # magenta
]

# =============================================================================
# GRAFICA: LINEAS COMPARATIVAS (una linea por modelo, eje X = metricas)
# =============================================================================

x = list(range(len(METRICAS)))

plt.figure(figsize=(11, 7))

for i, (nombre, valores) in enumerate(MODELOS.items()):
    plt.plot(
        x, valores,
        marker="o", markersize=7, linewidth=2.2,
        label=nombre, color=COLORES[i % len(COLORES)],
    )
    # Etiqueta con el valor en el ultimo punto de cada linea (AUC)
    plt.annotate(
        f"{valores[-1]:.3f}",
        (x[-1], valores[-1]),
        textcoords="offset points", xytext=(8, 0),
        fontsize=8, va="center", color=COLORES[i % len(COLORES)],
    )

plt.xticks(x, METRICAS, fontsize=11)
plt.ylabel("Valor de la metrica", fontsize=11)
plt.ylim(0.80, 1.02)
plt.title("Comparacion de Modelos - Metricas Oficiales (Set de Prueba Real)", fontsize=13, fontweight="bold")
plt.legend(title="Modelo", loc="lower left", ncol=2, fontsize=9)
plt.grid(axis="y", alpha=0.3)
plt.tight_layout()

GRAPH_PATH = os.path.join(GRAPHS_DIR, "comparativa_7_modelos_lineas.png")
plt.savefig(GRAPH_PATH, dpi=150)
plt.close()

print(f"Grafica guardada en -> {GRAPH_PATH}")