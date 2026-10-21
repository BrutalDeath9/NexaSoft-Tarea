class Incidencia {
  static const List<String> prioridadesValidas = ['Baja', 'Media', 'Alta'];

  String id;
  String titulo;
  String descripcion;
  String cliente;
  String categoria;
  String estado;
  String fecha;
  String prioridad;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.cliente,
    required this.categoria,
    required this.estado,
    required this.fecha,
    this.prioridad = 'Media',
  });

  factory Incidencia.desdeJson(Map<String, dynamic> m) {
    final rawPrioridad = m['prioridad']?.toString();
    final prioridadSegura =
        (rawPrioridad != null && prioridadesValidas.contains(rawPrioridad))
            ? rawPrioridad
            : 'Media';

    return Incidencia(
      id: m['id']?.toString() ?? '',
      titulo: m['titulo']?.toString() ?? '',
      descripcion: m['descripcion']?.toString() ?? '',
      cliente: m['cliente']?.toString() ?? '',
      categoria: m['categoria']?.toString() ?? 'Software',
      estado: m['estado']?.toString() ?? 'Pendiente',
      fecha: m['fecha']?.toString() ?? '',
      prioridad: prioridadSegura,
    );
  }

  Map<String, dynamic> toJson() {
    final prioridadSegura =
        prioridadesValidas.contains(prioridad) ? prioridad : 'Media';
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'cliente': cliente,
      'categoria': categoria,
      'estado': estado,
      'fecha': fecha,
      'prioridad': prioridadSegura,
    };
  }
}
