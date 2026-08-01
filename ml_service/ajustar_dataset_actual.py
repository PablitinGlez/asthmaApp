import pandas as pd
import numpy as np
import os

DATASET_PATH = os.path.join(os.path.dirname(__file__), "DATASETNOW", "dataset_hibrido_8020_v5.csv")

def ajustar_dataset():
    print("=" * 80)
    print(" AJUSTANDO DATASET ACTUAL (DATASETNOW/dataset_hibrido_8020_v5.csv)")
    print("=" * 80)

    if not os.path.exists(DATASET_PATH):
        print(f" Error: No se encontró el archivo {DATASET_PATH}")
        return

    df = pd.read_csv(DATASET_PATH)
    total_original = len(df)
    print(f"• Registros totales cargados: {total_original:,}")

    # Separar bloque real (primeros 1,657) y sintético (el resto)
    df_real = df.iloc[:1657].copy()
    df_sint = df.iloc[1657:].copy()

    print(f"• Registros reales intocables (AAMOS-00): {len(df_real):,}")
    print(f"• Registros sintéticos a ajustar: {len(df_sint):,}")

    # Regla estricta GINA en sintéticos: PEF < 60% o SpO2 <= 92% NUNCA es sano (crisis = 1)
    cond_crisis_gina = (df_sint['pef_porcentaje'] < 60.0) | (df_sint['spo2'] <= 92.0)
    df_sint.loc[cond_crisis_gina, 'crisis'] = 1

    # Inyectar desacoplamiento (PEF bajo + SpO2 normal/default) en sintéticos de crisis
    # Seleccionamos registros sintéticos etiquetados como crisis con PEF < 60%
    crisis_indices = df_sint[(df_sint['crisis'] == 1) & (df_sint['pef_porcentaje'] < 60.0)].index
    
    # Tomamos 300 registros de esos para inyectarle SpO2 alta (95-98%)
    np.random.seed(42)
    sample_indices = np.random.choice(crisis_indices, size=min(300, len(crisis_indices)), replace=False)
    
    # A los 300 seleccionados les asignamos SpO2 normal (95-98%)
    df_sint.loc[sample_indices, 'spo2'] = np.random.uniform(95.0, 98.0, size=len(sample_indices))
    
    # A 100 de esos 300 les inyectamos los defaults exactos de la app móvil (SpO2=98.0, BPM=75.0)
    default_indices = sample_indices[:100]
    df_sint.loc[default_indices, 'spo2'] = 98.0
    df_sint.loc[default_indices, 'bpm'] = 75.0

    # Re-consolidar y ajustar para mantener EXACTAMENTE 10,000 registros y 2,000 crisis (20.0%)
    df_adjusted = pd.concat([df_real, df_sint], ignore_index=True)
    
    # Ajuste fino de la proporción objetivo: 2,000 crisis / 8,000 sanos
    current_crisis = (df_adjusted['crisis'] == 1).sum()
    print(f"• Crisis antes de rebalanceo fino: {current_crisis}")

    if current_crisis > 2000:
        # Si excedió 2,000, ajustamos registros sintéticos estables (PEF > 80% y SpO2 > 96%) a sanos
        excess = current_crisis - 2000
        convertible_indices = df_adjusted[(df_adjusted.index >= 1657) & 
                                          (df_adjusted['crisis'] == 1) & 
                                          (df_adjusted['pef_porcentaje'] > 80.0) & 
                                          (df_adjusted['spo2'] > 96.0)].index
        if len(convertible_indices) >= excess:
            to_convert = np.random.choice(convertible_indices, size=excess, replace=False)
            df_adjusted.loc[to_convert, 'crisis'] = 0

    final_crisis = (df_adjusted['crisis'] == 1).sum()
    final_sanos = (df_adjusted['crisis'] == 0).sum()
    print(f"• Crisis finales: {final_crisis:,} ({final_crisis/len(df_adjusted)*100:.2f}%)")
    print(f"• Sanos finales: {final_sanos:,} ({final_sanos/len(df_adjusted)*100:.2f}%)")
    print(f"• Total final: {len(df_adjusted):,} registros")

    # Guardar en la misma ruta (sobrescribir CSV)
    df_adjusted.to_csv(DATASET_PATH, index=False)
    print(f" CSV actualizado exitosamente en {DATASET_PATH}")

if __name__ == "__main__":
    ajustar_dataset()
