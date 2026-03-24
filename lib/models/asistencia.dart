enum EstadoAsistencia { asistencia, falta, retardo }

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
    return {
      'grupo_id': grupoId,
      'alumno_id': alumnoId,
      'fecha': fecha,
      'estado': estado.name.toUpperCase(),
      'asistio': estado != EstadoAsistencia.falta,
      'observaciones': observaciones ?? '',
    };
  }
}
