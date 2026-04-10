import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/maestro.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _service;
  Maestro? _maestro;
  bool _isLoading = false;

  AuthProvider(this._service);

  Maestro? get maestro => _maestro;
  bool get isLoading => _isLoading;

  Future<void> checkSession() async {
    final session = _service.client.auth.currentSession;
    if (session != null && session.user.email != null) {
      try {
        _maestro = await _service.getMaestroProfile(session.user.email!);
      } catch (e) {
        debugPrint('Error restoring session: $e');
        _maestro = null;
      }
    }
  }

  // Retorna '' si éxito, o un mensaje de error específico
  Future<String> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.signIn(email.trim(), password.trim());

      if (response.user == null) {
        _isLoading = false;
        notifyListeners();
        return 'No se pudo iniciar sesión. Verifica tus datos.';
      }

      final authedEmail = response.user!.email!;
      _maestro = await _service.getMaestroProfile(authedEmail);

      if (_maestro == null) {
        // El usuario existe en Auth pero no en la tabla maestros
        await _service.signOut();
        _isLoading = false;
        notifyListeners();
        return 'Tu correo no tiene un perfil de maestro asignado. Contacta al administrador.';
      }

      _isLoading = false;
      notifyListeners();
      return ''; // éxito

    } on AuthApiException catch (e) {
      debugPrint('Login auth error: ${e.message} (${e.statusCode})');
      _isLoading = false;
      notifyListeners();

      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        return 'Correo o contraseña incorrectos.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Debes confirmar tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.';
      }
      if (msg.contains('too many requests') || e.statusCode == '429') {
        return 'Demasiados intentos. Espera unos minutos.';
      }
      return 'Error: ${e.message}';

    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Error de conexión. Verifica tu internet.';
    }
  }

  // Verifica maestro usando su CLAVE y el email que desea registrar
  // Retorna: 'OK', 'NOT_FOUND', 'EMAIL_MISMATCH', 'ERROR'
  Future<String> verifyTeacher(String clave, String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final status = await _service.verifyMaestroForRegistration(clave, email);
      _isLoading = false;
      notifyListeners();
      return status;
    } catch (e) {
      debugPrint('Verify error: $e');
      _isLoading = false;
      notifyListeners();
      return 'ERROR';
    }
  }

  Future<String> registerTeacher(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.signUpMaestro(email, password);
      _isLoading = false;
      notifyListeners();
      return response.user != null ? 'OK' : 'ERROR';
    } on AuthApiException catch (e) {
      debugPrint('Register auth error: ${e.message}');
      _isLoading = false;
      notifyListeners();
      if (e.statusCode == '429' || e.message.toLowerCase().contains('rate limit')) {
        return 'RATE_LIMIT';
      }
      if (e.message.toLowerCase().contains('already') ||
          e.message.toLowerCase().contains('registered') ||
          e.statusCode == '422') {
        return 'ALREADY_REGISTERED';
      }
      return 'AUTH_ERROR: ${e.message}';
    } catch (e) {
      debugPrint('Register error: $e');
      _isLoading = false;
      notifyListeners();
      return 'ERROR';
    }
  }

  Future<String> changePassword(String currentPassword, String newPassword) async {
    if (_maestro == null) return 'No hay sesión activa';

    _isLoading = true;
    notifyListeners();

    try {
      final verifyResponse = await _service.signIn(_maestro!.email, currentPassword);
      if (verifyResponse.user == null) {
        _isLoading = false;
        notifyListeners();
        return 'La contraseña actual es incorrecta';
      }

      await _service.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
      return 'OK';
    } catch (e) {
      debugPrint('Change password error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Error al cambiar la contraseña';
    }
  }

  Future<void> logout() async {
    await _service.signOut();
    _maestro = null;
    notifyListeners();
  }
}
