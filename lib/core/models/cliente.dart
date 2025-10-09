class Cliente {
  final int? id_cliente;
  final String nombre;
  final String telefono;
  final String correo;
  final String direccion;
  final String notas;

  Cliente({
    this.id_cliente,
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.notas,
  });

  Map<String, dynamic> to_map() => {
    'id_cliente': id_cliente,
    'nombre': nombre,
    'telefono': telefono,
    'correo': correo,
    'direccion': direccion,
    'notas': notas,
  };

  factory Cliente.from_map(Map<String, dynamic> map) => Cliente(
    id_cliente: map['id_cliente'] as int?,
    nombre: map['nombre'] ?? '',
    telefono: map['telefono'] ?? '',
    correo: map['correo'] ?? '',
    direccion: map['direccion'] ?? '',
    notas: map['notas'] ?? '',
  );
}
