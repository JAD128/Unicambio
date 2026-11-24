// =============================================================================
// ARCHIVO: test/perfil_provider_test.dart
// DESCRIPCIÓN: Pruebas del teléfono opcional y las preferencias de sugerencias
//              con el repositorio EN MEMORIA (sin Firebase).
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:unicambio/datos/perfil_repositorio.dart';
import 'package:unicambio/estado/perfil_provider.dart';
import 'package:unicambio/modelos/categoria.dart';
import 'package:unicambio/modelos/perfil_usuario.dart';

/// Repositorio que cuenta lecturas para verificar la caché de teléfonos.
class RepositorioConteo extends PerfilRepositorioMemoria {
  int lecturas = 0;

  @override
  Future<PerfilUsuario> obtener(String uid) async {
    lecturas++;
    return super.obtener(uid);
  }
}

void main() {
  late PerfilProvider provider;
  late RepositorioConteo repositorio;

  setUp(() {
    repositorio = RepositorioConteo();
    provider = PerfilProvider(repositorio);
  });

  test('el perfil nuevo empieza sin teléfono y sin sugerencias', () async {
    await provider.iniciar('uid-1');

    expect(provider.telefono, isEmpty);
    expect(provider.sugerenciasActivas, isFalse);
    expect(provider.categoriasSugerencias, isEmpty);
  });

  test('guardarTelefono normaliza el número y rechaza entradas inválidas',
      () async {
    await provider.iniciar('uid-1');

    await provider.guardarTelefono('300 123 4567');
    expect(provider.telefono, '573001234567');

    await provider.guardarTelefono('123');
    expect(provider.telefono, '573001234567');
    expect(provider.error, contains('celular colombiano'));

    await provider.guardarTelefono('');
    expect(provider.telefono, isEmpty);
  });

  test('activar sugerencias por primera vez elige todas las categorías',
      () async {
    await provider.iniciar('uid-1');

    await provider.actualizarPreferencias(activas: true);

    expect(provider.sugerenciasActivas, isTrue);
    expect(provider.categoriasSugerencias, Categoria.values.toSet());
  });

  test('marcarVisto guarda la fecha actual', () async {
    await provider.iniciar('uid-1');

    await provider.marcarVisto();

    expect(provider.ultimaVista, isNotNull);
    expect(
      provider.ultimaVista!.difference(DateTime.now()).inSeconds.abs() < 5,
      isTrue,
    );
  });

  test('telefonoDe consulta a otro usuario una sola vez', () async {
    await repositorio.guardar(
      const PerfilUsuario(uid: 'vendedor', telefono: '573112223344'),
    );
    await provider.iniciar('uid-1');
    final int lecturasAlIniciar = repositorio.lecturas;

    expect(await provider.telefonoDe('vendedor'), '573112223344');
    expect(await provider.telefonoDe('vendedor'), '573112223344');
    expect(repositorio.lecturas - lecturasAlIniciar, 1);
  });
}
