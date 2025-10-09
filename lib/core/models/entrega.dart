class Entrega {
  int? idEntrega;
  int idReparacion;
  String fechaEntrega;
  String observaciones;
  String firmaCliente; // base64 (para la firma digital, futura)
  String estado; // entregado | pendiente_pdf

  Entrega({
    this.idEntrega,
    required this.idReparacion,
    required this.fechaEntrega,
    required this.observaciones,
    required this.firmaCliente,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_entrega': idEntrega,
      'id_reparacion': idReparacion,
      'fecha_entrega': fechaEntrega,
      'observaciones': observaciones,
      'firma_cliente': firmaCliente,
      'estado': estado,
    };
  }

  factory Entrega.fromMap(Map<String, dynamic> map) {
    return Entrega(
      idEntrega: map['id_entrega'],
      idReparacion: map['id_reparacion'],
      fechaEntrega: map['fecha_entrega'],
      observaciones: map['observaciones'] ?? '',
      firmaCliente: map['firma_cliente'] ?? '',
      estado: map['estado'] ?? 'entregado',
    );
  }
}
