import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../models/grupo.dart';
import '../models/alumno.dart';
import '../models/sesion.dart';
import '../models/asistencia.dart';
import '../models/examen_programado.dart';

class DataProvider extends ChangeNotifier {
  final SupabaseService _service;
  List<Grupo> _grupos = [];
  List<Alumno> _alumnos = [];
  List<ExamenProgramado> _examenes = [];
  bool _isLoading = false;

  List<String> _hiddenIds = [];
  List<String> get hiddenIds => _hiddenIds;

  DataProvider(this._service) {
    _loadHiddenIds();
  }

  Future<void> _loadHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    _hiddenIds = prefs.getStringList('hiddenIds') ?? [];
    notifyListeners();
  }

  Future<void> toggleHidden(String id) async {
    if (_hiddenIds.contains(id)) {
      _hiddenIds.remove(id);
    } else {
      _hiddenIds.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hiddenIds', _hiddenIds);
    notifyListeners();
  }

  List<Grupo> get grupos => _grupos;
  List<Alumno> get alumnos => _alumnos;
  List<ExamenProgramado> get examenes => _examenes;
  bool get isLoading => _isLoading;

  List<String> _salones = [];
  List<String> get salones => _salones;

  Future<void> loadSalones() async {
    if (_salones.isEmpty) {
      _salones = await _service.getSalonesNumeros();
      notifyListeners();
    }
  }

  Future<void> loadGrupos(int maestroId) async {
    _isLoading = true;
    notifyListeners();
    _grupos = await _service.getMaestroGrupos(maestroId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAlumnos(String grupoClave) async {
    _isLoading = true;
    notifyListeners();
    _alumnos = await _service.getGrupoAlumnos(grupoClave);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExamenes(int maestroId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _examenes = await _service.getExamenesMaestro(maestroId);
    } catch (e) {
      debugPrint('Load examenes error: $e');
      _examenes = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<int> contarSesionesGrupo(String grupoId) async {
    try {
      return await _service.contarSesionesGrupo(grupoId);
    } catch (e) {
      debugPrint('Contar sesiones error: $e');
      return 0;
    }
  }

  Future<String?> obtenerClaveAcceso(String claveExamen, int maestroId) async {
    try {
      return await _service.obtenerClaveAcceso(claveExamen, maestroId);
    } catch (e) {
      debugPrint('Obtener clave acceso error: $e');
      return null;
    }
  }

  Future<bool> verificarClaveAcceso(String claveExamen, String claveAcceso) async {
    try {
      return await _service.verificarClaveAcceso(claveExamen, claveAcceso);
    } catch (e) {
      debugPrint('Verificar clave acceso error: $e');
      return false;
    }
  }

  Future<ExamenProgramado?> getExamenPorClaveAcceso(String claveAcceso) async {
    try {
      return await _service.getExamenPorClaveAcceso(claveAcceso);
    } catch (e) {
      debugPrint('Get examen clave acceso error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAlumnosGrupoExamen(String grupoId) async {
    try {
      return await _service.getAlumnosGrupoExamen(grupoId);
    } catch (e) {
      debugPrint('Get alumnos grupo examen error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getResultadosExamen(String claveExamen) async {
    try {
      return await _service.getResultadosExamen(claveExamen);
    } catch (e) {
      debugPrint('Get resultados examen error: $e');
      return [];
    }
  }

  Future<String> guardarResultadosExamen({
    required String claveExamen,
    required int maestroCalificadorId,
    required String credencialMaestro,
    required List<ResultadoExamen> resultados,
  }) async {
    try {
      await _service.guardarResultadosExamen(
        claveExamen: claveExamen,
        maestroCalificadorId: maestroCalificadorId,
        credencialMaestro: credencialMaestro,
        resultados: resultados,
      );
      return 'OK';
    } catch (e) {
      debugPrint('Guardar resultados error: $e');
      return e.toString();
    }
  }

  Future<String> startClassSession(Sesion sesion) async {
    try {
      await _service.startSession(sesion);
      return 'OK';
    } catch (e) {
      debugPrint('Start session error: $e');
      if (e.toString().contains('23505') || e.toString().contains('duplicate key')) {
        return 'DUPLICATE_DAY';
      }
      return 'ERROR';
    }
  }

  Future<bool> checkSessionExistsThisWeek(String grupoId, DateTime date) async {
    try {
      return await _service.checkSessionExistsThisWeek(grupoId, date);
    } catch (e) {
      debugPrint('Check session error: $e');
      return false;
    }
  }

  Future<bool> checkSalonAvailability(String salonId, String fecha, String hora) async {
    try {
      return await _service.checkSalonAvailability(salonId, fecha, hora);
    } catch (e) {
      debugPrint('Check salon error: $e');
      return false;
    }
  }

  Future<String> saveAttendance(List<Asistencia> asistencias) async {
    try {
      await _service.saveAttendance(asistencias);
      return 'OK';
    } catch (e) {
      debugPrint('Save attendance error: $e');
      return e.toString();
    }
  }
}


