import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/grupo.dart';
import '../models/alumno.dart';
import '../models/sesion.dart';
import '../models/asistencia.dart';

class DataProvider extends ChangeNotifier {
  final SupabaseService _service;
  List<Grupo> _grupos = [];
  List<Alumno> _alumnos = [];
  bool _isLoading = false;

  DataProvider(this._service);

  List<Grupo> get grupos => _grupos;
  List<Alumno> get alumnos => _alumnos;
  bool get isLoading => _isLoading;

  Future<void> loadGrupos(int maestroId) async {
    _isLoading = true;
    notifyListeners();
    _grupos = await _service.getMaestroGrupos(maestroId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAlumnos(int grupoId) async {
    _isLoading = true;
    notifyListeners();
    _alumnos = await _service.getGrupoAlumnos(grupoId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> startClassSession(int grupoId, int maestroId) async {
    try {
      final now = DateTime.now();
      final sesion = Sesion(
        grupoId: grupoId,
        maestroId: maestroId,
        fecha: now.toIso8601String().split('T')[0],
        horaInicio: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      await _service.startSession(sesion);
      return true;
    } catch (e) {
      debugPrint('Start session error: $e');
      return false;
    }
  }

  Future<bool> saveAttendance(List<Asistencia> asistencias) async {
    try {
      await _service.saveAttendance(asistencias);
      return true;
    } catch (e) {
      debugPrint('Save attendance error: $e');
      return false;
    }
  }
}
