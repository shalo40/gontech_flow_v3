class Equipo {
  final int? id_equipo;
  final int id_cliente;
  final String tipo_equipo;
  final String marca;
  final String modelo;
  final String numero_serie;
  final String descripcion;

  Equipo({
    this.id_equipo,
    required this.id_cliente,
    required this.tipo_equipo,
    required this.marca,
    required this.modelo,
    required this.numero_serie,
    required this.descripcion,
  });

  Map<String, dynamic> toMap() => {
    'id_equipo': id_equipo,
    'id_cliente': id_cliente,
    'tipo_equipo': tipo_equipo,
    'marca': marca,
    'modelo': modelo,
    'numero_serie': numero_serie,
    'descripcion': descripcion,
  };

  factory Equipo.fromMap(Map<String, dynamic> map) => Equipo(
    id_equipo: map['id_equipo'],
    id_cliente: map['id_cliente'],
    tipo_equipo: map['tipo_equipo'],
    marca: map['marca'],
    modelo: map['modelo'],
    numero_serie: map['numero_serie'],
    descripcion: map['descripcion'],
  );
}
