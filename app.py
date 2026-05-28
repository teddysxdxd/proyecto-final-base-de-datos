import os
import pyodbc
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'clave_secreta_proyecto_final_db2'

# Configuración de conexión a SQL Server
def get_db_connection():
    conn = pyodbc.connect(
        f'DRIVER={{ODBC Driver 17 for SQL Server}};'
        f'SERVER={os.environ.get("DB_SERVER", "localhost,1433")};'
        f'DATABASE={os.environ.get("DB_NAME", "CRM_Innovacion")};'
        f'UID={os.environ.get("DB_USER", "sa")};'
        f'PWD={os.environ.get("DB_PASSWORD", "desa123$")};'
        'TrustServerCertificate=yes;'
    )
    return conn

def get_dw_connection():
    conn = pyodbc.connect(
        f'DRIVER={{ODBC Driver 17 for SQL Server}};'
        f'SERVER={os.environ.get("DB_SERVER", "localhost,1433")};'
        f'DATABASE={os.environ.get("DB_DW_NAME", "DW_Ventas")};'
        f'UID={os.environ.get("DB_USER", "sa")};'
        f'PWD={os.environ.get("DB_PASSWORD", "desa123$")};'
        'TrustServerCertificate=yes;'
    )
    return conn

# ==================== RUTAS PRINCIPALES ====================
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/clientes')
def clientes():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC sp_Cliente_GetAll")
    clientes = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('clientes.html', clientes=clientes)

@app.route('/cliente/nuevo', methods=['GET', 'POST'])
def cliente_nuevo():
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Obtener próximo código de cliente
            cursor.execute("SELECT 'CLI' + RIGHT('000' + CAST(ISNULL(MAX(CAST(SUBSTRING(codigo_cliente, 4, 3) AS INT)), 0) + 1 AS VARCHAR(3)), 3) FROM Clientes")
            codigo = cursor.fetchone()[0]
            
            cursor.execute("""EXEC sp_Cliente_Insert 
                @codigo_cliente=?, @nombre_comercial=?, @razon_social=?, @direccion_empresa=?,
                @telefono=?, @celular=?, @email_empresa=?, @contacto_nombre=?, @contacto_telefono=?, @division_id=?""",
                codigo, request.form['nombre_comercial'], request.form.get('razon_social', ''),
                request.form.get('direccion_empresa', ''), request.form.get('telefono', ''),
                request.form.get('celular', ''), request.form.get('email_empresa', ''),
                request.form.get('contacto_nombre', ''), request.form.get('contacto_telefono', ''),
                int(request.form['division_id']))
            
            conn.commit()
            cursor.close()
            conn.close()
            flash('Cliente creado exitosamente', 'success')
            return redirect(url_for('clientes'))
        except Exception as e:
            flash(f'Error al crear cliente: {str(e)}', 'danger')
    
    # GET: mostrar formulario
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT division_id, nombre_division FROM Divisiones")
    divisiones = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('cliente_form.html', divisiones=divisiones, titulo="Nuevo Cliente")

@app.route('/oportunidades')
def oportunidades():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC sp_Oportunidad_GetAll")
    oportunidades = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('oportunidades.html', oportunidades=oportunidades)

@app.route('/oportunidad/nuevo', methods=['GET', 'POST'])
def oportunidad_nuevo():
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Generar número de oportunidad
            cursor.execute("SELECT 'OP-' + CAST(YEAR(GETDATE()) AS VARCHAR) + '-' + RIGHT('000' + CAST(ISNULL(MAX(CAST(RIGHT(numero_oportunidad, 3) AS INT)), 0) + 1 AS VARCHAR(3)), 3) FROM Oportunidades")
            numero = cursor.fetchone()[0]
            
            cursor.execute("""EXEC sp_Oportunidad_Insert
                @numero_oportunidad=?, @nombre_oportunidad=?, @tipo_oportunidad_id=?,
                @cliente_id=?, @empleado_asignado_id=?, @gerente_comercial_id=?,
                @fecha_inicio=?, @fecha_cierre_planificada=?, @etapa_actual_id=?, @monto_potencial=?""",
                numero, request.form['nombre_oportunidad'], int(request.form['tipo_oportunidad_id']),
                int(request.form['cliente_id']), int(request.form['empleado_asignado_id']),
                int(request.form['gerente_comercial_id']), request.form['fecha_inicio'],
                request.form['fecha_cierre_planificada'], int(request.form['etapa_actual_id']),
                float(request.form['monto_potencial']))
            
            conn.commit()
            cursor.close()
            conn.close()
            flash('Oportunidad creada exitosamente', 'success')
            return redirect(url_for('oportunidades'))
        except Exception as e:
            flash(f'Error: {str(e)}', 'danger')
    
    # GET
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT cliente_id, nombre_comercial FROM Clientes WHERE activo=1 ORDER BY nombre_comercial")
    clientes = cursor.fetchall()
    cursor.execute("SELECT empleado_id, nombre, apellido, cargo FROM Empleados WHERE activo=1")
    empleados = cursor.fetchall()
    cursor.execute("SELECT tipo_oportunidad_id, nombre_tipo FROM TiposOportunidad")
    tipos = cursor.fetchall()
    cursor.execute("SELECT etapa_id, nombre_etapa, porcentaje_cierre FROM EtapasOportunidad ORDER BY orden")
    etapas = cursor.fetchall()
    cursor.close()
    conn.close()
    
    asistentes = [e for e in empleados if e.cargo == 'Asistente Comercial']
    gerentes = [e for e in empleados if e.cargo == 'Gerente Comercial']
    
    return render_template('oportunidad_form.html', clientes=clientes, asistentes=asistentes,
                          gerentes=gerentes, tipos=tipos, etapas=etapas, titulo="Nueva Oportunidad",
                          oportunidad=None)


@app.route('/oportunidad/<int:oportunidad_id>/editar', methods=['GET', 'POST'])
def oportunidad_editar(oportunidad_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    if request.method == 'POST':
        try:
            cursor.execute("""EXEC sp_Oportunidad_Update
                @oportunidad_id=?, @nombre_oportunidad=?, @tipo_oportunidad_id=?,
                @cliente_id=?, @empleado_asignado_id=?, @gerente_comercial_id=?,
                @estado_oportunidad=?, @fecha_cierre_planificada=?, @fecha_cierre_real=?,
                @etapa_actual_id=?, @monto_potencial=?, @resultado_oportunidad=?""",
                oportunidad_id,
                request.form['nombre_oportunidad'],
                int(request.form['tipo_oportunidad_id']),
                int(request.form['cliente_id']),
                int(request.form['empleado_asignado_id']),
                int(request.form['gerente_comercial_id']),
                request.form['estado_oportunidad'],
                request.form['fecha_cierre_planificada'] or None,
                request.form['fecha_cierre_real'] or None,
                int(request.form['etapa_actual_id']),
                float(request.form['monto_potencial']),
                request.form.get('resultado_oportunidad') or None)
            conn.commit()
            flash('Oportunidad actualizada exitosamente', 'success')
            return redirect(url_for('oportunidades'))
        except Exception as e:
            flash(f'Error al actualizar oportunidad: {str(e)}', 'danger')

    cursor.execute("EXEC sp_Oportunidad_GetById ?", oportunidad_id)
    oportunidad = cursor.fetchone()
    if not oportunidad:
        cursor.close()
        conn.close()
        flash('Oportunidad no encontrada', 'warning')
        return redirect(url_for('oportunidades'))

    cursor.execute("SELECT cliente_id, nombre_comercial FROM Clientes WHERE activo=1 ORDER BY nombre_comercial")
    clientes = cursor.fetchall()
    cursor.execute("SELECT empleado_id, nombre, apellido, cargo FROM Empleados WHERE activo=1")
    empleados = cursor.fetchall()
    cursor.execute("SELECT tipo_oportunidad_id, nombre_tipo FROM TiposOportunidad")
    tipos = cursor.fetchall()
    cursor.execute("SELECT etapa_id, nombre_etapa, porcentaje_cierre FROM EtapasOportunidad ORDER BY orden")
    etapas = cursor.fetchall()
    cursor.close()
    conn.close()

    asistentes = [e for e in empleados if e.cargo == 'Asistente Comercial']
    gerentes = [e for e in empleados if e.cargo == 'Gerente Comercial']

    return render_template('oportunidad_form.html', clientes=clientes, asistentes=asistentes,
                          gerentes=gerentes, tipos=tipos, etapas=etapas, titulo="Editar Oportunidad",
                          oportunidad=oportunidad)

@app.route('/actividades')
def actividades():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT a.*, t.nombre_tipo, e.nombre + ' ' + e.apellido AS responsable, 
               c.nombre_comercial
        FROM Actividades a
        INNER JOIN TiposActividad t ON a.tipo_actividad_id = t.tipo_actividad_id
        INNER JOIN Empleados e ON a.empleado_responsable_id = e.empleado_id
        INNER JOIN Clientes c ON a.cliente_id = c.cliente_id
        ORDER BY a.fecha DESC, a.hora_inicio DESC
    """)
    actividades = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('actividades.html', actividades=actividades)

@app.route('/actividad/nuevo', methods=['GET', 'POST'])
def actividad_nuevo():
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            cursor.execute("SELECT 'ACT-' + RIGHT('000' + CAST(ISNULL(MAX(CAST(RIGHT(numero_actividad, 3) AS INT)), 0) + 1 AS VARCHAR(3)), 3) FROM Actividades")
            numero = cursor.fetchone()[0]
            
            cursor.execute("""EXEC sp_Actividad_Insert
                @numero_actividad=?, @cliente_id=?, @oportunidad_id=?, @empleado_responsable_id=?,
                @tipo_actividad_id=?, @asunto=?, @fecha=?, @hora_inicio=?, @hora_fin=?,
                @prioridad=?, @comentario=?, @calle=?, @ciudad=?, @sala=?""",
                numero, int(request.form['cliente_id']), 
                int(request.form.get('oportunidad_id', 0)) if request.form.get('oportunidad_id') else None,
                int(request.form['empleado_responsable_id']), int(request.form['tipo_actividad_id']),
                request.form['asunto'], request.form['fecha'],
                request.form.get('hora_inicio'), request.form.get('hora_fin'),
                request.form.get('prioridad', 'Normal'), request.form.get('comentario', ''),
                request.form.get('calle', ''), request.form.get('ciudad', ''),
                request.form.get('sala', ''))
            
            conn.commit()
            cursor.close()
            conn.close()
            flash('Actividad creada exitosamente', 'success')
            return redirect(url_for('actividades'))
        except Exception as e:
            flash(f'Error: {str(e)}', 'danger')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT cliente_id, nombre_comercial FROM Clientes WHERE activo=1")
    clientes = cursor.fetchall()
    cursor.execute("SELECT oportunidad_id, nombre_oportunidad FROM Oportunidades WHERE activo=1 AND estado_oportunidad='Abierto'")
    oportunidades = cursor.fetchall()
    cursor.execute("SELECT empleado_id, nombre, apellido FROM Empleados WHERE activo=1")
    empleados = cursor.fetchall()
    cursor.execute("SELECT tipo_actividad_id, nombre_tipo FROM TiposActividad")
    tipos = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('actividad_form.html', clientes=clientes, oportunidades=oportunidades,
                          empleados=empleados, tipos=tipos, titulo="Nueva Actividad")

@app.route('/actividad/estado/<int:actividad_id>', methods=['POST'])
def actividad_cambiar_estado(actividad_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("EXEC sp_Actividad_UpdateEstado ?, ?", actividad_id, request.form['estado'])
        conn.commit()
        cursor.close()
        conn.close()
        flash('Estado actualizado', 'success')
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
    return redirect(url_for('actividades'))
@app.route('/actividad/<int:actividad_id>')
def actividad_ver(actividad_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT a.*, t.nombre_tipo, e.nombre + ' ' + e.apellido AS responsable, 
               c.nombre_comercial
        FROM Actividades a
        INNER JOIN TiposActividad t ON a.tipo_actividad_id = t.tipo_actividad_id
        INNER JOIN Empleados e ON a.empleado_responsable_id = e.empleado_id
        INNER JOIN Clientes c ON a.cliente_id = c.cliente_id
        WHERE a.actividad_id = ?
    """, actividad_id)
    actividad = cursor.fetchone()
    cursor.close()
    conn.close()
    
    if actividad:
        return render_template('actividad_detalle.html', actividad=actividad)
    else:
        flash('Actividad no encontrada', 'danger')
        return redirect(url_for('actividades'))
@app.route('/informes')
def informes():
    return render_template('informes.html')

@app.route('/informes/oportunidades_fecha', methods=['POST'])
def informes_oportunidades_fecha():
    fecha_inicio = request.form['fecha_inicio']
    fecha_fin = request.form['fecha_fin']
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC sp_Reporte_OportunidadesPorFecha ?, ?", fecha_inicio, fecha_fin)
    resultados = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('informes_resultados.html', resultados=resultados, titulo="Oportunidades por Fecha")

@app.route('/informes/por_gestor')
def informes_por_gestor():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC sp_Reporte_OportunidadesPorGestor")
    resultados = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('informes_resultados.html', resultados=resultados, titulo="Oportunidades por Gestor")

@app.route('/informes/ganadas_perdidas')
def informes_ganadas_perdidas():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC sp_Reporte_OportunidadesGanadasPerdidas")
    resultados = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('informes_resultados.html', resultados=resultados, titulo="Oportunidades Ganadas vs Perdidas")

@app.route('/etl')
def etl():
    return render_template('etl.html')

@app.route('/etl/ejecutar', methods=['POST'])
def etl_ejecutar():
    try:
        conn = get_dw_connection()
        cursor = conn.cursor()
        cursor.execute("EXEC sp_ETL_CargarDataWarehouse")
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        
        # Obtener tendencias después del ETL
        conn = get_dw_connection()
        cursor = conn.cursor()
        cursor.execute("EXEC sp_DW_TendenciasMensuales")
        tendencias = cursor.fetchall()
        cursor.close()
        conn.close()
        
        flash(f'ETL ejecutado: {result.mensaje if result else "Completado"}', 'success')
        return render_template('etl_resultados.html', tendencias=tendencias)
    except Exception as e:
        flash(f'Error en ETL: {str(e)}', 'danger')
        return redirect(url_for('etl'))

@app.route('/auditoria')
def auditoria():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT TOP 50 * FROM Auditoria ORDER BY fecha_cambio DESC")
    auditoria = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('auditoria.html', auditoria=auditoria)

# ==================== API ENDPOINTS CORREGIDOS ====================

@app.route('/api/dashboard-data')
def api_dashboard_data():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Estadísticas para el dashboard
    cursor.execute("SELECT COUNT(*) FROM Clientes")
    clientes_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM Oportunidades WHERE estado_oportunidad='Abierto' AND activo=1")
    oportunidades_activas = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM Actividades WHERE estado NOT IN ('Concluido')")
    actividades_pendientes = cursor.fetchone()[0]
    
    # Sumar solo oportunidades abiertas y activas para reflejar el pipeline vigente
    cursor.execute("""
        SELECT ISNULL(SUM(v.monto_ponderado), 0) 
        FROM vw_Oportunidades v
        INNER JOIN Oportunidades o ON v.oportunidad_id = o.oportunidad_id
        WHERE o.activo = 1
          AND o.estado_oportunidad = 'Abierto'
    """)
    monto_total = cursor.fetchone()[0]
    
    # Datos para gráfico de etapas
    cursor.execute("""
        SELECT e.nombre_etapa, COUNT(o.oportunidad_id) as cantidad
        FROM Oportunidades o
        INNER JOIN EtapasOportunidad e ON o.etapa_actual_id = e.etapa_id
        WHERE o.activo = 1 AND o.estado_oportunidad = 'Abierto'
        GROUP BY e.nombre_etapa, e.orden
        ORDER BY e.orden
    """)
    etapas_data = cursor.fetchall()
    
    # Últimas actividades
    cursor.execute("""
        SELECT TOP 5 a.asunto, a.fecha, c.nombre_comercial, e.nombre + ' ' + e.apellido as responsable
        FROM Actividades a
        INNER JOIN Clientes c ON a.cliente_id = c.cliente_id
        INNER JOIN Empleados e ON a.empleado_responsable_id = e.empleado_id
        WHERE a.fecha >= CAST(GETDATE() AS DATE)
        ORDER BY a.fecha ASC
    """)
    ultimas_actividades = [{'asunto': row[0], 'fecha': str(row[1]), 'nombre_comercial': row[2], 'responsable': row[3]} 
                           for row in cursor.fetchall()]
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'clientes_count': clientes_count,
        'oportunidades_activas': oportunidades_activas,
        'actividades_pendientes': actividades_pendientes,
        'monto_total': float(monto_total),
        'etapas_labels': [row[0] for row in etapas_data],
        'etapas_values': [row[1] for row in etapas_data],
        'ultimas_actividades': ultimas_actividades
    })

@app.route('/api/pipeline-data')
def api_pipeline_data():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT e.nombre_etapa, 
               COUNT(o.oportunidad_id) as cantidad,
               ISNULL(SUM(o.monto_potencial), 0) as monto_total
        FROM Oportunidades o
        INNER JOIN EtapasOportunidad e ON o.etapa_actual_id = e.etapa_id
        WHERE o.activo = 1 AND o.estado_oportunidad = 'Abierto'
        GROUP BY e.nombre_etapa, e.orden
        ORDER BY e.orden
    """)
    data = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return jsonify({
        'etapas': [row[0] for row in data],
        'cantidades': [row[1] for row in data],
        'montos': [float(row[2]) for row in data]
    })

@app.route('/api/dw-stats')
def api_dw_stats():
    conn = get_dw_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM Fact_Oportunidades")
    total_opp = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM Dim_Cliente")
    total_clientes = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM Dim_Empleado")
    total_empleados = cursor.fetchone()[0]
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'total_oportunidades': total_opp,
        'total_clientes': total_clientes,
        'total_empleados': total_empleados
    })

# ==================== RUTAS ADICIONALES ====================

@app.route('/cliente/<int:cliente_id>')
def cliente_ver(cliente_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC sp_Cliente_GetById ?", cliente_id)
    cliente = cursor.fetchone()
    
    cursor.execute("EXEC sp_Actividad_GetByCliente ?", cliente_id)
    actividades = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('cliente_detalle.html', cliente=cliente, actividades=actividades)

@app.route('/cliente/<int:cliente_id>/delete', methods=['POST'])
def cliente_delete(cliente_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC sp_Cliente_Delete ?", cliente_id)
    conn.commit()
    cursor.close()
    conn.close()
    flash('Cliente eliminado exitosamente', 'success')
    return redirect(url_for('clientes'))



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)