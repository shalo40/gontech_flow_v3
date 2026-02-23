class Cliente {
  int? idCliente;
  String nombre;
  String? rut;
  String telefono;
  String correo;
  String direccion;
  String notas;
  String? fotoPath;

  Cliente({
    this.idCliente,
    required this.nombre,
    this.rut,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.notas,
    this.fotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_cliente': idCliente,
      'nombre': nombre,
      'rut': rut,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'notas': notas,
      'foto_path': fotoPath,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      idCliente: map['id_cliente'],
      nombre: map['nombre'] ?? '',
      rut: map['rut'] as String?,
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      direccion: map['direccion'] ?? '',
      notas: map['notas'] ?? '',
      fotoPath: map['foto_path'],
    );
  }
}
