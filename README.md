# Gontech Flow v3

Sistema de gestion de helpdesk para talleres de servicio tecnico, desarrollado con Flutter.

## Descripcion

Gontech Flow es una aplicacion movil que permite administrar el flujo completo de un taller de reparacion de equipos tecnologicos: desde el registro de clientes y equipos, pasando por diagnosticos, presupuestos y reparaciones, hasta la entrega final con firma digital y comprobante PDF.

## Flujo de negocio

```
Cliente -> Equipo -> Ingreso -> Diagnostico -> Presupuesto -> Reparacion -> Entrega + Firma
                                    |                              |
                                    +-> Repuestos                  +-> Informe tecnico
```

## Tecnologias

| Componente | Tecnologia |
|---|---|
| Framework | Flutter (Dart) |
| Base de datos | SQLite (sqflite) |
| Estado | Provider |
| Autenticacion | Local + biometria (local_auth) |
| Seguridad | SHA-256 para contrasenas (crypto) |
| PDFs | pdf + printing + barcode_widget |
| Firma digital | signature |

## Estructura del proyecto

```
lib/
  main.dart                     # Punto de entrada + MultiProvider + rutas
  core/
    database/                   # DatabaseHelper (SQLite) + DbLoader (datos demo)
    dao/                        # Data Access Objects (11 DAOs)
    models/                     # Modelos de dominio (11 modelos)
    session/                    # AuthService, SessionManager, PasswordHasher
    providers/                  # AuthProvider + HelpdeskProvider
  ui/
    theme/                      # AppColors, AppTextStyles, AppTheme
    components/                 # Widgets reutilizables
    layout/                     # LayoutPrincipal + MenuLateral
    screens/                    # Pantallas principales + modulos
    reports/                    # Generacion de PDFs
```

## Modulos

- **Clientes**: CRUD con foto y busqueda alfabetica
- **Equipos**: Registro con QR, fotos y estados
- **Ingresos**: Registro de entrada de equipos al taller
- **Diagnosticos**: Asistente de 3 pasos (falla, pruebas, conclusiones)
- **Presupuestos**: Autorizacion automatica crea reparacion
- **Reparaciones**: Gestion de reparaciones con repuestos
- **Repuestos**: Inventario de partes utilizadas
- **Informes**: Informes tecnicos con exportacion PDF
- **Entregas**: Cierre con firma digital del cliente y comprobante PDF
- **Estadisticas**: Dashboard de metricas en tiempo real

## Base de datos

SQLite local con 12 tablas y sistema de migraciones automaticas (version 9).

## Como ejecutar

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar tests
flutter test
```

## Usuarios demo

| Rol | Correo | Contrasena |
|---|---|---|
| Admin | admin@gontech.cl | 1234 |
| Tecnico | tecnico@gontech.cl | 1234 |
| Cliente | cliente@gontech.cl | 1234 |

## Autor

Proyecto de tesis - Gontech Solutions
