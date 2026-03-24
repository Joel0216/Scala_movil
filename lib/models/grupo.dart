class Grupo {
  final int id;
  final String nombre;
  final int? maestroId;
  final String? horario;
  final String? salon;
  final String? curso;

  Grupo({
    required this.id,
    required this.nombre,
    this.maestroId,
    this.horario,
    this.salon,
    this.curso,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      maestroId: json['maestro_id'],
      horario: json['horario'],
      salon: json['salon'],
      curso: json['cursos'] != null ? json['cursos']['nombre'] : json['curso'],
    );
  }
}
