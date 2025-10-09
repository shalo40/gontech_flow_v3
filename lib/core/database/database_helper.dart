import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instancia = DatabaseHelper._interno();
  DatabaseHelper._interno();
  factory DatabaseHelper() => _instancia;

  static Database? _db;

  static const int _dbVersion = 13; // ✅ versión final
  static const String _dbName = 'gontech_flow_v3.db';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _inicializarDb();
    return _db!;
  }

  Future<Database> _inicializarDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final rutaDb = p.join(dir.path, _dbName);

    return await openDatabase(
      rutaDb,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ===========================
  // CREACIÓN INICIAL
  // ===========================
  Future<void> _onCreate(Database db, int version) async {
    await _createUsuarios(db);
    await _seedAdmin(db);

    await _createClientes(db);
    await _createFirmas(db);
    await _createEquipos(db);
    await _createIngresos(db);
    await _createDiagnosticos(db);
    await _createTareas(db);
    await _createPresupuestos(db);
    await _createRepuestos(db);
    await _createReparaciones(db);
    await _createInformes(db);
    await _createEntregas(db);
    await _createHistorial(db);

    print('✅ Base de datos GontechFlow v$version creada exitosamente.');
  }

  // ===========================
  // MIGRACIONES
  // ===========================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 13) {
      await _createReparaciones(db);
      await _createEntregas(db);
      print('🧩 Migración completada a versión $newVersion');
    }
  }

  // ===========================
  // TABLAS DEFINITIVAS
  // ===========================

  Future<void> _createUsuarios(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        rol TEXT NOT NULL DEFAULT 'admin',
        creado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_usuarios_correo ON usuarios(correo);',
    );
  }

  Future<void> _seedAdmin(Database db) async {
    final existe = await db.query(
      'usuarios',
      where: 'correo=?',
      whereArgs: ['admin@gontech.cl'],
      limit: 1,
    );
    if (existe.isEmpty) {
      await db.insert('usuarios', {
        'nombre': 'Administrador',
        'correo': 'admin@gontech.cl',
        'contrasena': '1234', // ⚠️ cambiar por hash en producción
        'rol': 'admin',
      });
    }
  }

  Future<void> _createClientes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id_cliente INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        rut TEXT,
        telefono TEXT,
        correo TEXT,
        direccion TEXT,
        notas TEXT,
        creado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  Future<void> _createFirmas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS firmas (
        id_firma INTEGER PRIMARY KEY AUTOINCREMENT,
        imagen_base64 TEXT,
        nombre_firmante TEXT,
        fecha_firma TEXT DEFAULT CURRENT_TIMESTAMP
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
        creado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _createIngresos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ingresos (
        id_ingreso INTEGER PRIMARY KEY AUTOINCREMENT,
        id_equipo INTEGER NOT NULL,
        fecha_ingreso TEXT,
        accesorios TEXT,
        observaciones TEXT,
        estado_ingreso TEXT,
        firma_cliente INTEGER,
        creado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_equipo) REFERENCES equipos(id_equipo) ON DELETE CASCADE,
        FOREIGN KEY (firma_cliente) REFERENCES firmas(id_firma) ON DELETE SET NULL
      );
    ''');
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
        estado TEXT,
        creado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_ingreso) REFERENCES ingresos(id_ingreso) ON DELETE CASCADE,
        FOREIGN KEY (id_tecnico) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
      );
    ''');
  }

  Future<void> _createTareas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tareas (
        id_tarea INTEGER PRIMARY KEY AUTOINCREMENT,
        id_diagnostico INTEGER NOT NULL,
        descripcion TEXT,
        tecnico_asignado INTEGER,
        fecha_inicio TEXT,
        fecha_fin TEXT,
        estado TEXT,
        notas TEXT,
        FOREIGN KEY (id_diagnostico) REFERENCES diagnosticos(id_diagnostico) ON DELETE CASCADE,
        FOREIGN KEY (tecnico_asignado) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
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
        estado TEXT,
        fecha_creacion TEXT,
        FOREIGN KEY (id_diagnostico) REFERENCES diagnosticos(id_diagnostico) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _createRepuestos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS repuestos (
        id_repuesto INTEGER PRIMARY KEY AUTOINCREMENT,
        id_presupuesto INTEGER NOT NULL,
        nombre TEXT,
        cantidad INTEGER,
        costo_unitario REAL,
        proveedor TEXT,
        estado TEXT,
        FOREIGN KEY (id_presupuesto) REFERENCES presupuestos(id_presupuesto) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _createReparaciones(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reparaciones (
        id_reparacion INTEGER PRIMARY KEY AUTOINCREMENT,
        id_diagnostico INTEGER NOT NULL,
        descripcion_trabajo TEXT,
        observaciones TEXT,
        fecha_inicio TEXT,
        estado TEXT,
        FOREIGN KEY (id_diagnostico) REFERENCES diagnosticos(id_diagnostico) ON DELETE CASCADE
      );
    ''');
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
        actualizado_en TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_diagnostico) REFERENCES diagnosticos(id_diagnostico) ON DELETE CASCADE,
        FOREIGN KEY (id_tecnico) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
      );
    ''');
  }

  Future<void> _createEntregas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entregas (
        id_entrega INTEGER PRIMARY KEY AUTOINCREMENT,
        id_reparacion INTEGER NOT NULL,
        fecha_entrega TEXT,
        observaciones TEXT,
        firma_cliente TEXT,
        estado TEXT,
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
