class Informe {
  int? idInforme;
  int idDiagnostico;
  int? idTecnico;
  String descripcionGeneral;
  String conclusiones;
  String recomendaciones;
  String fechaCreacion;

  Informe({
    this.idInforme,
    required this.idDiagnostico,
    this.idTecnico,
    required this.descripcionGeneral,
    required this.conclusiones,
    required this.recomendaciones,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() => {
    'id_informe': idInforme,
    'id_diagnostico': idDiagnostico,
    'id_tecnico': idTecnico,
    'descripcion_general': descripcionGeneral,
    'conclusiones': conclusiones,
    'recomendaciones': recomendaciones,
    'creado_en': fechaCreacion,
  };

  factory Informe.fromMap(Map<String, dynamic> map) => Informe(
    idInforme: map['id_informe'],
    idDiagnostico: map['id_diagnostico'],
    idTecnico: map['id_tecnico'],
    descripcionGeneral: map['descripcion_general'] ?? '',
    conclusiones: map['conclusiones'] ?? '',
    recomendaciones: map['recomendaciones'] ?? '',
    fechaCreacion: map['creado_en'] ?? '',
  );
}
