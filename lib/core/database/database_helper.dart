import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // ================================
  // 🚀 Inicialización de la BD
  // ================================
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'gontech_flow_v3.db');
    return await openDatabase(
      path,
      version: 8, // ⬅️ Subimos versión para forzar onUpgrade()
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🧱 Creando estructura completa Gontech Flow v3...');
    await _createClientes(db);
    await _createEquipos(db);
    await _createIngresos(db);
    await _createDiagnosticos(db);
    await _createPresupuestos(db);
    await _createReparaciones(db);
    await _createRepuestos(db);
    await _createEntregas(db);
    await _createFirmas(db);
    await _createUsuarios(db);
    await _createTareas(db);
    await _createHistorial(db);
  }

  // ================================
  // 🧠 MIGRACIONES / UPGRADES
  // ================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('⬆️ Migrando base de datos de v$oldVersion a v$newVersion...');

    // --- CLIENTES ---
    final columnasClientes = await db.rawQuery('PRAGMA table_info(clientes)');
    if (!columnasClientes.any((c) => c['name'] == 'foto_path')) {
      await db.execute(
        "ALTER TABLE clientes ADD COLUMN foto_path TEXT DEFAULT '';",
      );
      debugPrint('✅ Columna foto_path agregada correctamente a clientes.');
    }

    // --- PRESUPUESTOS ---
    final columnasPresupuestos = await db.rawQuery(
      'PRAGMA table_info(presupuestos)',
    );
    if (!columnasPresupuestos.any((c) => c['name'] == 'fecha_creacion')) {
      await db.execute(
        "ALTER TABLE presupuestos ADD COLUMN fecha_creacion TEXT;",
      );
      debugPrint(
        '✅ Columna fecha_creacion agregada correctamente a presupuestos.',
      );
    }
    // --- REPUESTOS ---
    final columnasRepuestos = await db.rawQuery('PRAGMA table_info(repuestos)');
    final tieneIdDiagnostico = columnasRepuestos.any(
      (c) => c['name'] == 'id_diagnostico',
    );
    if (!tieneIdDiagnostico) {
      await db.execute(
        "ALTER TABLE repuestos ADD COLUMN id_diagnostico INTEGER;",
      );
      debugPrint(
        '✅ Columna id_diagnostico agregada correctamente a repuestos.',
      );
    }

    final tieneFechaRegistro = columnasRepuestos.any(
      (c) => c['name'] == 'fecha_registro',
    );
    if (!tieneFechaRegistro) {
      await db.execute(
        "ALTER TABLE repuestos ADD COLUMN fecha_registro TEXT DEFAULT CURRENT_TIMESTAMP;",
      );
      debugPrint(
        '✅ Columna fecha_registro agregada correctamente a repuestos.',
      );
    }
    // --- ENTREGAS ---
    final columnasEntregas = await db.rawQuery('PRAGMA table_info(entregas)');
    final tieneIdReparacion = columnasEntregas.any(
      (c) => c['name'] == 'id_reparacion',
    );
    if (!tieneIdReparacion) {
      await db.execute(
        "ALTER TABLE entregas ADD COLUMN id_reparacion INTEGER;",
      );
      debugPrint('✅ Columna id_reparacion agregada correctamente a entregas.');
    }

    final tieneFirmaCliente = columnasEntregas.any(
      (c) => c['name'] == 'firma_cliente',
    );
    if (!tieneFirmaCliente) {
      await db.execute(
        "ALTER TABLE entregas ADD COLUMN firma_cliente TEXT DEFAULT '';",
      );
      debugPrint('✅ Columna firma_cliente agregada correctamente a entregas.');
    }

    final tieneEstado = columnasEntregas.any((c) => c['name'] == 'estado');
    if (!tieneEstado) {
      await db.execute(
        "ALTER TABLE entregas ADD COLUMN estado TEXT DEFAULT 'pendiente_pdf';",
      );
      debugPrint('✅ Columna estado agregada correctamente a entregas.');
    }
  }

  // ================================
  // 🧱 ESTRUCTURAS DE TABLAS
  // ================================

  Future<void> _createClientes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id_cliente INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        correo TEXT,
        direccion TEXT,
        notas TEXT,
        foto_path TEXT
      );
    ''');
  }

  Future<void> _createEquipos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS equipos (
        id_equipo INTEGER PRIMARY KEY AUTOINCREMENT,
        id_cliente INTEGER NOT NULL,
        tipo_equipo TEXT,
        marca TEXT,
        modelo TEXT,
        numero_serie TEXT,
        descripcion TEXT,
        foto_path TEXT,
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_equipo_cliente ON equipos(id_cliente);',
    );
  }

  Future<void> _createIngresos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ingresos (
        id_ingreso INTEGER PRIMARY KEY AUTOINCREMENT,
        id_equipo INTEGER NOT NULL,
        fecha_ingreso TEXT NOT NULL,
        accesorios TEXT,
        observaciones TEXT,
        estado_ingreso TEXT DEFAULT 'pendiente',
        qr_code TEXT,
        FOREIGN KEY (id_equipo) REFERENCES equipos(id_equipo) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ingreso_equipo ON ingresos(id_equipo);',
    );
  }

  Future<void> _createDiagnosticos(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS diagnosticos (
      id_diagnostico INTEGER PRIMARY KEY AUTOINCREMENT,
      id_ingreso INTEGER NOT NULL,
      id_tecnico INTEGER,
      descripcion_falla TEXT,
      pruebas_realizadas TEXT,
      conclusiones TEXT,
      estado TEXT DEFAULT 'pendiente',
      creado_en TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (id_ingreso) REFERENCES ingresos(id_ingreso) ON DELETE CASCADE
    );
  ''');
  }

  Future<void> _createPresupuestos(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS presupuestos (
      id_presupuesto INTEGER PRIMARY KEY AUTOINCREMENT,
      id_diagnostico INTEGER NOT NULL,
      descripcion TEXT,
      total REAL,
      estado TEXT DEFAULT 'pendiente',
      fecha_creacion TEXT,
      FOREIGN KEY (id_diagnostico) REFERENCES diagnosticos(id_diagnostico) ON DELETE CASCADE
    );
  ''');
  }

  Future<void> _createReparaciones(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS reparaciones (
      id_reparacion INTEGER PRIMARY KEY AUTOINCREMENT,
      id_presupuesto INTEGER,  -- 🔥 nuevo campo
      id_diagnostico INTEGER NOT NULL,
      id_tecnico INTEGER,
      descripcion TEXT,
      fecha_inicio TEXT,
      fecha_fin TEXT,
      estado TEXT DEFAULT 'pendiente', -- pendiente | en_proceso | finalizada
      notas TEXT,
      FOREIGN KEY (id_presupuesto) REFERENCES presupuestos(id_presupuesto) ON DELETE SET NULL,
      FOREIGN KEY (id_diagnostico) REFERENCES diagnosticos(id_diagnostico) ON DELETE CASCADE
    );
  ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_reparaciones_diag ON reparaciones(id_diagnostico);',
    );
  }

  Future<void> _createRepuestos(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS repuestos (
      id_repuesto INTEGER PRIMARY KEY AUTOINCREMENT,
      id_diagnostico INTEGER,
      id_presupuesto INTEGER NOT NULL,
      nombre TEXT,
      cantidad INTEGER DEFAULT 1,
      costo_unitario REAL,
      proveedor TEXT,
      estado TEXT DEFAULT 'sugerido', -- sugerido | instalado | rechazado
      origen TEXT DEFAULT 'diagnostico',
      fecha_registro TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (id_diagnostico) REFERENCES diagnosticos(id_diagnostico) ON DELETE CASCADE,
      FOREIGN KEY (id_presupuesto) REFERENCES presupuestos(id_presupuesto) ON DELETE CASCADE
    );
  ''');
  }

  Future<void> _createEntregas(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS entregas (
      id_entrega INTEGER PRIMARY KEY AUTOINCREMENT,
      id_reparacion INTEGER NOT NULL,
      nombre_receptor TEXT,
      rut_receptor TEXT,
      observaciones TEXT,
      firma_path TEXT,
      fecha_entrega TEXT DEFAULT CURRENT_TIMESTAMP,
      estado TEXT DEFAULT 'entregado', -- entregado | pendiente | anulado
      FOREIGN KEY (id_reparacion) REFERENCES reparaciones(id_reparacion) ON DELETE CASCADE
    );
  ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entregas_reparacion ON entregas(id_reparacion);',
    );
  }

  Future<void> _createFirmas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS firmas (
        id_firma INTEGER PRIMARY KEY AUTOINCREMENT,
        id_entrega INTEGER,
        nombre TEXT,
        rut TEXT,
        firma_path TEXT,
        fecha TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_entrega) REFERENCES entregas(id_entrega) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _createUsuarios(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        correo TEXT,
        contrasena TEXT,
        rol TEXT DEFAULT 'tecnico'
      );
    ''');
  }

  Future<void> _createTareas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tareas (
        id_tarea INTEGER PRIMARY KEY AUTOINCREMENT,
        id_reparacion INTEGER,
        descripcion TEXT,
        estado TEXT DEFAULT 'pendiente',
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
        fecha_fin TEXT,
        FOREIGN KEY (id_reparacion) REFERENCES reparaciones(id_reparacion) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _createHistorial(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historial (
        id_historial INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER,
        accion TEXT,
        entidad TEXT,
        id_entidad INTEGER,
        fecha_accion TEXT DEFAULT CURRENT_TIMESTAMP,
        descripcion TEXT,
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
      );
    ''');
  }
}
