class Pet {
  final String id;
  final String name;
  final String breed;
  final String age;
  final String color;
  final String ownerName;
  final String ownerPhone;
  final String ownerAddress;
  final String? photoPath;
  final String? driveUrl;  // URL del archivo en Drive
  final DateTime registeredAt;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.color,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerAddress,
    this.photoPath,
    this.driveUrl,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'breed': breed,
    'age': age,
    'color': color,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'ownerAddress': ownerAddress,
    'photoPath': photoPath,
    'driveUrl': driveUrl,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json['id'],
    name: json['name'],
    breed: json['breed'],
    age: json['age'],
    color: json['color'],
    ownerName: json['ownerName'],
    ownerPhone: json['ownerPhone'],
    ownerAddress: json['ownerAddress'],
    photoPath: json['photoPath'],
    driveUrl: json['driveUrl'],
    registeredAt: DateTime.parse(json['registeredAt']),
  );

  String toQRData() {
    // Si tiene URL de Drive, usa esa; si no, muestra info básica
    if (driveUrl != null && driveUrl!.isNotEmpty) {
      return driveUrl!;
    }
    return 'PET:|OWNER:|PHONE:';
  }
}
