class Repuesto {
  int? id_repuesto;
  int? id_presupuesto;
  int? id_diagnostico;
  String nombre;
  int cantidad;
  double? costo_unitario;
  String proveedor;
  String estado;
  String origen;

  Repuesto({
    this.id_repuesto,
    this.id_presupuesto,
    this.id_diagnostico,
    required this.nombre,
    this.cantidad = 1,
    this.costo_unitario,
    this.proveedor = '',
    this.estado = 'sugerido',
    this.origen = 'diagnostico',
  });

  Map<String, dynamic> toMap() => {
    'id_presupuesto': id_presupuesto,
    'id_diagnostico': id_diagnostico,
    'nombre': nombre,
    'cantidad': cantidad,
    'costo_unitario': costo_unitario,
    'proveedor': proveedor,
    'estado': estado,
    'origen': origen,
  };

  factory Repuesto.fromMap(Map<String, dynamic> map) => Repuesto(
    id_repuesto: map['id_repuesto'],
    id_presupuesto: map['id_presupuesto'],
    id_diagnostico: map['id_diagnostico'],
    nombre: map['nombre'] ?? '',
    cantidad: map['cantidad'] ?? 1,
    costo_unitario: map['costo_unitario']?.toDouble(),
    proveedor: map['proveedor'] ?? '',
    estado: map['estado'] ?? 'sugerido',
    origen: map['origen'] ?? 'diagnostico',
  );
}
