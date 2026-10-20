import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Pantalla para iniciar sesión, crear cuenta o recuperar contraseña.
class PantallaAutenticacion extends StatefulWidget {
  const PantallaAutenticacion({super.key});

  @override
  State<PantallaAutenticacion> createState() => _PantallaAutenticacionState();
}

class _PantallaAutenticacionState extends State<PantallaAutenticacion> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _nombre = TextEditingController();
  bool _registro = false;
  bool _cargando = false;
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _autenticar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final auth = FirebaseAuth.instance;
      if (_registro) {
        final credencial = await auth.createUserWithEmailAndPassword(
          email: _correo.text.trim(),
          password: _contrasena.text,
        );
        final nombre = _nombre.text.trim();
        if (nombre.isNotEmpty) await credencial.user?.updateDisplayName(nombre);
      } else {
        await auth.signInWithEmailAndPassword(
          email: _correo.text.trim(),
          password: _contrasena.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      _mostrarMensaje(_mensajeError(error.code));
    } catch (_) {
      _mostrarMensaje('No se pudo completar la solicitud. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Inicia sesión con Google. En móvil se pide el token a google_sign_in y
  /// Firebase lo valida; en web se usa el popup nativo de Firebase Auth
  /// (google_sign_in no soporta authenticate() en la web).
  Future<void> _iniciarSesionConGoogle() async {
    setState(() => _cargando = true);
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
        return;
      }
      final cuenta = await GoogleSignIn.instance.authenticate();
      final idToken = cuenta.authentication.idToken;
      if (idToken == null) {
        _mostrarMensaje('Google no devolvió un token válido. Intenta de nuevo.');
        return;
      }
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (error) {
      // Si el usuario cancela el selector de cuentas, no avisamos.
      if (error.code != GoogleSignInExceptionCode.canceled) {
        _mostrarMensaje('No se pudo iniciar sesión con Google. Intenta de nuevo.');
      }
    } on FirebaseAuthException catch (error) {
      // Cerrar la ventana del popup es una cancelación, no un error.
      if (error.code != 'popup-closed-by-user' &&
          error.code != 'cancelled-popup-request') {
        _mostrarMensaje(_mensajeError(error.code));
      }
    } catch (_) {
      _mostrarMensaje('No se pudo iniciar sesión con Google. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperarContrasena() async {
    final correo = _correo.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      _mostrarMensaje('Escribe un correo válido para recibir el enlace.');
      return;
    }
    setState(() => _cargando = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: correo);
      _mostrarMensaje('Si la cuenta existe, recibirás un correo para restablecer la contraseña.');
    } on FirebaseAuthException catch (error) {
      _mostrarMensaje(_mensajeError(error.code));
    } catch (_) {
      _mostrarMensaje('No se pudo enviar el correo. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _mensajeError(String codigo) => switch (codigo) {
        'invalid-email' => 'El formato del correo no es válido.',
        'user-disabled' => 'Esta cuenta está deshabilitada.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'El correo o la contraseña no son correctos.',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
        'account-exists-with-different-credential' =>
          'Ya existe una cuenta con ese correo. Inicia sesión con tu contraseña.',
        'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
        'operation-not-allowed' => 'Activa el acceso por correo y contraseña en Firebase.',
        'too-many-requests' => 'Hubo demasiados intentos. Espera un momento.',
        'network-request-failed' => 'Revisa tu conexión a internet.',
        _ => 'No se pudo autenticar. Intenta de nuevo.',
      };

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 64, color: color.primary),
                    const SizedBox(height: 12),
                    Text('UniCambio', textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_registro ? 'Crea tu cuenta de estudiante' : 'Ingresa para continuar',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    if (_registro) ...[
                      TextFormField(
                        controller: _nombre,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                        validator: (valor) => valor == null || valor.trim().isEmpty ? 'Escribe tu nombre.' : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (valor) => valor == null || !valor.trim().contains('@') ? 'Escribe un correo válido.' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _contrasena,
                      obscureText: _ocultarContrasena,
                      autofillHints: [_registro ? AutofillHints.newPassword : AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _ocultarContrasena ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          onPressed: () => setState(() => _ocultarContrasena = !_ocultarContrasena),
                          icon: Icon(_ocultarContrasena ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (valor) => valor == null || valor.length < 6 ? 'Usa al menos 6 caracteres.' : null,
                    ),
                    if (!_registro)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: _cargando ? null : _recuperarContrasena, child: const Text('¿Olvidaste tu contraseña?')),
                      )
                    else
                      const SizedBox(height: 20),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _cargando ? null : _autenticar,
                      child: _cargando
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_registro ? 'Crear cuenta' : 'Iniciar sesión'),
                    ),
                    TextButton(
                      onPressed: _cargando ? null : () => setState(() => _registro = !_registro),
                      child: Text(_registro ? 'Ya tengo una cuenta · Iniciar sesión' : '¿Nuevo en UniCambio? Crear cuenta'),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _cargando ? null : _iniciarSesionConGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continuar con Google'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: color.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
