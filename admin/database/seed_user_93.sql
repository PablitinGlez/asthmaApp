-- Script para insertar ~25 mediciones de prueba para el usuario 93
-- Rango de fechas: 1 de Marzo de 2026 al 18 de Marzo de 2026

-- Limpiar mediciones previas (opcional, por si quieres reiniciar el historial de este usuario)
-- DELETE FROM spirometer_readings WHERE user_id = 93;

-- SEMANA PASADA (valores PEF más bajos, simulando peor control)
INSERT INTO spirometer_readings (user_id, pef, fev1, aqi, temperature, humidity, pollen_level, symptom_intensity, measured_at)
VALUES 
(93, 340, 2.10, 85, 21.5, 65, 'Alto', 'Moderada', '2026-03-04 08:30:00'),
(93, 320, 2.00, 90, 20.0, 70, 'Alto', 'Moderada', '2026-03-05 09:15:00'),
(93, 350, 2.20, 60, 22.0, 60, 'Moderado', 'Leve', '2026-03-06 08:45:00'),
(93, 360, 2.25, 50, 23.5, 55, 'Moderado', 'Leve', '2026-03-06 20:10:00'),
(93, 330, 2.05, 80, 21.0, 68, 'Alto', 'Moderada', '2026-03-07 07:50:00'),
(93, 355, 2.22, 55, 22.5, 58, 'Bajo', 'Leve', '2026-03-08 08:20:00'),
(93, 370, 2.30, 45, 24.0, 50, 'Bajo', NULL, '2026-03-09 08:40:00'),
(93, 380, 2.35, 40, 24.5, 48, 'Bajo', NULL, '2026-03-09 19:30:00'),
(93, 365, 2.28, 50, 23.0, 52, 'Moderado', 'Leve', '2026-03-10 09:00:00');

-- ESTA SEMANA (valores PEF más altos, simulando mejora)
INSERT INTO spirometer_readings (user_id, pef, fev1, aqi, temperature, humidity, pollen_level, symptom_intensity, measured_at)
VALUES 
(93, 400, 2.50, 35, 25.0, 45, 'Bajo', NULL, '2026-03-11 08:15:00'),
(93, 410, 2.60, 30, 25.5, 42, 'Bajo', NULL, '2026-03-11 20:00:00'),
(93, 395, 2.45, 45, 24.0, 50, 'Moderado', 'Leve', '2026-03-12 08:30:00'),
(93, 430, 2.75, 25, 26.0, 40, 'Bajo', NULL, '2026-03-13 07:45:00'),
(93, 440, 2.80, 20, 26.5, 38, 'Bajo', NULL, '2026-03-14 09:10:00'),
(93, 420, 2.65, 38, 25.0, 45, 'Moderado', NULL, '2026-03-14 20:30:00'),
(93, 450, 2.90, 15, 27.0, 35, 'Bajo', NULL, '2026-03-15 08:20:00'),
(93, 460, 2.95, 12, 27.5, 33, 'Bajo', NULL, '2026-03-16 08:00:00'),
(93, 445, 2.85, 25, 26.0, 40, 'Moderado', NULL, '2026-03-16 19:40:00'),
(93, 470, 3.00, 10, 28.0, 30, 'Bajo', NULL, '2026-03-17 08:30:00'),
(93, 480, 3.10, 15, 27.5, 32, 'Bajo', NULL, '2026-03-18 07:15:00');
