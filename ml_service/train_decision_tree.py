import os
import pickle
import pandas as pd
import numpy as np
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.metrics import (
    accuracy_score,
    recall_score,
    precision_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
)
import matplotlib.pyplot as plt
import seaborn as sns
import time

start_time = time.time()

# =============================================================================
# CONFIGURACION FINAL PARA DECISION TREE (Fase 1 + Fase 2 ya resueltas)
# =============================================================================
# - Particion       : 80% entrenamiento / 20% prueba
# - Validacion      : CV estratificada de 10 folds
# - Variables       : 4 -> ganadoras de la seleccion secuencial (mejor F1,
#                      mejor Accuracy y mejor Precision frente a 8, 5 y 3 vars)
# - Umbral clinico  : 40%
# Nota: esta es la configuracion DEFINITIVA de Decision Tree. Ya no hay
# comparacion de particiones/folds ni de variables: aqui se entrena el
# modelo final y se guarda (pkl + imagen de matriz de confusion).

DATASET_PATH = r"C:\Users\gonza\Downloads\dataset_hibrido_8020_v5.csv"
MODELS_DIR   = "ml_service/models"
GRAPHS_DIR   = "ml_service/graphs"
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(GRAPHS_DIR, exist_ok=True)

FEATURES = ["spo2", "pasos", "pef_porcentaje", "bpm"]
TARGET   = "crisis"

TEST_SIZE = 0.20
N_FOLDS   = 10
THRESHOLD = 0.40
PARTICION_LABEL = f"{int(round((1 - TEST_SIZE) * 100))}-{int(round(TEST_SIZE * 100))}"

print("Cargando dataset...")
df = pd.read_csv(DATASET_PATH)


def balancear(df_in):
    sanos  = df_in[df_in[TARGET] == 0]
    crisis = df_in[df_in[TARGET] == 1]
    crisis_over = crisis.sample(len(sanos), replace=True, random_state=42)
    return pd.concat([sanos, crisis_over], axis=0).sample(frac=1, random_state=42)


X = df[FEATURES]
y = df[TARGET]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=TEST_SIZE, random_state=42, stratify=y
)

# =============================================================================
# CV=10 (chequeo de estabilidad, no es la metrica oficial)
# =============================================================================
print("\n" + "=" * 90)
print(f"DECISION TREE - MODELO FINAL (particion {PARTICION_LABEL}, CV={N_FOLDS}, {len(FEATURES)} variables)")
print("=" * 90)
print(f"Variables usadas: {FEATURES}")

cv = StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=42)
cv_accs, cv_recs, cv_precs, cv_f1s, cv_aucs = [], [], [], [], []

for fold, (train_idx, val_idx) in enumerate(cv.split(X_train, y_train), 1):
    X_tr_fold, y_tr_fold = X_train.iloc[train_idx], y_train.iloc[train_idx]
    X_val_fold, y_val_fold = X_train.iloc[val_idx], y_train.iloc[val_idx]

    fold_train_over = balancear(pd.concat([X_tr_fold, y_tr_fold], axis=1))
    X_tr_fold_final = fold_train_over[FEATURES]
    y_tr_fold_final = fold_train_over[TARGET]

    fold_model = DecisionTreeClassifier(
        max_depth=12,
        min_samples_leaf=5,
        random_state=42,
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

    print(f"  Fold {fold}/{N_FOLDS} -> Acc: {cv_accs[-1]:.4f} | Rec: {cv_recs[-1]:.4f} "
          f"| Prec: {cv_precs[-1]:.4f} | F1: {cv_f1s[-1]:.4f} | AUC: {cv_aucs[-1]:.4f}")

print("\nPromedio CV (chequeo de estabilidad, no es la metrica oficial):")
print(f"  Accuracy: {np.mean(cv_accs):.4f}  Recall: {np.mean(cv_recs):.4f}  "
      f"Precision: {np.mean(cv_precs):.4f}  F1: {np.mean(cv_f1s):.4f}  AUC: {np.mean(cv_aucs):.4f}")

# =============================================================================
# MODELO FINAL: 100% del train balanceado, evaluado contra el 20% de test real
# =============================================================================
train_over = balancear(pd.concat([X_train, y_train], axis=1))
X_train_final = train_over[FEATURES]
y_train_final = train_over[TARGET]

modelo = DecisionTreeClassifier(
    max_depth=12,
    min_samples_leaf=5,
    random_state=42,
    class_weight="balanced",
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

importancias = pd.Series(modelo.feature_importances_, index=FEATURES).sort_values(ascending=False)

print("\nImportancias finales:")
for feat in importancias.index:
    print(f"  {feat:<18} {importancias[feat]:.4f}")

print(f"\n" + "-" * 55)
print(f"METRICAS OFICIALES (test real, umbral {int(THRESHOLD*100)}%)")
print("-" * 55)
for k, v in test_metrics.items():
    print(f"  {k:<10}: {v:.4f}")

# =============================================================================
# MATRIZ DE CONFUSION OFICIAL (unica que se guarda como imagen)
# =============================================================================
cm = confusion_matrix(y_test, preds_test)

print("\nMatriz de confusion (oficial, modelo final):")
print(f"                      Predicho Sano   Predicho Crisis")
print(f"    Real Sano         {cm[0][0]:<15}  {cm[0][1]}")
print(f"    Real Crisis       {cm[1][0]:<15}  {cm[1][1]}")
print(f"\n    Crisis detectadas : {cm[1][1]} de {cm[1][0] + cm[1][1]}")
print(f"    Crisis perdidas   : {cm[1][0]}")
print(f"    Falsas alarmas    : {cm[0][1]}")

plt.figure(figsize=(6, 5))
sns.heatmap(
    cm, annot=True, fmt="d", cmap="YlOrRd",
    xticklabels=["Predicho Sano", "Predicho Crisis"],
    yticklabels=["Real Sano", "Real Crisis"],
)
plt.title("Decision Tree - Matriz de Confusion (modelo final)")
plt.ylabel("Real")
plt.xlabel("Predicho")
plt.tight_layout()
CM_PATH = os.path.join(GRAPHS_DIR, "decision_tree_matriz_confusion_final.png")
plt.savefig(CM_PATH, dpi=150)
plt.close()
print(f"\nImagen de matriz de confusion guardada en -> {CM_PATH}")

# =============================================================================
# GUARDAR MODELO FINAL
# =============================================================================
MODEL_PATH = os.path.join(MODELS_DIR, "decision_tree_final.pkl")
with open(MODEL_PATH, "wb") as f:
    pickle.dump(modelo, f)
print(f"Modelo final guardado en -> {MODEL_PATH}")

exec_time = time.time() - start_time
print(f"\n[METRICS] Tiempo total de ejecucion: {exec_time:.2f} segundos")