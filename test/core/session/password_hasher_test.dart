import 'package:flutter_test/flutter_test.dart';
import 'package:gontech_flow_v2/core/session/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('hash genera un string de 64 caracteres (SHA-256 hex)', () {
      final result = PasswordHasher.hash('1234');
      expect(result.length, 64);
    });

    test('hash es determinista (mismo input, mismo output)', () {
      final hash1 = PasswordHasher.hash('1234');
      final hash2 = PasswordHasher.hash('1234');
      expect(hash1, hash2);
    });

    test('hash produce resultados diferentes para inputs diferentes', () {
      final hash1 = PasswordHasher.hash('1234');
      final hash2 = PasswordHasher.hash('5678');
      expect(hash1, isNot(hash2));
    });

    test('verify retorna true para contrasena correcta', () {
      final hashed = PasswordHasher.hash('miPassword');
      expect(PasswordHasher.verify('miPassword', hashed), true);
    });

    test('verify retorna false para contrasena incorrecta', () {
      final hashed = PasswordHasher.hash('miPassword');
      expect(PasswordHasher.verify('otraPassword', hashed), false);
    });

    test('hash no almacena la contrasena original', () {
      final hashed = PasswordHasher.hash('1234');
      expect(hashed, isNot('1234'));
      expect(hashed.contains('1234'), false);
    });
  });
}
