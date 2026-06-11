// ignore_for_file: non_constant_identifier_names
// ignore_for_file: non_constant_identifier_names

class Entrega {
  int? id_entrega;
  int id_reparacion;
  String? nombre_receptor;
  String? rut_receptor;
  String? observaciones;
  String? firma_path;
  String? fecha_entrega;
  String estado;

  Entrega({
    this.id_entrega,
    required this.id_reparacion,
    this.nombre_receptor,
    this.rut_receptor,
    this.observaciones,
    this.firma_path,
    this.fecha_entrega,
    this.estado = 'pendiente', // Valor por defecto
  });

  /// 🔹 Convierte el objeto a un Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id_entrega': id_entrega,
      'id_reparacion': id_reparacion,
      'nombre_receptor': nombre_receptor,
      'rut_receptor': rut_receptor,
      'observaciones': observaciones,
      'firma_path': firma_path,
      'fecha_entrega': fecha_entrega,
      'estado': estado,
    };
  }

  /// 🔹 Crea un objeto Entrega a partir de un Map de SQLite
  factory Entrega.fromMap(Map<String, dynamic> map) {
    return Entrega(
      id_entrega: map['id_entrega'],
      id_reparacion: map['id_reparacion'],
      nombre_receptor: map['nombre_receptor'],
      rut_receptor: map['rut_receptor'],
      observaciones: map['observaciones'],
      firma_path: map['firma_path'],
      fecha_entrega: map['fecha_entrega'],
      estado: map['estado'] ?? 'pendiente',
    );
  }
}
