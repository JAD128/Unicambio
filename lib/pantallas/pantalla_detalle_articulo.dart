// =============================================================================
// ARCHIVO: lib/pantallas/pantalla_detalle_articulo.dart
// DESCRIPCIÓN: Muestra toda la información de un artículo seleccionado:
//              imagen, título, precio, descripción, vendedor y botón de
//              contacto.
//
// El estado del favorito se lee del provider (por id), así que el corazón
// refleja cambios hechos en otras pantallas y los que se hacen aquí.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/lanzador_whatsapp.dart';
import '../estado/articulos_provider.dart';
import '../estado/perfil_provider.dart';
import '../modelos/articulo.dart';
import '../modelos/categoria.dart';

/// Texto prellenado para escribir al vendedor.
String textoContactoVendedor(Articulo articulo) =>
    'Hola, vi "${articulo.titulo}" (${articulo.precioTexto}) en UniCambio. '
    '¿Sigue disponible?';

/// Texto para compartir la publicación por WhatsApp (sin enlaces).
String textoCompartirArticulo(Articulo articulo) =>
    'Mira "${articulo.titulo}" (${articulo.precioTexto}) en UniCambio: '
    '${articulo.descripcion}';

/// Pantalla de detalle. Recibe el [articulo] que se quiere mostrar.
class PantallaDetalleArticulo extends StatefulWidget {
  /// Artículo que se muestra en el detalle.
  final Articulo articulo;

  /// Lanzador inyectable para probar los botones sin abrir WhatsApp.
  final LanzadorWhatsapp lanzador;

  const PantallaDetalleArticulo({
    super.key,
    required this.articulo,
    LanzadorWhatsapp? lanzador,
  }) : lanzador = lanzador ?? const LanzadorWhatsappUrl();

  @override
  State<PantallaDetalleArticulo> createState() =>
      _PantallaDetalleArticuloState();
}

class _PantallaDetalleArticuloState extends State<PantallaDetalleArticulo> {
  /// WhatsApp del vendedor, si decidió compartirlo en su perfil.
  String? _telefonoVendedor;

  /// `true` mientras se consulta el perfil del vendedor.
  bool _cargandoTelefono = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ArticulosProvider>().refrescarArticulo(widget.articulo.id);
      _cargarTelefonoVendedor();
    });
  }

  /// Lee de forma asíncrona el número público del autor del artículo.
  Future<void> _cargarTelefonoVendedor() async {
    final ArticulosProvider articulos = context.read<ArticulosProvider>();
    final Articulo actual =
        articulos.articuloPorId(widget.articulo.id) ?? widget.articulo;
    final String? uid = actual.uidAutor;
    if (uid == null || uid == articulos.uidActual) return;

    setState(() => _cargandoTelefono = true);
    final String? telefono = await context.read<PerfilProvider>().telefonoDe(
      uid,
    );
    if (!mounted) return;
    setState(() {
      _telefonoVendedor = telefono;
      _cargandoTelefono = false;
    });
  }

  /// Muestra el resultado de intentar abrir WhatsApp.
  void _avisar(bool abierto, String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(abierto ? mensaje : 'No se pudo abrir WhatsApp.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ArticulosProvider proveedor = context.watch<ArticulosProvider>();
    final Articulo actual =
        proveedor.articuloPorId(widget.articulo.id) ?? widget.articulo;
    final bool esPropio =
        actual.uidAutor != null && actual.uidAutor == proveedor.uidActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del artículo'),
        actions: <Widget>[
          IconButton(
            onPressed: () =>
                context.read<ArticulosProvider>().alternarFavorito(actual.id),
            icon: Icon(
              actual.esFavorito ? Icons.favorite : Icons.favorite_border,
              color: actual.esFavorito ? const Color(0xFFE53935) : null,
            ),
            tooltip: 'Favorito',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ------------------ Imagen grande simulada ------------------
            _CabeceraImagen(articulo: actual),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ----------------- Etiquetas superiores ----------------
                  Row(
                    children: <Widget>[
                      _Pastilla(
                        icono: actual.tipo.icono,
                        texto: actual.tipo.etiqueta,
                        color: actual.tipo.color,
                      ),
                      const SizedBox(width: 8),
                      _Pastilla(
                        icono: actual.categoria.icono,
                        texto: actual.categoria.etiqueta,
                        color: tema.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _Pastilla(
                        icono: actual.estado == EstadoPublicacion.finalizado
                            ? Icons.lock_outline
                            : Icons.check_circle_outline,
                        texto: actual.estado.etiquetaPara(actual.tipo),
                        color: actual.estado == EstadoPublicacion.finalizado
                            ? Colors.grey
                            : tema.colorScheme.tertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // -------------------------- Título ---------------------
                  Text(
                    actual.titulo,
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // -------------------------- Precio ---------------------
                  Text(
                    actual.precioTexto,
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: actual.tipo == TipoPublicacion.venta
                          ? tema.colorScheme.primary
                          : actual.tipo.color,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ----------------------- Descripción -------------------
                  Text(
                    'Descripción',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    actual.descripcion,
                    style: tema.textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // ------------------------- Vendedor --------------------
                  Text(
                    'Publicado por',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TarjetaVendedor(nombre: actual.vendedor),
                ],
              ),
            ),
          ],
        ),
      ),

      // Acciones fijas: compartir y contactar por WhatsApp (opcional).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _AccionesDetalle(
            esPropio: esPropio,
            finalizado: actual.estado == EstadoPublicacion.finalizado,
            cargandoTelefono: _cargandoTelefono,
            telefonoVendedor: _telefonoVendedor,
            alCompartir: () async {
              final bool abierto = await widget.lanzador.compartir(
                textoCompartirArticulo(actual),
              );
              _avisar(abierto, 'WhatsApp abierto para compartir.');
            },
            alContactar: () async {
              final String? telefono = _telefonoVendedor;
              if (telefono == null) return;
              final bool abierto = await widget.lanzador.contactar(
                telefono: telefono,
                mensaje: textoContactoVendedor(actual),
              );
              _avisar(abierto, 'WhatsApp abierto con el mensaje listo.');
            },
          ),
        ),
      ),
    );
  }
}

/// Botones inferiores del detalle, según el estado y la propiedad.
class _AccionesDetalle extends StatelessWidget {
  const _AccionesDetalle({
    required this.esPropio,
    required this.finalizado,
    required this.cargandoTelefono,
    required this.telefonoVendedor,
    required this.alCompartir,
    required this.alContactar,
  });

  final bool esPropio;
  final bool finalizado;
  final bool cargandoTelefono;
  final String? telefonoVendedor;
  final VoidCallback alCompartir;
  final VoidCallback alContactar;

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    if (esPropio || finalizado) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('contactar-vendedor'),
          onPressed: null,
          icon: Icon(esPropio ? Icons.person_outline : Icons.lock_outline),
          label: Text(esPropio ? 'Tu publicación' : 'Publicación finalizada'),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('compartir-whatsapp'),
                onPressed: alCompartir,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartir'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const Key('contactar-vendedor'),
                onPressed: cargandoTelefono || telefonoVendedor == null
                    ? null
                    : alContactar,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  cargandoTelefono
                      ? 'Buscando...'
                      : telefonoVendedor == null
                      ? 'Sin WhatsApp'
                      : 'Abrir WhatsApp',
                ),
              ),
            ),
          ],
        ),
        if (telefonoVendedor == null && !cargandoTelefono)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'El vendedor no compartió su número de WhatsApp.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Imagen grande simulada del artículo (degradado + ícono de la categoría).
class _CabeceraImagen extends StatelessWidget {
  final Articulo articulo;

  const _CabeceraImagen({required this.articulo});

  @override
  Widget build(BuildContext context) {
    final Color colorTipo = articulo.tipo.color;

    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorTipo.withValues(alpha: 0.90),
            colorTipo.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: Icon(
              articulo.categoria.icono,
              size: 96,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (articulo.imagenUrl != null)
            Image.network(
              articulo.imagenUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// Pastilla de color con ícono y texto (para tipo y categoría).
class _Pastilla extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _Pastilla({
    required this.icono,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con la información del estudiante que publicó el artículo.
class _TarjetaVendedor extends StatelessWidget {
  final String nombre;

  const _TarjetaVendedor({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    // Tomamos la primera letra del nombre para el avatar circular.
    final String inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Text(
                inicial,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tema.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Estudiante de la universidad',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.verified_outlined, color: tema.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
