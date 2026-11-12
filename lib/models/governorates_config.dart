import 'package:latlong2/latlong.dart';

class GovernorateConfig {
  final String id;
  final String nameEn;
  final String nameAr;
  final double centerLat;
  final double centerLng;
  final double defaultZoom;
  final List<LatLng> boundaryPolygon;

  const GovernorateConfig({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.centerLat,
    required this.centerLng,
    required this.defaultZoom,
    required this.boundaryPolygon,
  });

  static const all = <GovernorateConfig>[
    alexandriaGovernorate,
    cairoGovernorate,
  ];
}

const alexandriaGovernorate = GovernorateConfig(
  id: 'alexandria',
  nameEn: 'Alexandria',
  nameAr: 'الإسكندرية',
  centerLat: 31.2001,
  centerLng: 29.9187,
  defaultZoom: 11,
  boundaryPolygon: [
    LatLng(31.470, 29.420),
    LatLng(31.485, 29.620),
    LatLng(31.485, 29.850),
    LatLng(31.465, 30.080),
    LatLng(31.425, 30.145),
    LatLng(31.350, 30.165),
    LatLng(31.280, 30.155),
    LatLng(31.210, 30.140),
    LatLng(31.150, 30.120),
    LatLng(31.100, 30.090),
    LatLng(30.980, 29.990),
    LatLng(30.880, 29.840),
    LatLng(30.800, 29.680),
    LatLng(30.735, 29.520),
    LatLng(30.755, 29.435),
    LatLng(30.870, 29.400),
    LatLng(31.000, 29.415),
    LatLng(31.150, 29.455),
    LatLng(31.300, 29.450),
    LatLng(31.410, 29.425),
  ],
);

const cairoGovernorate = GovernorateConfig(
  id: 'cairo',
  nameEn: 'Cairo',
  nameAr: 'القاهرة',
  centerLat: 30.0444,
  centerLng: 31.2357,
  defaultZoom: 11,
  boundaryPolygon: [
    LatLng(30.1350, 31.2420),
    LatLng(30.1620, 31.3350),
    LatLng(30.1450, 31.4350),
    LatLng(30.0800, 31.5200),
    LatLng(29.9600, 31.5000),
    LatLng(29.8300, 31.3600),
    LatLng(29.8400, 31.2950),
    LatLng(29.9550, 31.2450),
    LatLng(30.0050, 31.2220),
    LatLng(30.0430, 31.2160),
    LatLng(30.0680, 31.2155),
    LatLng(30.0950, 31.2330),
  ],
);

const Map<String, GovernorateConfig> governoratesConfig = {
  'alexandria': alexandriaGovernorate,
  'cairo': cairoGovernorate,
};

bool isPointInGovernorate(double lat, double lng, String governorateId) {
  if (!lat.isFinite ||
      !lng.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180) {
    return false;
  }
  final polygon = governoratesConfig[governorateId]?.boundaryPolygon;
  if (polygon == null || polygon.length < 3) return false;

  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[j];
    final b = polygon[i];
    final onEdge =
        ((lng - a.longitude) * (b.latitude - a.latitude) -
                    (lat - a.latitude) * (b.longitude - a.longitude))
                .abs() <
            1e-10 &&
        lat >= (a.latitude < b.latitude ? a.latitude : b.latitude) &&
        lat <= (a.latitude > b.latitude ? a.latitude : b.latitude) &&
        lng >= (a.longitude < b.longitude ? a.longitude : b.longitude) &&
        lng <= (a.longitude > b.longitude ? a.longitude : b.longitude);
    if (onEdge) return true;

    final crossesLatitude = (a.latitude > lat) != (b.latitude > lat);
    if (crossesLatitude) {
      final edgeLongitude =
          (b.longitude - a.longitude) *
              (lat - a.latitude) /
              (b.latitude - a.latitude) +
          a.longitude;
      if (lng < edgeLongitude) inside = !inside;
    }
  }
  return inside;
}
