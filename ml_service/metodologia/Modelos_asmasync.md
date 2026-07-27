# Modelos ASMAsync — Contenido completo del Excel

> Convertido desde `1784841027854_Modelos_asmasync.xlsx` (9 hojas). Todo el contenido de cada celda con datos se conserva a continuación, organizado por hoja y por bloque/tabla tal como aparece en el archivo original.

---

## Hoja 1: random_forest

### Modelo Final - Random Forest (Partición 80-20, umbral clínico 40%)

### Tabla Comparativa - Validación Cruzada (CV)
Promedio de métricas por partición (70-30 / 75-25 / 80-20) y número de folds (3 / 5 / 10)

| Partición | Folds CV | Accuracy | Recall | Precision | F1-Score | AUC |
|---|---|---|---|---|---|---|
| 70-30 | 3 | 0.9817 | 0.9514 | 0.9609 | 0.9561 | 0.9932 |
| 70-30 | 5 | 0.9831 | 0.9542 | 0.9649 | 0.9594 | 0.9942 |
| 70-30 | 10 | 0.9829 | 0.9535 | 0.9642 | 0.9587 | 0.9949 |
| 75-25 | 3 | 0.9827 | 0.9534 | 0.9633 | 0.9583 | 0.9945 |
| 75-25 | 5 | 0.9829 | 0.9528 | 0.9651 | 0.9589 | 0.9948 |
| 75-25 | 10 | 0.9827 | 0.9521 | 0.9645 | 0.9582 | 0.9944 |
| 80-20 | 3 | 0.9833 | 0.9539 | 0.9656 | 0.9597 | 0.9943 |
| 80-20 | 5 | 0.9826 | 0.9527 | 0.9639 | 0.9582 | 0.9937 |
| 80-20 | 10 | 0.9834 | 0.9545 | 0.9658 | 0.9599 | 0.9947 |

### Tabla complementaria - Evaluación sobre el set de prueba

| Partición | Accuracy | Recall | Precision | F1-Score | AUC |
|---|---|---|---|---|---|
| 70-30 | 0.9743 | 0.9442 | 0.9338 | 0.9389 | 0.9925 |
| 75-25 | 0.9748 | 0.9425 | 0.9371 | 0.9398 | 0.9936 |
| 80-20 | 0.973 | 0.9378 | 0.9333 | 0.9356 | 0.9912 |

### Umbral de decisión

| Umbral | Valor |
|---|---|
| Óptimo matemático (por F1) | 0.652 |
| Clínico elegido (usado en el modelo) | 0.4 |

### Variables usadas y descartadas en cada paso

| Paso | Detalle |
|---|---|
| 8 variables (inicio) | spo2, bpm, pasos, pef_porcentaje, horas_sueno, humedad, temperatura, aqi |
| 5 variables | spo2, bpm, pasos, pef_porcentaje, horas_sueno (se quitaron: humedad, temperatura, aqi) |
| 4 variables | spo2, bpm, pasos, pef_porcentaje (se quitó: horas_sueno) |
| 3 variables (final del recorte) | spo2, bpm, pasos (se quitó: pef_porcentaje) |

### Tabla Comparativa Oficial - Selección de Variables

| # Variables | Variables incluidas | Accuracy | Recall | Precision | F1-Score | AUC |
|---|---|---|---|---|---|---|
| 8 | spo2, bpm, pasos, pef_porcentaje, horas_sueno, humedad, temperatura, aqi | 0.973 | 0.9378 | 0.9333 | 0.9356 | 0.9912 |
| 5 | spo2, bpm, pasos, pef_porcentaje, horas_sueno | 0.976 | 0.9354 | 0.949 | 0.9422 | 0.9924 |
| 4 | spo2, bpm, pasos, pef_porcentaje | 0.972 | 0.9306 | 0.9351 | 0.9329 | 0.9924 |
| 3 | spo2, bpm, pasos | 0.972 | 0.933 | 0.933 | 0.933 | 0.9879 |

### Importancia de variables — Paso 1: 8 variables (todas)

| Variable | Importancia |
|---|---|
| spo2 | 0.48 |
| bpm | 0.1787 |
| pasos | 0.1481 |
| pef_porcentaje | 0.0865 |
| horas_sueno | 0.0694 |
| humedad | 0.0132 |
| temperatura | 0.0124 |
| aqi | 0.0117 |

### Importancia de variables — Paso 2: 5 variables
Se quitaron: humedad, temperatura, aqi

| Variable | Importancia |
|---|---|
| spo2 | 0.558 |
| bpm | 0.1714 |
| pasos | 0.1464 |
| pef_porcentaje | 0.0686 |
| horas_sueno | 0.0557 |

### Importancia de variables — Paso 3: 4 variables
Se quitó: horas_sueno

| Variable | Importancia |
|---|---|
| spo2 | 0.647 |
| bpm | 0.1857 |
| pasos | 0.1094 |
| pef_porcentaje | 0.0579 |

### Importancia de variables — Paso 4: 3 variables
Se quitó: pef_porcentaje

| Variable | Importancia |
|---|---|
| spo2 | 0.5567 |
| bpm | 0.2342 |
| pasos | 0.2091 |

---

## Hoja 2: Comparativa

### Tabla Comparativa - Modelos
Comparación de métricas oficiales (set de prueba real) entre los 7 modelos entrenados

| Modelo | Accuracy | Recall | Precision | F1-Score | AUC / ROC-AUC |
|---|---|---|---|---|---|
| Random Forest | 0.973 | 0.9378 | 0.9333 | 0.9356 | 0.9912 |
| XGBoost | 0.9745 | 0.9378 | 0.94 | 0.9389 | 0.9923 |
| Regresión Logística | 0.946 | 0.9426 | 0.8243 | 0.8795 | 0.985 |
| Decision Tree | 0.961 | 0.9091 | 0.9048 | 0.9069 | 0.9587 |
| Gradient Boosting | 0.971 | 0.9378 | 0.9245 | 0.9311 | 0.9922 |
| SVM | 0.9665 | 0.9258 | 0.9149 | 0.9203 | 0.9869 |
| KNN | 0.9465 | 0.945 | 0.8246 | 0.8807 | 0.9799 |

### Tabla Comparativa - Matriz de Confusión

| Modelo | Real Sano → Pred. Sano (VN) | Real Sano → Pred. Crisis (FP) | Real Crisis → Pred. Sano (FN) | Real Crisis → Pred. Crisis (VP) | Crisis Detectadas | Crisis Pérdidas | Falsas Alarmas |
|---|---|---|---|---|---|---|---|
| Random Forest | 1554 | 28 | 26 | 392 | 392 de 418 | 26 | 28 |
| XGBoost | 1557 | 25 | 26 | 392 | 392 de 418 | 26 | 25 |
| Regresión Logística | 1498 | 84 | 24 | 394 | 394 de 418 | 24 | 84 |
| Decision Tree | 1542 | 40 | 38 | 380 | 380 de 418 | 38 | 40 |
| Gradient Boosting | 1550 | 32 | 26 | 392 | 392 de 418 | 26 | 32 |
| SVM | 1546 | 36 | 31 | 387 | 387 de 418 | 31 | 36 |
| KNN | 1498 | 84 | 23 | 395 | 395 de 418 | 23 | 84 |

### Tabla Comparativa - Falsos Positivos y Falsos Negativos

| Modelo | Falsos Positivos (FP) | Falsos Negativos (FN) | Tasa Falsos Positivos (FPR) | Tasa Falsos Negativos (FNR) | Especificidad | Total Errores | % Error sobre 2,000 |
|---|---|---|---|---|---|---|---|
| Random Forest | 28 | 26 | 0.017699115044247787 | 0.06220095693779904 | 0.9823008849557522 | 54 | 0.027 |
| XGBoost | 25 | 26 | 0.01580278128950695 | 0.06220095693779904 | 0.984197218710493 | 51 | 0.0255 |
| Regresión Logística | 84 | 24 | 0.05309734513274336 | 0.05741626794258373 | 0.9469026548672567 | 108 | 0.054 |
| Decision Tree | 40 | 38 | 0.025284450063211124 | 0.09090909090909091 | 0.9747155499367889 | 78 | 0.039 |
| Gradient Boosting | 32 | 26 | 0.020227560050568902 | 0.06220095693779904 | 0.9797724399494311 | 58 | 0.029 |
| SVM | 36 | 31 | 0.022756005056890013 | 0.07416267942583732 | 0.97724399494311 | 67 | 0.0335 |
| KNN | 84 | 23 | 0.05309734513274336 | 0.05502392344497608 | 0.9469026548672567 | 107 | 0.0535 |

---

## Hoja 3: xgboost

### Modelo: XGBoost

### Validación Cruzada (CV) - Set de entrenamiento

| Métrica | Valor |
|---|---|
| Accuracy | 0.9826 |
| Recall | 0.9509 |
| Precision | 0.9657 |
| F1-Score | 0.958 |
| AUC | 0.9959 |

### Métricas Oficiales - Set de Prueba Real (nunca visto)

| Métrica | Valor |
|---|---|
| Accuracy | 0.9745 |
| Recall | 0.9378 |
| Precision | 0.94 |
| F1-Score | 0.9389 |
| AUC | 0.9923 |

### Matriz de Confusión

| | Predicho: Sano | Predicho: Crisis |
|---|---|---|
| Real: Sano | 1557 | 25 |
| Real: Crisis | 26 | 392 |

- Crisis detectadas: 392 de 418
- Crisis pérdidas: 26
- Falsas alarmas: 25

### Importancia de Variables

| Variable | Importancia |
|---|---|
| spo2 | 0.6733 |
| bpm | 0.1441 |
| pasos | 0.0769 |
| pef_porcentaje | 0.0679 |
| horas_sueno | 0.0377 |

### Validación del Umbral y Tiempo de Ejecución

| Concepto | Valor |
|---|---|
| Umbral óptimo (matemático, por F1) | 0.7854 |
| Umbral clínico elegido | 0.4 |
| Tiempo de ejecución (segundos) | 8.32 |

### Tabla Comparativa - Validación Cruzada (CV) - XGBoost
Promedio de métricas por partición (70-30 / 75-25 / 80-20) y número de folds (3 / 5 / 10)

| Partición | Folds CV | Accuracy | Recall | Precision | F1-Score | AUC |
|---|---|---|---|---|---|---|
| 70-30 | 3 | 0.9819 | 0.9521 | 0.9607 | 0.9564 | 0.995 |
| 70-30 | 5 | 0.9826 | 0.9528 | 0.9634 | 0.958 | 0.9958 |
| 70-30 | 10 | 0.982 | 0.9535 | 0.9602 | 0.9567 | 0.996 |
| 75-25 | 3 | 0.9817 | 0.9534 | 0.9589 | 0.9561 | 0.9958 |
| 75-25 | 5 | 0.9821 | 0.9521 | 0.962 | 0.957 | 0.9961 |
| 75-25 | 10 | 0.9812 | 0.9521 | 0.9578 | 0.9549 | 0.9958 |
| 80-20 | 3 | 0.983 | 0.9551 | 0.9633 | 0.9592 | 0.9956 |
| 80-20 | 5 | 0.9811 | 0.9509 | 0.9586 | 0.9547 | 0.9954 |

---

## Hoja 4: Regresión Logística

### Modelo: Regresión Logística

### Validación Cruzada (CV) - Set de entrenamiento

| Métrica | Valor |
|---|---|
| Accuracy | 0.9629 |
| Recall | 0.9593 |
| Precision | 0.8756 |
| F1-Score | 0.9153 |
| AUC | 0.9911 |

### Métricas Oficiales - Set de Prueba Real (nunca visto)

| Métrica | Valor |
|---|---|
| Accuracy | 0.946 |
| Recall | 0.9426 |
| Precision | 0.8243 |
| F1-Score | 0.8795 |
| AUC | 0.985 |

### Matriz de Confusión

| | Predicho: Sano | Predicho: Crisis |
|---|---|---|
| Real: Sano | 1498 | 84 |
| Real: Crisis | 24 | 394 |

- Crisis detectadas: 394 de 418
- Crisis pérdidas: 24
- Falsas alarmas: 84

### Coeficientes de Variables (impacto en el riesgo)

| Variable | Coeficiente |
|---|---|
| spo2 | -4.7147 |
| bpm | 1.4361 |
| pef_porcentaje | 0.8505 |
| horas_sueno | -0.4954 |
| pasos | -0.4351 |

### Validación del Umbral y Tiempo de Ejecución

| Concepto | Valor |
|---|---|
| Umbral óptimo (matemático, por F1) | 0.7722 |
| Umbral clínico elegido | 0.4 |
| Tiempo de ejecución (segundos) | 1.88 |

---

## Hoja 5: Decision Tree

### Modelo: Decision Tree

### Validación Cruzada (CV) - Set de entrenamiento

| Métrica | Valor |
|---|---|
| Accuracy | 0.9711 |
| Recall | 0.9497 |
| Precision | 0.9161 |
| F1-Score | 0.9323 |
| AUC | 0.9746 |

### Métricas Oficiales - Set de Prueba Real (nunca visto)

| Métrica | Valor |
|---|---|
| Accuracy | 0.961 |
| Recall | 0.9091 |
| Precision | 0.9048 |
| F1-Score | 0.9069 |
| AUC | 0.9587 |

### Matriz de Confusión

| | Predicho: Sano | Predicho: Crisis |
|---|---|---|
| Real: Sano | 1542 | 40 |
| Real: Crisis | 38 | 380 |

- Crisis detectadas: 380 de 418
- Crisis pérdidas: 38
- Falsas alarmas: 40

### Importancia de Variables

| Variable | Importancia |
|---|---|
| spo2 | 0.8604 |
| pasos | 0.0609 |
| pef_porcentaje | 0.032 |
| bpm | 0.0265 |
| horas_sueno | 0.0202 |

### Validación del Umbral y Tiempo de Ejecución

| Concepto | Valor |
|---|---|
| Umbral óptimo (matemático, por F1) | 0.8571 |
| Umbral clínico elegido | 0.4 |
| Tiempo de ejecución (segundos) | 3.5 |

---

## Hoja 6: Gradient Boosting

### Modelo: Gradient Boosting
Partición 80-20 | CV = 10 folds | Umbral clínico = 40% | Variables: spo2, bpm, pasos, pef_porcentaje, horas_sueno

### Validación Cruzada (CV) - Set de entrenamiento

| Métrica | Valor |
|---|---|
| Accuracy | 0.9796 |
| Recall | 0.9557 |
| Precision | 0.9476 |
| F1-Score | 0.9514 |
| AUC | 0.9952 |

### Métricas Oficiales - Set de Prueba Real (nunca visto)

| Métrica | Valor |
|---|---|
| Accuracy | 0.971 |
| Recall | 0.9378 |
| Precision | 0.9245 |
| F1-Score | 0.9311 |
| AUC | 0.9922 |

### Matriz de Confusión

| | Predicho: Sano | Predicho: Crisis |
|---|---|---|
| Real: Sano | 1550 | 32 |
| Real: Crisis | 26 | 392 |

- Crisis detectadas: 392 de 418
- Crisis pérdidas: 26
- Falsas alarmas: 32

### Importancia de Variables

| Variable | Importancia |
|---|---|
| spo2 | 0.8835 |
| pasos | 0.0488 |
| bpm | 0.036 |
| pef_porcentaje | 0.0259 |
| horas_sueno | 0.0058 |

### Validación del Umbral y Tiempo de Ejecución

| Concepto | Valor |
|---|---|
| Umbral óptimo (matemático, por F1) | 0.7429 |
| Umbral clínico elegido | 0.4 |
| Tiempo de ejecución (segundos) | 47.32 |

### Tabla Comparativa - Validación Cruzada (CV) - Gradient Boosting

| Partición | Folds CV | Accuracy | Recall | Precision | F1-Score | AUC |
|---|---|---|---|---|---|---|
| 70-30 | 3 | 0.9816 | 0.9528 | 0.9587 | 0.9557 | 0.9951 |
| 70-30 | 5 | 0.9803 | 0.9528 | 0.953 | 0.9528 | 0.9957 |
| 70-30 | 10 | 0.9807 | 0.9535 | 0.9544 | 0.9538 | 0.9956 |
| 75-25 | 3 | 0.9812 | 0.954 | 0.9559 | 0.955 | 0.9958 |
| 75-25 | 5 | 0.9812 | 0.9534 | 0.9565 | 0.9549 | 0.9956 |
| 75-25 | 10 | 0.9801 | 0.9515 | 0.9535 | 0.9524 | 0.9954 |
| 80-20 | 3 | 0.9814 | 0.9527 | 0.9579 | 0.9553 | 0.9953 |
| 80-20 | 5 | 0.981 | 0.9557 | 0.9536 | 0.9546 | 0.9955 |

---

## Hoja 7: SVM

### Modelo Final - SVM (Partición 80-20, umbral clínico 40%)
Entrenado sobre set balanceado (12,658 registros) y evaluado en 2,000 registros de prueba

(Incluye una gráfica de matriz de confusión en el Excel original, no reproducible en Markdown)

### Métricas del modelo final

| Métrica | Valor |
|---|---|
| Accuracy (Exactitud) | 96.65% |
| Recall (Sensibilidad) | 92.58% |
| Precision | 91.49% |
| F1-Score | 92.03% |
| ROC-AUC | 98.69% |

### Matriz de confusión

| | Predicho: Sano | Predicho: Crisis | Total |
|---|---|---|---|
| Real: Sano | 1546 | 36 | 1582 |
| Real: Crisis | 31 | 387 | 418 |

Crisis detectadas: 387 de 418 | Crisis pérdidas: 31 | Falsas alarmas: 36

### Importancia de variables

| Variable | Importancia |
|---|---|
| SpO2 (saturación de oxígeno) | 56.26% |
| BPM (ritmo cardíaco) | 20.46% |
| Pasos | 14.86% |
| PEF % (flujo espiratorio máximo) | 6.55% |
| Horas de sueño | 1.87% |

### Mejores hiperparámetros (GridSearchCV, cv=10)

| Hiperparámetro | Valor |
|---|---|
| C | 100 |
| gamma | 0.5 |
| kernel | rbf |

### Umbral de decisión

| Umbral | Valor |
|---|---|
| Clínico elegido (usado en evaluación) | 40.00% |

---

## Hoja 8: KNN

### Modelo Final - KNN (Partición 80-20, umbral clínico 40%)
Entrenado sobre set balanceado (12,658 registros) y evaluado en 2,000 registros de prueba

(Incluye una gráfica de matriz de confusión en el Excel original, no reproducible en Markdown)

### Métricas del modelo final

| Métrica | Valor |
|---|---|
| Accuracy (Exactitud) | 94.65% |
| Recall (Sensibilidad) | 94.50% |
| Precision | 82.46% |
| F1-Score | 88.07% |
| ROC-AUC | 97.99% |

### Matriz de confusión

| | Predicho: Sano | Predicho: Crisis | Total |
|---|---|---|---|
| Real: Sano | 1498 | 84 | 1582 |
| Real: Crisis | 23 | 395 | 418 |

Crisis detectadas: 395 de 418 | Crisis pérdidas: 23 | Falsas alarmas: 84

### Importancia de variables

| Variable | Importancia |
|---|---|
| SpO2 (saturación de oxígeno) | 73.54% |
| BPM (ritmo cardíaco) | 11.97% |
| PEF % (flujo espiratorio máximo) | 6.18% |
| Pasos | 6.03% |
| Horas de sueño | 2.27% |

### Mejores hiperparámetros (GridSearchCV, cv=10)

| Hiperparámetro | Valor |
|---|---|
| metric | manhattan |
| n_neighbors | 15 |
| weights | distance |

### Umbral de decisión

| Umbral | Valor |
|---|---|
| Clínico elegido (usado en evaluación) | 40.00% |

---

## Hoja 9: Proceso Seleccion Modelo

### Proceso de Selección del Modelo - Comparación por Partición y Folds (Random Forest, XGBoost, Gradient Boosting)

| Modelo | Partición | Folds CV | Accuracy | Recall | Precision | F1-Score | AUC |
|---|---|---|---|---|---|---|---|
| Random Forest | 70-30 | 3 | 0.9817 | 0.9514 | 0.9609 | 0.9561 | 0.9932 |
| Random Forest | 70-30 | 5 | 0.9831 | 0.9542 | 0.9649 | 0.9594 | 0.9942 |
| Random Forest | 70-30 | 10 | 0.9829 | 0.9535 | 0.9642 | 0.9587 | 0.9949 |
| Random Forest | 75-25 | 3 | 0.9827 | 0.9534 | 0.9633 | 0.9583 | 0.9945 |
| Random Forest | 75-25 | 5 | 0.9829 | 0.9528 | 0.9651 | 0.9589 | 0.9948 |
| Random Forest | 75-25 | 10 | 0.9827 | 0.9521 | 0.9645 | 0.9582 | 0.9944 |
| Random Forest | 80-20 | 3 | 0.9833 | 0.9539 | 0.9656 | 0.9597 | 0.9943 |
| Random Forest | 80-20 | 5 | 0.9826 | 0.9527 | 0.9639 | 0.9582 | 0.9937 |
| Random Forest | 80-20 | 10 | 0.9834 | 0.9545 | 0.9658 | 0.9599 | 0.9947 |
| XGBoost | 70-30 | 3 | 0.9819 | 0.9521 | 0.9607 | 0.9564 | 0.995 |
| XGBoost | 70-30 | 5 | 0.9826 | 0.9528 | 0.9634 | 0.958 | 0.9958 |
| XGBoost | 70-30 | 10 | 0.982 | 0.9535 | 0.9602 | 0.9567 | 0.996 |
| XGBoost | 75-25 | 3 | 0.9817 | 0.9534 | 0.9589 | 0.9561 | 0.9958 |
| XGBoost | 75-25 | 5 | 0.9821 | 0.9521 | 0.962 | 0.957 | 0.9961 |
| XGBoost | 75-25 | 10 | 0.9812 | 0.9521 | 0.9578 | 0.9549 | 0.9958 |
| XGBoost | 80-20 | 3 | 0.983 | 0.9551 | 0.9633 | 0.9592 | 0.9956 |
| XGBoost | 80-20 | 5 | 0.9811 | 0.9509 | 0.9586 | 0.9547 | 0.9954 |
| XGBoost | 80-20 | 10 | 0.9811 | 0.9509 | 0.9584 | 0.9546 | 0.9957 |
| Gradient Boosting | 70-30 | 3 | 0.9816 | 0.9528 | 0.9587 | 0.9557 | 0.9951 |
| Gradient Boosting | 70-30 | 5 | 0.9803 | 0.9528 | 0.953 | 0.9528 | 0.9957 |
| Gradient Boosting | 70-30 | 10 | 0.9807 | 0.9535 | 0.9544 | 0.9538 | 0.9956 |
| Gradient Boosting | 75-25 | 3 | 0.9812 | 0.954 | 0.9559 | 0.955 | 0.9958 |
| Gradient Boosting | 75-25 | 5 | 0.9812 | 0.9534 | 0.9565 | 0.9549 | 0.9956 |
| Gradient Boosting | 75-25 | 10 | 0.9801 | 0.9515 | 0.9535 | 0.9524 | 0.9954 |
| Gradient Boosting | 80-20 | 3 | 0.9814 | 0.9527 | 0.9579 | 0.9553 | 0.9953 |
| Gradient Boosting | 80-20 | 5 | 0.981 | 0.9557 | 0.9536 | 0.9546 | 0.9955 |
| Gradient Boosting | 80-20 | 10 | 0.9796 | 0.9557 | 0.9476 | 0.9514 | 0.9952 |

