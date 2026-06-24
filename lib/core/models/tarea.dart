// ignore_for_file: non_constant_identifier_names

/// Modelo que representa una tarea o sub-tarea técnica asociada a una reparación.
/// Permite desglosar el trabajo técnico en pasos individuales con estados.
class Tarea {
  final int? id;
  final int? reparacionId;
  final String descripcion;
  final String estado;        // 'pendiente', 'en_progreso', 'completada'
  final String? observaciones;
  final String? completadaEn;
  final String? creadoEn;

  const Tarea({
    this.id,
    this.reparacionId,
    required this.descripcion,
    this.estado = 'pendiente',
    this.observaciones,
    this.completadaEn,
    this.creadoEn,
  });

  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id:            map['id']             as int?,
      reparacionId:  map['reparacion_id']  as int?,
      descripcion:   map['descripcion']    as String? ?? '',
      estado:        map['estado']         as String? ?? 'pendiente',
      observaciones: map['observaciones']  as String?,
      completadaEn:  map['completada_en']  as String?,
      creadoEn:      map['created_at']     as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null)           'id':            id,
      if (reparacionId != null) 'reparacion_id': reparacionId,
      'descripcion':             descripcion,
      'estado':                  estado,
      'observaciones':           observaciones,
    };
  }

  Tarea copyWith({String? estado, String? observaciones}) {
    return Tarea(
      id:            id,
      reparacionId:  reparacionId,
      descripcion:   descripcion,
      estado:        estado        ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      completadaEn:  completadaEn,
      creadoEn:      creadoEn,
    );
  }
}
