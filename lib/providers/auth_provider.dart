import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/maestro.dart';

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
      if (response.user != null) {
        _maestro = await _service.getMaestroProfile(response.user!.id);
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

  Future<void> logout() async {
    await _service.signOut();
    _maestro = null;
    notifyListeners();
  }
}
