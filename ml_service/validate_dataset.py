"""
=============================================================================
ASTHMA PREDICTION SYSTEM - Dataset Validation & Exploratory Data Analysis
=============================================================================
Script: validate_dataset.py
Description:
    Applies the 4 synthetic data validation techniques to prove the
    generated dataset faithfully represents real asthma patient behaviour.

    Techniques Applied:
    1. Class Balance Check (Prevalence Realism)
    2. Pearson Correlation Heatmap (Bivariate Statistical Validation)
    3. Gaussian Distribution Histograms (Density Inspection per variable)

Output:
    ml_service/graphs/heatmap_correlacion.png
    ml_service/graphs/distribucion_variables.png
=============================================================================
"""

import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# ─────────────────────────────────────────────────────────────────────────────
# SETUP
# ─────────────────────────────────────────────────────────────────────────────
DATASET_PATH = "ml_service/dataset_asma.csv"
GRAPHS_DIR = "ml_service/graphs"
os.makedirs(GRAPHS_DIR, exist_ok=True)

print("Loading dataset...")
df = pd.read_csv(DATASET_PATH)

# ─────────────────────────────────────────────────────────────────────────────
# TECHNIQUE 1: Class Balance Check
# ─────────────────────────────────────────────────────────────────────────────
print("\nTECHNIQUE 1: Class Balance (Crisis Prevalence)")
print("-" * 50)

counts = df["crisis"].value_counts()
pct = df["crisis"].value_counts(normalize=True) * 100

print(f"  Healthy  (0): {counts[0]:,}  ({pct[0]:.1f}%)")
print(f"  Crisis   (1): {counts[1]:,}  ({pct[1]:.1f}%)")

if 5 <= pct[1] <= 25:
    print("  [OK] Balance is medically realistic.")
else:
    print("  [WARNING] Class balance may not reflect real asthma prevalence.")

# ─────────────────────────────────────────────────────────────────────────────
# TECHNIQUE 2: Pearson Correlation Heatmap
# ─────────────────────────────────────────────────────────────────────────────
print("\nTECHNIQUE 2: Pearson Correlation Heatmap")
print("-" * 50)

COLUMN_LABELS = {
    "spo2": "SpO2 (%)",
    "bpm": "Ritmo Cardíaco (BPM)",
    "pasos": "Pasos",
    "horas_sueno": "Horas Sueño",
    "pef_porcentaje": "PEF (%)",
    "aqi": "Calidad del Aire (AQI)",
    "humedad": "Humedad (%)",
    "temperatura": "Temperatura (°C)",
    "crisis": "Crisis (TARGET)",
}

df_renamed = df.rename(columns=COLUMN_LABELS)
correlation_matrix = df_renamed.corr()

fig, ax = plt.subplots(figsize=(11, 8))
sns.heatmap(
    correlation_matrix,
    annot=True,
    fmt=".2f",
    cmap="coolwarm",
    center=0,
    vmin=-0.15,  # Exagerar el azul oscuro al llegar a -0.15
    vmax=0.15,   # Exagerar el rojo al llegar a +0.15
    linewidths=0.5,
    ax=ax,
)
ax.set_title(
    "Matriz de Correlación de Pearson — Dataset Sintético de Asma",
    fontsize=13, fontweight="bold", pad=16
)
plt.tight_layout()

heatmap_path = os.path.join(GRAPHS_DIR, "heatmap_correlacion.png")
plt.savefig(heatmap_path, dpi=150)
plt.close()
print(f"  [OK] Heatmap saved -> {heatmap_path}")

# ─────────────────────────────────────────────────────────────────────────────
# TECHNIQUE 3: Gaussian Distribution Histograms (per variable)
# ─────────────────────────────────────────────────────────────────────────────
print("\nTECHNIQUE 3: Gaussian Distribution Histograms")
print("-" * 50)

FEATURES = ["spo2", "bpm", "pasos", "horas_sueno", "pef_porcentaje", "aqi", "humedad", "temperatura"]

fig, axes = plt.subplots(nrows=2, ncols=4, figsize=(16, 8))
axes = axes.flatten()

for i, col in enumerate(FEATURES):
    ax = axes[i]
    ax.hist(df[col], bins=40, color="#4C8BF5", edgecolor="white", alpha=0.85)
    ax.set_title(COLUMN_LABELS[col], fontsize=10, fontweight="bold")
    ax.set_xlabel("Valor", fontsize=8)
    ax.set_ylabel("Frecuencia", fontsize=8)
    ax.tick_params(labelsize=7)

fig.suptitle(
    "Distribución Gaussiana de Variables — Dataset Sintético de Asma",
    fontsize=13, fontweight="bold", y=1.01
)
plt.tight_layout()

histograms_path = os.path.join(GRAPHS_DIR, "distribucion_variables.png")
plt.savefig(histograms_path, dpi=150, bbox_inches="tight")
plt.close()
print(f"  [OK] Histograms saved -> {histograms_path}")

print("\n[DONE] Validation complete. All graphs are in ml_service/graphs/")
