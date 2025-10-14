class Ingreso {
  final int? id_ingreso;
  final int id_equipo;
  final String fecha_ingreso;
  final String accesorios;
  final String observaciones;
  final String estado_ingreso;
  final String qr_code; // 👈 NUEVO

  Ingreso({
    this.id_ingreso,
    required this.id_equipo,
    required this.fecha_ingreso,
    required this.accesorios,
    required this.observaciones,
    required this.estado_ingreso,
    required this.qr_code,
  });

  Map<String, dynamic> toMap() => {
    'id_ingreso': id_ingreso,
    'id_equipo': id_equipo,
    'fecha_ingreso': fecha_ingreso,
    'accesorios': accesorios,
    'observaciones': observaciones,
    'estado_ingreso': estado_ingreso,
    'qr_code': qr_code,
  };

  factory Ingreso.fromMap(Map<String, dynamic> map) => Ingreso(
    id_ingreso: map['id_ingreso'],
    id_equipo: map['id_equipo'],
    fecha_ingreso: map['fecha_ingreso'] ?? '',
    accesorios: map['accesorios'] ?? '',
    observaciones: map['observaciones'] ?? '',
    estado_ingreso: map['estado_ingreso'] ?? 'pendiente',
    qr_code: map['qr_code'] ?? '',
  );
}
