import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns

# Estilo de las graficas
sns.set_theme(style="whitegrid")

def run_analysis():
    rutas = [
        r"C:\Users\gonza\Downloads\dataset_hibrido_8020_final (1).csv",
        r"C:\Users\gonza\Downloads\dataset_hibrido_8020_final.csv",
        r"C:\Users\gonza\Downloads\dataset_hibrido_8020.csv",
        r"C:\Users\gonza\Downloads\dataset_asma_v3.csv",
        "ml_service/dataset_asma_v3.csv",
        "dataset_asma_v3.csv"
    ]
    
    df = None
    archivo_cargado = ""
    for r in rutas:
        if os.path.exists(r):
            df = pd.read_csv(r)
            archivo_cargado = r
            break
            
    if df is None:
        print("No se encontro el archivo csv."); return

    print("=" * 60)
    print("   DIAGNOSTICO DE DATOS (EDA) - ASMA APP")
    print(f"   Archivo cargado: {archivo_cargado}")
    print("=" * 60)

    print("\n--- RESUMEN DEL DATASET ---")
    total = len(df)
    sanos = len(df[df['crisis']==0])
    crisis = len(df[df['crisis']==1])
    print(f"Total registros: {total:,}")
    print(f"Sanos:  {sanos:,}  ({(sanos/total*100):.1f}%)")
    print(f"Crisis: {crisis:,} ({(crisis/total*100):.1f}%)")

    print("\n--- MEDIAS POR CATEGORIA ---")
    variables = ['spo2', 'bpm', 'pef_porcentaje', 'aqi', 'humedad', 'temperatura', 'pasos', 'horas_sueno']
    perfiles = df.groupby('crisis')[variables].mean().T
    perfiles.columns = ['Sano', 'Crisis']
    print(perfiles.round(2).to_string())

    print("\n--- COMPARATIVA DE PERCENTILES ---")
    for var in ['spo2', 'bpm', 'pef_porcentaje']:
        sano_95   = df[df['crisis']==0][var].quantile(0.95)
        crisis_05 = df[df['crisis']==1][var].quantile(0.05)
        print(f"{var:15}: Sano (95%): {sano_95:.1f} | Crisis (5%): {crisis_05:.1f}")

    print("\n--- CONSULTAS ESPECIFICAS ---")
    # Casos de alto riesgo detectados
    peligro = df[(df['spo2'] < 92) & (df['bpm'] > 100)]
    print(f"Casos con SpO2 < 92% y BPM > 100:        {len(peligro)}")
    
    # Casos de crisis sin baja de oxigeno
    silenciosa = df[(df['spo2'] > 95) & (df['crisis'] == 1)]
    print(f"Crisis con oxigenacion normal (>95%):     {len(silenciosa)}")
    
    # Impacto del descanso
    riesgo_sueno = df[df['horas_sueno'] < 5]['crisis'].mean() * 100
    print(f"Prob. de crisis con poco sueno (<5h):     {riesgo_sueno:.1f}%")

    print("\n--- CORRELACION CON EL RIESGO ---")
    corrs = df.corr()['crisis'].sort_values(ascending=False).to_frame()
    print(corrs.drop('crisis').round(4).to_string())

    print("\nGenerando graficas...")
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle('Distribucion de Variables Fisicas — Dataset Hibrido 8020', fontsize=16)

    sns.histplot(data=df, x="spo2", hue="crisis", kde=True, ax=axes[0, 0], palette="coolwarm")
    axes[0, 0].set_title('Distribucion de SpO2')

    sns.boxplot(data=df, x="crisis", y="bpm", hue="crisis", legend=False, ax=axes[0, 1], palette="Set2")
    axes[0, 1].set_title('Ritmo Cardiaco (BPM): Sano vs Crisis')
    axes[0, 1].set_xticks([0, 1]); axes[0, 1].set_xticklabels(['Sano', 'Crisis'])

    sns.boxplot(data=df, x="crisis", y="pef_porcentaje", hue="crisis", legend=False, ax=axes[1, 0], palette="viridis")
    axes[1, 0].set_title('Capacidad Pulmonar (PEF %): Sano vs Crisis')
    axes[1, 0].set_xticks([0, 1]); axes[1, 0].set_xticklabels(['Sano', 'Crisis'])

    sns.heatmap(df[variables + ['crisis']].corr(), annot=True, cmap='RdYlGn', fmt=".2f", ax=axes[1, 1])
    axes[1, 1].set_title('Mapa de Calor de Correlaciones')

    plt.tight_layout(rect=[0, 0.03, 1, 0.95])

    output_img = "ml_service/analisis_datos_asma.png"
    plt.savefig(output_img)
    print(f"\n[EXITO] Grafica guardada en: {output_img}")
    print("=" * 60)
    print("   ANALISIS FINALIZADO")
    print("=" * 60)

if __name__ == "__main__":
    run_analysis()
