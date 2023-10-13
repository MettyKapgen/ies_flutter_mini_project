class User {
  final String userId;
  final String age;
  final String name;

  const User({
    required this.userId,
    required this.age,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      age: json["age"] as String,
      userId: json["userId"] as String,
      name: json["name"] as String,
    );
  }
}
