import 'package:flutter_test/flutter_test.dart';
import 'package:gontech_flow_v2/core/models/usuario.dart';

void main() {
  group('Usuario', () {
    test('fromMap crea un usuario correctamente', () {
      final map = {
        'id_usuario': 1,
        'nombre': 'Admin Test',
        'correo': 'admin@test.cl',
        'contrasena': 'hashedpass',
        'rol': 'admin',
        'creado_en': '2025-01-01T00:00:00',
        'actualizado_en': null,
      };

      final usuario = Usuario.fromMap(map);

      expect(usuario.idUsuario, 1);
      expect(usuario.nombre, 'Admin Test');
      expect(usuario.correo, 'admin@test.cl');
      expect(usuario.contrasena, 'hashedpass');
      expect(usuario.rol, 'admin');
      expect(usuario.creadoEn, '2025-01-01T00:00:00');
      expect(usuario.actualizadoEn, isNull);
    });

    test('toMap genera un mapa correcto para SQLite', () {
      final usuario = Usuario(
        idUsuario: 5,
        nombre: 'Tecnico',
        correo: 'tec@test.cl',
        contrasena: 'hash123',
        rol: 'tecnico',
      );

      final map = usuario.toMap();

      expect(map['id_usuario'], 5);
      expect(map['nombre'], 'Tecnico');
      expect(map['correo'], 'tec@test.cl');
      expect(map['contrasena'], 'hash123');
      expect(map['rol'], 'tecnico');
    });

    test('roundtrip toMap -> fromMap preserva datos', () {
      final original = Usuario(
        nombre: 'Test',
        correo: 'test@test.cl',
        contrasena: 'abc',
        rol: 'cliente',
      );

      final restored = Usuario.fromMap(original.toMap());

      expect(restored.nombre, original.nombre);
      expect(restored.correo, original.correo);
      expect(restored.contrasena, original.contrasena);
      expect(restored.rol, original.rol);
    });
  });
}
