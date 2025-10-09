// ---------- lib/core/models/usuario.dart ----------
class Usuario {
  final int? id_usuario;
  final String nombre;
  final String correo;
  final String contrasena;
  final String rol;
  final String? creado_en;
  final String? actualizado_en;

  Usuario({
    this.id_usuario,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.rol,
    this.creado_en,
    this.actualizado_en,
  });

  factory Usuario.from_map(Map<String, dynamic> map) => Usuario(
    id_usuario: map['id_usuario'] as int?,
    nombre: map['nombre'] as String,
    correo: map['correo'] as String,
    contrasena: map['contrasena'] as String,
    rol: map['rol'] as String,
    creado_en: map['creado_en'] as String?,
    actualizado_en: map['actualizado_en'] as String?,
  );

  Map<String, dynamic> to_map() => {
    'id_usuario': id_usuario,
    'nombre': nombre,
    'correo': correo,
    'contrasena': contrasena,
    'rol': rol,
    'creado_en': creado_en,
    'actualizado_en': actualizado_en,
  };
}
