import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('BUG-001: El cambio de estado debe persistir tras reiniciar el gestor', () async {
    // 1. Instancia inicial del gestor (primera sesión de la app)
    final gestor1 = GestorIncidencias();
    await gestor1.iniciar();

    // Verificamos el estado inicial de INC-101
    final incInicial = gestor1.porId('INC-101');
    expect(incInicial, isNotNull);
    expect(incInicial!.estado, 'Pendiente');

    // 2. Modificamos el estado a 'Resuelta'
    await gestor1.cambiarEstado('INC-101', 'Resuelta');
    expect(gestor1.porId('INC-101')!.estado, 'Resuelta');

    // 3. Simulamos reinicio de la aplicación creando una nueva instancia del gestor
    final gestor2 = GestorIncidencias();
    await gestor2.iniciar();

    // 4. Comprobamos si el estado persiste tras el reinicio
    final incReiniciada = gestor2.porId('INC-101');
    expect(incReiniciada, isNotNull);
    expect(
      incReiniciada!.estado,
      'Resuelta',
      reason: 'El cambio de estado debe persistir en el almacenamiento local tras reiniciar la app',
    );
  });
}
