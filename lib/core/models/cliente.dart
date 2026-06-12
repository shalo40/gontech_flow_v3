class Cliente {
  final int? idCliente;
  final String nombre;
  final String? rut;
  final String telefono;
  final String correo;
  final String? direccion;
  final String? notas;
  final String? fotoPath;

  Cliente({
    this.idCliente,
    required this.nombre,
    this.rut,
    required this.telefono,
    required this.correo,
    this.direccion,
    this.notas,
    this.fotoPath,
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      // 👇 ESTA ES LA LÍNEA CRÍTICA (Busca 'id', si no está busca 'id_cliente', si no 'idCliente')
      idCliente: map['id'] ?? map['id_cliente'] ?? map['idCliente'], 
      nombre: map['nombre'] ?? '',
      rut: map['rut'],
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      direccion: map['direccion'],
      notas: map['notas'],
      fotoPath: map['foto_path'] ?? map['fotoPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Al enviar a la API o guardar localmente, mapeamos correctamente
      'id': idCliente,
      'nombre': nombre,
      'rut': rut,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'notas': notas,
      'foto_path': fotoPath,
    };
  }
}