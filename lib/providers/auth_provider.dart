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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.signIn(email, password);
      if (response.user != null && response.user!.email != null) {
        _maestro = await _service.getMaestroProfile(response.user!.email!);
        _isLoading = false;
        notifyListeners();
        return _maestro != null;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<String> verifyTeacher(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final status = await _service.verifyMaestroStatus(email);
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
      debugPrint('Register auth error: \${e.message}');
      _isLoading = false;
      notifyListeners();
      if (e.message.toLowerCase().contains('already') || 
          e.statusCode == '429' || 
          e.message.toLowerCase().contains('rate limit')) {
        return 'ALREADY_REGISTERED';
      }
      return 'ERROR';
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
      // Verificar contraseña actual
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
