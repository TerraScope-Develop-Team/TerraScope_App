import 'package:flutter_test/flutter_test.dart';
import 'package:terrascope/components/models/reto_model.dart';

void main() {
  group('Reto.fromJson condiciones', () {
    test('lee el id que serializa Prisma y conserva el alias _id', () {
      final prismaReto = Reto.fromJson({
        'id': '507f1f77bcf86cd799439011',
        'condiciones': {'fauna.Ave': 1},
      });
      final legacyReto = Reto.fromJson({
        '_id': '507f1f77bcf86cd799439012',
        'condiciones': {'fauna.Ave': 1},
      });

      expect(prismaReto.id, '507f1f77bcf86cd799439011');
      expect(legacyReto.id, '507f1f77bcf86cd799439012');
    });

    test('aplana condiciones anidadas de fauna y flora', () {
      final reto = Reto.fromJson({
        '_id': 'reto-1',
        'condiciones': {
          'fauna': {'Ave': 2},
          'flora': {'Arbol': 1},
        },
      });

      expect(reto.condiciones, {'fauna.Ave': 2, 'flora.Arbol': 1});
    });

    test('conserva compatibilidad con condiciones planas', () {
      final reto = Reto.fromJson({
        '_id': 'reto-2',
        'condiciones': {'fauna.Ave': 3},
      });

      expect(reto.condiciones, {'fauna.Ave': 3});
    });

    test('convierte cantidades numéricas decimales a enteros', () {
      final reto = Reto.fromJson({
        '_id': 'reto-3',
        'condiciones': {
          'fauna': {'Ave': 2.0},
        },
      });

      expect(reto.condiciones['fauna.Ave'], 2);
    });

    test('rechaza una condición cuyo requisito no sea numérico', () {
      expect(
        () => Reto.fromJson({
          '_id': 'reto-4',
          'condiciones': {
            'fauna': {'Ave': 'dos'},
          },
        }),
        throwsFormatException,
      );
    });
  });
}
