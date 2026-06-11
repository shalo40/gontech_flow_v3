// ignore_for_file: non_constant_identifier_names
// ignore_for_file: non_constant_identifier_names

class Equipo {
  final int? id_equipo;
  final int id_cliente;
  final String tipo_equipo;
  final String marca;
  final String modelo;
  final String numero_serie;
  final String descripcion;
  final String foto_path; // Nueva propiedad opcional

  Equipo({
    this.id_equipo,
    required this.id_cliente,
    required this.tipo_equipo,
    required this.marca,
    required this.modelo,
    required this.numero_serie,
    required this.descripcion,
    this.foto_path = '',
  });

  Map<String, dynamic> toMap() => {
    'id_equipo': id_equipo,
    'id_cliente': id_cliente,
    'tipo_equipo': tipo_equipo,
    'marca': marca,
    'modelo': modelo,
    'numero_serie': numero_serie,
    'descripcion': descripcion,
    'foto_path': foto_path,
  };

  factory Equipo.fromMap(Map<String, dynamic> map) => Equipo(
    id_equipo: map['id_equipo'] as int?,
    id_cliente: map['id_cliente'] as int,
    tipo_equipo: map['tipo_equipo'] ?? '',
    marca: map['marca'] ?? '',
    modelo: map['modelo'] ?? '',
    numero_serie: map['numero_serie'] ?? '',
    descripcion: map['descripcion'] ?? '',
    foto_path: map['foto_path'] ?? '',
  );
}
