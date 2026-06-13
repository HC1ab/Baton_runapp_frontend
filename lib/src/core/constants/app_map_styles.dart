/// Google Maps style JSON strings.
///
/// [darkWarm] is the redesign's warm near-black map theme — used on the
/// Live Run and Run Detail screens so the map blends into the dark UI.
abstract final class AppMapStyles {
  /// Refined charcoal map matching the redesign surfaces (--screen #141416).
  /// Place & road labels visible; POI/transit icons hidden. Buildings render
  /// via the map's buildingsEnabled flag (3D on the Live Run screen).
  static const String darkWarm = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#17171A"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8E8E91"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0F0F11"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "administrative.neighborhood", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#242427"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1A1A1D"}]},
  {"featureType": "road", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2B2B2E"}]},
  {"featureType": "road.local", "elementType": "geometry", "stylers": [{"color": "#1F1F22"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#101012"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4A5468"}]}
]
''';
}
