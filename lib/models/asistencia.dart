enum EstadoAsistencia { asistencia, falta, retardo, reposicion }

class Asistencia {
  final int? id;
  final String grupoId;
  final int alumnoId;
  final String fecha;
  final EstadoAsistencia estado;
  final String? observaciones;

  Asistencia({
    this.id,
    required this.grupoId,
    required this.alumnoId,
    required this.fecha,
    required this.estado,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    String obs = observaciones ?? '';
    
    // Limpieza: eliminar prefijos anteriores para evitar duplicados o conflictos
    // Busca "RETARDO - ", "REPOSICIÓN - ", o las palabras solas
    obs = obs.replaceAll(RegExp(r'^(RETARDO|REPOSICIÓN) - ', caseSensitive: false), '');
    obs = obs.replaceAll(RegExp(r'^(RETARDO|REPOSICIÓN)$', caseSensitive: false), '');
    obs = obs.trim();

    String finalObservaciones = obs;
    if (estado == EstadoAsistencia.retardo) {
      finalObservaciones = obs.isNotEmpty ? 'RETARDO - $obs' : 'RETARDO';
    } else if (estado == EstadoAsistencia.reposicion) {
      finalObservaciones = obs.isNotEmpty ? 'REPOSICIÓN - $obs' : 'REPOSICIÓN';
    }

    return {
      'grupo_id': grupoId,
      'alumno_id': alumnoId,
      'fecha': fecha,
      'asistio': estado != EstadoAsistencia.falta, // Reposición cuenta como asistencia
      'observaciones': finalObservaciones,
    };
  }
}
