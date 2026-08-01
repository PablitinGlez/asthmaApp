import os
import pickle
import pandas as pd
import numpy as np
from xgboost import XGBClassifier
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

DATASET_PATH = r"C:\Users\gonza\dataset.csv"
MODELS_DIR = "ml_service/modelo"
GRAPHS_DIR = "ml_service/graphs"
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(GRAPHS_DIR, exist_ok=True)

FEATURES = ["spo2", "bpm", "pasos", "horas_sueno", "pef_porcentaje", "aqi", "humedad", "temperatura"]
TARGET = "crisis"
TEST_SIZE = 0.30
N_FOLDS = 3
THRESHOLD = 0.40

df = pd.read_csv(DATASET_PATH)
X = df[FEATURES]
y = df[TARGET]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=TEST_SIZE, random_state=42, stratify=y
)


def balancear(df_in):
    sanos = df_in[df_in[TARGET] == 0]
    crisis = df_in[df_in[TARGET] == 1]
    crisis_over = crisis.sample(len(sanos), replace=True, random_state=42)
    return pd.concat([sanos, crisis_over], axis=0).sample(frac=1, random_state=42)


cv = StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=42)
cv_accs, cv_recs, cv_precs, cv_f1s, cv_aucs = [], [], [], [], []

for train_idx, val_idx in cv.split(X_train, y_train):
    X_tr_fold, y_tr_fold = X_train.iloc[train_idx], y_train.iloc[train_idx]
    X_val_fold, y_val_fold = X_train.iloc[val_idx], y_train.iloc[val_idx]

    fold_train = balancear(pd.concat([X_tr_fold, y_tr_fold], axis=1))
    X_tr_fold_final = fold_train[FEATURES]
    y_tr_fold_final = fold_train[TARGET]

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

print(f"Accuracy CV: {np.mean(cv_accs):.4f}")
print(f"Recall CV: {np.mean(cv_recs):.4f}")
print(f"Precision CV: {np.mean(cv_precs):.4f}")
print(f"F1 CV: {np.mean(cv_f1s):.4f}")
print(f"AUC CV: {np.mean(cv_aucs):.4f}")

train_final = balancear(pd.concat([X_train, y_train], axis=1))
X_train_final = train_final[FEATURES]
y_train_final = train_final[TARGET]

model = XGBClassifier(
    n_estimators=200,
    max_depth=4,
    subsample=0.8,
    colsample_bytree=0.8,
    min_child_weight=5,
    learning_rate=0.1,
    random_state=42,
    n_jobs=-1,
    eval_metric="logloss",
)
model.fit(X_train_final, y_train_final)

y_prob = model.predict_proba(X_test)[:, 1]
y_pred = (y_prob >= THRESHOLD).astype(int)

acc = accuracy_score(y_test, y_pred)
rec = recall_score(y_test, y_pred)
prec = precision_score(y_test, y_pred)
f1 = f1_score(y_test, y_pred)
auc = roc_auc_score(y_test, y_prob)

print(f"Accuracy: {acc:.4f}")
print(f"Recall: {rec:.4f}")
print(f"Precision: {prec:.4f}")
print(f"F1: {f1:.4f}")
print(f"AUC: {auc:.4f}")

print(classification_report(y_test, y_pred, target_names=["Sano", "Crisis"]))

cm = confusion_matrix(y_test, y_pred)
print(f"Real Sano - Predicho Sano: {cm[0][0]}, Predicho Crisis: {cm[0][1]}")
print(f"Real Crisis - Predicho Sano: {cm[1][0]}, Predicho Crisis: {cm[1][1]}")

plt.figure(figsize=(6, 5))
sns.heatmap(cm, annot=True, fmt="d", cmap="YlOrRd", cbar=False,
            xticklabels=["Predicho Sano", "Predicho Crisis"],
            yticklabels=["Real Sano", "Real Crisis"])
plt.title("Matriz de Confusion - XGBoost")
plt.tight_layout()
plt.savefig(os.path.join(GRAPHS_DIR, "confusion_matrix_xgboost.png"), dpi=150)
plt.close()

importances = pd.Series(model.feature_importances_, index=FEATURES).sort_values(ascending=False)
for feature, importance in importances.items():
    print(f"{feature}: {importance:.4f}")

with open(os.path.join(MODELS_DIR, "xgboost_asma.pkl"), "wb") as f:
    pickle.dump(model, f)