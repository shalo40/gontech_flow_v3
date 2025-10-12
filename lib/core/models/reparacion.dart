class Reparacion {
  int? idReparacion;
  int idDiagnostico;
  int? idTecnico;
  String descripcion;
  String fechaInicio;
  String? fechaFin;
  String estado;
  String notas;

  Reparacion({
    this.idReparacion,
    required this.idDiagnostico,
    this.idTecnico,
    required this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    required this.estado,
    required this.notas,
  });

  Map<String, dynamic> toMap() => {
    'id_reparacion': idReparacion,
    'id_diagnostico': idDiagnostico,
    'id_tecnico': idTecnico,
    'descripcion': descripcion,
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    'estado': estado,
    'notas': notas,
  };

  factory Reparacion.fromMap(Map<String, dynamic> map) => Reparacion(
    idReparacion: map['id_reparacion'],
    idDiagnostico: map['id_diagnostico'],
    idTecnico: map['id_tecnico'],
    descripcion: map['descripcion'] ?? '',
    fechaInicio: map['fecha_inicio'] ?? '',
    fechaFin: map['fecha_fin'],
    estado: map['estado'] ?? 'pendiente',
    notas: map['notas'] ?? '',
  );
}
