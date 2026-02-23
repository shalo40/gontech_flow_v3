class Firma {
  final int? idFirma;
  final int idEntrega;
  final String? nombre;
  final String? rut;
  final String? firmaPath;
  final String? fecha;

  Firma({
    this.idFirma,
    required this.idEntrega,
    this.nombre,
    this.rut,
    this.firmaPath,
    this.fecha,
  });

  Map<String, dynamic> toMap() => {
    'id_firma': idFirma,
    'id_entrega': idEntrega,
    'nombre': nombre,
    'rut': rut,
    'firma_path': firmaPath,
    'fecha': fecha ?? DateTime.now().toIso8601String(),
  };

  factory Firma.fromMap(Map<String, dynamic> map) => Firma(
    idFirma: map['id_firma'],
    idEntrega: map['id_entrega'],
    nombre: map['nombre'],
    rut: map['rut'],
    firmaPath: map['firma_path'],
    fecha: map['fecha'],
  );
}
