import 'package:flutter_test/flutter_test.dart';
import 'package:gontech_flow_v2/core/models/firma.dart';

void main() {
  group('Firma', () {
    test('fromMap crea una firma correctamente', () {
      final map = {
        'id_firma': 1,
        'id_entrega': 5,
        'nombre': 'Juan Perez',
        'rut': '12.345.678-9',
        'firma_path': '/path/firma.png',
        'fecha': '2025-06-01T10:00:00',
      };

      final firma = Firma.fromMap(map);

      expect(firma.idFirma, 1);
      expect(firma.idEntrega, 5);
      expect(firma.nombre, 'Juan Perez');
      expect(firma.rut, '12.345.678-9');
      expect(firma.firmaPath, '/path/firma.png');
      expect(firma.fecha, '2025-06-01T10:00:00');
    });

    test('toMap genera mapa correcto', () {
      final firma = Firma(
        idEntrega: 10,
        nombre: 'Test',
        rut: '11.111.111-1',
        firmaPath: '/firma.png',
        fecha: '2025-01-01',
      );

      final map = firma.toMap();

      expect(map['id_entrega'], 10);
      expect(map['nombre'], 'Test');
      expect(map['firma_path'], '/firma.png');
      expect(map['fecha'], '2025-01-01');
    });

    test('toMap usa fecha actual cuando fecha es null', () {
      final firma = Firma(idEntrega: 1);
      final map = firma.toMap();
      expect(map['fecha'], isNotNull);
      expect(map['fecha'], isA<String>());
    });
  });
}
