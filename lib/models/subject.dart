class Subject {
  final String id;
  final String code;
  final String name;
  final int credits;
  final int capacity;
  final int enrolled;

  Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.capacity,
    required this.enrolled,
  });

  factory Subject.fromMap(String id, Map<String, dynamic> data) {
    return Subject(
      id: id,
      code: data['code'],
      name: data['name'],
      credits: data['credits'],
      capacity: data['capacity'],
      enrolled: data['enrolled'],
    );
  }
}