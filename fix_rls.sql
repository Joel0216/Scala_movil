-- ============================================================
-- SCALA MOVIL — SCRIPT DE REPARACIÓN COMPLETO
-- Ejecuta TODO esto en el SQL Editor de Supabase
-- ============================================================

-- ============================================================
-- SECCIÓN 1: PERMISOS (RLS)
-- ============================================================

-- GRUPOS: cualquier maestro autenticado puede ver todos los grupos (para supervisión)
DROP POLICY IF EXISTS "Maestros pueden ver sus grupos" ON grupos;
DROP POLICY IF EXISTS "Acceso para dueños y supervisores" ON grupos;
CREATE POLICY "Acceso para dueños y supervisores" ON grupos 
FOR SELECT TO authenticated 
USING (EXISTS (SELECT 1 FROM maestros WHERE email = auth.email()));

-- ALUMNOS
DROP POLICY IF EXISTS "Maestros pueden ver alumnos" ON alumnos;
CREATE POLICY "Maestros pueden ver alumnos" ON alumnos
FOR SELECT TO authenticated USING (true);

-- ALUMNO_GRUPOS
DROP POLICY IF EXISTS "Maestros pueden ver inscripciones" ON alumno_grupos;
CREATE POLICY "Maestros pueden ver inscripciones" ON alumno_grupos
FOR SELECT TO authenticated USING (true);

-- PROGRAMACION_EXAMENES (nombre real de la tabla)
DROP POLICY IF EXISTS "Maestros pueden ver examenes" ON programacion_examenes;
CREATE POLICY "Maestros pueden ver examenes" ON programacion_examenes
FOR SELECT TO authenticated USING (true);

-- ============================================================
-- SECCIÓN 2: COLUMNAS FALTANTES EN sesiones_clase
-- ============================================================
ALTER TABLE sesiones_clase ADD COLUMN IF NOT EXISTS maestro_id UUID REFERENCES maestros(id);
ALTER TABLE sesiones_clase ADD COLUMN IF NOT EXISTS hora_inicio TIME DEFAULT CURRENT_TIME;
ALTER TABLE sesiones_clase ADD COLUMN IF NOT EXISTS es_extra BOOLEAN DEFAULT FALSE;
ALTER TABLE sesiones_clase ADD COLUMN IF NOT EXISTS motivo_extra TEXT;
ALTER TABLE sesiones_clase ADD COLUMN IF NOT EXISTS salon_extra TEXT;
ALTER TABLE sesiones_clase ADD COLUMN IF NOT EXISTS organizacion_id UUID;

-- ============================================================
-- SECCIÓN 2B: COLUMNAS FALTANTES EN asistencias
-- ============================================================
-- La app móvil necesita 'asistio' y 'observaciones'
ALTER TABLE asistencias ADD COLUMN IF NOT EXISTS asistio BOOLEAN DEFAULT TRUE;
ALTER TABLE asistencias ADD COLUMN IF NOT EXISTS observaciones TEXT;

-- ============================================================
-- SECCIÓN 3: COLUMNAS FALTANTES EN resultados_examen
-- ============================================================
ALTER TABLE resultados_examen ADD COLUMN IF NOT EXISTS maestro_calificador_id UUID REFERENCES maestros(id);
ALTER TABLE resultados_examen ADD COLUMN IF NOT EXISTS credencial_maestro TEXT;
ALTER TABLE resultados_examen ADD COLUMN IF NOT EXISTS hora_calificacion TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE resultados_examen ADD COLUMN IF NOT EXISTS organizacion_id UUID;
ALTER TABLE resultados_examen ADD COLUMN IF NOT EXISTS presento BOOLEAN DEFAULT FALSE;
ALTER TABLE resultados_examen ADD COLUMN IF NOT EXISTS aprobo BOOLEAN DEFAULT FALSE;
ALTER TABLE resultados_examen ADD COLUMN IF NOT EXISTS calificacion NUMERIC(5,2);
ALTER TABLE resultados_examen ADD COLUMN IF NOT EXISTS nota TEXT;

-- ============================================================
-- SECCIÓN 4: DATOS — Arreglar nombres de grupos que salen S/N
-- ============================================================
UPDATE grupos SET nombre = 'Grupo ' || clave 
WHERE nombre IS NULL OR nombre = '' OR nombre = 'Grupo S/N' OR nombre = 'S/N';

-- ============================================================
-- SECCIÓN 5: PERMISOS Y RLS
-- ============================================================
-- Desactivamos RLS para sesiones y asistencias para que Electron (Desktop) pueda verlas
ALTER TABLE sesiones_clase DISABLE ROW LEVEL SECURITY;
ALTER TABLE asistencias DISABLE ROW LEVEL SECURITY;

-- Políticas adicionales para usuarios autenticados (Móvil)
DROP POLICY IF EXISTS "Maestros pueden insertar sesiones" ON sesiones_clase;
CREATE POLICY "Maestros pueden insertar sesiones" ON sesiones_clase
FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Maestros pueden ver sesiones" ON sesiones_clase;
CREATE POLICY "Maestros pueden ver sesiones" ON sesiones_clase
FOR SELECT TO authenticated USING (true);

-- Asegurar que la tabla asistencias tenga la estructura y restricciones correctas para el móvil
ALTER TABLE asistencias ADD COLUMN IF NOT EXISTS sesion_id UUID REFERENCES sesiones_clase(id);

-- El móvil usa ON CONFLICT (grupo_id, alumno_id, fecha)
ALTER TABLE asistencias DROP CONSTRAINT IF EXISTS unique_asistencia_diaria;
ALTER TABLE asistencias ADD CONSTRAINT unique_asistencia_diaria UNIQUE (grupo_id, alumno_id, fecha);

-- Para resultados_examen
ALTER TABLE resultados_examen DROP CONSTRAINT IF EXISTS unique_alumno_examen;
ALTER TABLE resultados_examen ADD CONSTRAINT unique_alumno_examen UNIQUE (clave_examen, alumno_id);

-- ============================================================
-- SECCIÓN 7: VISTA v_examenes_alumno (con calificación)
-- ============================================================
-- DROP primero para evitar conflicto de renombrado de columnas
DROP VIEW IF EXISTS v_examenes_alumno;
CREATE VIEW v_examenes_alumno AS
SELECT
    pe.id                       AS examen_id,
    pe.clave_examen,
    ag.alumno_id,
    a.credencial,
    a.nombre                    AS alumno_nombre,
    pe.fecha,
    pe.hora,
    pe.salon_id,
    pe.grupo_id,
    g.clave                     AS grupo_clave,
    m.nombre                    AS maestro_nombre,
    m.id                        AS maestro_id,
    -- Calificación desde resultados_examen
    re.calificacion,
    re.presento,
    re.aprobo,
    -- Precio fijo (el cobro se registra en recibos_detalle por referencia externa)
    0::numeric                  AS precio_unitario,
    -- Status: PAGADO si hay resultado con calificación y hay recibo, sino por calificación
    CASE
        WHEN re.calificacion IS NOT NULL THEN 'PAGADO'
        ELSE 'PENDIENTE DE PAGO'
    END                         AS status
FROM programacion_examenes pe
JOIN grupos g ON g.id = pe.grupo_id
JOIN alumno_grupos ag ON ag.grupo_clave = g.clave AND ag.estado = 'Activo'
JOIN alumnos a ON a.id = ag.alumno_id
LEFT JOIN maestros m ON m.id = pe.maestro_base_id
LEFT JOIN resultados_examen re ON re.clave_examen = pe.clave_examen AND re.alumno_id = ag.alumno_id;


-- ============================================================
-- SECCIÓN 8: BORRADO EN CASCADA (ON DELETE CASCADE)
-- ============================================================

-- 1. Sesiones de clase (Usa grupo_id)
ALTER TABLE sesiones_clase 
  DROP CONSTRAINT IF EXISTS sesiones_clase_grupo_id_fkey;
ALTER TABLE sesiones_clase 
  ADD CONSTRAINT sesiones_clase_grupo_id_fkey 
  FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE;

-- 2. Asistencias (Usa grupo_id)
ALTER TABLE asistencias 
  DROP CONSTRAINT IF EXISTS asistencias_grupo_id_fkey;
ALTER TABLE asistencias 
  ADD CONSTRAINT asistencias_grupo_id_fkey 
  FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE;

-- 3. Inscripciones (Usa grupo_clave)
-- Primero aseguramos que grupos(clave) sea único para poder referenciarlo
ALTER TABLE grupos DROP CONSTRAINT IF EXISTS grupos_clave_unique;
ALTER TABLE grupos ADD CONSTRAINT grupos_clave_unique UNIQUE (clave);

ALTER TABLE alumno_grupos 
  DROP CONSTRAINT IF EXISTS alumno_grupos_grupo_clave_fkey;
ALTER TABLE alumno_grupos 
  ADD CONSTRAINT alumno_grupos_grupo_clave_fkey 
  FOREIGN KEY (grupo_clave) REFERENCES grupos(clave) ON DELETE CASCADE;

-- 4. Programación de Exámenes (Usa grupo_id)
ALTER TABLE programacion_examenes 
  DROP CONSTRAINT IF EXISTS programacion_examenes_grupo_id_fkey;
ALTER TABLE programacion_examenes 
  ADD CONSTRAINT programacion_examenes_grupo_id_fkey 
  FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE;

-- ============================================================
-- SECCIÓN 8B: COLUMNA ANULADO EN colegiaturas (Para Vacaciones)
-- ============================================================
ALTER TABLE colegiaturas ADD COLUMN IF NOT EXISTS anulado BOOLEAN DEFAULT FALSE;

ALTER TABLE grupos ADD COLUMN IF NOT EXISTS costo_mensual DECIMAL(10,2) DEFAULT 0;
ALTER TABLE alumno_grupos ADD COLUMN IF NOT EXISTS costo_mensual DECIMAL(10,2) DEFAULT 0;

-- SCRIPT DE REPARACIÓN DE DATOS (Llenar costos vacíos desde cursos)
UPDATE grupos g
SET costo_mensual = COALESCE(c.precio_mensual, c.costo, 0)
FROM cursos c
WHERE g.curso_id = c.id AND (g.costo_mensual IS NULL OR g.costo_mensual = 0);

UPDATE alumno_grupos ag
SET costo_mensual = COALESCE(c.precio_mensual, c.costo, g.costo_mensual, 0)
FROM grupos g
LEFT JOIN cursos c ON g.curso_id = c.id
WHERE ag.grupo_clave = g.clave AND (ag.costo_mensual IS NULL OR ag.costo_mensual = 0);

-- ============================================================
-- SECCIÓN 9: VISTAS DE PAGOS (VACACIONES Y DEUDAS HISTÓRICAS)
-- ============================================================
-- Recreamos las vistas de pagos para soportar el estatus de VACACIONES
-- y asegurar que las deudas no desaparezcan al dar de baja al alumno.

DROP VIEW IF EXISTS v_colegiaturas_pendientes CASCADE;
DROP VIEW IF EXISTS v_seguimiento_pagos CASCADE;

CREATE OR REPLACE VIEW v_seguimiento_pagos AS
WITH RECURSIVE meses(n) AS (
    SELECT 0 UNION ALL SELECT n + 1 FROM meses WHERE n < 11
),
alumno_ciclos AS (
    SELECT 
        ag.alumno_id, ag.grupo_clave, a.porcentaje_beca,
        COALESCE(g.fecha_inicio, '2024-01-01'::date) as inicio_grupo,
        -- Prioridad de precio: Curso(mensual) -> Curso(costo) -> Inscripción -> Grupo
        COALESCE(NULLIF(c.precio_mensual, 0), NULLIF(c.costo, 0), NULLIF(ag.costo_mensual, 0), NULLIF(g.costo_mensual, 0), 0) as costo_base,
        m.n as n_ciclo,
        (COALESCE(g.fecha_inicio, '2024-01-01'::date) + (m.n || ' months')::interval)::date as inicio_ciclo,
        (COALESCE(g.fecha_inicio, '2024-01-01'::date) + ((m.n + 1) || ' months')::interval - ('1 day')::interval)::date as fin_ciclo
    FROM alumno_grupos ag
    JOIN alumnos a ON ag.alumno_id = a.id
    JOIN grupos g ON ag.grupo_clave = g.clave
    LEFT JOIN cursos c ON g.curso_id = c.id
    CROSS JOIN meses m
    -- Eliminamos el filtro estricto de 'Activo' para que las deudas históricas se calculen
    -- pero limitamos los ciclos al periodo en que el alumno estuvo/está inscrito.
    WHERE (ag.fecha_baja IS NULL OR (COALESCE(g.fecha_inicio, '2024-01-01'::date) + (m.n || ' months')::interval)::date <= ag.fecha_baja)
)
SELECT 
    ac.*,
    EXTRACT(MONTH FROM ac.inicio_ciclo)::INTEGER as mes,
    EXTRACT(YEAR FROM ac.inicio_ciclo)::INTEGER as anio,
    ROUND(ac.costo_base * (1 - COALESCE(ac.porcentaje_beca, 0) / 100.0), 2) as monto,
    ROUND(ac.costo_base * (1 - COALESCE(ac.porcentaje_beca, 0) / 100.0), 2) as monto_calculado,
    CASE 
        WHEN EXISTS (SELECT 1 FROM colegiaturas col WHERE col.alumno_id = ac.alumno_id AND col.mes = EXTRACT(MONTH FROM ac.inicio_ciclo) AND col.anio = EXTRACT(YEAR FROM ac.inicio_ciclo) AND col.anulado = true) THEN 'vacaciones'
        WHEN EXISTS (SELECT 1 FROM colegiaturas col WHERE col.alumno_id = ac.alumno_id AND col.mes = EXTRACT(MONTH FROM ac.inicio_ciclo) AND col.anio = EXTRACT(YEAR FROM ac.inicio_ciclo)) THEN 'pagado'
        WHEN ac.porcentaje_beca >= 100 THEN 'pagado'
        WHEN ac.inicio_ciclo < CURRENT_DATE - interval '5 days' THEN 'deuda'
        ELSE 'futuro'
    END as estatus
FROM alumno_ciclos ac
WHERE (ac.inicio_ciclo <= CURRENT_DATE + interval '7 days') 
   OR (EXISTS (SELECT 1 FROM colegiaturas col WHERE col.alumno_id = ac.alumno_id AND col.mes = EXTRACT(MONTH FROM ac.inicio_ciclo) AND col.anio = EXTRACT(YEAR FROM ac.inicio_ciclo)));

CREATE OR REPLACE VIEW v_colegiaturas_pendientes AS
SELECT 
    vsp.alumno_id, a.credencial, a.nombre, vsp.grupo_clave as grupo, c.curso, vsp.mes, vsp.anio, vsp.monto as precio_mensual, vsp.monto as monto_a_pagar
FROM v_seguimiento_pagos vsp
JOIN alumnos a ON vsp.alumno_id = a.id
JOIN grupos g ON vsp.grupo_clave = g.clave
JOIN cursos c ON g.curso_id = c.id
WHERE vsp.estatus = 'deuda';



