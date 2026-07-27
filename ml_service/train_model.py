import os
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.metrics import (
    accuracy_score,
    recall_score,
    precision_score,
    f1_score,
    roc_auc_score,
)
import time

start_time = time.time()

# =============================================================================
# FASE 1 - RANDOM FOREST: comparar particiones y folds (8 variables originales)
# =============================================================================
# Se prueban 3 particiones x 3 configuraciones de folds, con las 8 variables
# originales, para elegir la combinacion ganadora de Random Forest antes de
# pasar a seleccion de variables.

DATASET_PATH = r"C:\Users\gonza\Documents\FlutterX\asthmaapp\ml_service\DATASETNOW\dataset_hibrido_8020_v5.csv"
MODELS_DIR   = r"C:\Users\gonza\Documents\FlutterX\asthmaapp\ml_service\modelo"
os.makedirs(MODELS_DIR, exist_ok=True)

print("Cargando dataset...")
df = pd.read_csv(DATASET_PATH)

# Las 8 variables clinicas originales
FEATURES = ["spo2", "bpm", "pasos", "pef_porcentaje", "horas_sueno"]
TARGET = "crisis"

X = df[FEATURES]
y = df[TARGET]

# =============================================================================
# CONFIGURACION DE LOS EXPERIMENTOS: 3 SPLITS x 3 CANTIDADES DE FOLDS
# =============================================================================

SPLIT_OPTIONS = [0.30, 0.25, 0.20]   # test_size -> genera 70-30, 75-25, 80-20
FOLD_OPTIONS  = [3, 5, 10]

resultados_cv = []

def balancear(df_in):
    sanos  = df_in[df_in[TARGET] == 0]
    crisis = df_in[df_in[TARGET] == 1]
    crisis_over = crisis.sample(len(sanos), replace=True, random_state=42)
    return pd.concat([sanos, crisis_over], axis=0).sample(frac=1, random_state=42)

# =============================================================================
# BUCLE PRINCIPAL: por cada split, por cada cantidad de folds
# =============================================================================

for test_size in SPLIT_OPTIONS:
    particion_label = f"{int(round((1 - test_size) * 100))}-{int(round(test_size * 100))}"

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=42, stratify=y
    )

    print("\n" + "=" * 80)
    print(f"SPLIT {particion_label}  (train={len(X_train):,} / test={len(X_test):,})")
    print("=" * 80)

    for n_folds in FOLD_OPTIONS:
        print(f"\n  --- Particion {particion_label} | CV con {n_folds} folds ---")
        cv = StratifiedKFold(n_splits=n_folds, shuffle=True, random_state=42)

        cv_accs, cv_recs, cv_precs, cv_f1s, cv_aucs = [], [], [], [], []

        for fold, (train_idx, val_idx) in enumerate(cv.split(X_train, y_train), 1):
            X_tr_fold, y_tr_fold = X_train.iloc[train_idx], y_train.iloc[train_idx]
            X_val_fold, y_val_fold = X_train.iloc[val_idx], y_train.iloc[val_idx]

            fold_train_over = balancear(pd.concat([X_tr_fold, y_tr_fold], axis=1))
            X_tr_fold_final = fold_train_over[FEATURES]
            y_tr_fold_final = fold_train_over[TARGET]

            fold_model = RandomForestClassifier(
                n_estimators=200,
                max_depth=12,
                min_samples_leaf=5,
                random_state=42,
                n_jobs=-1,
                class_weight="balanced",
            )
            fold_model.fit(X_tr_fold_final, y_tr_fold_final)

            probs_val = fold_model.predict_proba(X_val_fold)[:, 1]
            preds_val = (probs_val >= 0.50).astype(int)

            cv_accs.append(accuracy_score(y_val_fold, preds_val))
            cv_recs.append(recall_score(y_val_fold, preds_val))
            cv_precs.append(precision_score(y_val_fold, preds_val))
            cv_f1s.append(f1_score(y_val_fold, preds_val))
            cv_aucs.append(roc_auc_score(y_val_fold, probs_val))

            print(f"      Fold {fold}/{n_folds} -> Acc: {cv_accs[-1]:.4f} | Rec: {cv_recs[-1]:.4f} "
                  f"| Prec: {cv_precs[-1]:.4f} | F1: {cv_f1s[-1]:.4f} | AUC: {cv_aucs[-1]:.4f}")

        resultados_cv.append({
            "Particion": particion_label,
            "CV Folds": n_folds,
            "Accuracy": np.mean(cv_accs),
            "Recall": np.mean(cv_recs),
            "Precision": np.mean(cv_precs),
            "F1": np.mean(cv_f1s),
            "AUC": np.mean(cv_aucs),
        })

# =============================================================================
# TABLA COMPARATIVA FINAL: LOS 3 SPLITS x LOS 3 FOLDS (9 FILAS)
# =============================================================================

tabla_cv = pd.DataFrame(resultados_cv)

print("\n" + "=" * 90)
print("TABLA COMPARATIVA - RANDOM FOREST - VALIDACION CRUZADA (70-30 / 75-25 / 80-20)")
print("=" * 90)
print(f"{'Particion':<10}{'CV Folds':<10}{'Accuracy':<12}{'Recall':<12}{'Precision':<12}{'F1':<12}{'AUC':<12}")
print("-" * 90)
for row in resultados_cv:
    print(f"{row['Particion']:<10}{row['CV Folds']:<10}"
          f"{row['Accuracy']:<12.4f}{row['Recall']:<12.4f}"
          f"{row['Precision']:<12.4f}{row['F1']:<12.4f}{row['AUC']:<12.4f}")
print("=" * 90)

TABLA_CV_PATH = os.path.join(MODELS_DIR, "random_forest_comparativa_cv_folds.csv")
tabla_cv.to_csv(TABLA_CV_PATH, index=False)
print(f"\nTabla comparativa guardada en -> {TABLA_CV_PATH}")

exec_time = time.time() - start_time
print(f"\n[METRICS] Tiempo total de ejecucion: {exec_time:.2f} segundos")