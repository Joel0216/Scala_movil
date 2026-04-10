import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maestro.dart';
import '../models/grupo.dart';
import '../models/alumno.dart';
import '../models/sesion.dart';
import '../models/asistencia.dart';
import '../models/examen_programado.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Auth
  Future<AuthResponse> signIn(String emailOrClave, String password) async {
    String email = emailOrClave;

    // Check if it's a clave instead of an email (doesn't contain @)
    if (!emailOrClave.contains('@')) {
      final response = await client
          .from('maestros')
          .select('email')
          .or('clave.eq.$emailOrClave,nombre.ilike.%$emailOrClave%')
          .limit(1)
          .maybeSingle();

      if (response != null && response['email'] != null) {
        email = response['email'];
      }
    }

    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Verifica si el maestro existe por CLAVE y está activo.
  // Si existe y no tiene email, guarda el email proporcionado.
  // Retorna: 'OK' = puede registrarse, 'ALREADY_VERIFIED' = ya tiene email (quizá ya registrado),
  //          'NOT_FOUND' = clave inválida o inactivo
  Future<String> verifyMaestroForRegistration(String clave, String email) async {
    // Buscar maestro por clave exacta
    final response = await client
        .from('maestros')
        .select('id, activo, email')
        .eq('clave', clave.toUpperCase().trim())
        .limit(1)
        .maybeSingle();

    if (response == null) return 'NOT_FOUND';
    if (response['activo'] != true) return 'NOT_FOUND';

    final existingEmail = response['email'];
    final maestroId = response['id'];

    if (existingEmail != null && existingEmail.toString().trim().isNotEmpty) {
      // Ya tiene un email guardado
      if (existingEmail.toString().toLowerCase() == email.toLowerCase()) {
        // Es el mismo email → puede registrarse o actualizar contraseña
        return 'OK';
      } else {
        // El email ya fue asignado a otra cuenta diferente
        return 'EMAIL_MISMATCH';
      }
    }

    // No tiene email → guardar el email proporcionado
    await client
        .from('maestros')
        .update({'email': email.toLowerCase().trim()})
        .eq('id', maestroId);

    return 'OK';
  }

  Future<AuthResponse> signUpMaestro(String email, String password) async {
    final response = await client.auth.signUp(email: email, password: password);
    return response;
  }

  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Teacher Profile - busca por email (insensible a mayúsculas)
  Future<Maestro?> getMaestroProfile(String email) async {
    final response = await client
        .from('maestros')
        .select('id, nombre, email, clave')
        .ilike('email', email.trim())
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Maestro.fromJson(response);
  }

  // Groups
  Future<List<Grupo>> getMaestroGrupos(int maestroId) async {
    final response = await client
        .from('grupos')
        .select('*, cursos(curso)')
        .eq('maestro_id', maestroId);

    return (response as List).map((json) => Grupo.fromJson(json)).toList();
  }

  // Salones
  Future<List<String>> getSalonesNumeros() async {
    final response = await client.from('salones').select('numero').eq('activo', true);
    return (response as List).map((e) => e['numero'].toString()).toList();
  }

  // Students in Group
  Future<List<Alumno>> getGrupoAlumnos(String grupoClave) async {
    final response = await client
        .from('alumno_grupos')
        .select('alumnos(*)')
        .eq('grupo_clave', grupoClave)
        .eq('estado', 'Activo');

    final List<Alumno> alumnos = [];
    final Set<int> added = {};
    for (var json in response as List) {
      if (json['alumnos'] != null) {
        final a = Alumno.fromJson(json);
        if (!added.contains(a.id)) {
          added.add(a.id);
          alumnos.add(a);
        }
      }
    }
    return alumnos;
  }

  // Sessions
  Future<void> startSession(Sesion sesion) async {
    await client.from('sesiones_clase').insert(sesion.toJson());
  }

  Future<bool> checkSessionExistsThisWeek(String grupoId, DateTime date) async {
    final int difference = date.weekday - 1;
    final DateTime monday = date.subtract(Duration(days: difference));
    final DateTime sunday = monday.add(const Duration(days: 6));

    final String mondayStr = monday.toIso8601String().split('T')[0];
    final String sundayStr = sunday.toIso8601String().split('T')[0];

    final response = await client
        .from('sesiones_clase')
        .select('id')
        .eq('grupo_id', grupoId)
        .gte('fecha', mondayStr)
        .lte('fecha', sundayStr);

    return (response as List).isNotEmpty;
  }

  Future<bool> checkSalonAvailability(String salonId, String fecha, String hora) async {
    final response = await client.rpc(
      'check_salon_disponible',
      params: {
        'p_salon': salonId,
        'p_fecha': fecha,
        'p_hora_inicio': hora,
      },
    );
    return response as bool;
  }

  // Attendance
  Future<void> saveAttendance(List<Asistencia> asistencias) async {
    final data = asistencias.map((a) => a.toJson()).toList();
    await client.from('asistencias').upsert(data, onConflict: 'grupo_id, alumno_id, fecha').select();
  }

  // ============================================================
  // EXÁMENES
  // ============================================================

  /// Devuelve los exámenes donde el maestro es base, examinador1 o examinador2
  Future<List<ExamenProgramado>> getExamenesMaestro(int maestroId) async {
    final response = await client
        .from('programacion_examenes')
        .select('''
          id,
          clave_examen,
          fecha,
          hora,
          tipo_examen,
          salon_id,
          grupo_id,
          clave_acceso,
          maestro_base_id,
          examinador1_id,
          examinador2_id,
          grupos(clave, cursos(curso))
        ''')
        .or('maestro_base_id.eq.$maestroId,examinador1_id.eq.$maestroId,examinador2_id.eq.$maestroId')
        .order('fecha', ascending: false);

    // Deduplicar por clave_examen
    final set = <String>{};
    final result = <ExamenProgramado>[];
    for (final json in response as List) {
      final clave = json['clave_examen'] as String;
      if (!set.contains(clave)) {
        set.add(clave);
        result.add(ExamenProgramado.fromJson(json));
      }
    }
    return result;
  }

  /// Cuenta las sesiones registradas para un grupo
  Future<int> contarSesionesGrupo(String grupoId) async {
    final response = await client
        .from('sesiones_clase')
        .select('id')
        .eq('grupo_id', grupoId);
    return (response as List).length;
  }

  /// Obtiene la clave de acceso de un examen (solo si el maestro es base)
  Future<String?> obtenerClaveAcceso(String claveExamen, int maestroId) async {
    final response = await client
        .from('programacion_examenes')
        .select('clave_acceso')
        .eq('clave_examen', claveExamen)
        .eq('maestro_base_id', maestroId)
        .maybeSingle();
    return response?['clave_acceso'] as String?;
  }

  /// Verifica si una clave de acceso es válida para el examen
  Future<bool> verificarClaveAcceso(String claveExamen, String claveAcceso) async {
    final response = await client
        .from('programacion_examenes')
        .select('clave_acceso')
        .eq('clave_examen', claveExamen)
        .maybeSingle();
    if (response == null) return false;
    return response['clave_acceso'] == claveAcceso;
  }

  /// Busca un examen por su clave de acceso
  Future<ExamenProgramado?> getExamenPorClaveAcceso(String claveAcceso) async {
    final response = await client
        .from('programacion_examenes')
        .select('*, grupos(clave, cursos(curso))')
        .eq('clave_acceso', claveAcceso)
        .maybeSingle();
    
    if (response == null) return null;
    return ExamenProgramado.fromJson(response);
  }

  /// Obtiene los alumnos del grupo del examen
  Future<List<Map<String, dynamic>>> getAlumnosGrupoExamen(String grupoClave) async {
    final response = await client
        .from('alumno_grupos')
        .select('alumno_id')
        .eq('grupo_clave', grupoClave)
        .eq('estado', 'Activo');

    final List<int> alumnoIds = (response as List)
        .map((e) => e['alumno_id'] as int)
        .toList();

    if (alumnoIds.isEmpty) return [];

    final result = await client
        .from('alumnos')
        .select('id, nombre, credencial')
        .inFilter('id', alumnoIds)
        .eq('activo', true);

    return (result as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Consulta resultados existentes para bloquear los ya calificados
  Future<List<Map<String, dynamic>>> getResultadosExamen(String claveExamen) async {
    final response = await client
        .from('resultados_examen')
        .select('*')
        .eq('clave_examen', claveExamen);
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Guarda los resultados de un examen en resultados_examen
  Future<void> guardarResultadosExamen({
    required String claveExamen,
    required int maestroCalificadorId,
    required String credencialMaestro,
    required List<ResultadoExamen> resultados,
  }) async {
    final ahora = DateTime.now().toUtc().toIso8601String();
    final data = resultados.map((r) => {
      'clave_examen': claveExamen,
      'alumno_id': r.alumnoId,
      'presento': r.presento,
      'aprobo': r.aprobo,
      'calificacion': r.calificacion,
      'nota': r.nota,
      'maestro_calificador_id': maestroCalificadorId,
      'credencial_maestro': credencialMaestro,
      'hora_calificacion': ahora,
    }).toList();
    await client.from('resultados_examen').upsert(data, onConflict: 'clave_examen,alumno_id');
  }
}

