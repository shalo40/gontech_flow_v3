import 'package:flutter_test/flutter_test.dart';
import 'package:gontech_flow_v2/core/models/cliente.dart';

void main() {
  group('Cliente', () {
    test('fromMap crea un cliente correctamente', () {
      final map = {
        'id_cliente': 1,
        'nombre': 'Gonzalo Castillo',
        'rut': '12.345.678-9',
        'telefono': '912345678',
        'correo': 'gonzalo@test.cl',
        'direccion': 'Antofagasta Centro',
        'notas': 'Cliente VIP',
        'foto_path': '/path/foto.jpg',
      };

      final cliente = Cliente.fromMap(map);

      expect(cliente.idCliente, 1);
      expect(cliente.nombre, 'Gonzalo Castillo');
      expect(cliente.rut, '12.345.678-9');
      expect(cliente.telefono, '912345678');
      expect(cliente.correo, 'gonzalo@test.cl');
      expect(cliente.direccion, 'Antofagasta Centro');
      expect(cliente.notas, 'Cliente VIP');
      expect(cliente.fotoPath, '/path/foto.jpg');
    });

    test('toMap genera mapa correcto para SQLite', () {
      final cliente = Cliente(
        idCliente: 2,
        nombre: 'Michelle',
        rut: '11.111.111-1',
        telefono: '998877',
        correo: 'mich@test.cl',
        direccion: 'Sur',
        notas: 'Nota',
      );

      final map = cliente.toMap();

      expect(map['id_cliente'], 2);
      expect(map['nombre'], 'Michelle');
      expect(map['rut'], '11.111.111-1');
      expect(map['telefono'], '998877');
    });

    test('fromMap con campos nulos no lanza error', () {
      final map = <String, dynamic>{
        'id_cliente': null,
        'nombre': null,
        'rut': null,
        'telefono': null,
        'correo': null,
        'direccion': null,
        'notas': null,
        'foto_path': null,
      };

      final cliente = Cliente.fromMap(map);
      expect(cliente.nombre, '');
      expect(cliente.rut, isNull);
      expect(cliente.fotoPath, isNull);
    });

    test('rut es de tipo String? (nullable)', () {
      final sinRut = Cliente(
        nombre: 'Test',
        telefono: '',
        correo: '',
        direccion: '',
        notas: '',
      );
      expect(sinRut.rut, isNull);

      final conRut = Cliente(
        nombre: 'Test',
        rut: '12.345.678-9',
        telefono: '',
        correo: '',
        direccion: '',
        notas: '',
      );
      expect(conRut.rut, '12.345.678-9');
    });
  });
}
