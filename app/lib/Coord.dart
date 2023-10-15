class Coord {
  final int userId;
  final double Lat;
  final double Lon;

  const Coord({
    required this.userId,
    required this.Lat,
    required this.Lon,
  });

  factory Coord.fromJson(Map<String, dynamic> json) {
    return Coord(
      userId: json["userId"] as int,
      Lat: json["lat"] as double,
      Lon: json["lon"] as double,
    );
  }
}
