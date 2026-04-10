class Maestro {
  final int id;
  final String nombre;
  final String email;
  final String? clave;

  Maestro({
    required this.id,
    required this.nombre,
    required this.email,
    this.clave,
  });

  factory Maestro.fromJson(Map<String, dynamic> json) {
    return Maestro(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      clave: json['clave']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'clave': clave,
    };
  }
}

