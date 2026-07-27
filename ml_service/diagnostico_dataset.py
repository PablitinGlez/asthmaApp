import pandas as pd
import numpy as np

DATASET_PATH = r"C:\Users\gonza\Downloads\dataset_hibrido_8020_v5.csv"

print("Cargando dataset...")
df = pd.read_csv(DATASET_PATH)

FEATURES = ["spo2", "bpm", "pasos", "horas_sueno", "pef_porcentaje", "aqi", "humedad", "temperatura"]
TARGET = "crisis"

print(f"\nTotal de registros: {len(df):,}")
print(f"Distribucion de la clase objetivo:")
print(df[TARGET].value_counts())
print(f"Proporcion: {df[TARGET].value_counts(normalize=True).round(4).to_dict()}")

# =============================================================================
# 1) CORRELACION DE CADA VARIABLE CON LA ETIQUETA DE CRISIS
# =============================================================================
print("\n" + "=" * 70)
print("CORRELACION DE CADA VARIABLE CON 'crisis' (Pearson)")
print("=" * 70)
correlaciones = df[FEATURES + [TARGET]].corr()[TARGET].drop(TARGET).sort_values(key=abs, ascending=False)
for feat, corr in correlaciones.items():
    print(f"  {feat:<18} {corr:+.4f}")

# =============================================================================
# 2) PROMEDIO DE CADA VARIABLE, SEPARADO POR CLASE (sano vs crisis)
# =============================================================================
print("\n" + "=" * 70)
print("PROMEDIO DE CADA VARIABLE POR CLASE (Sano vs Crisis)")
print("=" * 70)
comparacion = df.groupby(TARGET)[FEATURES].mean().T
comparacion.columns = ["Sano (0)", "Crisis (1)"]
comparacion["Diferencia"] = comparacion["Crisis (1)"] - comparacion["Sano (0)"]
print(comparacion.round(2))

# =============================================================================
# 3) EL PUNTO CLAVE: CASOS CON PEF BAJO PERO SPO2 NORMAL -> ¿SE ETIQUETARON COMO CRISIS?
# =============================================================================
print("\n" + "=" * 70)
print("CASOS CON PEF BAJO (<50%) Y SPO2 NORMAL (>=95%)")
print("=" * 70)
pef_bajo_spo2_normal = df[(df["pef_porcentaje"] < 50) & (df["spo2"] >= 95)]
print(f"Total de registros en esta condicion: {len(pef_bajo_spo2_normal)}")
if len(pef_bajo_spo2_normal) > 0:
    print(f"De esos, cuantos fueron etiquetados como crisis (1): {pef_bajo_spo2_normal[TARGET].sum()}")
    print(f"Porcentaje etiquetado como crisis: {pef_bajo_spo2_normal[TARGET].mean()*100:.2f}%")
else:
    print("No hay registros en el dataset con esta combinacion -> el modelo nunca vio este escenario.")

# =============================================================================
# 4) EL CONTRASTE: CASOS CON SPO2 BAJO PERO PEF NORMAL -> ¿SE ETIQUETARON COMO CRISIS?
# =============================================================================
print("\n" + "=" * 70)
print("CASOS CON SPO2 BAJO (<92%) Y PEF NORMAL (>=80%)")
print("=" * 70)
spo2_bajo_pef_normal = df[(df["spo2"] < 92) & (df["pef_porcentaje"] >= 80)]
print(f"Total de registros en esta condicion: {len(spo2_bajo_pef_normal)}")
if len(spo2_bajo_pef_normal) > 0:
    print(f"De esos, cuantos fueron etiquetados como crisis (1): {spo2_bajo_pef_normal[TARGET].sum()}")
    print(f"Porcentaje etiquetado como crisis: {spo2_bajo_pef_normal[TARGET].mean()*100:.2f}%")
else:
    print("No hay registros en el dataset con esta combinacion.")

# =============================================================================
# 5) DISTRIBUCION COMPLETA DE PEF, SEPARADA POR CLASE
# =============================================================================
print("\n" + "=" * 70)
print("ESTADISTICAS DE pef_porcentaje POR CLASE")
print("=" * 70)
print(df.groupby(TARGET)["pef_porcentaje"].describe().round(2))

print("\n" + "=" * 70)
print("ESTADISTICAS DE spo2 POR CLASE")
print("=" * 70)
print(df.groupby(TARGET)["spo2"].describe().round(2))