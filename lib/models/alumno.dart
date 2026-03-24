class Alumno {
  final int id;
  final String nombre;
  final String? email;

  Alumno({
    required this.id,
    required this.nombre,
    this.email,
  });

  factory Alumno.fromJson(Map<String, dynamic> json) {
    // Handling possible join structure from Supabase
    final alumnoData = json['alumnos'] ?? json;
    return Alumno(
      id: alumnoData['id'],
      nombre: alumnoData['nombre'] ?? '',
      email: alumnoData['email'],
    );
  }
}
