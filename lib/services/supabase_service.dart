import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maestro.dart';
import '../models/grupo.dart';
import '../models/alumno.dart';
import '../models/sesion.dart';
import '../models/asistencia.dart';

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

  // Teacher Verification and Registration
  Future<String> verifyMaestroStatus(String email) async {
    final response = await client
        .from('maestros')
        .select('id, activo')
        .eq('email', email)
        .maybeSingle();
    
    if (response == null || response['activo'] != true) return 'NOT_FOUND';
    return 'OK';
  }

  Future<AuthResponse> signUpMaestro(String email, String password) async {
    final response = await client.auth.signUp(email: email, password: password);
    return response;
  }

  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Teacher Profile
  Future<Maestro?> getMaestroProfile(String email) async {
    final response = await client
        .from('maestros')
        .select()
        .eq('email', email)
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

  // Students in Group
  Future<List<Alumno>> getGrupoAlumnos(String grupoId) async {
    final response = await client
        .from('alumno_grupos')
        .select('alumnos(*)')
        .eq('grupo_id', grupoId);
    
    return (response as List).map((json) => Alumno.fromJson(json)).toList();
  }

  // Sessions
  Future<void> startSession(Sesion sesion) async {
    await client.from('sesiones_clase').insert(sesion.toJson());
  }

  // Attendance
  Future<void> saveAttendance(List<Asistencia> asistencias) async {
    final data = asistencias.map((a) => a.toJson()).toList();
    await client.from('asistencias').upsert(data, onConflict: 'grupo_id, alumno_id, fecha');
  }
}
