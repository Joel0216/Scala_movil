class Grupo {
  final String id;
  final String nombre;
  final String? clave;
  final String? maestroId;
  final String? horario;
  final String? salon;
  final String? curso;
  final String? fechaInicio;
  final String? dia;

  Grupo({
    required this.id,
    required this.nombre,
    this.clave,
    this.maestroId,
    this.horario,
    this.salon,
    this.curso,
    this.fechaInicio,
    this.dia,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    // Si viene el nombre del curso en el join con cursos, lo usamos como nombre descriptivo
    final String cursoName = json['cursos'] != null ? json['cursos']['curso']?.toString() ?? '' : json['curso']?.toString() ?? '';
    
    return Grupo(
      id: json['id'].toString(), // Es un UUID
      nombre: cursoName.isNotEmpty ? cursoName : (json['nombre'] != null && json['nombre'] != '' && json['nombre'] != 'Grupo S/N' ? json['nombre'] : 'Grupo ${json['clave']}'),
      clave: json['clave'],
      maestroId: json['maestro_id'],
      horario: json['horario'],
      salon: json['salon'],
      curso: cursoName,
      fechaInicio: json['fecha_inicio'],
      dia: json['dia'],
    );
  }
}
