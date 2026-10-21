import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('FEAT-001: Clasificación por prioridad', () {
    test('1. Incidencia antigua sin campo prioridad se inicializa con Media por defecto', () {
      final jsonAntiguo = {
        'id': 'INC-ANTIGUO',
        'titulo': 'Servidor no responde',
        'descripcion': 'Falla general sin prioridad previa',
        'cliente': 'Banco Central',
        'categoria': 'Redes',
        'estado': 'Pendiente',
        'fecha': '2026-10-01',
      };

      final incidencia = Incidencia.desdeJson(jsonAntiguo);
      expect(incidencia.prioridad, 'Media',
          reason: 'Datos legados sin prioridad deben cargar como Media');
      expect(incidencia.toJson()['prioridad'], 'Media');
    });

    test('2. Normalización de valores inválidos de prioridad a Media', () {
      final jsonInvalido = {
        'id': 'INC-INV',
        'titulo': 'Prueba invalida',
        'descripcion': 'Descripcion',
        'cliente': 'Cliente',
        'categoria': 'Software',
        'estado': 'Pendiente',
        'fecha': '2026-10-01',
        'prioridad': 'UrgenteSuperCritica', // Valor no permitido
      };

      final incidencia = Incidencia.desdeJson(jsonInvalido);
      expect(incidencia.prioridad, 'Media',
          reason: 'Valores desconocidos o no permitidos deben normalizarse a Media');
    });

    test('3. Creación de una incidencia con prioridad Alta y persistencia', () async {
      final gestor1 = GestorIncidencias();
      await gestor1.iniciar();

      await gestor1.crear(
        'Falla de firewall crítico',
        'Ataque DDoS detectado',
        'Corporativo Sol',
        'Redes',
        'Alta',
      );

      final creada = gestor1.incidencias.first;
      expect(creada.prioridad, 'Alta');
      expect(creada.titulo, 'Falla de firewall crítico');

      // Simular reinicio de aplicación para verificar persistencia
      final gestor2 = GestorIncidencias();
      await gestor2.iniciar();

      final recuperada = gestor2.porId(creada.id);
      expect(recuperada, isNotNull);
      expect(recuperada!.prioridad, 'Alta',
          reason: 'La prioridad Alta asignada en creación debe persistir tras reinicio');
    });

    test('4. Modificación de prioridad desde el gestor y comprobación de persistencia', () async {
      final gestor1 = GestorIncidencias();
      await gestor1.iniciar();

      // Tomamos INC-101 que inicia con prioridad por defecto
      final inc = gestor1.porId('INC-101');
      expect(inc, isNotNull);
      expect(inc!.prioridad, 'Media');

      // Modificamos a Baja
      await gestor1.cambiarPrioridad('INC-101', 'Baja');
      expect(gestor1.porId('INC-101')!.prioridad, 'Baja');

      // Reinicio simulado
      final gestor2 = GestorIncidencias();
      await gestor2.iniciar();

      expect(gestor2.porId('INC-101')!.prioridad, 'Baja',
          reason: 'El cambio de prioridad a Baja debe persistir');

      // Modificamos a Alta
      await gestor2.cambiarPrioridad('INC-101', 'Alta');
      expect(gestor2.porId('INC-101')!.prioridad, 'Alta');

      // Reinicio simulado 2
      final gestor3 = GestorIncidencias();
      await gestor3.iniciar();
      expect(gestor3.porId('INC-101')!.prioridad, 'Alta',
          reason: 'El cambio de prioridad a Alta debe persistir');
    });

    test('5. No rompe funciones previas: cambio de estado, contador y búsqueda', () async {
      final gestor = GestorIncidencias();
      await gestor.iniciar();

      final pendientesAntes = gestor.contar('Pendiente');
      await gestor.cambiarEstado('INC-101', 'Resuelta');
      expect(gestor.contar('Pendiente'), pendientesAntes - 1);
      expect(gestor.contar('Resuelta'), greaterThan(0));

      final busqueda = gestor.buscar('wifi');
      expect(busqueda.length, 1);
      expect(busqueda.first.id, 'INC-102');
    });
  });
}
