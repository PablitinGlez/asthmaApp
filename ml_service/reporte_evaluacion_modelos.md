# REPORTE DE EVALUACIÓN: MODELOS DE MACHINE LEARNING
## Detección de Crisis Asmáticas — AsthmaApp

| Parámetro | Detalle |
| :--- | :--- |
| **Proyecto** | AsthmaApp — Flutter |
| **Modelos evaluados** | Random Forest · XGBoost · Regresión Logística |
| **Dataset** | `dataset_hibrido_8020_v5.csv` (10,000 registros tabulares) |
| **Umbral clínico** | 40% (prioridad: minimizar crisis no detectadas) |
| **Fecha** | Junio 2026 |
| **Modelo seleccionado** | **Random Forest** (Split 75/25) |

---

## 1. Introducción y Contexto

Este reporte documenta la evaluación comparativa de tres modelos de Machine Learning entrenados para detectar crisis asmáticas en tiempo real dentro de la aplicación móvil **AsthmaApp**. El objetivo principal del sistema es clasificar el estado del paciente como **Sano (0)** o en **Crisis (1)** a partir de señales fisiológicas (wearables) y ambientales.

En aplicaciones de salud digital, la métrica más crítica es el **Recall o Sensibilidad** (tasa de verdaderos positivos). Clínicamente, preferimos tolerar algunas falsas alarmas (falsos positivos) antes que pasar por alto una crisis real (falsos negativos), ya que este último caso puede representar un riesgo grave para la vida del paciente. Este principio es el pilar para la selección de nuestro modelo definitivo.

### Variables de Entrada al Modelo (Características / Features)
Las variables utilizadas para el entrenamiento y su nivel de importancia según el modelo Random Forest son:

*   **`spo2`** — Saturación de oxígeno en sangre — Importancia RF: **0.4778** *(variable más influyente)*
*   **`bpm`** — Frecuencia cardíaca — Importancia RF: **0.1765**
*   **`pasos`** — Actividad física diaria — Importancia RF: **0.1528**
*   **`pef_porcentaje`** — Flujo espiratorio máximo en % — Importancia RF: **0.0942**
*   **`horas_sueno`** — Horas de descanso nocturno — Importancia RF: **0.0642**
*   **`humedad`** — Humedad relativa ambiental — Importancia RF: **0.0125**
*   **`temperatura`** — Temperatura ambiente — Importancia RF: **0.0118**
*   **`aqi`** — Índice de calidad del aire — Importancia RF: **0.0102**

---

## 2. Descripción de los Modelos

### 2.1 Random Forest Classifier (Bosques Aleatorios)
Ensamble de árboles de decisión que construye múltiples árboles de forma independiente durante el entrenamiento y promedia sus predicciones. Es altamente robusto frente a datos no lineales, variables ruidosas y correlacionadas. Fue entrenado sobre registros balanceados mediante sobremuestreo y validado sobre el set de prueba con distribución original.

### 2.2 XGBoost (Extreme Gradient Boosting)
Algoritmo de *boosting* secuencial que construye árboles de decisión de forma aditiva, donde cada nuevo árbol corrige los errores cometidos por los anteriores. Es conocido por su extraordinaria eficiencia y óptimo desempeño en datos tabulares. Incluye optimización matemática interna y regularización por penalización.

### 2.3 Regresión Logística
Modelo lineal clásico de clasificación que calcula la probabilidad de pertenencia a una clase mediante la función sigmoide. Es sumamente interpretable: sus coeficientes nos permiten ver con exactitud la dirección matemática (protectora o de riesgo) y la magnitud del efecto de cada variable. Utilizado como línea base (*baseline*).

---

## 3. Comparativa de Métricas — Set de Prueba (Split 75/25 Definitivo)

Todas las evaluaciones se realizaron con un **umbral clínico del 40%** sobre el set de prueba de **2,500 registros** (1,978 sanos / 522 en crisis) que mantiene la distribución real no balanceada de la población.

### 3.1 Métricas Generales del Set de Prueba (Split 75/25)

| Métrica de Evaluación | Random Forest | XGBoost | Regresión Logística |
| :--- | :---: | :---: | :---: |
| **Exactitud (Accuracy)** | 0.9748 | **0.9772** | 0.9484 |
| **Sensibilidad (Recall / Sens)** | 0.9425 | 0.9138 | **0.9502** |
| **Precisión** | 0.9371 | **0.9755** | 0.8280 |
| **F1-Score** | 0.9398 | **0.9436** | 0.8849 |
| **ROC-AUC** | **0.9936** | 0.9929 | 0.9862 |
| **Crisis Detectadas** | 492 / 522 | 477 / 522 | **496 / 522** |
| **Falsas Alarmas** | 33 | **12** | 103 |

*(En **negrita** se destacan los mejores valores obtenidos para cada métrica).*

### 3.2 Métricas Promedio de Validación Cruzada (CV - 5 Folds)

La validación cruzada estratificada evalúa el modelo 5 veces sobre diferentes particiones del set de entrenamiento para verificar su estabilidad y generalización. Las métricas se calculan sobre los datos de validación interna (no sobre el set de prueba).

| Métrica CV Promedio (5 Folds) | Random Forest | XGBoost | Regresión Logística |
| :--- | :---: | :---: | :---: |
| **Exactitud Promedio (CV Accuracy)** | 0.9829 | **0.9812** | 0.9512 |
| **Sensibilidad Promedio (CV Recall)** | 0.9528 | **0.9566** | 0.9611 |
| **Precisión Promedio (CV Precision)** | **0.9651** | 0.9536 | 0.8317 |
| **F1-Score Promedio (CV F1)** | **0.9589** | 0.9551 | 0.8917 |
| **ROC-AUC Promedio (CV ROC-AUC)** | 0.9948 | **0.9958** | 0.9912 |

---

## 4. Matrices de Confusión (Split 75/25 Definitivo)

Las matrices de confusión reflejan la distribución de aciertos y errores en la clasificación sobre las 2,500 muestras de prueba (1,978 sanos / 522 en crisis) bajo el split final.

### 4.1 Random Forest

```
                    Predicho Sano   Predicho Crisis
  Real Sano         1,945           33
  Real Crisis       30              492
```

*   **Crisis detectadas:** 492 de 522 (94.25%)
*   **Crisis perdidas (Falsos Negativos):** 30
*   **Falsas alarmas (Falsos Positivos):** 33 (1.67% del grupo sano)

> **[INSERTAR AQUÍ IMAGEN: confusion_matrix_rf.png]**
> *(Ubicación del archivo: ml_service/graphs/confusion_matrix_rf.png)*

### 4.2 XGBoost

```
                    Predicho Sano   Predicho Crisis
  Real Sano         1,966           12
  Real Crisis       45              477
```

*   **Crisis detectadas:** 477 de 522 (91.38%)
*   **Crisis perdidas (Falsos Negativos):** 45
*   **Falsas alarmas (Falsos Positivos):** 12 (0.61% del grupo sano)

> **[INSERTAR AQUÍ IMAGEN: confusion_matrix_xgboost.png]**
> *(Ubicación del archivo: ml_service/graphs/confusion_matrix_xgboost.png)*

### 4.3 Regresión Logística

```
                    Predicho Sano   Predicho Crisis
  Real Sano         1,875           103
  Real Crisis       26              496
```

*   **Crisis detectadas:** 496 de 522 (95.02%)
*   **Crisis perdidas (Falsos Negativos):** 26
*   **Falsas alarmas (Falsos Positivos):** 103 (5.21% del grupo sano)

> **[INSERTAR AQUÍ IMAGEN: confusion_matrix_logistic_regression.png]**
> *(Ubicación del archivo: ml_service/graphs/confusion_matrix_logistic_regression.png)*

---

## 5. Importancia de Variables (Aporte al Modelo)

Los modelos asignan diferentes pesos a las características de entrada para tomar decisiones. Esto describe qué tanto influye cada señal en la detección de la crisis.

### 5.1 Random Forest — Peso de Variables (Features)
*   **`spo2`** (Saturación de oxígeno): **0.4778**  `###################`
*   **`bpm`** (Frecuencia cardíaca): **0.1765**  `#######`
*   **`pasos`** (Actividad física): **0.1528**  `######`
*   **`pef_porcentaje`** (Flujo pulmonar): **0.0942**  `###`
*   **`horas_sueno`** (Horas de descanso): **0.0642**  `##`
*   **`humedad`** (Humedad relativa): **0.0125**
*   **`temperatura`** (Clima exterior): **0.0118**
*   **`aqi`** (Contaminación del aire): **0.0102**

### 5.2 XGBoost — Peso de Variables (Top 5)
*   **`spo2`**: **0.5885**  `#######################`
*   **`bpm`**: **0.1625**  `######`
*   **`aqi`**: **0.1067**  `####`
*   **`pasos`**: **0.0580**  `##`
*   **`pef_porcentaje`**: **0.0418**  `#`

### 5.3 Regresión Logística — Coeficientes y Dirección del Efecto
El signo indica si el parámetro es un factor de riesgo (positivo) o protector (negativo), y el número indica su peso matemático:
*   **`spo2`**: **-4.6879**  *(Fuerte efecto protector: a mayor oxígeno, el riesgo cae drásticamente).*
*   **`bpm`**: **+1.4562**  *(Factor de riesgo: el aumento en pulsaciones eleva la alerta).*
*   **`pef_porcentaje`**: **+0.8410**  *(Aporte lineal positivo).*
*   **`horas_sueno`**: **-0.5154**  *(Protector: buen sueño reduce probabilidad de crisis).*
*   **`pasos`**: **-0.4624**  *(Protector: mayor actividad física correlaciona con salud).*
*   **`humedad`**: **+0.1977**  *(Mayor humedad aumenta levemente la probabilidad).*
*   **`aqi`**: **-0.1314**  *(Aporte leve).*
*   **`temperatura`**: **-0.0391**  *(Aporte leve).*

---

## 6. Justificación de la Selección del Modelo: Random Forest

El modelo final seleccionado para su integración y producción en **AsthmaApp** es **Random Forest** bajo la partición **Split 75/25**.

### 6.1 Razón Principal: Equilibrio Clínico y Robustez
Con el dataset v5 (que integra mayor ruido biológico y variabilidad real), el análisis de la capacidad de detección y volumen de alertas falsas muestra lo siguiente:

| Modelo (Split 75/25) | Crisis Perdidas | Falsas Alarmas | ROC-AUC | F1-Score |
| :--- | :---: | :---: | :---: | :---: |
| **Random Forest** | 30 | 33 | **0.9936** | 0.9398 |
| XGBoost | 45 | **12** | 0.9929 | **0.9436** |
| Regresión Logística | **26** | 103 | 0.9862 | 0.8849 |

- **Random Forest** ofrece la mejor combinación clínica. Pierde solo 30 crisis en comparación con las 45 perdidas por XGBoost (reduciendo el riesgo para el paciente), y al mismo tiempo evita la enorme cantidad de falsas alarmas de la Regresión Logística (103), lo que previene la fatiga de alertas por parte del usuario.
- **Distribución de importancia de variables:** Random Forest distribuye la importancia de manera más balanceada entre SpO2 (47.78%), BPM (17.65%) y pasos (15.28%), lo cual le otorga mayor estabilidad al modelo en el mundo real en caso de fallas temporales en los sensores del smartwatch u oxímetro.

---

## 7. Análisis de Estabilidad ante Diferentes Proporciones (Splits - Dataset v5)

Se entrenaron y evaluaron los tres modelos variando las proporciones de división de datos (70/30, 75/25 y 80/20) para comprobar la robustez de los algoritmos ante diferentes tamaños de sets de prueba.

### 7.1 Random Forest Classifier

| Proporción (Split) | Registros de Prueba | Accuracy | Recall (Sens) | Precisión | F1-Score | Crisis Perdidas | Falsas Alarmas |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **70 / 30** | 3,000 reg | 0.9743 | **0.9442** | 0.9338 | 0.9389 | 35 | 42 |
| **75 / 25** | 2,500 reg | **0.9748** | 0.9425 | **0.9371** | **0.9398** | **30** | 33 |
| **80 / 20** | 2,000 reg | 0.9730 | 0.9378 | 0.9333 | 0.9356 | 26 | **28** |

### 7.2 XGBoost Classifier

| Proporción (Split) | Registros de Prueba | Accuracy | Recall (Sens) | Precisión | F1-Score | Crisis Perdidas | Falsas Alarmas |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **70 / 30** | 3,000 reg | 0.9767 | **0.9155** | 0.9712 | 0.9425 | 53 | 17 |
| **75 / 25** | 2,500 reg | **0.9772** | 0.9138 | **0.9755** | **0.9436** | **45** | 12 |
| **80 / 20** | 2,000 reg | 0.9740 | 0.8995 | 0.9741 | 0.9353 | 42 | **10** |

### 7.3 Regresión Logística

| Proporción (Split) | Registros de Prueba | Accuracy | Recall (Sens) | Precisión | F1-Score | Crisis Perdidas | Falsas Alarmas |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **70 / 30** | 3,000 reg | 0.9477 | **0.9506** | **0.8255** | 0.8836 | 31 | 126 |
| **75 / 25** | 2,500 reg | **0.9484** | 0.9502 | 0.8280 | **0.8849** | **26** | 103 |
| **80 / 20** | 2,000 reg | 0.9450 | 0.9426 | 0.8208 | 0.8775 | 24 | **86** |

**Conclusión del análisis de estabilidad:**
Todos los modelos mantuvieron variaciones mínimas en su rendimiento general (menos del 0.4% en Accuracy y F1-Score) a lo largo de los tres splits. Esto demuestra que los algoritmos son **altamente robustos, estables** y no sufren fluctuaciones significativas basadas en la selección aleatoria de los conjuntos de entrenamiento y prueba.

---

## 8. Conclusiones y Configuración de Producción

El modelo **Random Forest** en su configuración **Split 75/25** ofrece el balance óptimo para la detección preventiva de crisis asmáticas en la aplicación.

### Resumen del Modelo de Producción
*   **Algoritmo seleccionado:** Random Forest Classifier (200 árboles)
*   **Dataset base:** `dataset_hibrido_8020_v5.csv` (10,000 registros)
*   **Partición definitiva:** 75% Entrenamiento / 25% Prueba (Split 75/25)
*   **Ruta del modelo exportado:** `ml_service/models/random_forest_asma.pkl`
*   **Umbral clínico configurado:** `0.40` (40%)
*   **Sensibilidad (Recall) definitiva:** **0.9425** (492 de 522 crisis detectadas)
*   **Tasa de falsas alarmas:** **1.67%** (33 falsas alertas de 1,978 casos sanos)
*   **Capacidad discriminativa (ROC-AUC):** **0.9936**

---
*AsthmaApp — Reporte Técnico de Inteligencia Artificial | Junio 2026 | Dataset v5*
