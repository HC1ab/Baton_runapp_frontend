/// A single GPS coordinate recorded during a run.
/// Immutable — no business logic inside.
class RunPathPoint {
  const RunPathPoint({
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  Map<String, double> toJson() => {'lat': lat, 'lng': lng};

  factory RunPathPoint.fromJson(Map<String, Object?> json) {
    return RunPathPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RunPathPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}
