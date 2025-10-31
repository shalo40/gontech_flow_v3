class Repuesto {
  int? idRepuesto;
  int? idDiagnostico;
  int? idPresupuesto;
  String? nombre;
  int cantidad;
  double? costoUnitario;
  String? proveedor;
  String estado;
  String origen;
  String? fechaRegistro;

  Repuesto({
    this.idRepuesto,
    this.idDiagnostico,
    this.idPresupuesto,
    this.nombre,
    this.cantidad = 1,
    this.costoUnitario,
    this.proveedor,
    this.estado = 'pendiente',
    this.origen = 'diagnostico',
    this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_repuesto': idRepuesto,
      'id_diagnostico': idDiagnostico,
      'id_presupuesto': idPresupuesto,
      'nombre': nombre,
      'cantidad': cantidad,
      'costo_unitario': costoUnitario,
      'proveedor': proveedor,
      'estado': estado,
      'origen': origen,
      'fecha_registro': fechaRegistro ?? DateTime.now().toIso8601String(),
    };
  }

  factory Repuesto.fromMap(Map<String, dynamic> map) {
    return Repuesto(
      idRepuesto: map['id_repuesto'],
      idDiagnostico: map['id_diagnostico'],
      idPresupuesto: map['id_presupuesto'],
      nombre: map['nombre'],
      cantidad: map['cantidad'] ?? 1,
      costoUnitario: (map['costo_unitario'] ?? 0).toDouble(),
      proveedor: map['proveedor'],
      estado: map['estado'] ?? 'pendiente',
      origen: map['origen'] ?? 'diagnostico',
      fechaRegistro: map['fecha_registro'],
    );
  }
}
