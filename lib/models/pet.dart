class Pet {
  final String id;
  final String name;
  final String breed;
  final String age;
  final String color;
  final String ownerName;
  final String ownerPhone;
  final String ownerAddress;
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
    registeredAt: DateTime.parse(json['registeredAt']),
  );

  String toQRData() {
    return 'PET:|BREED:|AGE:|COLOR:|OWNER:|PHONE:|ADDRESS:';
  }
}
