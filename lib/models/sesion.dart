class Sesion {
  final int? id;
  final String grupoId;
  final int maestroId;
  final String fecha;
  final String horaInicio;

  Sesion({
    this.id,
    required this.grupoId,
    required this.maestroId,
    required this.fecha,
    required this.horaInicio,
  });

  Map<String, dynamic> toJson() {
    return {
      'grupo_id': grupoId,
      'maestro_id': maestroId,
      'fecha': fecha,
      'hora_inicio': horaInicio,
    };
  }
}
