"""
=============================================================================
ASTHMA PREDICTION SYSTEM - Synthetic Dataset Generator
=============================================================================
Script: generate_dataset.py
Description:
    Generates a synthetic dataset of 10,000 patient-days for training
    the asthma crisis prediction model.

    All medical thresholds are based on:
    - GINA 2023 (Global Initiative for Asthma)
    - OMS Pulse Oximetry Training Manual
    - US EPA AirNow AQI Standards

Output:
    dataset_asma.csv (in the same ml_service/ folder)
=============================================================================
"""

import numpy as np
import pandas as pd

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
NUM_REGISTROS = 10_000
RANDOM_SEED = 42  # For reproducibility in scientific experiments
np.random.seed(RANDOM_SEED)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Generate raw biometric values using Gaussian distributions.
#         All values are restrained to realistic medical/environmental ranges.
# ─────────────────────────────────────────────────────────────────────────────

print("Generating synthetic patient records...")

# SpO2 (Oxygen Saturation %)
# Healthy population: mean 97%, std 2%. Clipped to [85, 100].
# Source: OMS Pulse Oximetry Manual / GINA 2023 p.58
spo2 = np.clip(np.random.normal(loc=97.0, scale=2.0, size=NUM_REGISTROS), 85, 100).round(1)

# BPM (Heart Rate - beats per minute)
# Healthy resting: mean 75 bpm, std 12. Clipped to [45, 160].
# Source: GINA 2023 p.59
bpm = np.clip(np.random.normal(loc=75, scale=12, size=NUM_REGISTROS), 45, 160).astype(int)

# Pasos (Daily Step Count from smartwatch)
# Average person: mean 6000 steps, std 2500. Clipped to [0, 25000].
pasos = np.clip(np.random.normal(loc=6000, scale=2500, size=NUM_REGISTROS), 0, 25000).astype(int)

# Horas de Sueño (Sleep hours detected by smartwatch)
# Healthy mean: 7 hours, std 1.2. Clipped to [2, 10].
# Source: GINA 2023 p.25 (Nocturnal symptom assessment)
horas_sueno = np.clip(np.random.normal(loc=7.0, scale=1.2, size=NUM_REGISTROS), 2, 10).round(1)

# PEF % (Peak Expiratory Flow as % of personal best)
# Healthy population: mean 82%, std 12. Clipped to [25, 100].
# Source: GINA 2023 p.56 (Green/Yellow/Red Zone thresholds)
pef_porcentaje = np.clip(np.random.normal(loc=82, scale=12, size=NUM_REGISTROS), 25, 100).round(1)

# AQI (Air Quality Index - environmental factor)
# Skewed toward "Good/Moderate" days (mean 60, std 35). Clipped to [0, 400].
# Source: US EPA AirNow - AQI Basics
aqi = np.clip(np.random.normal(loc=60, scale=35, size=NUM_REGISTROS), 0, 400).astype(int)

# Humedad (Relative Humidity %) 
# Mean 55%, std 15. Clipped to [10, 100].
humedad = np.clip(np.random.normal(loc=55, scale=15, size=NUM_REGISTROS), 10, 100).round(1)

# Temperatura (Celsius)
# Moderate climate: mean 22°C, std 6. Clipped to [-5, 45].
temperatura = np.clip(np.random.normal(loc=22, scale=6, size=NUM_REGISTROS), -5, 45).round(1)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Apply GINA 2023 Clinical Rules to determine the TARGET column.
#         A patient-day is labeled CRISIS=1 if ANY of the following is true:
#
#         Rule A: SpO2 < 92%                              (GINA p.58)
#         Rule B: PEF% < 50%                             (GINA p.56 - RED ZONE)
#         Rule C: PEF% < 80% AND BPM > 120 AND AQI > 100 (GINA p.59 - SEVERE)
# ─────────────────────────────────────────────────────────────────────────────

regla_a = spo2 < 92
regla_b = pef_porcentaje < 50
regla_c = (pef_porcentaje < 80) & (bpm > 120) & (aqi > 100)

crisis = (regla_a | regla_b | regla_c).astype(int)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Add biological noise (5% random flip).
#         In real life, some patients have attacks without obvious triggers
#         and some don't despite worsened metrics. This prevents the model
#         from memorizing rules instead of learning patterns.
# ─────────────────────────────────────────────────────────────────────────────

NOISE_RATE = 0.05
noise_mask = np.random.random(NUM_REGISTROS) < NOISE_RATE
crisis[noise_mask] = 1 - crisis[noise_mask]  # Flip 5% of labels

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Assemble the DataFrame and export to CSV
# ─────────────────────────────────────────────────────────────────────────────

dataset = pd.DataFrame({
    "spo2":           spo2,
    "bpm":            bpm,
    "pasos":          pasos,
    "horas_sueno":    horas_sueno,
    "pef_porcentaje": pef_porcentaje,
    "aqi":            aqi,
    "humedad":        humedad,
    "temperatura":    temperatura,
    "crisis":         crisis,
})

OUTPUT_PATH = "ml_service/dataset_asma.csv"
dataset.to_csv(OUTPUT_PATH, index=False)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: Print summary stats for quick sanity check
# ─────────────────────────────────────────────────────────────────────────────
total = len(dataset)
crisis_count = dataset["crisis"].sum()
sano_count = total - crisis_count
crisis_pct = (crisis_count / total) * 100

print(f"\n[OK] Dataset generated successfully -> {OUTPUT_PATH}")
print(f"   Total records  : {total:,}")
print(f"   Crisis (1)     : {crisis_count:,}  ({crisis_pct:.1f}%)")
print(f"   Healthy (0)    : {sano_count:,}  ({100 - crisis_pct:.1f}%)")
print(f"\nColumn summary:")
print(dataset.describe().round(2).to_string())
