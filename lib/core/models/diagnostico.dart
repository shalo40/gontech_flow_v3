// ignore_for_file: non_constant_identifier_names

class Diagnostico {
  int? id_diagnostico;
  int id_ingreso;
  int? id_tecnico;
  String descripcion_falla;
  String pruebas_realizadas;
  String conclusiones;
  String estado;

  Diagnostico({
    this.id_diagnostico,
    required this.id_ingreso,
    this.id_tecnico,
    required this.descripcion_falla,
    required this.pruebas_realizadas,
    required this.conclusiones,
    this.estado = 'pendiente',
  });

  Map<String, dynamic> toMap() => {
    'id_ingreso': id_ingreso,
    'id_tecnico': id_tecnico,
    'descripcion_falla': descripcion_falla,
    'pruebas_realizadas': pruebas_realizadas,
    'conclusiones': conclusiones,
    'estado': estado,
  };

  factory Diagnostico.fromMap(Map<String, dynamic> map) => Diagnostico(
    id_diagnostico: map['id_diagnostico'],
    id_ingreso: map['id_ingreso'],
    id_tecnico: map['id_tecnico'],
    descripcion_falla: map['descripcion_falla'] ?? '',
    pruebas_realizadas: map['pruebas_realizadas'] ?? '',
    conclusiones: map['conclusiones'] ?? '',
    estado: map['estado'] ?? 'pendiente',
  );
}
