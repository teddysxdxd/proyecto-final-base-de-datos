-- Crear base de datos para Data Warehouse
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'DW_Ventas')
    DROP DATABASE DW_Ventas;
GO

CREATE DATABASE DW_Ventas;
GO

USE DW_Ventas;
GO

-- Tabla de Dimensiones
CREATE TABLE Dim_Tiempo (
    tiempo_id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE,
    anio INT,
    mes INT,
    mes_nombre VARCHAR(20),
    trimestre INT,
    semana INT,
    dia_semana INT,
    dia_nombre VARCHAR(20)
);
GO

CREATE TABLE Dim_Cliente (
    cliente_id INT PRIMARY KEY,
    codigo_cliente VARCHAR(20),
    nombre_comercial VARCHAR(200),
    division_cliente VARCHAR(50),
    ciudad VARCHAR(100)
);
GO

CREATE TABLE Dim_Empleado (
    empleado_id INT PRIMARY KEY,
    nombre_completo VARCHAR(200),
    cargo VARCHAR(50),
    email VARCHAR(150)
);
GO

CREATE TABLE Dim_Etapa (
    etapa_id INT PRIMARY KEY,
    nombre_etapa VARCHAR(100),
    porcentaje_cierre DECIMAL(5,2)
);
GO

-- Tabla de Hechos
CREATE TABLE Fact_Oportunidades (
    hecho_id INT IDENTITY(1,1) PRIMARY KEY,
    oportunidad_id INT,
    cliente_id INT FOREIGN KEY REFERENCES Dim_Cliente(cliente_id),
    empleado_id INT FOREIGN KEY REFERENCES Dim_Empleado(empleado_id),
    etapa_id INT FOREIGN KEY REFERENCES Dim_Etapa(etapa_id),
    fecha_inicio_id INT FOREIGN KEY REFERENCES Dim_Tiempo(tiempo_id),
    fecha_cierre_id INT FOREIGN KEY REFERENCES Dim_Tiempo(tiempo_id),
    monto_potencial DECIMAL(18,2),
    monto_ponderado DECIMAL(18,2),
    resultado VARCHAR(20),
    dias_duracion INT
);
GO

-- =====================================================
-- PROCEDIMIENTO ETL (VERSION CORREGIDA)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_ETL_CargarDataWarehouse
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Limpiar tablas (para recarga completa)
    TRUNCATE TABLE Fact_Oportunidades;
    TRUNCATE TABLE Dim_Tiempo;
    TRUNCATE TABLE Dim_Cliente;
    TRUNCATE TABLE Dim_Empleado;
    TRUNCATE TABLE Dim_Etapa;
    
    -- 2. Cargar Dim_Tiempo (últimos 5 años)
    DECLARE @start_date DATE = DATEADD(YEAR, -5, GETDATE());
    DECLARE @end_date DATE = DATEADD(YEAR, 1, GETDATE());
    
    WHILE @start_date <= @end_date
    BEGIN
        INSERT INTO Dim_Tiempo (fecha, anio, mes, mes_nombre, trimestre, semana, dia_semana, dia_nombre)
        VALUES (
            @start_date,
            YEAR(@start_date),
            MONTH(@start_date),
            DATENAME(MONTH, @start_date),
            DATEPART(QUARTER, @start_date),
            DATEPART(WEEK, @start_date),
            DATEPART(WEEKDAY, @start_date),
            DATENAME(WEEKDAY, @start_date)
        );
        SET @start_date = DATEADD(DAY, 1, @start_date);
    END;
    
    -- 3. Cargar Dim_Cliente desde CRM
    INSERT INTO Dim_Cliente (cliente_id, codigo_cliente, nombre_comercial, division_cliente, ciudad)
    SELECT c.cliente_id, c.codigo_cliente, c.nombre_comercial, d.nombre_division, 'N/A'
    FROM CRM_Innovacion.dbo.Clientes c
    INNER JOIN CRM_Innovacion.dbo.Divisiones d ON c.division_id = d.division_id;
    
    -- 4. Cargar Dim_Empleado
    INSERT INTO Dim_Empleado (empleado_id, nombre_completo, cargo, email)
    SELECT empleado_id, nombre + ' ' + apellido, cargo, email
    FROM CRM_Innovacion.dbo.Empleados;
    
    -- 5. Cargar Dim_Etapa
    INSERT INTO Dim_Etapa (etapa_id, nombre_etapa, porcentaje_cierre)
    SELECT etapa_id, nombre_etapa, porcentaje_cierre
    FROM CRM_Innovacion.dbo.EtapasOportunidad;
    
    -- 6. Cargar Fact_Oportunidades (monto_ponderado CALCULADO aquí)
    INSERT INTO Fact_Oportunidades (oportunidad_id, cliente_id, empleado_id, etapa_id,
                                    fecha_inicio_id, fecha_cierre_id, monto_potencial, 
                                    monto_ponderado, resultado, dias_duracion)
    SELECT 
        o.oportunidad_id,
        o.cliente_id,
        o.empleado_asignado_id,
        o.etapa_actual_id,
        t1.tiempo_id,
        t2.tiempo_id,
        o.monto_potencial,
        o.monto_potencial * (et.porcentaje_cierre / 100) AS monto_ponderado,  -- <--- CAMBIO AQUI
        o.resultado_oportunidad,
        DATEDIFF(DAY, o.fecha_inicio, ISNULL(o.fecha_cierre_real, GETDATE())) AS dias_duracion
    FROM CRM_Innovacion.dbo.Oportunidades o
    INNER JOIN CRM_Innovacion.dbo.EtapasOportunidad et ON o.etapa_actual_id = et.etapa_id  -- <--- JOIN CON ETAPAS
    INNER JOIN Dim_Tiempo t1 ON o.fecha_inicio = t1.fecha
    LEFT JOIN Dim_Tiempo t2 ON o.fecha_cierre_real = t2.fecha
    WHERE o.activo = 1;
    
    -- Mostrar resultado
    SELECT 'ETL Completado exitosamente' AS mensaje,
           (SELECT COUNT(*) FROM Fact_Oportunidades) AS total_factos;
END;
GO

-- =====================================================
-- CONSULTAS ANALÍTICAS SOBRE DW
-- =====================================================
CREATE OR ALTER PROCEDURE sp_DW_VentasPorGestor
AS
BEGIN
    SELECT e.nombre_completo AS gestor,
           COUNT(f.oportunidad_id) AS total_oportunidades,
           SUM(f.monto_potencial) AS monto_total_potencial,
           SUM(f.monto_ponderado) AS monto_total_ponderado,
           AVG(f.dias_duracion) AS promedio_dias_cierre
    FROM Fact_Oportunidades f
    INNER JOIN Dim_Empleado e ON f.empleado_id = e.empleado_id
    GROUP BY e.nombre_completo
    ORDER BY total_oportunidades DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_DW_TendenciasMensuales
AS
BEGIN
    SELECT t.anio, t.mes, t.mes_nombre,
           COUNT(f.oportunidad_id) AS cantidad_oportunidades,
           SUM(f.monto_potencial) AS monto_total,
           SUM(CASE WHEN f.resultado = 'Ganada' THEN f.monto_potencial ELSE 0 END) AS monto_ganado
    FROM Fact_Oportunidades f
    INNER JOIN Dim_Tiempo t ON f.fecha_inicio_id = t.tiempo_id
    GROUP BY t.anio, t.mes, t.mes_nombre
    ORDER BY t.anio DESC, t.mes DESC;
END;
GO