import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; 
import '../../../core/providers/helpdesk_provider.dart'; 
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class RepuestosScreen extends StatefulWidget {
  final int? idDiagnosticoFiltro;
  
  const RepuestosScreen({super.key, this.idDiagnosticoFiltro});

  @override
  State<RepuestosScreen> createState() => _RepuestosScreenState();
}

class _RepuestosScreenState extends State<RepuestosScreen> {
  String filtroEstado = 'todos';
  String filtroOrigen = 'todos'; 
  String busqueda = '';
  String orden = 'reciente';
  final formatoFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    await context.read<HelpdeskProvider>().recargarRepuestos();
  }

  // --- Helpers de compatibilidad API / Local ---
  int _getId(Map<String, dynamic> r) {
    return int.tryParse((r['id_repuesto'] ?? r['id'] ?? '0').toString()) ?? 0;
  }

  int _getDiagnosticoId(Map<String, dynamic> r) {
    return int.tryParse((r['id_diagnostico'] ?? r['diagnostico_id'] ?? '0').toString()) ?? 0;
  }

  bool _esDeBodega(String proveedor) {
    final prov = proveedor.toLowerCase().trim();
    return prov.contains('bodega') || prov.isEmpty || prov == '-' || prov == 'interno';
  }
  // ---------------------------------------------

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
      case 'sugerido': return Colors.amberAccent;
      case 'instalado': return Colors.greenAccent;
      case 'rechazado': return Colors.redAccent;
      default: return Colors.white70;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
      case 'sugerido': return Icons.timelapse;
      case 'instalado': return Icons.check_circle;
      case 'rechazado': return Icons.cancel;
      default: return Icons.inventory_2;
    }
  }

  List<Map<String, dynamic>> _filtrarYOrdenar(List<Map<String, dynamic>> repuestosGlobales) {
    var lista = repuestosGlobales;

    if (widget.idDiagnosticoFiltro != null) {
      lista = lista.where((r) => _getDiagnosticoId(r) == widget.idDiagnosticoFiltro).toList();
    }

    lista = lista.where((r) {
      final estado = (r['estado'] ?? '').toString().toLowerCase();
      final proveedor = (r['proveedor'] ?? '').toString();
      final nombre = (r['nombre'] ?? '').toString().toLowerCase();
      final query = busqueda.toLowerCase();

      final coincideBusqueda = nombre.contains(query) || proveedor.toLowerCase().contains(query);
      final coincideEstado = filtroEstado == 'todos' || estado == filtroEstado;
      
      final esBodega = _esDeBodega(proveedor);
      final coincideOrigen = filtroOrigen == 'todos' || 
                             (filtroOrigen == 'bodega' && esBodega) || 
                             (filtroOrigen == 'externo' && !esBodega);

      return coincideBusqueda && coincideEstado && coincideOrigen;
    }).toList();

    if (orden == 'nombre') {
      lista.sort((a, b) => (a['nombre'] ?? '').toString().compareTo((b['nombre'] ?? '').toString()));
    } else {
      lista.sort((a, b) => _getId(b).compareTo(_getId(a)));
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final isLoading = provider.loading;
    final repuestosBase = widget.idDiagnosticoFiltro != null 
        ? provider.repuestos.where((r) => _getDiagnosticoId(r) == widget.idDiagnosticoFiltro).toList()
        : provider.repuestos;
        
    final listaFiltrada = _filtrarYOrdenar(provider.repuestos);

    int cantBodega = 0;
    int cantExternos = 0;
    double inversionTotal = 0;

    for (var r in repuestosBase) {
      if (_esDeBodega(r['proveedor'] ?? '')) {
        cantBodega++;
      } else {
        cantExternos++;
      }
      final costo = double.tryParse(r['costo_unitario']?.toString() ?? '0') ?? 0;
      final cant = int.tryParse(r['cantidad']?.toString() ?? '1') ?? 1;
      inversionTotal += (costo * cant);
    }

    final formatoPesos = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return LayoutPrincipal(
      titulo: 'Inventario y Compras',
      // 🚀 NUEVO: Botón Flotante para Ingresar a Bodega / Comprar
      floatingActionButton: widget.idDiagnosticoFiltro == null ? FloatingActionButton.extended(
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Ingresar Insumo', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _mostrarModalNuevaCompra(context, provider),
      ) : null,
      child: Column(
        children: [
          // 📊 1. TABLERO DE INVENTARIO
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(child: _CardMetrica(titulo: 'En Bodega', valor: cantBodega.toString(), color: Colors.purpleAccent, icono: Icons.all_inbox)),
                const SizedBox(width: 8),
                Expanded(child: _CardMetrica(titulo: 'Compras Ext.', valor: cantExternos.toString(), color: Colors.blueAccent, icono: Icons.local_shipping)),
                const SizedBox(width: 8),
                Expanded(child: _CardMetrica(titulo: 'Inversión', valor: formatoPesos.format(inversionTotal), color: Colors.tealAccent, icono: Icons.monetization_on)),
              ],
            ),
          ),

          // 🔍 2. BUSCADOR Y FILTROS MODERNOS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => busqueda = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar repuesto, proveedor...',
                      hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.tealAccent, size: 20),
                      filled: true,
                      fillColor: AppColors.fondo.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.tealAccent),
                  color: AppColors.fondo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
                  onSelected: (v) => setState(() => orden = v),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'reciente', child: Text('Más recientes', style: TextStyle(color: Colors.white))),
                    PopupMenuItem(value: 'nombre', child: Text('Por nombre', style: TextStyle(color: Colors.white))),
                  ],
                ),
              ],
            ),
          ),

          // 🏷️ 3. FILTROS RÁPIDOS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _chipFiltroOrigen('todos', 'Todo el Inventario', Icons.layers),
                    _chipFiltroOrigen('bodega', 'Solo Bodega', Icons.all_inbox),
                    _chipFiltroOrigen('externo', 'Solo Compras Externas', Icons.local_shipping),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _chipFiltroEstado('todos', 'Todos los estados', Icons.list),
                    _chipFiltroEstado('sugerido', 'Sugeridos', Icons.lightbulb_outline),
                    _chipFiltroEstado('instalado', 'Instalados', Icons.check_circle),
                    _chipFiltroEstado('rechazado', 'Rechazados', Icons.cancel),
                  ],
                ),
              ],
            ),
          ),
          
          if (widget.idDiagnosticoFiltro != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.tealAccent.withOpacity(0.3))),
              child: Row(
                children: [
                  const Icon(Icons.build_circle, color: Colors.tealAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Mostrando repuestos de la Reparación #${widget.idDiagnosticoFiltro}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.tealAccent, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RepuestosScreen())),
                  ),
                ],
              ),
            ),

          // 📦 4. LISTA DE REPUESTOS REDISEÑADA
          Expanded(
            child: isLoading && listaFiltrada.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : listaFiltrada.isEmpty
                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 60), SizedBox(height: 16), Text('No hay repuestos registrados.', style: TextStyle(color: Colors.white70))]))
                    : RefreshIndicator(
                        color: Colors.tealAccent,
                        backgroundColor: AppColors.fondo,
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: listaFiltrada.length,
                          itemBuilder: (context, index) {
                            return _cardRepuestoPremium(listaFiltrada[index], provider);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // --- Chips de Filtro ---
  Widget _chipFiltroEstado(String valor, String label, IconData icono) {
    final activo = filtroEstado == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, color: activo ? Colors.black : Colors.white54, size: 14), const SizedBox(width: 6), Text(label)]),
        labelStyle: TextStyle(color: activo ? Colors.black : Colors.white70, fontSize: 11, fontWeight: activo ? FontWeight.bold : FontWeight.normal),
        selectedColor: Colors.white,
        backgroundColor: AppColors.fondo.withOpacity(0.4),
        selected: activo,
        side: BorderSide(color: activo ? Colors.white : Colors.white12),
        onSelected: (_) => setState(() => filtroEstado = valor),
      ),
    );
  }

  Widget _chipFiltroOrigen(String valor, String label, IconData icono) {
    final activo = filtroOrigen == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, color: activo ? Colors.black : Colors.tealAccent, size: 14), const SizedBox(width: 6), Text(label)]),
        labelStyle: TextStyle(color: activo ? Colors.black : Colors.tealAccent, fontSize: 11, fontWeight: activo ? FontWeight.bold : FontWeight.normal),
        selectedColor: Colors.tealAccent,
        backgroundColor: Colors.tealAccent.withOpacity(0.1),
        selected: activo,
        side: BorderSide(color: activo ? Colors.tealAccent : Colors.tealAccent.withOpacity(0.3)),
        onSelected: (_) => setState(() => filtroOrigen = valor),
      ),
    );
  }

  // ===========================================
  // 🆕 TARJETA DE REPUESTO PREMIUM
  // ===========================================
  Widget _cardRepuestoPremium(Map<String, dynamic> r, HelpdeskProvider provider) {
    final estado = (r['estado'] ?? 'sugerido').toString().toLowerCase();
    final colorEst = _colorEstado(estado);
    final fechaRaw = r['fecha_registro'] ?? r['created_at'];
    final fecha = fechaRaw != null ? formatoFecha.format(DateTime.parse(fechaRaw.toString())) : '-';
    
    final proveedor = (r['proveedor'] ?? 'N/D').toString();
    final esBodega = _esDeBodega(proveedor);
    
    final costo = double.tryParse(r['costo_unitario']?.toString() ?? '0') ?? 0;
    final costoFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0).format(costo);
    final idRepuesto = _getId(r);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fondo.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorEst.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: colorEst.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colorEst.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: Icon(_iconoEstado(estado), color: colorEst, size: 28),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r['nombre'] ?? 'Repuesto'} (${r['cantidad'] ?? 1}x)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: esBodega ? Colors.purpleAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: esBodega ? Colors.purpleAccent.withOpacity(0.5) : Colors.blueAccent.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(esBodega ? Icons.all_inbox : Icons.local_shipping, size: 12, color: esBodega ? Colors.purpleAccent : Colors.blueAccent),
                            const SizedBox(width: 6),
                            Text(esBodega ? 'Bodega Interna' : proveedor, style: TextStyle(color: esBodega ? Colors.purpleAccent : Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: AppColors.fondo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
                  onSelected: (opcion) async {
                    if (opcion == 'instalar' || opcion == 'rechazar') {
                      final nuevoEstado = opcion == 'instalar' ? 'instalado' : 'rechazado';
                      await provider.actualizarRepuesto(idRepuesto, {'estado': nuevoEstado});
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nuevoEstado == 'instalado' ? '🔧 Repuesto instalado' : '❌ Repuesto rechazado'), backgroundColor: nuevoEstado == 'instalado' ? Colors.green : Colors.redAccent));
                    } else if (opcion == 'eliminar') {
                      final exito = await provider.eliminarRepuesto(idRepuesto);
                      if (exito && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Repuesto eliminado correctamente')));
                    }
                  },
                  itemBuilder: (context) => [
                    if (estado != 'instalado')
                      const PopupMenuItem(value: 'instalar', child: Row(children: [Icon(Icons.build, color: Colors.greenAccent, size: 20), SizedBox(width: 12), Text('Marcar Instalado', style: TextStyle(color: Colors.white))])),
                    if (estado != 'rechazado')
                      const PopupMenuItem(value: 'rechazar', child: Row(children: [Icon(Icons.cancel, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('Marcar Rechazado', style: TextStyle(color: Colors.white))])),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(value: 'eliminar', child: Row(children: [Icon(Icons.delete_forever, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('Eliminar Registro', style: TextStyle(color: Colors.redAccent))])),
                  ],
                ),
              ],
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Costo Unitario', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text(costoFormat, style: const TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Registro: $fecha', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(estado.toUpperCase(), style: TextStyle(color: colorEst, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ===========================================
  // 🆕 MODAL DE COMPRA / INGRESO A BODEGA GENÉRICO
  // ===========================================
  Future<void> _mostrarModalNuevaCompra(BuildContext context, HelpdeskProvider provider) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final proveedorCtrl = TextEditingController(text: 'Bodega Interna'); // Por defecto a bodega
    final costoCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: '1');
    bool procesando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.fondo.withOpacity(0.98),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: Colors.tealAccent, width: 2)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.tealAccent, size: 28),
                          SizedBox(width: 12),
                          Text('Ingresar Insumo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Agrega repuestos genéricos a tu inventario sin vincularlos a un diagnóstico específico.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: nombreCtrl,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value!.isEmpty ? 'Requerido' : null,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Insumo / Repuesto', labelStyle: const TextStyle(color: Colors.white54),
                          filled: true, fillColor: Colors.black45, prefixIcon: const Icon(Icons.build_circle, color: Colors.white38),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: proveedorCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Proveedor (Dejar "Bodega Interna" si es stock propio)', labelStyle: const TextStyle(color: Colors.white54),
                          filled: true, fillColor: Colors.black45, prefixIcon: const Icon(Icons.storefront, color: Colors.white38),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: costoCtrl,
                              style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Costo Unit. (\$)', labelStyle: const TextStyle(color: Colors.white54),
                                filled: true, fillColor: Colors.black45, prefixIcon: const Icon(Icons.attach_money, color: Colors.tealAccent),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: cantidadCtrl,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty ? 'Req' : null,
                              decoration: InputDecoration(
                                labelText: 'Cant.', labelStyle: const TextStyle(color: Colors.white54),
                                filled: true, fillColor: Colors.black45, prefixIcon: const Icon(Icons.numbers, color: Colors.white38),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: procesando ? null : () async {
                            if (formKey.currentState!.validate()) {
                              setStateModal(() => procesando = true);
                              try {
                                final data = {
                                  'nombre': nombreCtrl.text.trim(),
                                  'proveedor': proveedorCtrl.text.trim(),
                                  'costo_unitario': double.tryParse(costoCtrl.text.trim()) ?? 0,
                                  'cantidad': int.tryParse(cantidadCtrl.text.trim()) ?? 1,
                                  'estado': 'pendiente', // Ingresa como pendiente de uso
                                  // No enviamos id_diagnostico para que quede libre en bodega
                                };
                                
                                // Asume que tu provider tiene este método estándar
                                final exito = await provider.agregarRepuesto(data);
                                
                                if (exito && context.mounted) {
                                  Navigator.pop(context);
                                  await _cargar();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📦 Insumo ingresado al inventario con éxito'), backgroundColor: Colors.green));
                                }
                              } catch (e) {
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                              } finally {
                                if (context.mounted) setStateModal(() => procesando = false);
                              }
                            }
                          },
                          icon: procesando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.black),
                          label: Text(procesando ? 'Guardando...' : 'Confirmar Ingreso', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }
}

// --- Componente FIX para las métricas superior ---
class _CardMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _CardMetrica({required this.titulo, required this.valor, required this.color, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: color, size: 16),
              const SizedBox(width: 4),
              // 🚀 SOLUCIÓN DEL OVERFLOW: FittedBox encapsulado en Expanded
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}