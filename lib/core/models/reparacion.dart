class Reparacion {
  int? idReparacion;
  int idDiagnostico;
  String descripcionTrabajo;
  String observaciones;
  String fechaInicio;
  String estado; // en_proceso | finalizada

  Reparacion({
    this.idReparacion,
    required this.idDiagnostico,
    required this.descripcionTrabajo,
    required this.observaciones,
    required this.fechaInicio,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_reparacion': idReparacion,
      'id_diagnostico': idDiagnostico,
      'descripcion_trabajo': descripcionTrabajo,
      'observaciones': observaciones,
      'fecha_inicio': fechaInicio,
      'estado': estado,
    };
  }

  factory Reparacion.fromMap(Map<String, dynamic> map) {
    return Reparacion(
      idReparacion: map['id_reparacion'],
      idDiagnostico: map['id_diagnostico'],
      descripcionTrabajo: map['descripcion_trabajo'] ?? '',
      observaciones: map['observaciones'] ?? '',
      fechaInicio: map['fecha_inicio'] ?? '',
      estado: map['estado'] ?? 'en_proceso',
    );
  }
}
