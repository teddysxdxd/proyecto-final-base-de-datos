USE CRM_Innovacion;
GO

-- =====================================================
-- CRUD Clientes (CORREGIDOS - sin dependencias de vistas)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_Cliente_Insert
    @codigo_cliente VARCHAR(20),
    @nombre_comercial VARCHAR(200),
    @razon_social VARCHAR(200) = NULL,
    @direccion_empresa VARCHAR(300) = NULL,
    @telefono VARCHAR(20) = NULL,
    @celular VARCHAR(20) = NULL,
    @email_empresa VARCHAR(150) = NULL,
    @contacto_nombre VARCHAR(150) = NULL,
    @contacto_telefono VARCHAR(20) = NULL,
    @division_id INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Clientes (codigo_cliente, nombre_comercial, razon_social, direccion_empresa, 
                          telefono, celular, email_empresa, contacto_nombre, contacto_telefono, division_id)
    VALUES (@codigo_cliente, @nombre_comercial, @razon_social, @direccion_empresa,
            @telefono, @celular, @email_empresa, @contacto_nombre, @contacto_telefono, @division_id);
    
    SELECT SCOPE_IDENTITY() AS cliente_id;
END;
GO

CREATE OR ALTER PROCEDURE sp_Cliente_Update
    @cliente_id INT,
    @nombre_comercial VARCHAR(200),
    @razon_social VARCHAR(200) = NULL,
    @direccion_empresa VARCHAR(300) = NULL,
    @telefono VARCHAR(20) = NULL,
    @celular VARCHAR(20) = NULL,
    @email_empresa VARCHAR(150) = NULL,
    @contacto_nombre VARCHAR(150) = NULL,
    @contacto_telefono VARCHAR(20) = NULL,
    @division_id INT,
    @activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Clientes SET
        nombre_comercial = @nombre_comercial,
        razon_social = @razon_social,
        direccion_empresa = @direccion_empresa,
        telefono = @telefono,
        celular = @celular,
        email_empresa = @email_empresa,
        contacto_nombre = @contacto_nombre,
        contacto_telefono = @contacto_telefono,
        division_id = @division_id,
        activo = @activo
    WHERE cliente_id = @cliente_id;
    
    SELECT @cliente_id AS cliente_id;
END;
GO

CREATE OR ALTER PROCEDURE sp_Cliente_Delete
    @cliente_id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Clientes SET activo = 0 WHERE cliente_id = @cliente_id;
    SELECT @cliente_id AS cliente_id;
END;
GO

CREATE OR ALTER PROCEDURE sp_Cliente_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.cliente_id, c.codigo_cliente, c.nombre_comercial, c.razon_social, 
           c.direccion_empresa, c.telefono, c.celular, c.email_empresa, 
           c.contacto_nombre, c.contacto_telefono, c.division_id, c.fecha_registro, c.activo,
           d.nombre_division 
    FROM Clientes c
    INNER JOIN Divisiones d ON c.division_id = d.division_id
    WHERE c.activo = 1
    ORDER BY c.nombre_comercial;
END;
GO

CREATE OR ALTER PROCEDURE sp_Cliente_GetById
    @cliente_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.*, d.nombre_division 
    FROM Clientes c
    INNER JOIN Divisiones d ON c.division_id = d.division_id
    WHERE c.cliente_id = @cliente_id AND c.activo = 1;
END;
GO

-- =====================================================
-- CRUD Oportunidades (CORREGIDO - usando la vista)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_Oportunidad_Insert
    @numero_oportunidad VARCHAR(20),
    @nombre_oportunidad VARCHAR(200),
    @tipo_oportunidad_id INT,
    @cliente_id INT,
    @empleado_asignado_id INT,
    @gerente_comercial_id INT,
    @fecha_inicio DATE,
    @fecha_cierre_planificada DATE,
    @etapa_actual_id INT,
    @monto_potencial DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Oportunidades (numero_oportunidad, nombre_oportunidad, tipo_oportunidad_id, cliente_id,
                               empleado_asignado_id, gerente_comercial_id, fecha_inicio, 
                               fecha_cierre_planificada, etapa_actual_id, monto_potencial)
    VALUES (@numero_oportunidad, @nombre_oportunidad, @tipo_oportunidad_id, @cliente_id,
            @empleado_asignado_id, @gerente_comercial_id, @fecha_inicio, 
            @fecha_cierre_planificada, @etapa_actual_id, @monto_potencial);
    
    DECLARE @oportunidad_id INT = SCOPE_IDENTITY();
    
    INSERT INTO HistorialEtapas (oportunidad_id, etapa_id, empleado_id, fecha_inicio, monto_potencial_actual)
    VALUES (@oportunidad_id, @etapa_actual_id, @empleado_asignado_id, @fecha_inicio, @monto_potencial);
    
    SELECT @oportunidad_id AS oportunidad_id;
END;
GO

CREATE OR ALTER PROCEDURE sp_Oportunidad_Update
    @oportunidad_id INT,
    @nombre_oportunidad VARCHAR(200),
    @tipo_oportunidad_id INT,
    @cliente_id INT,
    @empleado_asignado_id INT,
    @gerente_comercial_id INT,
    @estado_oportunidad VARCHAR(10),
    @fecha_cierre_planificada DATE,
    @fecha_cierre_real DATE = NULL,
    @etapa_actual_id INT,
    @monto_potencial DECIMAL(18,2),
    @resultado_oportunidad VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @etapa_anterior INT;
    SELECT @etapa_anterior = etapa_actual_id FROM Oportunidades WHERE oportunidad_id = @oportunidad_id;
    
    UPDATE Oportunidades SET
        nombre_oportunidad = @nombre_oportunidad,
        tipo_oportunidad_id = @tipo_oportunidad_id,
        cliente_id = @cliente_id,
        empleado_asignado_id = @empleado_asignado_id,
        gerente_comercial_id = @gerente_comercial_id,
        estado_oportunidad = @estado_oportunidad,
        fecha_cierre_planificada = @fecha_cierre_planificada,
        fecha_cierre_real = @fecha_cierre_real,
        etapa_actual_id = @etapa_actual_id,
        monto_potencial = @monto_potencial,
        resultado_oportunidad = @resultado_oportunidad
    WHERE oportunidad_id = @oportunidad_id;
    
    IF @etapa_anterior != @etapa_actual_id
    BEGIN
        INSERT INTO HistorialEtapas (oportunidad_id, etapa_id, empleado_id, fecha_inicio, monto_potencial_actual)
        VALUES (@oportunidad_id, @etapa_actual_id, @empleado_asignado_id, GETDATE(), @monto_potencial);
    END
    
    SELECT @oportunidad_id AS oportunidad_id;
END;
GO

CREATE OR ALTER PROCEDURE sp_Oportunidad_Delete
    @oportunidad_id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Oportunidades SET activo = 0 WHERE oportunidad_id = @oportunidad_id;
    SELECT @oportunidad_id AS oportunidad_id;
END;
GO

CREATE OR ALTER PROCEDURE sp_Oportunidad_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.oportunidad_id, o.numero_oportunidad, o.nombre_oportunidad,
           o.tipo_oportunidad_id, o.cliente_id, o.empleado_asignado_id,
           o.gerente_comercial_id, o.estado_oportunidad, o.fecha_inicio,
           o.fecha_cierre_planificada, o.fecha_cierre_real, o.etapa_actual_id,
           o.monto_potencial, o.resultado_oportunidad, o.fecha_creacion, o.activo,
           v.porcentaje_avance, v.monto_ponderado,
           c.nombre_comercial, c.codigo_cliente,
           e1.nombre + ' ' + e1.apellido AS asistente_comercial,
           e2.nombre + ' ' + e2.apellido AS gerente_comercial,
           t.nombre_tipo AS tipo_oportunidad,
           et.nombre_etapa, et.porcentaje_cierre
    FROM Oportunidades o
    INNER JOIN vw_Oportunidades v ON o.oportunidad_id = v.oportunidad_id
    INNER JOIN Clientes c ON o.cliente_id = c.cliente_id
    INNER JOIN Empleados e1 ON o.empleado_asignado_id = e1.empleado_id
    INNER JOIN Empleados e2 ON o.gerente_comercial_id = e2.empleado_id
    INNER JOIN TiposOportunidad t ON o.tipo_oportunidad_id = t.tipo_oportunidad_id
    INNER JOIN EtapasOportunidad et ON o.etapa_actual_id = et.etapa_id
    WHERE o.activo = 1
    ORDER BY o.fecha_creacion DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_Oportunidad_GetById
    @oportunidad_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.*, 
           c.nombre_comercial, c.codigo_cliente,
           e1.nombre + ' ' + e1.apellido AS asistente_comercial,
           e2.nombre + ' ' + e2.apellido AS gerente_comercial
    FROM Oportunidades o
    INNER JOIN Clientes c ON o.cliente_id = c.cliente_id
    INNER JOIN Empleados e1 ON o.empleado_asignado_id = e1.empleado_id
    INNER JOIN Empleados e2 ON o.gerente_comercial_id = e2.empleado_id
    WHERE o.oportunidad_id = @oportunidad_id AND o.activo = 1;
END;
GO

-- =====================================================
-- REPORTES (CORREGIDOS)
-- =====================================================
CREATE OR ALTER PROCEDURE sp_Reporte_OportunidadesPorFecha
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT o.numero_oportunidad, o.nombre_oportunidad, c.nombre_comercial,
           o.fecha_inicio, o.fecha_cierre_planificada, o.monto_potencial,
           v.monto_ponderado, et.nombre_etapa, o.resultado_oportunidad
    FROM Oportunidades o
    INNER JOIN Clientes c ON o.cliente_id = c.cliente_id
    INNER JOIN EtapasOportunidad et ON o.etapa_actual_id = et.etapa_id
    INNER JOIN vw_Oportunidades v ON o.oportunidad_id = v.oportunidad_id
    WHERE o.fecha_inicio BETWEEN @fecha_inicio AND @fecha_fin
    ORDER BY o.fecha_inicio;
END;
GO

CREATE OR ALTER PROCEDURE sp_Reporte_OportunidadesPorGestor
    @empleado_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT e.nombre + ' ' + e.apellido AS gestor,
           COUNT(o.oportunidad_id) AS total_oportunidades,
           SUM(CASE WHEN o.estado_oportunidad = 'Cerrado' AND o.resultado_oportunidad = 'Ganada' THEN 1 ELSE 0 END) AS ganadas,
           SUM(CASE WHEN o.estado_oportunidad = 'Cerrado' AND o.resultado_oportunidad = 'Perdida' THEN 1 ELSE 0 END) AS perdidas,
           SUM(CASE WHEN o.estado_oportunidad = 'Abierto' THEN 1 ELSE 0 END) AS abiertas,
           ISNULL(SUM(v.monto_ponderado), 0) AS monto_total_ponderado
    FROM Empleados e
    LEFT JOIN Oportunidades o ON e.empleado_id = o.empleado_asignado_id AND o.activo = 1
    LEFT JOIN vw_Oportunidades v ON o.oportunidad_id = v.oportunidad_id
    WHERE (@empleado_id IS NULL OR e.empleado_id = @empleado_id)
    GROUP BY e.empleado_id, e.nombre, e.apellido
    ORDER BY total_oportunidades DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_Reporte_OportunidadesGanadasPerdidas
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        YEAR(fecha_cierre_real) AS año,
        MONTH(fecha_cierre_real) AS mes,
        resultado_oportunidad,
        COUNT(*) AS cantidad,
        SUM(monto_potencial) AS monto_total
    FROM Oportunidades
    WHERE estado_oportunidad = 'Cerrado'
        AND resultado_oportunidad IN ('Ganada', 'Perdida')
        AND (@fecha_inicio IS NULL OR fecha_cierre_real >= @fecha_inicio)
        AND (@fecha_fin IS NULL OR fecha_cierre_real <= @fecha_fin)
    GROUP BY YEAR(fecha_cierre_real), MONTH(fecha_cierre_real), resultado_oportunidad
    ORDER BY año DESC, mes DESC;
END;
GO

-- =====================================================
-- ACTIVIDADES
-- =====================================================
CREATE OR ALTER PROCEDURE sp_Actividad_Insert
    @numero_actividad VARCHAR(20),
    @cliente_id INT,
    @oportunidad_id INT = NULL,
    @empleado_responsable_id INT,
    @tipo_actividad_id INT,
    @asunto VARCHAR(300),
    @fecha DATE,
    @hora_inicio TIME = NULL,
    @hora_fin TIME = NULL,
    @prioridad VARCHAR(10) = 'Normal',
    @comentario TEXT = NULL,
    @calle VARCHAR(200) = NULL,
    @ciudad VARCHAR(100) = NULL,
    @sala VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @duracion_minutos INT = NULL;
    
    IF @hora_inicio IS NOT NULL AND @hora_fin IS NOT NULL
    BEGIN
        SET @duracion_minutos = DATEDIFF(MINUTE, @hora_inicio, @hora_fin);
    END
    
    INSERT INTO Actividades (numero_actividad, cliente_id, oportunidad_id, empleado_responsable_id,
                             tipo_actividad_id, asunto, fecha, hora_inicio, hora_fin, duracion_minutos,
                             prioridad, comentario, calle, ciudad, sala)
    VALUES (@numero_actividad, @cliente_id, @oportunidad_id, @empleado_responsable_id,
            @tipo_actividad_id, @asunto, @fecha, @hora_inicio, @hora_fin, @duracion_minutos,
            @prioridad, @comentario, @calle, @ciudad, @sala);
    
    SELECT SCOPE_IDENTITY() AS actividad_id;
END;
GO

CREATE OR ALTER PROCEDURE sp_Actividad_UpdateEstado
    @actividad_id INT,
    @estado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Actividades SET estado = @estado WHERE actividad_id = @actividad_id;
    SELECT @actividad_id AS actividad_id;
END;
GO

CREATE OR ALTER PROCEDURE sp_Actividad_GetByCliente
    @cliente_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.*, t.nombre_tipo, e.nombre + ' ' + e.apellido AS responsable
    FROM Actividades a
    INNER JOIN TiposActividad t ON a.tipo_actividad_id = t.tipo_actividad_id
    INNER JOIN Empleados e ON a.empleado_responsable_id = e.empleado_id
    WHERE a.cliente_id = @cliente_id
    ORDER BY a.fecha DESC, a.hora_inicio DESC;
END;
GO

-- =====================================================
-- EMPLEADOS
-- =====================================================
CREATE OR ALTER PROCEDURE sp_Empleado_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    SELECT empleado_id, nombre, apellido, email, telefono, cargo, activo
    FROM Empleados
    WHERE activo = 1
    ORDER BY nombre;
END;
GO

CREATE OR ALTER PROCEDURE sp_Empleado_GetByCargo
    @cargo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT empleado_id, nombre, apellido, email, telefono, cargo
    FROM Empleados
    WHERE cargo = @cargo AND activo = 1;
END;
GO

PRINT 'Todos los procedimientos fueron actualizados correctamente';