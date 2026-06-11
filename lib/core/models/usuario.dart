// ignore_for_file: non_constant_identifier_names
class Usuario {
  final int? idUsuario;
  final String nombre;
  final String correo;
  final String contrasena;
  final String rol;
  final String? creadoEn;
  final String? actualizadoEn;

  Usuario({
    this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.rol,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
    idUsuario: map['id_usuario'] as int?,
    nombre: map['nombre'] as String,
    correo: map['correo'] as String,
    contrasena: map['contrasena'] as String,
    rol: map['rol'] as String,
    creadoEn: map['creado_en'] as String?,
    actualizadoEn: map['actualizado_en'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id_usuario': idUsuario,
    'nombre': nombre,
    'correo': correo,
    'contrasena': contrasena,
    'rol': rol,
    'creado_en': creadoEn,
    'actualizado_en': actualizadoEn,
  };
}
