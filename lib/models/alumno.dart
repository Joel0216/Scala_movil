class Alumno {
  final String id;
  final String nombre;
  final String? email;
  final String? credencial;

  Alumno({
    required this.id,
    required this.nombre,
    this.email,
    this.credencial,
  });

  factory Alumno.fromJson(Map<String, dynamic> json) {
    // Handling possible join structure from Supabase
    final alumnoData = json['alumnos'] ?? json;
    return Alumno(
      id: alumnoData['id'].toString(),
      nombre: alumnoData['nombre'] ?? '',
      email: alumnoData['email'],
      credencial: alumnoData['credencial']?.toString(),
    );
  }
}
