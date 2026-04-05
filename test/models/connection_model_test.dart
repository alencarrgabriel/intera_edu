import 'package:flutter_test/flutter_test.dart';
import 'package:intera_edu/data/models/connection_model.dart';

void main() {
  group('Connection.fromJson', () {
    test('parseia conexão com other_user completo', () {
      final json = {
        'id': 'conn1',
        'status': 'accepted',
        'direction': null,
        'created_at': '2026-01-10T08:00:00.000Z',
        'other_user': {
          'id': 'u5',
          'full_name': 'Pedro Silva',
          'course': 'Direito',
          'avatar_url': null,
          'institution': {'id': 'i2', 'name': 'USP', 'slug': 'usp'},
        },
      };

      final conn = Connection.fromJson(json);

      expect(conn.id, 'conn1');
      expect(conn.status, 'accepted');
      expect(conn.otherUser, isNotNull);
      expect(conn.otherUser!.fullName, 'Pedro Silva');
      expect(conn.otherUser!.institution?.name, 'USP');
    });

    test('otherUser é null quando ausente no JSON', () {
      final json = {
        'id': 'conn2',
        'status': 'pending',
        'created_at': '2026-01-11T08:00:00.000Z',
      };

      final conn = Connection.fromJson(json);
      expect(conn.otherUser, isNull);
    });
  });
}
