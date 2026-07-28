import os
import pickle
import pandas as pd
import numpy as np

try:
    from xgboost import XGBClassifier
except ImportError:
    print("\n[ERROR] libreria 'xgboost' no instalada. Usa: pip install xgboost")
    exit()

from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.metrics import (
    accuracy_score,
    recall_score,
    precision_score,
    f1_score,
    roc_auc_score,
    classification_report,
    confusion_matrix,
)
import matplotlib.pyplot as plt
import seaborn as sns
import time

start_time = time.time()

# =============================================================================
# CONFIGURACION FIJA PARA XGBOOST (resultado de la Fase 1)
# =============================================================================
# - Particion       : 70% entrenamiento /30% prueba
# - Validacion       : CV estratificada de 3 folds (gano sobre 5 y 10 para XGBoost)
# - Umbral clinico   : 40%
# Nota: esta combinacion es propia de XGBoost, distinta a la de Random Forest
# (80-20 / 10 folds). Cada modelo se evalua con su propia mejor configuracion.

DATASET_PATH = r"C:\Users\gonza\Documents\FlutterX\asthmaapp\ml_service\DATASETNOW\dataset_hibrido_8020_v5.csv"
MODELS_DIR   = r"C:\Users\gonza\Documents\FlutterX\asthmaapp\ml_service\modelo"
GRAPHS_DIR   = r"C:\Users\gonza\Documents\FlutterX\asthmaapp\ml_service\graphs"
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(GRAPHS_DIR, exist_ok=True)

FEATURES_ALL = [
    "spo2", "bpm", "pasos", "horas_sueno",
    "pef_porcentaje", "aqi", "humedad", "temperatura"
]
TARGET = "crisis"

TEST_SIZE = 0.30
N_FOLDS   = 3
THRESHOLD = 0.40
PARTICION_LABEL = f"{int(round((1 - TEST_SIZE) * 100))}-{int(round(TEST_SIZE * 100))}"

print("Cargando dataset...")
df = pd.read_csv(DATASET_PATH)

def balancear(df_in):
    sanos  = df_in[df_in[TARGET] == 0]
    crisis = df_in[df_in[TARGET] == 1]
    crisis_over = crisis.sample(len(sanos), replace=True, random_state=42)
    return pd.concat([sanos, crisis_over], axis=0).sample(frac=1, random_state=42)


def evaluar_features(features):
    """
    Con la particion y folds fijos para XGBoost (80-20, CV=3):
    1. Split 80-20 usando SOLO las columnas de 'features'.
    2. CV=3 sobre el train (chequeo de estabilidad).
    3. Modelo final con el 100% del train balanceado, evaluado contra el
       20% de test real (metrica oficial).
    4. Regresa tambien las importancias, para decidir que quitar despues.
    """
    X = df[features]
    y = df[TARGET]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=TEST_SIZE, random_state=42, stratify=y
    )

    # ---- CV=3 (chequeo de estabilidad) ----
    cv = StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=42)
    cv_accs, cv_recs, cv_precs, cv_f1s, cv_aucs = [], [], [], [], []

    for train_idx, val_idx in cv.split(X_train, y_train):
        X_tr_fold, y_tr_fold = X_train.iloc[train_idx], y_train.iloc[train_idx]
        X_val_fold, y_val_fold = X_train.iloc[val_idx], y_train.iloc[val_idx]

        fold_train_over = balancear(pd.concat([X_tr_fold, y_tr_fold], axis=1))
        X_tr_fold_final = fold_train_over[features]
        y_tr_fold_final = fold_train_over[TARGET]

        fold_model = XGBClassifier(
            n_estimators=200, max_depth=4, subsample=0.8, colsample_bytree=0.8,
            min_child_weight=5, learning_rate=0.1, random_state=42, n_jobs=-1,
            eval_metric="logloss",
        )
        fold_model.fit(X_tr_fold_final, y_tr_fold_final)

        probs_val = fold_model.predict_proba(X_val_fold)[:, 1]
        preds_val = (probs_val >= 0.50).astype(int)

        cv_accs.append(accuracy_score(y_val_fold, preds_val))
        cv_recs.append(recall_score(y_val_fold, preds_val))
        cv_precs.append(precision_score(y_val_fold, preds_val))
        cv_f1s.append(f1_score(y_val_fold, preds_val))
        cv_aucs.append(roc_auc_score(y_val_fold, probs_val))

    cv_metrics = {
        "Accuracy": np.mean(cv_accs), "Recall": np.mean(cv_recs),
        "Precision": np.mean(cv_precs), "F1": np.mean(cv_f1s), "AUC": np.mean(cv_aucs),
    }

    # ---- Modelo final con el 100% del train, evaluado contra test real ----
    train_over = balancear(pd.concat([X_train, y_train], axis=1))
    X_train_final = train_over[features]
    y_train_final = train_over[TARGET]

    modelo = XGBClassifier(
        n_estimators=200, max_depth=4, subsample=0.8, colsample_bytree=0.8,
        min_child_weight=5, learning_rate=0.1, random_state=42, n_jobs=-1,
        eval_metric="logloss",
    )
    modelo.fit(X_train_final, y_train_final)

    probs_test = modelo.predict_proba(X_test)[:, 1]
    preds_test = (probs_test >= THRESHOLD).astype(int)

    test_metrics = {
        "Accuracy": accuracy_score(y_test, preds_test),
        "Recall": recall_score(y_test, preds_test),
        "Precision": precision_score(y_test, preds_test),
        "F1": f1_score(y_test, preds_test),
        "AUC": roc_auc_score(y_test, probs_test),
    }

    importancias = pd.Series(
        modelo.feature_importances_, index=features
    ).sort_values(ascending=False)

    cm = confusion_matrix(y_test, preds_test)

    return {
        "modelo": modelo, "cv_metrics": cv_metrics, "test_metrics": test_metrics,
        "importancias": importancias, "X_test": X_test, "y_test": y_test,
        "cm": cm,
    }


# =============================================================================
# ELIMINACION SECUENCIAL DE VARIABLES (backward elimination) PARA XGBOOST
# =============================================================================

resultados_features = []
resultados_por_paso = {}

print("\n" + "=" * 90)
print(f"XGBOOST - SELECCION DE VARIABLES (particion {PARTICION_LABEL} fija, CV={N_FOLDS} fija)")
print("=" * 90)

def mostrar_matriz_confusion(res, n_vars):
    """Imprime la matriz de confusion en consola y guarda su grafica en PNG."""
    cm = res["cm"]
    print("  Matriz de confusion:")
    print(f"                      Predicho Sano   Predicho Crisis")
    print(f"    Real Sano         {cm[0][0]:<15}  {cm[0][1]}")
    print(f"    Real Crisis       {cm[1][0]:<15}  {cm[1][1]}")
    print(f"\n    Crisis detectadas : {cm[1][1]} de {cm[1][0] + cm[1][1]}")
    print(f"    Crisis perdidas   : {cm[1][0]}")
    print(f"    Falsas alarmas    : {cm[0][1]}")

    plt.figure(figsize=(6, 5))
    sns.heatmap(cm, annot=True, fmt="d", cmap="YlOrRd", cbar=False,
                xticklabels=["Predicho Sano", "Predicho Crisis"],
                yticklabels=["Real Sano", "Real Crisis"])
    plt.title(f"Matriz de Confusion - XGBoost ({n_vars} vars, Umbral {int(THRESHOLD*100)}%)")
    plt.tight_layout()
    graph_path = os.path.join(GRAPHS_DIR, f"confusion_matrix_xgboost_{n_vars}vars.png")
    plt.savefig(graph_path, dpi=150)
    plt.close()
    print(f"    Grafica guardada en -> {graph_path}")


# --- Paso 1: 8 variables (todas) ---
print(f"\n--- Paso 1: 8 variables (todas) ---")
res_8 = evaluar_features(FEATURES_ALL)
resultados_por_paso["8"] = res_8
print("  Importancias:")
for feat, imp in res_8["importancias"].items():
    print(f"    {feat:<18} {imp:.4f}")
mostrar_matriz_confusion(res_8, 8)
resultados_features.append({"# Variables": "8 (todas)", **res_8["test_metrics"]})

# --- Paso 2: 5 variables (top 5 por importancia del modelo de 8) ---
top5 = res_8["importancias"].head(5).index.tolist()
print(f"\n--- Paso 2: 5 variables -> {top5} ---")
res_5 = evaluar_features(top5)
resultados_por_paso["5"] = res_5
print("  Importancias recalculadas (con solo estas 5):")
for feat, imp in res_5["importancias"].items():
    print(f"    {feat:<18} {imp:.4f}")
mostrar_matriz_confusion(res_5, 5)
resultados_features.append({"# Variables": "5", **res_5["test_metrics"]})

# --- Paso 3: 4 variables ---
peor_de_5 = res_5["importancias"].idxmin()
top4 = [f for f in top5 if f != peor_de_5]
print(f"\n--- Paso 3: 4 variables (se quito '{peor_de_5}') -> {top4} ---")
res_4 = evaluar_features(top4)
resultados_por_paso["4"] = res_4
print("  Importancias recalculadas (con solo estas 4):")
for feat, imp in res_4["importancias"].items():
    print(f"    {feat:<18} {imp:.4f}")
mostrar_matriz_confusion(res_4, 4)
resultados_features.append({"# Variables": "4", **res_4["test_metrics"]})

# --- Paso 4: 3 variables ---
peor_de_4 = res_4["importancias"].idxmin()
top3 = [f for f in top4 if f != peor_de_4]
print(f"\n--- Paso 4: 3 variables (se quito '{peor_de_4}') -> {top3} ---")
res_3 = evaluar_features(top3)
resultados_por_paso["3"] = res_3
print("  Importancias recalculadas (con solo estas 3):")
for feat, imp in res_3["importancias"].items():
    print(f"    {feat:<18} {imp:.4f}")
mostrar_matriz_confusion(res_3, 3)
resultados_features.append({"# Variables": "3", **res_3["test_metrics"]})

# =============================================================================
# TABLA COMPARATIVA FINAL (metricas OFICIALES: sobre test real)
# =============================================================================

tabla_features = pd.DataFrame(resultados_features)

print("\n" + "=" * 90)
print(f"XGBOOST - TABLA COMPARATIVA SELECCION DE VARIABLES (test real, particion {PARTICION_LABEL}, umbral {int(THRESHOLD*100)}%)")
print("=" * 90)
print(f"{'# Variables':<14}{'Accuracy':<12}{'Recall':<12}{'Precision':<12}{'F1':<12}{'AUC':<12}")
print("-" * 90)
for row in resultados_features:
    print(f"{row['# Variables']:<14}"
          f"{row['Accuracy']:<12.4f}{row['Recall']:<12.4f}"
          f"{row['Precision']:<12.4f}{row['F1']:<12.4f}{row['AUC']:<12.4f}")
print("=" * 90)

TABLA_FEATURES_PATH = os.path.join(MODELS_DIR, "xgboost_comparativa_feature_selection.csv")
tabla_features.to_csv(TABLA_FEATURES_PATH, index=False)
print(f"\nTabla comparativa guardada en -> {TABLA_FEATURES_PATH}")

print("\n" + "-" * 55)
print("RESUMEN DE VARIABLES USADAS EN CADA PASO")
print("-" * 55)
print(f"  8 variables : {FEATURES_ALL}")
print(f"  5 variables : {top5}")
print(f"  4 variables : {top4}  (se quito '{peor_de_5}')")
print(f"  3 variables : {top3}  (se quito '{peor_de_4}')")

exec_time = time.time() - start_time
print(f"\n[METRICS] Tiempo total de ejecucion: {exec_time:.2f} segundos")