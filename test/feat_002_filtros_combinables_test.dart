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
    // Cargamos una lista de incidencias con combinaciones conocidas de estado y prioridad
    gestor.incidencias = [
      Incidencia(
        id: 'INC-201',
        titulo: 'Pantalla azul en servidor contable',
        descripcion: 'Servidor caído',
        cliente: 'Finanzas Corp',
        categoria: 'Hardware',
        estado: 'Pendiente',
        fecha: '2026-10-10',
        prioridad: 'Alta',
      ),
      Incidencia(
        id: 'INC-202',
        titulo: 'Pantalla parpadea en recepción',
        descripcion: 'Monitor secundario',
        cliente: 'Hotel Real',
        categoria: 'Hardware',
        estado: 'En proceso',
        fecha: '2026-10-11',
        prioridad: 'Baja',
      ),
      Incidencia(
        id: 'INC-203',
        titulo: 'WiFi no conecta en almacén',
        descripcion: 'Punto de acceso dañado',
        cliente: 'Logística Central',
        categoria: 'Redes',
        estado: 'Pendiente',
        fecha: '2026-10-12',
        prioridad: 'Alta',
      ),
      Incidencia(
        id: 'INC-204',
        titulo: 'Pantalla congelada en caja 3',
        descripcion: 'Software de punto de venta',
        cliente: 'Supermercado Sol',
        categoria: 'Software',
        estado: 'Resuelta',
        fecha: '2026-10-13',
        prioridad: 'Media',
      ),
      Incidencia(
        id: 'INC-205',
        titulo: 'Actualización de antivirus pendiente',
        descripcion: 'Equipos administrativos',
        cliente: 'Finanzas Corp',
        categoria: 'Software',
        estado: 'Pendiente',
        fecha: '2026-10-14',
        prioridad: 'Media',
      ),
    ];
  });

  group('FEAT-002: Filtros combinables', () {
    test('1. Sin filtros (valores por defecto) devuelve todas las incidencias', () {
      final res = gestor.filtrar();
      expect(res.length, 5);
      expect(res.length, gestor.incidencias.length,
          reason: 'El filtrado no debe alterar ni mutar la lista original');
    });

    test('2. Filtrado exclusivo por estado', () {
      final pendientes = gestor.filtrar(estado: 'Pendiente');
      expect(pendientes.length, 3);
      expect(pendientes.every((x) => x.estado == 'Pendiente'), isTrue);

      final enProceso = gestor.filtrar(estado: 'En proceso');
      expect(enProceso.length, 1);
      expect(enProceso.first.id, 'INC-202');

      final resueltas = gestor.filtrar(estado: 'Resuelta');
      expect(resueltas.length, 1);
      expect(resueltas.first.id, 'INC-204');
    });

    test('3. Filtrado exclusivo por prioridad', () {
      final altas = gestor.filtrar(prioridad: 'Alta');
      expect(altas.length, 2);
      expect(altas.every((x) => x.prioridad == 'Alta'), isTrue);

      final medias = gestor.filtrar(prioridad: 'Media');
      expect(medias.length, 2);
      expect(medias.every((x) => x.prioridad == 'Media'), isTrue);

      final bajas = gestor.filtrar(prioridad: 'Baja');
      expect(bajas.length, 1);
      expect(bajas.first.id, 'INC-202');
    });

    test('4. Combinación de estado Pendiente y prioridad Alta', () {
      final res = gestor.filtrar(estado: 'Pendiente', prioridad: 'Alta');
      expect(res.length, 2);
      expect(res.map((x) => x.id).toSet(), equals({'INC-201', 'INC-203'}));
    });

    test('5. Combinación triple simultánea: texto "pantalla" + Pendiente + Alta', () {
      // Coincide solo INC-201 (Pantalla + Pendiente + Alta)
      // INC-202 tiene pantalla pero es 'En proceso' y 'Baja'
      // INC-203 es Pendiente y Alta pero su título es 'WiFi...'
      // INC-204 tiene pantalla pero es 'Resuelta' y 'Media'
      final res = gestor.filtrar(
        texto: 'pantalla',
        estado: 'Pendiente',
        prioridad: 'Alta',
      );

      expect(res.length, 1);
      expect(res.first.id, 'INC-201');
      expect(res.first.titulo, contains('Pantalla azul en servidor contable'));
    });

    test('6. Búsqueda con cero resultados por filtros incompatibles', () {
      // Buscar 'WiFi' + Resuelta -> no existe ninguna
      final res = gestor.filtrar(texto: 'WiFi', estado: 'Resuelta');
      expect(res.isEmpty, isTrue);

      // Buscar texto inexistente
      final resInexistente = gestor.filtrar(texto: 'impresora láser inexistente');
      expect(resInexistente.isEmpty, isTrue);
    });

    test('7. Cambio de un filtro conservando los otros criterios activos', () {
      // Primero: 'pantalla' + 'Pendiente' -> INC-201
      final paso1 = gestor.filtrar(texto: 'pantalla', estado: 'Pendiente');
      expect(paso1.length, 1);
      expect(paso1.first.id, 'INC-201');

      // Cambiamos estado a 'En proceso' manteniendo texto 'pantalla' -> INC-202
      final paso2 = gestor.filtrar(texto: 'pantalla', estado: 'En proceso');
      expect(paso2.length, 1);
      expect(paso2.first.id, 'INC-202');

      // Cambiamos estado a 'Resuelta' manteniendo texto 'pantalla' -> INC-204
      final paso3 = gestor.filtrar(texto: 'pantalla', estado: 'Resuelta');
      expect(paso3.length, 1);
      expect(paso3.first.id, 'INC-204');
    });

    test('8. Restablecimiento completo de filtros recupera toda la lista intacta', () {
      // Aplicamos filtros estrictos
      final filtradas = gestor.filtrar(texto: 'servidor', estado: 'Pendiente', prioridad: 'Alta');
      expect(filtradas.length, 1);

      // Restablecemos a valores por defecto
      final restauradas = gestor.filtrar(texto: '', estado: 'Todos', prioridad: 'Todas');
      expect(restauradas.length, 5);
      expect(gestor.incidencias.length, 5, reason: 'La colección base no fue modificada');
    });

    test('9. El método buscar(texto) sigue funcionando delegando en filtrar()', () {
      final res = gestor.buscar('wifi');
      expect(res.length, 1);
      expect(res.first.id, 'INC-203');
    });
  });
}
