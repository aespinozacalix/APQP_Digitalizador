-- =========================================================================
-- ESTRUCTURA DE SEGURIDAD Y PERFILES
-- =========================================================================

-- TABLA 1: PERFILES DE USUARIO
CREATE TABLE perfiles (
    id_perfil INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_perfil TEXT UNIQUE NOT NULL -- 'Administrador', 'Supervisor', 'Auditor'
);

-- TABLA 2: USUARIOS (AUDITORES, SUPERVISORES, ADMIN)
CREATE TABLE usuarios (
    id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    usuario TEXT UNIQUE NOT NULL, -- Nombre de usuario para login
    password BLOB NOT NULL, -- Contraseña hasheada (se usará hash en Python)
    id_perfil INTEGER NOT NULL,
    planta TEXT NOT NULL,
    activo TEXT CHECK(activo IN ('SI', 'NO')) NOT NULL DEFAULT 'SI',
    
    FOREIGN KEY (id_perfil) REFERENCES perfiles(id_perfil)
);

-- =========================================================================
-- ESTRUCTURA MAESTRA DE UBTS Y FAMILIAS
-- =========================================================================

-- TABLA 3: PLANTAS
CREATE TABLE plantas (
    id_planta INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_planta TEXT UNIQUE NOT NULL, -- Esperanza, Cortes
    activa TEXT CHECK(activa IN ('SI', 'NO')) NOT NULL DEFAULT 'SI' -- Solo Esperanza SI por ahora
);

-- TABLA 4: UBTS (LINEAS DE TRABAJO ÚNICAS)
-- La UBT está linkeada al Supervisor y a la Planta.
CREATE TABLE ubts (
    id_ubt INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_ubt TEXT UNIQUE NOT NULL, -- Ej: 301-2, 305-1
    id_supervisor INTEGER NOT NULL, -- FK al supervisor responsable (Rodmel o Aristides)
    id_planta INTEGER NOT NULL,
    activo TEXT CHECK(activo IN ('SI', 'NO')) NOT NULL DEFAULT 'SI',
    
    FOREIGN KEY (id_supervisor) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_planta) REFERENCES plantas(id_planta)
);

-- TABLA 5: FAMILIAS DE ARNES (RELACIÓN UBT-PRODUCTO)
CREATE TABLE familias_arnes (
    id_familia INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_arnes TEXT NOT NULL, -- Ej: A2LL DRIVER
    programa TEXT NOT NULL, -- Ej: GLOBAL SEAT
    composite TEXT, -- Campo Composite del CSV
    id_ubt INTEGER NOT NULL,
    
    FOREIGN KEY (id_ubt) REFERENCES ubts(id_ubt)
);


-- =========================================================================
-- ESTRUCTURA DEL CHECKLIST Y REGISTRO
-- =========================================================================

-- TABLA 6: PREGUNTAS MAESTRAS (Estructura estática del CL)
CREATE TABLE auditorias_maestras (
    id_pregunta INTEGER PRIMARY KEY AUTOINCREMENT,
    texto_pregunta TEXT NOT NULL,
    tipo_pregunta TEXT CHECK(tipo_pregunta IN ('CRITICA', 'ESTANDAR')) NOT NULL
);

-- TABLA 7: REGISTRO DE CADA AUDITORÍA COMPLETADA (Encabezado)
CREATE TABLE auditorias_registro (
    id_registro INTEGER PRIMARY KEY AUTOINCREMENT,
    id_auditor INTEGER, -- FK al auditor que la realiza
    id_ubt INTEGER, 
    id_familia INTEGER, -- El arnés específico auditado (para trazabilidad)
    fecha_hora TEXT NOT NULL, 
    
    -- ESTADOS: BORRADOR, PENDIENTE_SUPERVISOR, CASO_ABIERTO, CERRADA
    estado_auditoria TEXT CHECK(estado_auditoria IN ('BORRADOR', 'PENDIENTE_SUPERVISOR', 'CASO_ABIERTO', 'CERRADA')) NOT NULL DEFAULT 'BORRADOR', 
    
    -- El supervisor se asigna automáticamente al guardar/enviar
    id_supervisor INTEGER, 
    
    FOREIGN KEY (id_auditor) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_ubt) REFERENCES ubts(id_ubt),
    FOREIGN KEY (id_familia) REFERENCES familias_arnes(id_familia),
    FOREIGN KEY (id_supervisor) REFERENCES usuarios(id_usuario)
);

-- TABLA 8: RESPUESTAS DE CADA PREGUNTA (Detalles)
CREATE TABLE auditorias_detalles (
    id_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
    id_registro INTEGER, 
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

-- Insertar Perfiles
INSERT INTO perfiles (nombre_perfil) VALUES 
('Administrador'), 
('Supervisor'), 
('Auditor'); 

-- Insertar Plantas (Cortes inactiva por ahora)
INSERT INTO plantas (nombre_planta, activa) VALUES 
('Esperanza', 'SI'), 
('Cortes', 'NO');

-- Insertar Usuarios (Contraseña '1234' hasheada - La implementaremos en Python)
-- Nota: La contraseña '1234' no es hasheada aquí, se inserta como texto para que 'database.py' la hashee. 
-- Por ahora usamos un placeholder hasta que implementemos la función de hash.
-- La columna password es BLOB, pero SQLITE permite insertar texto y lo convierte a BLOB, el problema es que la función de hash debe ejecutarse antes.

-- Temporalmente insertamos la contraseña '1234' como texto para la demo inicial.
-- ¡IMPORTANTE! Esto se debe corregir con una función de hash antes de ponerlo en producción.
-- Perfil 3 (ID=1)
INSERT INTO usuarios (nombre, usuario, password, id_perfil, planta) VALUES
('ADMIN (TU USUARIO)', 'admin', '1234', 1, 'Esperanza'); 

-- Supervisores (Perfil 2, ID=2)
INSERT INTO usuarios (nombre, usuario, password, id_perfil, planta) VALUES
('Aristides Espinoza', 'aespinoza', '1234', 2, 'Esperanza'),
('Rodmel Funes', 'rfunes', '1234', 2, 'Esperanza'),
('Alejandro Torres', 'atorres', '1234', 2, 'Cortes'); -- Oculto

-- Auditores (Perfil 1, ID=3)
INSERT INTO usuarios (nombre, usuario, password, id_perfil, planta) VALUES
('Olga Melga', 'omelga', '1234', 3, 'Esperanza'), 
('Francisco Melgar', 'fmelgar', '1234', 3, 'Esperanza'),
('William Zaldivar', 'wzaldivar', '1234', 3, 'Esperanza'),
('Mercy Fernandez', 'mfernandez', '1234', 3, 'Esperanza'), -- Nombre corregido
('Fany Gomez', 'fgomez', '1234', 3, 'Cortes'), -- Oculto
('Mario Valladares', 'mvalladares', '1234', 3, 'Cortes'); -- Oculto

-- Insertar UBTs de Esperanza (solo las únicas)
-- Las UBTs se asignan a Aristides (ID 2) o Rodmel (ID 3). Planta Esperanza (ID 1)
INSERT INTO ubts (nombre_ubt, id_supervisor, id_planta) VALUES
('305-2', 2, 1), ('305-1', 2, 1), ('307-1', 3, 1), ('309-1', 3, 1), ('308-2', 3, 1),
('318-2', 2, 1), ('315-2', 3, 1), ('302-1', 3, 1), ('304-1', 3, 1), ('301-1', 3, 1),
('303-1', 3, 1), ('301-2', 2, 1), ('325-3', 2, 1), ('325-2', 2, 1), ('325-4', 2, 1),
('310-1', 3, 1), ('308-1', 3, 1), ('322-2', 3, 1), ('310-2', 3, 1), ('321-2', 2, 1),
('320-2', 2, 1), ('320-1', 2, 1), ('317-1', 2, 1), ('316-1', 2, 1), ('315-1', 2, 1),
('313-1', 3, 1), ('314-1', 3, 1), ('321-1', 3, 1), ('322-1', 3, 1), ('312-1', 3, 1),
('319-2', 2, 1), ('318-1', 2, 1), ('323-1', 2, 1), ('306-1', 2, 1), ('323-2', 2, 1),
('324-2', 2, 1), ('302-2', 2, 1), ('317-2', 2, 1), ('326-2', 2, 1), ('326-1', 2, 1),
('325-1', 2, 1);

-- NOTA: Insertar Familias de Arneses a partir de tu CSV es muy extenso,
-- pero se harán algunos ejemplos manuales para demostrar la relación.
-- En un proyecto real, esto se haría mediante una importación de CSV.

-- Ejemplos de Familias (solo para demostrar el funcionamiento)
-- UBT 305-2 (ID 1)
INSERT INTO familias_arnes (nombre_arnes, programa, composite, id_ubt) VALUES
('A2LL DRIVER', 'GLOBAL SEAT', '86592688-AA', 1), 
('A2SL DRIVER', 'GLOBAL SEAT', '84252058-EB', 1); 

-- UBT 305-1 (ID 2)
INSERT INTO familias_arnes (nombre_arnes, programa, composite, id_ubt) VALUES
('A2LL PASSENGER', 'GLOBAL SEAT', '86592687-AA', 2),
('A2SL PASSENGER', 'GLOBAL SEAT', '84252059-EB', 2);

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