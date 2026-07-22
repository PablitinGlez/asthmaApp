"""
=============================================================================
COMPARATIVA DE 9 MODELOS - AsmaSync
=============================================================================
Flujo:
  1. Carga el dataset
  2. Train-Test Split (75% entrenamiento / 25% prueba)
  3. Aplica SMOTE solo al set de entrenamiento (no contamina la prueba)
  4. Entrena los 9 modelos
  5. Evalúa cada uno en el set de prueba independiente
  6. Muestra tabla comparativa con todas las métricas

Instalar dependencias si no las tienes:
  pip install scikit-learn xgboost imbalanced-learn pandas numpy
=============================================================================
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score, recall_score, precision_score,
    f1_score, roc_auc_score
)

# --- Modelos ---
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import (
    RandomForestClassifier,
    ExtraTreesClassifier,
    AdaBoostClassifier,
    GradientBoostingClassifier,
)
from sklearn.neighbors import KNeighborsClassifier
from xgboost import XGBClassifier

# --- Balanceo con SMOTE ---
from imblearn.over_sampling import SMOTE

import warnings
warnings.filterwarnings("ignore")

# =============================================================================
# 1. CARGA DEL DATASET
# =============================================================================

DATASET_PATH = r"C:\Users\gonza\Downloads\dataset_hibrido_8020_v5.csv"

print("Cargando dataset...")
df = pd.read_csv(DATASET_PATH)

FEATURES = [
    "spo2", "bpm", "pasos", "horas_sueno",
    "pef_porcentaje", "aqi", "humedad", "temperatura"
]
TARGET = "crisis"

X = df[FEATURES]
y = df[TARGET]

print(f"  Total de registros : {len(df):,}")
print(f"  Sanos (0)          : {(y == 0).sum():,}")
print(f"  En crisis (1)      : {(y == 1).sum():,}")

# =============================================================================
# 2. TRAIN-TEST SPLIT (75% entrenamiento / 25% prueba)
#    stratify=y → preserva la proporción 80/20 en ambas partes
# =============================================================================

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, random_state=42, stratify=y
)

print(f"\nDivisión de datos:")
print(f"  Entrenamiento (antes de SMOTE) : {len(X_train):,} registros")
print(f"  Prueba (nunca toca el modelo)  : {len(X_test):,} registros")

# =============================================================================
# 3. SMOTE — Aplica balanceo SOLO al set de entrenamiento
#    El set de prueba se deja con su distribución real (80/20)
# =============================================================================

print("\nAplicando SMOTE al set de entrenamiento...")
smote = SMOTE(random_state=42)
X_train_smote, y_train_smote = smote.fit_resample(X_train, y_train)

print(f"  Entrenamiento balanceado (SMOTE): {len(X_train_smote):,} registros")
print(f"  Sanos (0)  : {(y_train_smote == 0).sum():,}")
print(f"  Crisis (1) : {(y_train_smote == 1).sum():,}")

# =============================================================================
# 4. DEFINICIÓN DE LOS 9 MODELOS
# =============================================================================

THRESHOLD = 0.40  # umbral clínico: preferimos detectar más crisis aunque haya falsas alarmas

modelos = {
    "Regresión Logística":   LogisticRegression(max_iter=1000, random_state=42),
    "SVM":                   SVC(probability=True, random_state=42),
    "Decision Tree":         DecisionTreeClassifier(random_state=42),
    "Random Forest":         RandomForestClassifier(n_estimators=200, max_depth=12,
                                                    min_samples_leaf=5, random_state=42, n_jobs=-1),
    "Extra Trees":           ExtraTreesClassifier(n_estimators=200, random_state=42, n_jobs=-1),
    "AdaBoost":              AdaBoostClassifier(n_estimators=200, random_state=42),
    "Gradient Boosting":     GradientBoostingClassifier(n_estimators=200, random_state=42),
    "XGBoost":               XGBClassifier(n_estimators=200, max_depth=4, learning_rate=0.1,
                                           random_state=42, n_jobs=-1, eval_metric="logloss",
                                           verbosity=0),
    "KNN":                   KNeighborsClassifier(n_neighbors=5, n_jobs=-1),
}

# =============================================================================
# 5. ENTRENAMIENTO Y EVALUACIÓN DE LOS 9 MODELOS
# =============================================================================

print("\n" + "=" * 65)
print(f"ENTRENANDO Y EVALUANDO 9 MODELOS (Umbral clínico: {int(THRESHOLD*100)}%)")
print("=" * 65)

resultados = []

for nombre, modelo in modelos.items():
    print(f"  Entrenando: {nombre}...")
    modelo.fit(X_train_smote, y_train_smote)

    # Probabilidades sobre el set de PRUEBA real (nunca visto)
    y_prob = modelo.predict_proba(X_test)[:, 1]
    y_pred = (y_prob >= THRESHOLD).astype(int)

    acc   = accuracy_score(y_test, y_pred)
    rec   = recall_score(y_test, y_pred)
    prec  = precision_score(y_test, y_pred)
    f1    = f1_score(y_test, y_pred)
    auc   = roc_auc_score(y_test, y_prob)

    # Calcular crisis detectadas y falsas alarmas
    from sklearn.metrics import confusion_matrix
    cm = confusion_matrix(y_test, y_pred)
    crisis_detectadas = cm[1][1]
    total_crisis      = cm[1][0] + cm[1][1]
    falsas_alarmas    = cm[0][1]

    resultados.append({
        "Modelo":              nombre,
        "Accuracy":            round(acc,  4),
        "Recall":              round(rec,  4),
        "Precisión":           round(prec, 4),
        "F1-Score":            round(f1,   4),
        "ROC-AUC":             round(auc,  4),
        "Crisis detectadas":   f"{crisis_detectadas}/{total_crisis}",
        "Falsas alarmas":      falsas_alarmas,
    })

# =============================================================================
# 6. TABLA COMPARATIVA FINAL
# =============================================================================

df_resultados = pd.DataFrame(resultados)
df_resultados = df_resultados.sort_values("Recall", ascending=False).reset_index(drop=True)

print("\n" + "=" * 100)
print("TABLA COMPARATIVA — 9 MODELOS (ordenados por Recall / Sensibilidad)")
print("=" * 100)
print(df_resultados.to_string(index=False))
print("=" * 100)

# También guarda los resultados en un CSV para que los puedas copiar en tu artículo
OUTPUT_CSV = r"C:\Users\gonza\Documents\FlutterX\asthmaapp\ml_service\resultados_9_modelos.csv"
df_resultados.to_csv(OUTPUT_CSV, index=False)
print(f"\nResultados guardados en: {OUTPUT_CSV}")
print("\n¡Listo! Copia los números al artículo desde el CSV.")
