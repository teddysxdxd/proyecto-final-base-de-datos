USE CRM_Innovacion;
GO

-- Insertar Empleados
INSERT INTO Empleados (nombre, apellido, email, telefono, cargo, fecha_contratacion, activo) VALUES
('SANDRA', 'AROCHE', 'sandra.aroche@innovacion.com', '555-0101', 'Asistente Comercial', '2023-01-15', 1),
('CARLOS', 'MENDOZA', 'carlos.mendoza@innovacion.com', '555-0102', 'Gerente Comercial', '2022-06-20', 1),
('ANA', 'RAMIREZ', 'ana.ramirez@innovacion.com', '555-0103', 'Asistente Comercial', '2023-03-10', 1),
('LUIS', 'FERNADEZ', 'luis.fernandez@innovacion.com', '555-0104', 'Gerente Comercial', '2021-11-05', 1);
GO

-- Insertar Clientes
INSERT INTO Clientes (codigo_cliente, nombre_comercial, razon_social, direccion_empresa, telefono, celular, email_empresa, contacto_nombre, contacto_telefono, division_id) VALUES
('CLI001', 'Tecnología del Sur S.A.', 'Tecnología del Sur S.A.', 'Av. Reforma 123, Zona 10', '22334455', '51234567', 'info@tecnosur.com', 'Juan Pérez', '51234567', 2),
('CLI002', 'Distribuciones El Sol', 'Distribuciones El Sol S.A.', '5ta Calle 6-78, Zona 4', '22334466', '51234568', 'ventas@elsol.com', 'María López', '51234568', 1),
('CLI003', 'Industrias del Norte', 'Industrias del Norte S.A.', 'Km 15 Carretera al Norte', '22334477', '51234569', 'contacto@indnorte.com', 'Pedro Gómez', '51234569', 2),
('CLI004', 'Consultoría Empresarial GT', 'Consultoría Empresarial GT', 'Diagonal 6 10-01, Zona 10', '22334488', '51234570', 'info@consegt.com', 'Ana María Paz', '51234570', 1);
GO

-- Insertar Oportunidades
INSERT INTO Oportunidades (numero_oportunidad, nombre_oportunidad, tipo_oportunidad_id, cliente_id, 
                           empleado_asignado_id, gerente_comercial_id, fecha_inicio, 
                           fecha_cierre_planificada, etapa_actual_id, monto_potencial, estado_oportunidad) VALUES
('OP-2025-001', 'Implementación ERP', 1, 1, 1, 2, '2025-06-04', '2025-07-04', 4, 60000.00, 'Abierto'),
('OP-2025-002', 'Venta de Hardware', 1, 3, 3, 4, '2025-06-05', '2025-07-05', 3, 27000.00, 'Abierto'),
('OP-2025-003', 'Software CRM', 1, 2, 1, 2, '2025-06-01', '2025-06-30', 6, 45000.00, 'Cerrado'),
('OP-2025-004', 'Capacitación TI', 1, 4, 3, 4, '2025-05-20', '2025-06-20', 5, 15000.00, 'Cerrado');
GO

-- Actualizar resultado de oportunidades cerradas
UPDATE Oportunidades SET resultado_oportunidad = 'Ganada' WHERE numero_oportunidad = 'OP-2025-003';
UPDATE Oportunidades SET resultado_oportunidad = 'Perdida' WHERE numero_oportunidad = 'OP-2025-004';
UPDATE Oportunidades SET fecha_cierre_real = '2025-06-10' WHERE numero_oportunidad = 'OP-2025-003';
UPDATE Oportunidades SET fecha_cierre_real = '2025-05-25' WHERE numero_oportunidad = 'OP-2025-004';
GO

-- Insertar Historial de etapas (seguimiento)
INSERT INTO HistorialEtapas (oportunidad_id, etapa_id, empleado_id, fecha_inicio, monto_potencial_actual) VALUES
(1, 1, 1, '2025-06-04', 60000),
(1, 2, 1, '2025-06-05', 60000),
(1, 3, 1, '2025-06-06', 60000),
(1, 4, 1, '2025-06-07', 60000),
(2, 1, 3, '2025-06-05', 27000),
(2, 2, 3, '2025-06-06', 27000),
(2, 3, 3, '2025-06-07', 27000);
GO

-- Insertar Actividades (CORREGIDO - ahora incluye todos los campos definidos en la tabla)
INSERT INTO Actividades (numero_actividad, cliente_id, oportunidad_id, empleado_responsable_id, 
                         tipo_actividad_id, asunto, fecha, hora_inicio, hora_fin, prioridad, estado, comentario, calle, ciudad, sala) VALUES
('ACT-001', 1, 1, 1, 1, 'Llamada inicial para presentación', '2025-06-04', '10:00', '10:30', 'Alto', 'Concluido', 'Cliente interesado en ERP', NULL, NULL, NULL),
('ACT-002', 1, 1, 1, 2, 'Reunión con equipo de TI', '2025-06-06', '14:00', '15:30', 'Alto', 'Concluido', 'Presentación exitosa', 'Av. Reforma', 'Ciudad', 'Sala 1'),
('ACT-003', 3, 2, 3, 4, 'Envío de cotización de hardware', '2025-06-07', '09:00', '09:15', 'Normal', 'Concluido', 'Cotización enviada por email', NULL, NULL, NULL),
('ACT-004', 2, NULL, 1, 5, 'Agendar visita para demostración', '2025-06-10', '11:00', NULL, 'Normal', 'En Proceso', NULL, NULL, NULL, NULL);
GO

-- Insertar Documentos
INSERT INTO Documentos (oportunidad_id, clase_documento, numero_documento, fecha_emision, monto) VALUES
(1, 'Ofertas de ventas', 'COT-2025-001', '2025-06-05', 60000),
(1, 'Ofertas de ventas', 'COT-2025-002', '2025-06-07', 60000),
(2, 'Ofertas de ventas', 'COT-2025-003', '2025-06-06', 27000),
(2, 'Pedidos de cliente', 'PED-2025-001', '2025-06-09', 30357.14),
(3, 'Pedidos de cliente', 'PED-2025-002', '2025-06-10', 45000);
GO

-- Verificar datos insertados
SELECT 'Empleados:' AS Tabla, COUNT(*) AS Cantidad FROM Empleados
UNION ALL
SELECT 'Clientes:', COUNT(*) FROM Clientes
UNION ALL
SELECT 'Oportunidades:', COUNT(*) FROM Oportunidades
UNION ALL
SELECT 'Actividades:', COUNT(*) FROM Actividades
UNION ALL
SELECT 'Documentos:', COUNT(*) FROM Documentos;
GO