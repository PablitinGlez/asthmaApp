import pickle
import os
import numpy as np

# Ruta al modelo en ml_service y en asthma-api
MODEL_ML_PATH = os.path.join(os.path.dirname(__file__), "modelo", "random_forest_asma.pkl")
MODEL_API_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "asthma-api", "models", "random_forest_asma.pkl")

def probar_modelo(path, nombre):
    print("=" * 70)
    print(f"PROBANDO MODELO: {nombre}")
    print(f"Ruta: {path}")
    print("=" * 70)

    if not os.path.exists(path):
        print("Error: No existe el archivo.")
        return

    with open(path, "rb") as f:
        model = pickle.load(f)

    # 1. Inspeccionar n_features_in_ y feature_importances_
    n_features = getattr(model, "n_features_in_", "Desconocido")
    print(f"• Numero de features esperadas: {n_features}")

    if hasattr(model, "feature_importances_"):
        print("\nPESO / IMPORTANCIA DE CADA FEATURE EN EL MODELO:")
        nombres = ['spo2', 'bpm', 'pasos', 'pef_porcentaje', 'horas_sueno'] if n_features == 5 else ['spo2', 'bpm', 'pasos', 'horas_sueno', 'pef_porcentaje', 'aqi', 'humedad', 'temperatura']
        for name, imp in zip(nombres, model.feature_importances_):
            print(f"   • {name:<15} : {imp*100:.2f}%  {'#'*int(imp*30)}")

    # 2. Prueba 1: PEF = 4.0%, SpO2 = 98.0%, BPM = 75.0 (Caso de la app sin reloj)
    if n_features == 5:
        vector_prueba_1 = [[98.0, 75.0, 0.0, 4.0, 8.0]] # [spo2, bpm, pasos, pef_porcentaje, horas_sueno]
    else:
        vector_prueba_1 = [[98.0, 75.0, 0.0, 8.0, 4.0, 50.0, 50.0, 22.0]]

    prob_1 = model.predict_proba(vector_prueba_1)[0][1]
    pred_1 = model.predict(vector_prueba_1)[0]
    print("\nPRUEBA 1 (PEF = 4.0% con SpO2 = 98.0% default):")
    print(f"   • Vector enviado: {vector_prueba_1[0]}")
    print(f"   • Probabilidad de Crisis: {prob_1*100:.2f}%")
    print(f"   • Clasificacion: {'CRISIS (1)' if pred_1 == 1 or prob_1 >= 0.40 else 'SANO (0)'}")

    # 3. Prueba 2: Simulación de Ataque (PEF = 40%, SpO2 = 82%, BPM = 145)
    if n_features == 5:
        vector_prueba_2 = [[82.0, 145.0, 0.0, 40.0, 3.0]]
    else:
        vector_prueba_2 = [[82.0, 145.0, 0.0, 3.0, 40.0, 250.0, 85.0, 30.0]]

    prob_2 = model.predict_proba(vector_prueba_2)[0][1]
    pred_2 = model.predict(vector_prueba_2)[0]
    print("\nPRUEBA 2 (Simulacion de Ataque):")
    print(f"   • Vector enviado: {vector_prueba_2[0]}")
    print(f"   • Probabilidad de Crisis: {prob_2*100:.2f}%")
    print(f"   • Clasificacion: {'CRISIS (1)' if pred_2 == 1 or prob_2 >= 0.40 else 'SANO (0)'}")

if __name__ == "__main__":
    probar_modelo(MODEL_ML_PATH, "Modelo en ml_service/modelo")
    if os.path.exists(MODEL_API_PATH):
        probar_modelo(MODEL_API_PATH, "Modelo en asthma-api/models")
