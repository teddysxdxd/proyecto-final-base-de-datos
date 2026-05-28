-- Crear base de datos transaccional
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CRM_Innovacion')
    DROP DATABASE CRM_Innovacion;
GO

CREATE DATABASE CRM_Innovacion;
GO

USE CRM_Innovacion;
GO

-- =====================================================
-- TABLA: Divisiones de Clientes
-- =====================================================
CREATE TABLE Divisiones (
    division_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_division VARCHAR(50) NOT NULL UNIQUE,
    fecha_creacion DATETIME DEFAULT GETDATE()
);

INSERT INTO Divisiones (nombre_division) VALUES 
    ('Cliente Potencial'),
    ('Cliente Final');

-- =====================================================
-- TABLA: Empleados (Área Comercial)
-- =====================================================
CREATE TABLE Empleados (
    empleado_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    cargo VARCHAR(50),
    fecha_contratacion DATE,
    activo BIT DEFAULT 1
);

-- =====================================================
-- TABLA: Clientes
-- =====================================================
CREATE TABLE Clientes (
    cliente_id INT IDENTITY(1,1) PRIMARY KEY,
    codigo_cliente VARCHAR(20) UNIQUE NOT NULL,
    nombre_comercial VARCHAR(200) NOT NULL,
    razon_social VARCHAR(200),
    direccion_empresa VARCHAR(300),
    telefono VARCHAR(20),
    celular VARCHAR(20),
    email_empresa VARCHAR(150),
    contacto_nombre VARCHAR(150),
    contacto_telefono VARCHAR(20),
    division_id INT FOREIGN KEY REFERENCES Divisiones(division_id),
    fecha_registro DATETIME DEFAULT GETDATE(),
    activo BIT DEFAULT 1
);

-- =====================================================
-- TABLA: Tipos de Oportunidad
-- =====================================================
CREATE TABLE TiposOportunidad (
    tipo_oportunidad_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tipo VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO TiposOportunidad (nombre_tipo) VALUES ('Venta'), ('Compra');

-- =====================================================
-- TABLA: Etapas de Oportunidad
-- =====================================================
CREATE TABLE EtapasOportunidad (
    etapa_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_etapa VARCHAR(100) NOT NULL,
    porcentaje_cierre DECIMAL(5,2) NOT NULL,
    orden INT NOT NULL
);

INSERT INTO EtapasOportunidad (nombre_etapa, porcentaje_cierre, orden) VALUES
    ('Toma de Decisión', 20, 1),
    ('Proceso Toma de Decisión', 30, 2),
    ('Análisis de Proyecto', 50, 3),
    ('Presentación de Cotización', 80, 4),
    ('Validación de Cotización', 95, 5),
    ('Acuerdo de Cierre', 100, 6);

-- =====================================================
-- TABLA: Oportunidades (CORREGIDA)
-- =====================================================
CREATE TABLE Oportunidades (
    oportunidad_id INT IDENTITY(1,1) PRIMARY KEY,
    numero_oportunidad VARCHAR(20) UNIQUE NOT NULL,
    nombre_oportunidad VARCHAR(200) NOT NULL,
    tipo_oportunidad_id INT FOREIGN KEY REFERENCES TiposOportunidad(tipo_oportunidad_id),
    cliente_id INT FOREIGN KEY REFERENCES Clientes(cliente_id),
    empleado_asignado_id INT FOREIGN KEY REFERENCES Empleados(empleado_id),
    gerente_comercial_id INT FOREIGN KEY REFERENCES Empleados(empleado_id),
    estado_oportunidad VARCHAR(10) DEFAULT 'Abierto',
    fecha_inicio DATE NOT NULL,
    fecha_cierre_planificada DATE,
    fecha_cierre_real DATE,
    etapa_actual_id INT FOREIGN KEY REFERENCES EtapasOportunidad(etapa_id),
    monto_potencial DECIMAL(18,2),
    resultado_oportunidad VARCHAR(20),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    activo BIT DEFAULT 1
);
GO

-- =====================================================
-- VISTA para cálculos (alternativa a columnas calculadas)
-- =====================================================
CREATE VIEW vw_Oportunidades AS
SELECT 
    o.*,
    e.porcentaje_cierre AS porcentaje_avance,
    o.monto_potencial * (e.porcentaje_cierre / 100) AS monto_ponderado
FROM Oportunidades o
INNER JOIN EtapasOportunidad e ON o.etapa_actual_id = e.etapa_id;
GO

-- =====================================================
-- TABLA: Historial de Etapas (Seguimiento)
-- =====================================================
CREATE TABLE HistorialEtapas (
    historial_id INT IDENTITY(1,1) PRIMARY KEY,
    oportunidad_id INT FOREIGN KEY REFERENCES Oportunidades(oportunidad_id),
    etapa_id INT FOREIGN KEY REFERENCES EtapasOportunidad(etapa_id),
    empleado_id INT FOREIGN KEY REFERENCES Empleados(empleado_id),
    fecha_inicio DATE NOT NULL,
    fecha_cierre DATE,
    monto_potencial_actual DECIMAL(18,2),
    comentario TEXT,
    fecha_registro DATETIME DEFAULT GETDATE()
);

-- =====================================================
-- TABLA: Tipos de Actividad
-- =====================================================
CREATE TABLE TiposActividad (
    tipo_actividad_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tipo VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO TiposActividad (nombre_tipo) VALUES 
    ('Llamada Telefónica'), ('Reunión'), ('Tarea'), ('Nota'), ('Agendar Visita'), 
    ('Proyecto Nuevo'), ('Visita a Cliente'), ('Reclamo de Cliente');

-- =====================================================
-- TABLA: Actividades
-- =====================================================
CREATE TABLE Actividades (
    actividad_id INT IDENTITY(1,1) PRIMARY KEY,
    numero_actividad VARCHAR(20) UNIQUE NOT NULL,
    cliente_id INT FOREIGN KEY REFERENCES Clientes(cliente_id),
    oportunidad_id INT FOREIGN KEY REFERENCES Oportunidades(oportunidad_id),
    empleado_responsable_id INT FOREIGN KEY REFERENCES Empleados(empleado_id),
    tipo_actividad_id INT FOREIGN KEY REFERENCES TiposActividad(tipo_actividad_id),
    asunto VARCHAR(300) NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME,
    hora_fin TIME,
    duracion_minutos INT,
    prioridad VARCHAR(10) DEFAULT 'Normal',
    estado VARCHAR(20) DEFAULT 'No Iniciado',
    comentario TEXT,
    calle VARCHAR(200),
    ciudad VARCHAR(100),
    sala VARCHAR(100),
    fecha_registro DATETIME DEFAULT GETDATE()
);

-- =====================================================
-- TABLA: Documentos (Ofertas, Pedidos)
-- =====================================================
CREATE TABLE Documentos (
    documento_id INT IDENTITY(1,1) PRIMARY KEY,
    oportunidad_id INT FOREIGN KEY REFERENCES Oportunidades(oportunidad_id),
    clase_documento VARCHAR(50),
    numero_documento VARCHAR(50),
    fecha_emision DATE,
    monto DECIMAL(18,2),
    archivo_url VARCHAR(500),
    fecha_registro DATETIME DEFAULT GETDATE()
);

-- =====================================================
-- TABLA: Auditoría (para triggers)
-- =====================================================
CREATE TABLE Auditoria (
    auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
    tabla_afectada VARCHAR(100),
    operacion VARCHAR(20),
    registro_id INT,
    datos_anteriores NVARCHAR(MAX),
    datos_nuevos NVARCHAR(MAX),
    usuario VARCHAR(100),
    fecha_cambio DATETIME DEFAULT GETDATE()
);

GO

CREATE OR ALTER VIEW vw_Oportunidades
AS
SELECT 
    o.oportunidad_id,
    o.numero_oportunidad,
    o.nombre_oportunidad,
    o.tipo_oportunidad_id,
    o.cliente_id,
    o.empleado_asignado_id,
    o.gerente_comercial_id,
    o.estado_oportunidad,
    o.fecha_inicio,
    o.fecha_cierre_planificada,
    o.fecha_cierre_real,
    o.etapa_actual_id,
    o.monto_potencial,
    o.resultado_oportunidad,
    o.fecha_creacion,
    o.activo,
    -- Calcular porcentaje_avance desde la tabla de etapas
    ISNULL(et.porcentaje_cierre, 0) AS porcentaje_avance,
    -- Calcular monto_ponderado
    ISNULL(o.monto_potencial * (et.porcentaje_cierre / 100), 0) AS monto_ponderado
FROM Oportunidades o
LEFT JOIN EtapasOportunidad et ON o.etapa_actual_id = et.etapa_id;
GO