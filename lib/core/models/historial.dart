// ignore_for_file: non_constant_identifier_names

/// Modelo que representa una entrada en el historial de eventos de una entidad.
/// Registra cambios de estado, acciones y observaciones técnicas.
class Historial {
  final int? id;
  final String entidadTipo;   // 'ingreso', 'reparacion', 'entrega', etc.
  final int entidadId;
  final String accion;        // 'cambio_estado', 'observacion', 'actualizacion'
  final String? descripcion;
  final String? estadoAnterior;
  final String? estadoNuevo;
  final String? usuarioNombre;
  final String? creadoEn;

  const Historial({
    this.id,
    required this.entidadTipo,
    required this.entidadId,
    required this.accion,
    this.descripcion,
    this.estadoAnterior,
    this.estadoNuevo,
    this.usuarioNombre,
    this.creadoEn,
  });

  factory Historial.fromMap(Map<String, dynamic> map) {
    return Historial(
      id:              map['id']              as int?,
      entidadTipo:     map['entidad_tipo']    as String? ?? '',
      entidadId:       map['entidad_id']      as int? ?? 0,
      accion:          map['accion']          as String? ?? '',
      descripcion:     map['descripcion']     as String?,
      estadoAnterior:  map['estado_anterior'] as String?,
      estadoNuevo:     map['estado_nuevo']    as String?,
      usuarioNombre:   map['usuario_nombre']  as String?,
      creadoEn:        map['created_at']      as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entidad_tipo':    entidadTipo,
      'entidad_id':      entidadId,
      'accion':          accion,
      'descripcion':     descripcion,
      'estado_anterior': estadoAnterior,
      'estado_nuevo':    estadoNuevo,
    };
  }
}
