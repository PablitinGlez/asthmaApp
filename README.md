# 🫁 Reporte de Entrenamiento y Selección de Modelo: Predictor de Asma

Este documento detalla la evaluación comparativa de tres algoritmos de Machine Learning entrenados para predecir crisis de asma severas. El modelo final seleccionado fue integrado en la API de producción.

## 📊 1. Resumen del Dataset
El entrenamiento se realizó sobre un **Dataset Híbrido** de 10,000 registros, compuesto por:
- **1,657 registros clínicos reales** provenientes del estudio AAMOS-00 (Universidad de Edimburgo).
- **8,343 registros sintéticos** generados algorítmicamente respetando estrictamente los umbrales fisiológicos de la guía internacional **GINA 2023** (Global Initiative for Asthma).
- **Balanceo de Clases:** Se aplicó sobremuestreo (Oversampling/SMOTE) únicamente en el set de entrenamiento (80%) para equilibrar la clase minoritaria (crisis), dejando el set de prueba (20%) con la distribución real inalterada para una evaluación honesta.

---

## 📈 2. Comparativa de Modelos (Evaluación en Set de Prueba)
Todos los modelos fueron evaluados utilizando un **Umbral Clínico del 30% (0.30)** en lugar del umbral matemático estándar (0.50). Esto se decidió bajo el principio médico de priorizar la sensibilidad (Recall) para evitar falsos negativos a toda costa.

### Modelo A: XGBoost (Gradient Boosting)
XGBoost demostró ser el modelo matemáticamente más preciso y con mejor control de falsas alarmas, pero falló en detectar ciertas crisis atípicas.
- **Accuracy (Exactitud):** 99.30%
- **F1-Score:** 98.24%
- **Rendimiento Clínico:**
  - Crisis detectadas: 391 / 400
  - 🚨 **Crisis perdidas (Falsos Negativos): 9**
  - Falsas alarmas (Falsos Positivos): 5

### Modelo B: Regresión Logística
Un modelo más conservador y lineal. Aumentó la detección de crisis frente a XGBoost, pero disparó la tasa de falsas alarmas drásticamente.
- **Accuracy (Exactitud):** 97.50%
- **F1-Score:** 94.08%
- **Rendimiento Clínico:**
  - Crisis detectadas: 397 / 400
  - 🚨 **Crisis perdidas (Falsos Negativos): 3**
  - Falsas alarmas (Falsos Positivos): 47

### Modelo C: Random Forest (Modelo Ganador 🏆)
Random Forest logró el equilibrio perfecto. Sacrificó un porcentaje mínimo de exactitud general a cambio de lograr una Sensibilidad (Recall) perfecta, garantizando la seguridad del paciente.
- **Accuracy (Exactitud):** 98.30%
- **F1-Score:** 95.92%
- **Rendimiento Clínico:**
  - Crisis detectadas: 400 / 400
  - ✅ **Crisis perdidas (Falsos Negativos): 0**
  - Falsas alarmas (Falsos Positivos): 34

---

## ⚖️ 3. Justificación de la Selección (Random Forest)

A pesar de que el algoritmo **XGBoost** presentó métricas generales superiores (99.30% de Accuracy contra el 98.30% de Random Forest) y tuvo menos falsas alarmas (5 contra 34), la decisión técnica y médica fue **seleccionar Random Forest para el entorno de producción**.

**El argumento clínico:**
En un sistema de soporte vital o monitoreo médico como lo es el asma severo, los errores no tienen el mismo peso:
1. **Falso Positivo (Falsa Alarma):** El paciente recibe una alerta de crisis en su smartwatch, revisa su inhalador y se da cuenta de que está bien. Es una molestia temporal.
2. **Falso Negativo (Crisis Perdida):** El paciente entra en un cuadro de hipoxia severa, el modelo no lo detecta y no se envía la alerta a sus familiares (guardianes). **Esto puede resultar en fatalidad.**

**XGBoost** dejó pasar **9 crisis reales**, lo cual es inaceptable médicamente. **Random Forest** obtuvo un **Recall del 100% (0 crisis perdidas)**. En la medicina, un modelo es superior cuando garantiza la vida del paciente, por lo que las 34 falsas alarmas de Random Forest son un precio insignificante y totalmente aceptable a pagar por la detección perfecta de ataques reales.

---

## 🧬 4. Análisis de Importancia de Variables
De acuerdo con el modelo Random Forest, las variables más determinantes para predecir un ataque de asma son:
1. **SpO2 (Saturación de Oxígeno) - 48.19%**: Principal indicador fisiológico de obstrucción en las vías respiratorias.
2. **BPM (Frecuencia Cardíaca) - 18.38%**: La taquicardia secundaria al esfuerzo respiratorio es un claro indicador de exacerbación.
3. **Pasos Diarios - 16.06%**: La caída drástica en la actividad física correlaciona con la fatiga del paciente.

*Reporte generado automáticamente para el proyecto Asthma Predictor API.*
