class Maestro {
  final int id;
  final String nombre;
  final String email;
  final String? clave;
  final String? organizacionId;

  Maestro({
    required this.id,
    required this.nombre,
    required this.email,
    this.clave,
    this.organizacionId,
  });

  factory Maestro.fromJson(Map<String, dynamic> json) {
    return Maestro(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      clave: json['clave']?.toString(),
      organizacionId: json['organizacion_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'clave': clave,
      'organizacion_id': organizacionId,
    };
  }
}

