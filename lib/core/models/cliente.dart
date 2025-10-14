class Cliente {
  final int? id_cliente;
  final String nombre;
  final String telefono;
  final String correo;
  final String direccion;
  final String notas;
  final String foto_path; // 🆕 nuevo campo

  Cliente({
    this.id_cliente,
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.notas,
    this.foto_path = '', // valor por defecto
  });

  Map<String, dynamic> to_map() => {
    'id_cliente': id_cliente,
    'nombre': nombre,
    'telefono': telefono,
    'correo': correo,
    'direccion': direccion,
    'notas': notas,
    'foto_path': foto_path, // 🆕
  };

  factory Cliente.from_map(Map<String, dynamic> map) => Cliente(
    id_cliente: map['id_cliente'] as int?,
    nombre: map['nombre'] ?? '',
    telefono: map['telefono'] ?? '',
    correo: map['correo'] ?? '',
    direccion: map['direccion'] ?? '',
    notas: map['notas'] ?? '',
    foto_path: map['foto_path'] ?? '', // 🆕
  );
}
