import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../session/password_hasher.dart';

class DatabaseHelper {
  // ============================================================
  // 🔹 SINGLETON SEGURO (versión final)
  // ============================================================
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // ============================================================
  // 🚀 Inicialización de la BD
  // ============================================================
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'gontech_flow_v3.db');
    return await openDatabase(
      path,
      version: 11,
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
    await _createInformes(db);
    await _createFirmas(db);
    await _createUsuarios(db);
    await _createTareas(db);
    await _createHistorial(db);
  }

  // ============================================================
  // 🧠 MIGRACIONES / UPGRADES
  // ============================================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('⬆️ Migrando base de datos de v$oldVersion a v$newVersion...');

    // --- CLIENTES ---
    final columnasClientes = await db.rawQuery('PRAGMA table_info(clientes)');
    if (!columnasClientes.any((c) => c['name'] == 'foto_path')) {
      await db.execute(
        "ALTER TABLE clientes ADD COLUMN foto_path TEXT DEFAULT '';",
      );
    }
    if (!columnasClientes.any((c) => c['name'] == 'rut')) {
      await db.execute(
        "ALTER TABLE clientes ADD COLUMN rut TEXT DEFAULT '';",
      );
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
    if (!columnasRepuestos.any((c) => c['name'] == 'id_diagnostico')) {
      await db.execute(
        "ALTER TABLE repuestos ADD COLUMN id_diagnostico INTEGER;",
      );
      debugPrint(
        '✅ Columna id_diagnostico agregada correctamente a repuestos.',
      );
    }
    if (!columnasRepuestos.any((c) => c['name'] == 'fecha_registro')) {
      await db.execute(
        "ALTER TABLE repuestos ADD COLUMN fecha_registro TEXT DEFAULT CURRENT_TIMESTAMP;",
      );
      debugPrint(
        '✅ Columna fecha_registro agregada correctamente a repuestos.',
      );
    }

    // --- ENTREGAS ---
    final columnasEntregas = await db.rawQuery('PRAGMA table_info(entregas)');
    if (!columnasEntregas.any((c) => c['name'] == 'id_reparacion')) {
      await db.execute(
        "ALTER TABLE entregas ADD COLUMN id_reparacion INTEGER;",
      );
      debugPrint('✅ Columna id_reparacion agregada correctamente a entregas.');
    }
    if (!columnasEntregas.any((c) => c['name'] == 'firma_cliente')) {
      await db.execute(
        "ALTER TABLE entregas ADD COLUMN firma_cliente TEXT DEFAULT '';",
      );
      debugPrint('✅ Columna firma_cliente agregada correctamente a entregas.');
    }
    if (!columnasEntregas.any((c) => c['name'] == 'estado')) {
      await db.execute(
        "ALTER TABLE entregas ADD COLUMN estado TEXT DEFAULT 'pendiente_pdf';",
      );
      debugPrint('Columna estado agregada correctamente a entregas.');
    }

    // --- v9: MIGRAR CONTRASEÑAS A SHA-256 ---
    if (oldVersion < 9) {
      await _migratePasswords(db);
    }

    // --- v10: TABLA INFORMES ---
    if (oldVersion < 10) {
      await _createInformes(db);
      debugPrint('✅ Tabla informes creada en migracion v10.');
    }

    // --- v11: REESCRITURA DE ESQUEMAS DESINCRONIZADOS ---
    // Se recrean clientes, tareas, historial y usuarios con columnas alineadas
    // a los toMap() actuales de cada modelo (el error era: 'table clientes has no column named id').
    if (oldVersion < 11) {
      debugPrint('⬆️ v11: Recreando tablas con esquema sincronizado...');

      // Clientes: PK cambia de id_cliente -> id
      await db.execute('DROP TABLE IF EXISTS clientes;');
      await _createClientes(db);
      debugPrint('✅ Tabla clientes recreada con PK id.');

      // Tareas: esquema completamente rediseñado
      await db.execute('DROP TABLE IF EXISTS tareas;');
      await _createTareas(db);
      debugPrint('✅ Tabla tareas recreada con nuevo esquema.');

      // Historial: esquema completamente rediseñado
      await db.execute('DROP TABLE IF EXISTS historial;');
      await _createHistorial(db);
      debugPrint('✅ Tabla historial recreada con nuevo esquema.');

      // Usuarios: agrega columnas creado_en y actualizado_en
      final columnasUsuarios = await db.rawQuery('PRAGMA table_info(usuarios)');
      if (!columnasUsuarios.any((c) => c['name'] == 'creado_en')) {
        await db.execute("ALTER TABLE usuarios ADD COLUMN creado_en TEXT DEFAULT CURRENT_TIMESTAMP;");
        debugPrint('✅ Columna creado_en agregada a usuarios.');
      }
      if (!columnasUsuarios.any((c) => c['name'] == 'actualizado_en')) {
        await db.execute("ALTER TABLE usuarios ADD COLUMN actualizado_en TEXT DEFAULT CURRENT_TIMESTAMP;");
        debugPrint('✅ Columna actualizado_en agregada a usuarios.');
      }

      debugPrint('✅ Migración v11 completada.');
    }
  }

  Future<void> _migratePasswords(Database db) async {
    final usuarios = await db.query('usuarios');
    for (final u in usuarios) {
      final contrasena = u['contrasena'] as String? ?? '';
      // Si la contraseña no tiene 64 chars (longitud SHA-256 hex), está en texto plano
      if (contrasena.length != 64) {
        final hashed = PasswordHasher.hash(contrasena);
        await db.update(
          'usuarios',
          {'contrasena': hashed},
          where: 'id_usuario = ?',
          whereArgs: [u['id_usuario']],
        );
      }
    }
    debugPrint('Migracion de contrasenas a SHA-256 completada.');
  }

  // ============================================================
  // 🧱 ESTRUCTURAS DE TABLAS
  // ============================================================

  Future<void> _createClientes(Database db) async {
    // ⚠️ PK usa 'id' para coincidir con Cliente.toMap() -> {'id': idCliente, ...}
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        rut TEXT,
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
        id_presupuesto INTEGER,
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

  Future<void> _createInformes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS informes (
        id_informe INTEGER PRIMARY KEY AUTOINCREMENT,
        id_diagnostico INTEGER NOT NULL,
        id_tecnico INTEGER,
        descripcion_general TEXT,
        conclusiones TEXT,
        recomendaciones TEXT,
        creado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_diagnostico) REFERENCES diagnosticos(id_diagnostico) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_informes_diagnostico ON informes(id_diagnostico);',
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
    // ⚠️ Incluye creado_en y actualizado_en para coincidir con Usuario.toMap()
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        correo TEXT,
        contrasena TEXT,
        rol TEXT DEFAULT 'tecnico',
        creado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  Future<void> _createTareas(Database db) async {
    // ⚠️ Esquema alineado con Tarea.toMap(): id, reparacion_id, observaciones, completada_en, created_at
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tareas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reparacion_id INTEGER,
        descripcion TEXT,
        estado TEXT DEFAULT 'pendiente',
        observaciones TEXT,
        completada_en TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (reparacion_id) REFERENCES reparaciones(id_reparacion) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _createHistorial(Database db) async {
    // ⚠️ Esquema alineado con Historial.toMap(): id, entidad_tipo, entidad_id, accion,
    //    descripcion, estado_anterior, estado_nuevo, usuario_nombre, created_at
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entidad_tipo TEXT,
        entidad_id INTEGER,
        accion TEXT,
        descripcion TEXT,
        estado_anterior TEXT,
        estado_nuevo TEXT,
        usuario_nombre TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }
}
