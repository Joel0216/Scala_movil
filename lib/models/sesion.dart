class Sesion {
  final int? id;
  final String grupoId;
  final String maestroId;
  final String fecha;
  final String horaInicio;
  final bool esExtra;
  final String? motivoExtra;
  final String? salonExtra;

  Sesion({
    this.id,
    required this.grupoId,
    required this.maestroId,
    required this.fecha,
    required this.horaInicio,
    this.esExtra = false,
    this.motivoExtra,
    this.salonExtra,
  });

  Map<String, dynamic> toJson() {
    return {
      'grupo_id': grupoId,
      'maestro_id': maestroId,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'es_extra': esExtra,
      if (motivoExtra != null) 'motivo_extra': motivoExtra,
      if (salonExtra != null) 'salon_extra': salonExtra,
    };
  }
}
