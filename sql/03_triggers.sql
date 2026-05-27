USE CRM_Innovacion;
GO

-- =====================================================
-- TRIGGER: Auditoría para Clientes (VERSION CORREGIDA)
-- =====================================================
CREATE OR ALTER TRIGGER trg_Auditoria_Clientes
ON Clientes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @operacion VARCHAR(20);
    DECLARE @registro_id INT;
    DECLARE @datos_anteriores NVARCHAR(MAX);
    DECLARE @datos_nuevos NVARCHAR(MAX);
    
    -- Para INSERT
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        SET @operacion = 'INSERT';
        
        DECLARE cur_insert CURSOR FOR
            SELECT cliente_id, 
                   'codigo=' + ISNULL(codigo_cliente,'') + 
                   '|nombre=' + ISNULL(nombre_comercial,'') +
                   '|direccion=' + ISNULL(direccion_empresa,'') +
                   '|telefono=' + ISNULL(telefono,'') +
                   '|email=' + ISNULL(email_empresa,'')
            FROM inserted;
        
        OPEN cur_insert;
        FETCH NEXT FROM cur_insert INTO @registro_id, @datos_nuevos;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO Auditoria (tabla_afectada, operacion, registro_id, datos_nuevos, usuario)
            VALUES ('Clientes', @operacion, @registro_id, @datos_nuevos, SUSER_NAME());
            FETCH NEXT FROM cur_insert INTO @registro_id, @datos_nuevos;
        END;
        
        CLOSE cur_insert;
        DEALLOCATE cur_insert;
    END
    
    -- Para UPDATE
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        SET @operacion = 'UPDATE';
        
        DECLARE cur_update CURSOR FOR
            SELECT i.cliente_id,
                   'codigo=' + ISNULL(d.codigo_cliente,'') + 
                   '|nombre=' + ISNULL(d.nombre_comercial,'') AS datos_anteriores,
                   'codigo=' + ISNULL(i.codigo_cliente,'') + 
                   '|nombre=' + ISNULL(i.nombre_comercial,'') AS datos_nuevos
            FROM inserted i
            INNER JOIN deleted d ON i.cliente_id = d.cliente_id
            WHERE i.codigo_cliente != d.codigo_cliente 
               OR i.nombre_comercial != d.nombre_comercial
               OR ISNULL(i.direccion_empresa,'') != ISNULL(d.direccion_empresa,'');
        
        OPEN cur_update;
        FETCH NEXT FROM cur_update INTO @registro_id, @datos_anteriores, @datos_nuevos;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO Auditoria (tabla_afectada, operacion, registro_id, datos_anteriores, datos_nuevos, usuario)
            VALUES ('Clientes', @operacion, @registro_id, @datos_anteriores, @datos_nuevos, SUSER_NAME());
            FETCH NEXT FROM cur_update INTO @registro_id, @datos_anteriores, @datos_nuevos;
        END;
        
        CLOSE cur_update;
        DEALLOCATE cur_update;
    END
    
    -- Para DELETE
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        SET @operacion = 'DELETE';
        
        DECLARE cur_delete CURSOR FOR
            SELECT cliente_id,
                   'codigo=' + ISNULL(codigo_cliente,'') + 
                   '|nombre=' + ISNULL(nombre_comercial,'') AS datos_anteriores
            FROM deleted;
        
        OPEN cur_delete;
        FETCH NEXT FROM cur_delete INTO @registro_id, @datos_anteriores;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO Auditoria (tabla_afectada, operacion, registro_id, datos_anteriores, usuario)
            VALUES ('Clientes', @operacion, @registro_id, @datos_anteriores, SUSER_NAME());
            FETCH NEXT FROM cur_delete INTO @registro_id, @datos_anteriores;
        END;
        
        CLOSE cur_delete;
        DEALLOCATE cur_delete;
    END
END;
GO

-- =====================================================
-- TRIGGER: Actualizar automáticamente fecha_cierre_planificada según etapa
-- =====================================================
CREATE OR ALTER TRIGGER trg_Oportunidad_CalcularFechas
ON Oportunidades
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si se actualizó la etapa y la oportunidad está abierta, calcular nueva fecha planificada
    UPDATE o
    SET fecha_cierre_planificada = DATEADD(DAY, 
        CASE 
            WHEN et.porcentaje_cierre <= 30 THEN 30
            WHEN et.porcentaje_cierre <= 50 THEN 20
            WHEN et.porcentaje_cierre <= 80 THEN 15
            WHEN et.porcentaje_cierre <= 95 THEN 10
            ELSE 5
        END, GETDATE())
    FROM Oportunidades o
    INNER JOIN inserted i ON o.oportunidad_id = i.oportunidad_id
    INNER JOIN deleted d ON o.oportunidad_id = d.oportunidad_id
    INNER JOIN EtapasOportunidad et ON i.etapa_actual_id = et.etapa_id
    WHERE i.etapa_actual_id != d.etapa_actual_id
        AND o.estado_oportunidad = 'Abierto';
END;
GO

-- =====================================================
-- TRIGGER: Log de cambio de estado en actividades
-- =====================================================
CREATE OR ALTER TRIGGER trg_Actividad_LogEstado
ON Actividades
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Auditoria (tabla_afectada, operacion, registro_id, datos_anteriores, datos_nuevos, usuario)
    SELECT 'Actividades', 'UPDATE_ESTADO', i.actividad_id,
           'Estado anterior: ' + ISNULL(d.estado, 'NULL'),
           'Estado nuevo: ' + ISNULL(i.estado, 'NULL'),
           SUSER_NAME()
    FROM inserted i
    INNER JOIN deleted d ON i.actividad_id = d.actividad_id
    WHERE i.estado != d.estado;
END;
GO