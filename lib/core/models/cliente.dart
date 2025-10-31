class Cliente {
  int? idCliente;
  String nombre;
  String telefono;
  String correo;
  String direccion;
  String notas;
  String? fotoPath;

  var rut; // opcional (para imagen o firma)

  Cliente({
    this.idCliente,
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.notas,
    this.fotoPath,
    required String rut,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_cliente': idCliente,
      'nombre': nombre,
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
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      direccion: map['direccion'] ?? '',
      notas: map['notas'] ?? '',
      fotoPath: map['foto_path'],
      rut: '',
    );
  }
}
