// ignore_for_file: non_constant_identifier_names
class Presupuesto {
  int? idPresupuesto;
  int idDiagnostico;
  String descripcion;
  double total;
  String estado; // pendiente | autorizado | rechazado
  String fechaCreacion;

  Presupuesto({
    this.idPresupuesto,
    required this.idDiagnostico,
    required this.descripcion,
    required this.total,
    required this.estado,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_presupuesto': idPresupuesto,
      'id_diagnostico': idDiagnostico,
      'descripcion': descripcion,
      'total': total,
      'estado': estado,
      'fecha_creacion': fechaCreacion,
    };
  }

  factory Presupuesto.fromMap(Map<String, dynamic> map) {
    return Presupuesto(
      idPresupuesto: map['id_presupuesto'],
      idDiagnostico: map['id_diagnostico'],
      descripcion: map['descripcion'],
      total: map['total'] is int
          ? (map['total'] as int).toDouble()
          : map['total'],
      estado: map['estado'],
      fechaCreacion: map['fecha_creacion'],
    );
  }
}
