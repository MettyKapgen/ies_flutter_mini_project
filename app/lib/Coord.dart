class Coord {
  final int userId;
  final int randomLat;
  final int randomLon;

  const Coord({
    required this.userId,
    required this.randomLat,
    required this.randomLon,
  });

  factory Coord.fromJson(Map<String, dynamic> json) {
    return Coord(
      userId: json["userId"] as int,
      randomLat: json["lat"] as int,
      randomLon: json["lon"] as int,
    );
  }
}
