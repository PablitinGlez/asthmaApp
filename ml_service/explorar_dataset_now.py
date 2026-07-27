import pandas as pd
import numpy as np
import os

# Ruta del dataset en DATASETNOW
DATASET_PATH = os.path.join(os.path.dirname(__file__), "DATASETNOW", "dataset_hibrido_8020_v5.csv")

def explorar_dataset():
    print("=" * 80)
    print("🔍 EXPLORACIÓN EXHAUSTIVA Y DIAGNÓSTICO DEL DATASET ACTUAL (DATASETNOW)")
    print("=" * 80)

    if not os.path.exists(DATASET_PATH):
        print(f"❌ Error: No se encontró el archivo en {DATASET_PATH}")
        return

    df = pd.read_csv(DATASET_PATH)
    
    # 1. RESUMEN ESTRUCTURAL
    print("\n1. RESUMEN ESTRUCTURAL DEL DATASET:")
    print(f"   • Ubicación: {DATASET_PATH}")
    print(f"   • Total de filas (registros): {len(df):,}")
    print(f"   • Total de columnas: {len(df.columns)}")
    print(f"   • Columnas presentes: {list(df.columns)}")
    print(f"   • Valores nulos: {df.isnull().sum().sum()}")

    # 2. DISTRIBUCIÓN DE LA CLASE TARGET
    print("\n" + "=" * 80)
    print("2. DISTRIBUCIÓN DE LA VARIABLE OBJETIVO ('crisis'):")
    counts = df['crisis'].value_counts()
    props = df['crisis'].value_counts(normalize=True)
    for cls in counts.index:
        nombre = "Crisis (1)" if cls == 1 else "Sano (0)"
        print(f"   • Clase {cls} ({nombre}): {counts[cls]:,} registros ({props[cls]*100:.2f}%)")

    # 3. CORRELACIÓN DE PEARSON RESPECTO A CRISIS
    print("\n" + "=" * 80)
    print("3. CORRELACIÓN DE PEARSON CON 'crisis' (Orden de Impacto):")
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    correlations = df[numeric_cols].corr()['crisis'].drop('crisis').sort_values(ascending=False)
    for col, val in correlations.items():
        bar = "█" * int(abs(val) * 30)
        signo = "+" if val >= 0 else "-"
        print(f"   • {col:<18} : {signo}{abs(val):.4f}  {bar}")

    # 4. ESTADÍSTICAS POR CLASE (SANO vs CRISIS)
    print("\n" + "=" * 80)
    print("4. COMPARATIVA DE PROMEDIOS POR CLASE (Sano vs Crisis):")
    print(f"{'Variable':<18} | {'Promedio Sano (0)':<18} | {'Promedio Crisis (1)':<18} | {'Diferencia':<12}")
    print("-" * 75)
    for col in numeric_cols:
        if col == 'crisis':
            continue
        mean_sano = df[df['crisis'] == 0][col].mean()
        mean_crisis = df[df['crisis'] == 1][col].mean()
        diff = mean_crisis - mean_sano
        print(f"{col:<18} | {mean_sano:<18.2f} | {mean_crisis:<18.2f} | {diff:<+12.2f}")

    # 5. DIAGNÓSTICO DE ESCENARIOS CLÍNICOS CRÍTICOS
    print("\n" + "=" * 80)
    print("5. DIAGNÓSTICO DE ESCENARIOS CLÍNICOS CRÍTICOS (DESACOPLAMIENTO):")

    # a) PEF Bajo (<60%) con SpO2 Normal (>=95%)
    pef_bajo_spo2_normal = df[(df['pef_porcentaje'] < 60) & (df['spo2'] >= 95)]
    print("\n   [Caso A] PEF Bajo (< 60%) + SpO2 Normal (>= 95%):")
    print(f"   • Total de registros en esta condición: {len(pef_bajo_spo2_normal)}")
    if len(pef_bajo_spo2_normal) > 0:
        crisis_count = (pef_bajo_spo2_normal['crisis'] == 1).sum()
        print(f"   • Etiquetados como Crisis (1): {crisis_count} ({crisis_count/len(pef_bajo_spo2_normal)*100:.1f}%)")
        print(f"   • Etiquetados como Sano (0): {len(pef_bajo_spo2_normal) - crisis_count}")
    else:
        print("   ⚠️ ATENCIÓN: 0 registros encontrados. El modelo NUNCA vio un PEF < 60% acompañado de SpO2 >= 95%.")

    # b) PEF Severo (<50%) con SpO2 Normal (>=95%)
    pef_severo_spo2_normal = df[(df['pef_porcentaje'] < 50) & (df['spo2'] >= 95)]
    print("\n   [Caso B] PEF Severo (< 50%) + SpO2 Normal (>= 95%):")
    print(f"   • Total de registros en esta condición: {len(pef_severo_spo2_normal)}")

    # c) Valores por Defecto del Celular (SpO2=98, BPM=75) con PEF Bajo (<60%)
    defaults_pef_bajo = df[(df['spo2'] == 98.0) & (df['bpm'] == 75.0) & (df['pef_porcentaje'] < 60)]
    print("\n   [Caso C] Defaults de App (SpO2=98, BPM=75) + PEF Bajo (< 60%):")
    print(f"   • Total de registros en esta condición: {len(defaults_pef_bajo)}")
    if len(defaults_pef_bajo) > 0:
        crisis_cnt = (defaults_pef_bajo['crisis'] == 1).sum()
        print(f"   • Etiquetados como Crisis (1): {crisis_cnt} ({crisis_cnt/len(defaults_pef_bajo)*100:.1f}%)")
    else:
        print("   ⚠️ ATENCIÓN: 0 registros encontrados.")

    # d) SpO2 Baja (<92%) con PEF Normal (>=80%)
    spo2_baja_pef_normal = df[(df['spo2'] < 92) & (df['pef_porcentaje'] >= 80)]
    print("\n   [Caso D] SpO2 Baja (< 92%) + PEF Normal (>= 80%):")
    print(f"   • Total de registros en esta condición: {len(spo2_baja_pef_normal)}")
    if len(spo2_baja_pef_normal) > 0:
        c_cnt = (spo2_baja_pef_normal['crisis'] == 1).sum()
        print(f"   • Etiquetados como Crisis (1): {c_cnt} ({c_cnt/len(spo2_baja_pef_normal)*100:.1f}%)")

    # 6. DISTRIBUCIÓN DE CRISIS POR RANGOS DE PEF %
    print("\n" + "=" * 80)
    print("6. DISTRIBUCIÓN DE 'crisis' SEGÚN RANGOS DE pef_porcentaje:")
    bins = [0, 40, 60, 80, 100, 150]
    labels = ['< 40% (Muy Severo)', '40-60% (Severo)', '60-80% (Moderado)', '80-100% (Normal)', '> 100% (Excelente)']
    df['pef_rango'] = pd.cut(df['pef_porcentaje'], bins=bins, labels=labels)
    
    grouped = df.groupby('pef_rango', observed=False)['crisis'].agg(total='count', crisis_sum='sum', sano_sum=lambda x: (x==0).sum())
    grouped['pct_crisis'] = (grouped['crisis_sum'] / grouped['total']) * 100
    
    for idx, row in grouped.iterrows():
        print(f"   • PEF {idx:<20} | Total: {row['total']:>5} | Crisis: {row['crisis_sum']:>4} ({row['pct_crisis']:>5.1f}%) | Sanos: {row['sano_sum']:>5}")

    print("\n" + "=" * 80)
    print("✅ EXPLORACIÓN FINALIZADA DE FORMA EXITOSA.")
    print("=" * 80)

if __name__ == "__main__":
    explorar_dataset()
