class ExamenProgramado {
  final String claveExamen;
  final String? grupoId;
  final String? grupoNombre;
  final String? curso;
  final String? tipo;
  final String? fecha;
  final String? hora;
  final String? salon;
  final String? claveAcceso;
  final int? maestroBaseId;
  final int? examinador1Id;
  final int? examinador2Id;
  final String? maestroBaseNombre;
  final String? examinador1Nombre;
  final String? examinador2Nombre;

  ExamenProgramado({
    required this.claveExamen,
    this.grupoId,
    this.grupoNombre,
    this.curso,
    this.tipo,
    this.fecha,
    this.hora,
    this.salon,
    this.claveAcceso,
    this.maestroBaseId,
    this.examinador1Id,
    this.examinador2Id,
    this.maestroBaseNombre,
    this.examinador1Nombre,
    this.examinador2Nombre,
  });

  factory ExamenProgramado.fromJson(Map<String, dynamic> json) {
    final g = json['grupos'];
    final mb = json['maestro_base'];
    final e1 = json['examinador1'];
    final e2 = json['examinador2'];
    return ExamenProgramado(
      claveExamen: json['clave_examen'] ?? '',
      grupoId: json['grupo_id']?.toString(),
      grupoNombre: g != null ? (g['clave']?.toString() ?? '') : null,
      curso: g?['cursos']?['curso'],
      tipo: json['tipo_examen'],
      fecha: json['fecha'],
      hora: json['hora'],
      salon: json['salon_id']?.toString(),
      claveAcceso: json['clave_acceso'],
      maestroBaseId: json['maestro_base_id'],
      examinador1Id: json['examinador1_id'],
      examinador2Id: json['examinador2_id'],
      maestroBaseNombre: mb?['nombre'],
      examinador1Nombre: e1?['nombre'],
      examinador2Nombre: e2?['nombre'],
    );
  }
}

class ResultadoExamen {
  final int? alumnoId;
  final String? credencial;
  final String? nombreAlumno;
  bool presento;
  bool aprobo;
  double? calificacion;
  String? nota;

  ResultadoExamen({
    this.alumnoId,
    this.credencial,
    this.nombreAlumno,
    this.presento = false,
    this.aprobo = false,
    this.calificacion,
    this.nota,
  });

  /// Auto-calcula aprobo: >= 70 = aprobado, < 70 = reprobado
  void setCalificacion(double? valor) {
    calificacion = valor;
    if (valor != null) {
      aprobo = valor >= 70.0;
      presento = true;
    }
  }
}
