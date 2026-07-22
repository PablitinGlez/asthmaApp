import os
import pickle
import pandas as pd
import numpy as np
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.metrics import (
    accuracy_score,
    recall_score,
    precision_score,
    f1_score,
    roc_auc_score,
    classification_report,
    confusion_matrix,
    precision_recall_curve,
)
import matplotlib.pyplot as plt
import seaborn as sns
import time

start_time = time.time()

# =============================================================================
# CONFIGURACION FIJA (misma que Random Forest y Decision Tree, para comparar justo)
# =============================================================================
# - Particion       : 80% entrenamiento / 20% prueba
# - Validacion       : CV estratificada de 10 folds (chequeo de estabilidad)
# - Variables        : 5 (spo2, bpm, pasos, pef_porcentaje, horas_sueno)
# - Umbral clinico   : 40%
# - Modelo           : Gradient Boosting

DATASET_PATH = r"C:\Users\gonza\Downloads\dataset_hibrido_8020_v5.csv"
MODELS_DIR   = "ml_service/models"
GRAPHS_DIR   = "ml_service/graphs"
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(GRAPHS_DIR, exist_ok=True)

FEATURES = ["spo2", "bpm", "pasos", "pef_porcentaje", "horas_sueno"]
TARGET = "crisis"

TEST_SIZE = 0.20
N_FOLDS   = 10
THRESHOLD = 0.40
PARTICION_LABEL = f"{int(round((1 - TEST_SIZE) * 100))}-{int(round(TEST_SIZE * 100))}"
NOMBRE_MODELO = "Gradient Boosting"

print("Cargando dataset...")
df = pd.read_csv(DATASET_PATH)

X = df[FEATURES]
y = df[TARGET]

# =============================================================================
# PASO 1: SPLIT TRAIN-TEST (80/20) - misma semilla que el resto de los modelos
# =============================================================================

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=TEST_SIZE, random_state=42, stratify=y
)

print(f"\nModelo: {NOMBRE_MODELO}")
print(f"Particion {PARTICION_LABEL} | Train: {len(X_train):,} | Test: {len(X_test):,}")
print(f"Variables usadas ({len(FEATURES)}): {FEATURES}")

# =============================================================================
# FUNCION AUXILIAR: balancear (oversampling de la clase minoritaria)
# =============================================================================

def balancear(df_in):
    sanos  = df_in[df_in[TARGET] == 0]
    crisis = df_in[df_in[TARGET] == 1]
    crisis_over = crisis.sample(len(sanos), replace=True, random_state=42)
    return pd.concat([sanos, crisis_over], axis=0).sample(frac=1, random_state=42)

# =============================================================================
# PASO 2: VALIDACION CRUZADA (CV=10) - chequeo de estabilidad del modelo
# =============================================================================
# Nota: Gradient Boosting no tiene "class_weight", asi que el balanceo por
# oversampling es aun mas importante aqui que en Random Forest / Decision Tree.

print(f"\nEjecutando validacion cruzada estratificada ({N_FOLDS} folds) sobre el entrenamiento...")
cv = StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=42)

cv_accs, cv_recs, cv_precs, cv_f1s, cv_aucs = [], [], [], [], []

for fold, (train_idx, val_idx) in enumerate(cv.split(X_train, y_train), 1):
    X_tr_fold, y_tr_fold = X_train.iloc[train_idx], y_train.iloc[train_idx]
    X_val_fold, y_val_fold = X_train.iloc[val_idx], y_train.iloc[val_idx]

    fold_train_over = balancear(pd.concat([X_tr_fold, y_tr_fold], axis=1))
    X_tr_fold_final = fold_train_over[FEATURES]
    y_tr_fold_final = fold_train_over[TARGET]

    fold_model = GradientBoostingClassifier(
        n_estimators=200,
        learning_rate=0.1,
        max_depth=3,
        random_state=42,
    )
    fold_model.fit(X_tr_fold_final, y_tr_fold_final)

    probs_val = fold_model.predict_proba(X_val_fold)[:, 1]
    preds_val = (probs_val >= 0.50).astype(int)

    cv_accs.append(accuracy_score(y_val_fold, preds_val))
    cv_recs.append(recall_score(y_val_fold, preds_val))
    cv_precs.append(precision_score(y_val_fold, preds_val))
    cv_f1s.append(f1_score(y_val_fold, preds_val))
    cv_aucs.append(roc_auc_score(y_val_fold, probs_val))

print("\n" + "-" * 55)
print(f"METRICAS PROMEDIO DE CV ({N_FOLDS} folds) - chequeo de estabilidad")
print("-" * 55)
print(f"  Accuracy  : {np.mean(cv_accs):.4f}")
print(f"  Recall    : {np.mean(cv_recs):.4f}")
print(f"  Precision : {np.mean(cv_precs):.4f}")
print(f"  F1-Score  : {np.mean(cv_f1s):.4f}")
print(f"  ROC-AUC   : {np.mean(cv_aucs):.4f}")
print("-" * 55)

# =============================================================================
# PASO 3: BALANCEO DEL SET DE ENTRENAMIENTO COMPLETO
# =============================================================================

train_over = balancear(pd.concat([X_train, y_train], axis=1))
X_train_final = train_over[FEATURES]
y_train_final = train_over[TARGET]

print(f"\nSet de entrenamiento balanceado : {len(X_train_final):,} registros (50% sano / 50% crisis)")
print(f"Set de prueba (dist. original)  : {len(X_test):,} registros")

# =============================================================================
# PASO 4: ENTRENAMIENTO DEL MODELO FINAL (Gradient Boosting)
# =============================================================================

print(f"\nEntrenando modelo {NOMBRE_MODELO} final...")

model = GradientBoostingClassifier(
    n_estimators=200,
    learning_rate=0.1,
    max_depth=3,
    random_state=42,
)
model.fit(X_train_final, y_train_final)
print("  Entrenamiento completado.")

# =============================================================================
# PASO 5: METRICAS OFICIALES (sobre el test real, nunca visto)
# =============================================================================

y_prob = model.predict_proba(X_test)[:, 1]
y_pred = (y_prob >= THRESHOLD).astype(int)

acc  = accuracy_score(y_test, y_pred)
rec  = recall_score(y_test, y_pred)
prec = precision_score(y_test, y_pred)
f1   = f1_score(y_test, y_pred)
auc  = roc_auc_score(y_test, y_prob)

print("\n" + "=" * 55)
print(f"METRICAS OFICIALES - {NOMBRE_MODELO} (Test real | Umbral {int(THRESHOLD*100)}% | Particion {PARTICION_LABEL})")
print("=" * 55)
print(f"{'Metrica':<30} | {'Valor':<15}")
print("-" * 55)
print(f"{'Exactitud (Accuracy)':<30} | {acc:<15.4f}")
print(f"{'Sensibilidad (Recall)':<30} | {rec:<15.4f}")
print(f"{'Precision':<30} | {prec:<15.4f}")
print(f"{'F1-Score':<30} | {f1:<15.4f}")
print(f"{'ROC-AUC':<30} | {auc:<15.4f}")
print("=" * 55)

print("\nReporte de clasificacion (set de prueba):")
print(classification_report(y_test, y_pred, target_names=["Sano (0)", "Crisis (1)"]))

cm = confusion_matrix(y_test, y_pred)
print("Matriz de confusion:")
print(f"                    Predicho Sano   Predicho Crisis")
print(f"  Real Sano         {cm[0][0]:<15}  {cm[0][1]}")
print(f"  Real Crisis       {cm[1][0]:<15}  {cm[1][1]}")
print(f"\n  Crisis detectadas : {cm[1][1]} de {cm[1][0] + cm[1][1]}")
print(f"  Crisis perdidas   : {cm[1][0]}")
print(f"  Falsas alarmas    : {cm[0][1]}")

# =============================================================================
# PASO 6: GUARDAR LA MATRIZ DE CONFUSION COMO IMAGEN
# =============================================================================

plt.figure(figsize=(6, 5))
sns.heatmap(cm, annot=True, fmt="d", cmap="YlOrRd", cbar=False,
            xticklabels=["Predicho Sano", "Predicho Crisis"],
            yticklabels=["Real Sano", "Real Crisis"])
plt.title(f"Matriz de Confusion - {NOMBRE_MODELO} ({len(FEATURES)} vars, Umbral {int(THRESHOLD*100)}%)")
plt.tight_layout()
GRAPH_PATH = os.path.join(GRAPHS_DIR, "confusion_matrix_gb.png")
plt.savefig(GRAPH_PATH, dpi=150)
plt.close()
print(f"\nGrafica de la matriz de confusion guardada en -> {GRAPH_PATH}")

# =============================================================================
# PASO 7: IMPORTANCIA DE VARIABLES (del modelo final)
# =============================================================================

print("\nImportancia de variables del modelo final:")
importances = pd.Series(
    model.feature_importances_, index=FEATURES
).sort_values(ascending=False)

for feature, importance in importances.items():
    barra = "#" * int(importance * 40)
    print(f"  {feature:<18} {importance:.4f}  {barra}")

# =============================================================================
# PASO 8: VALIDACION MATEMATICA DEL UMBRAL
# =============================================================================

precisiones, recalls, umbrales_f1 = precision_recall_curve(y_test, y_prob)
f1s = 2 * (precisiones * recalls) / (precisiones + recalls + 1e-9)
mejor_umbral = umbrales_f1[f1s.argmax()]

print("\n" + "-" * 55)
print("VALIDACION MATEMATICA DEL UMBRAL (Curva Precision-Recall)")
print("-" * 55)
print(f"  Umbral optimo por F1 (matematico) : {mejor_umbral:.4f}")
print(f"  Umbral clinico elegido             : {THRESHOLD:.4f}")

# =============================================================================
# PASO 9: EXPORTAR EL MODELO
# =============================================================================

MODEL_PATH = os.path.join(MODELS_DIR, "gradient_boosting_asma.pkl")
with open(MODEL_PATH, "wb") as f:
    pickle.dump(model, f)

print(f"\nModelo exportado correctamente -> {MODEL_PATH}")

exec_time = time.time() - start_time
print(f"\n[METRICS] Tiempo total de ejecucion: {exec_time:.2f} segundos")