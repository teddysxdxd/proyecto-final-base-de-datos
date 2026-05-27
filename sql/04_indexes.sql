USE CRM_Innovacion;
GO

-- Índices para búsquedas frecuentes
CREATE NONCLUSTERED INDEX idx_clientes_nombre ON Clientes(nombre_comercial);
CREATE NONCLUSTERED INDEX idx_clientes_codigo ON Clientes(codigo_cliente);
CREATE NONCLUSTERED INDEX idx_clientes_telefono ON Clientes(telefono);
CREATE NONCLUSTERED INDEX idx_clientes_email ON Clientes(email_empresa);

CREATE NONCLUSTERED INDEX idx_oportunidades_numero ON Oportunidades(numero_oportunidad);
CREATE NONCLUSTERED INDEX idx_oportunidades_cliente ON Oportunidades(cliente_id);
CREATE NONCLUSTERED INDEX idx_oportunidades_empleado ON Oportunidades(empleado_asignado_id);
CREATE NONCLUSTERED INDEX idx_oportunidades_etapa ON Oportunidades(etapa_actual_id);
CREATE NONCLUSTERED INDEX idx_oportunidades_fecha_inicio ON Oportunidades(fecha_inicio);
CREATE NONCLUSTERED INDEX idx_oportunidades_fecha_cierre ON Oportunidades(fecha_cierre_planificada);

CREATE NONCLUSTERED INDEX idx_actividades_fecha ON Actividades(fecha);
CREATE NONCLUSTERED INDEX idx_actividades_cliente ON Actividades(cliente_id);
CREATE NONCLUSTERED INDEX idx_actividades_oportunidad ON Actividades(oportunidad_id);
CREATE NONCLUSTERED INDEX idx_actividades_empleado ON Actividades(empleado_responsable_id);
CREATE NONCLUSTERED INDEX idx_actividades_estado ON Actividades(estado);

CREATE NONCLUSTERED INDEX idx_historial_oportunidad ON HistorialEtapas(oportunidad_id);
CREATE NONCLUSTERED INDEX idx_documentos_oportunidad ON Documentos(oportunidad_id);