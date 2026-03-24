class Maestro {
  final int id;
  final String nombre;
  final String email;

  Maestro({
    required this.id,
    required this.nombre,
    required this.email,
  });

  factory Maestro.fromJson(Map<String, dynamic> json) {
    return Maestro(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
    };
  }
}
