import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GestorIncidencias gestor;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    gestor = GestorIncidencias();
    // Cargamos una lista controlada de incidencias para probar la búsqueda
    gestor.incidencias = [
      Incidencia(
        id: 'INC-101',
        titulo: 'Impresora del almacén no responde',
        descripcion: 'La impresora permanece en cola.',
        cliente: 'Almacenes del Centro',
        categoria: 'Hardware',
        estado: 'Pendiente',
        fecha: '2026-09-28',
      ),
      Incidencia(
        id: 'INC-102',
        titulo: 'WiFi intermitente en recepción',
        descripcion: 'La red inalámbrica se desconecta.',
        cliente: 'Clínica del Prado',
        categoria: 'Redes',
        estado: 'En proceso',
        fecha: '2026-09-29',
      ),
      Incidencia(
        id: 'INC-103',
        titulo: 'Pantalla azul al iniciar equipo',
        descripcion: 'Muestra pantalla azul tras login.',
        cliente: 'Servicios del Norte',
        categoria: 'Hardware',
        estado: 'Pendiente',
        fecha: '2026-09-30',
      ),
      Incidencia(
        id: 'INC-110',
        titulo: 'Pantalla de inventario desordenada',
        descripcion: 'Campos encimados.',
        cliente: 'Grupo Loma',
        categoria: 'Software',
        estado: 'Pendiente',
        fecha: '2026-10-09',
      ),
    ];
  });

  group('BUG-002: Búsqueda de incidencias', () {
    test('1. Búsqueda insensible a mayúsculas y minúsculas', () {
      // Buscar en minúsculas 'pantalla' debe encontrar 'Pantalla azul' y 'Pantalla de inventario'
      final resMinusculas = gestor.buscar('pantalla');
      expect(resMinusculas.length, 2, reason: 'Debe encontrar 2 coincidencias con "pantalla" en minúsculas');
      expect(resMinusculas.any((x) => x.id == 'INC-103'), isTrue);
      expect(resMinusculas.any((x) => x.id == 'INC-110'), isTrue);

      // Buscar en minúsculas 'wifi' debe encontrar 'WiFi intermitente'
      final resWifi = gestor.buscar('wifi');
      expect(resWifi.length, 1, reason: 'Debe encontrar 1 coincidencia con "wifi" en minúsculas');
      expect(resWifi.first.id, 'INC-102');

      // Buscar en MAYÚSCULAS 'IMPRESORA'
      final resMayusculas = gestor.buscar('IMPRESORA');
      expect(resMayusculas.length, 1, reason: 'Debe encontrar coincidencia con "IMPRESORA" en mayúsculas');
      expect(resMayusculas.first.id, 'INC-101');
    });

    test('2. Búsqueda con espacios antes y después del texto', () {
      // Espacios al inicio y al final
      final resEspacios = gestor.buscar('  WiFi  ');
      expect(resEspacios.length, 1, reason: 'Debe ignorar los espacios en blanco iniciales y finales');
      expect(resEspacios.first.id, 'INC-102');

      final resEspacioInicio = gestor.buscar(' pantalla ');
      expect(resEspacioInicio.length, 2, reason: 'Debe encontrar registros ignorando espacios al inicio y fin');
    });

    test('3. Búsqueda vacía o con solo espacios devuelve todo', () {
      final resVacia = gestor.buscar('');
      expect(resVacia.length, 4);

      final resSoloEspacios = gestor.buscar('   ');
      expect(resSoloEspacios.length, 4);
    });

    test('4. Búsqueda sin coincidencias devuelve lista vacía', () {
      final resSinResultado = gestor.buscar('bluetooth');
      expect(resSinResultado.isEmpty, isTrue);
    });
  });
}
