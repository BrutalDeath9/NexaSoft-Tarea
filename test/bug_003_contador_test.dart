import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GestorIncidencias gestor;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    gestor = GestorIncidencias();
    await gestor.iniciar();
  });

  group('BUG-003: Contador de incidencias pendientes', () {
    test('1. El contador inicial de pendientes debe corresponder a la lista real', () {
      final reales = gestor.incidencias.where((x) => x.estado == 'Pendiente').length;
      expect(gestor.contar('Pendiente'), reales);
      expect(gestor.cantidadPendientes, reales);
    });

    test('2. Al cambiar una incidencia de Pendiente a Resuelta, el contador debe disminuir', () async {
      final pendientesAntes = gestor.contar('Pendiente');
      final resueltasAntes = gestor.contar('Resuelta');

      // INC-101 inicia en estado 'Pendiente'
      expect(gestor.porId('INC-101')?.estado, 'Pendiente');

      await gestor.cambiarEstado('INC-101', 'Resuelta');

      expect(gestor.porId('INC-101')?.estado, 'Resuelta');
      expect(
        gestor.contar('Pendiente'),
        pendientesAntes - 1,
        reason: 'El contador de pendientes debe disminuir en 1 al pasar a Resuelta',
      );
      expect(
        gestor.cantidadPendientes,
        pendientesAntes - 1,
        reason: 'La propiedad cantidadPendientes debe coincidir con el número real de pendientes',
      );
      expect(
        gestor.contar('Resuelta'),
        resueltasAntes + 1,
        reason: 'El contador de resueltas debe aumentar en 1',
      );
    });

    test('3. Al crear una nueva incidencia pendiente, el contador debe aumentar', () async {
      final pendientesAntes = gestor.contar('Pendiente');

      await gestor.crear('Nueva falla', 'Descripción', 'Cliente A', 'Software');

      expect(
        gestor.contar('Pendiente'),
        pendientesAntes + 1,
        reason: 'El contador de pendientes debe aumentar en 1 al crear una incidencia',
      );
    });

    test('4. Al cambiar una incidencia de Resuelta a Pendiente, el contador debe aumentar', () async {
      // INC-104 inicia en estado 'Resuelta'
      expect(gestor.porId('INC-104')?.estado, 'Resuelta');
      final pendientesAntes = gestor.contar('Pendiente');

      await gestor.cambiarEstado('INC-104', 'Pendiente');

      expect(gestor.porId('INC-104')?.estado, 'Pendiente');
      expect(
        gestor.contar('Pendiente'),
        pendientesAntes + 1,
        reason: 'El contador de pendientes debe aumentar en 1 al cambiar a Pendiente',
      );
    });
  });
}
