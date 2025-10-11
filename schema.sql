-- =========================================================================
-- CREACIÓN DE TABLAS
-- =========================================================================

-- TABLA 1: PREGUNTAS MAESTRAS (Estructura estática del CL)
CREATE TABLE auditorias_maestras (
    id_pregunta INTEGER PRIMARY KEY AUTOINCREMENT,
    texto_pregunta TEXT NOT NULL,
    -- Clasifica la pregunta para priorización en reportes: 'CRITICA' o 'ESTANDAR'.
    tipo_pregunta TEXT CHECK(tipo_pregunta IN ('CRITICA', 'ESTANDAR')) NOT NULL 
);

-- TABLA 2: LINEAS DE TRABAJO (UBT)
CREATE TABLE ubts (
    id_ubt INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_ubt TEXT UNIQUE NOT NULL,
    -- 'SI' si la UBT está activa para auditoría, 'NO' si está deshabilitada.
    activo TEXT CHECK(activo IN ('SI', 'NO')) NOT NULL DEFAULT 'SI' 
);

-- TABLA 3: REGISTRO DE CADA AUDITORÍA COMPLETADA (Encabezado)
CREATE TABLE auditorias_registro (
    id_registro INTEGER PRIMARY KEY AUTOINCREMENT,
    -- FK a la tabla ubts
    id_ubt INTEGER, 
    fecha_hora TEXT NOT NULL, 
    auditor_nombre TEXT NOT NULL,
    supervisor_nombre TEXT,
    firma_auditor TEXT, 
    firma_supervisor TEXT, 
    
    FOREIGN KEY (id_ubt) REFERENCES ubts(id_ubt)
);

-- TABLA 4: RESPUESTAS DE CADA PREGUNTA (Detalles)
CREATE TABLE auditorias_detalles (
    id_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
    -- FK a la auditoría específica
    id_registro INTEGER, 
    -- FK a la pregunta específica
    id_pregunta INTEGER, 
    -- Valores permitidos: 'CUMPLE', 'NO_CUMPLE', 'NA'
    respuesta TEXT CHECK(respuesta IN ('CUMPLE', 'NO_CUMPLE', 'NA')) NOT NULL, 
    comentario TEXT, 
    
    FOREIGN KEY (id_registro) REFERENCES auditorias_registro(id_registro),
    FOREIGN KEY (id_pregunta) REFERENCES auditorias_maestras(id_pregunta)
);

-- =========================================================================
-- DATOS INICIALES (INSERT)
-- =========================================================================

-- Insertar las UBTs de ejemplo con su estado activo/inactivo
INSERT INTO ubts (nombre_ubt, activo) VALUES 
('Linea A', 'SI'), 
('Linea B', 'SI'), 
('Linea C', 'NO'); 

-- Insertar las 11 preguntas del CL con su clasificación CRÍTICA/ESTÁNDAR
INSERT INTO auditorias_maestras (texto_pregunta, tipo_pregunta) VALUES
('¿El operador(a) de Dimensiones sigue el procedimiento Centre y Mida apropiadamente?', 'ESTANDAR'),
('¿El operador(a) de Dimensiones conoce cual es la funcion correcta de las fixturas electrificadas? (únicamente para prueba de clips, no para dimensionar).', 'ESTANDAR'),
('¿Las fixturas electrificadas funcionan correctamente? (Observar al operador pasar pzs y verificar que no realice ningun paso o método incorrecto para pasar el árnes).', 'CRITICA'), 
('¿El operador(a) de prueba eléctrica valida la primera etiqueta del árnes de acuerdo a la ayuda visual?.', 'ESTANDAR'),
('¿Los módulos de prueba electrica funcionan correctamente? (Observar al operador pasar pzs y verificar que no realice ningun paso o método incorrecto para pasar el árnes).', 'CRITICA'), 
('¿El Auditor (a) de calidad valida correctamente los pokayokes? (Sabe que aplica si un pokayoke no funciona).', 'CRITICA'), 
('¿Los módulos de prueba electrica cuentan con todos los sus pines?.', 'CRITICA'), 
('¿El operador(a) de cuarentena conoce e inspecciona de forma correcta los puntos críticos y el llenado del reporte?(Verique que el reporte de cuarentena concuerde con la instruccion).', 'ESTANDAR'),
('EL master de cuarentena esta actualizado con los ultimos cambios de arnes?.', 'ESTANDAR'),
('¿El personal de red de calidad conoce y practica el plan de reacción ERIC?.', 'ESTANDAR'),
('Se usa contraparte para validar candados desensamblados y terminales desalineadas? Estan en buen estado?.', 'ESTANDAR');