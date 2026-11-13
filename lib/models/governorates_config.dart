import 'dart:math' as math;

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
  nameEn: 'Cairo & Giza',
  nameAr: 'القاهرة والجيزة',
  centerLat: 30.0444,
  centerLng: 31.2357,
  defaultZoom: 11,
  boundaryPolygon: [
    LatLng(30.1450, 31.1850),
    LatLng(30.1300, 31.2380),
    LatLng(30.1580, 31.3350),
    LatLng(30.1650, 31.4600),
    LatLng(30.1950, 31.6000),
    LatLng(30.1800, 31.7600),
    LatLng(30.0800, 31.8300),
    LatLng(29.9300, 31.8000),
    LatLng(29.8800, 31.6200),
    LatLng(29.7800, 31.4200),
    LatLng(29.7500, 31.2600),
    LatLng(29.7500, 31.1200),
    LatLng(29.8800, 30.8800),
    LatLng(30.0200, 30.8500),
    LatLng(30.1300, 30.9200),
    LatLng(30.1550, 31.0800),
  ],
);

String normalizeGovernorateId(String governorateId) {
  final normalized = governorateId.trim().toLowerCase();
  return normalized == 'giza' ? 'cairo' : normalized;
}

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
  final polygon = governoratesConfig[normalizeGovernorateId(governorateId)]
      ?.boundaryPolygon;
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

bool isPointInGovernorateOrExpandedBounds(
  double lat,
  double lng,
  String governorateId, {
  double expansionKm = 5,
}) {
  if (isPointInGovernorate(lat, lng, governorateId)) return true;
  if (!lat.isFinite ||
      !lng.isFinite ||
      expansionKm < 0 ||
      !expansionKm.isFinite) {
    return false;
  }
  final polygon = governoratesConfig[normalizeGovernorateId(governorateId)]
      ?.boundaryPolygon;
  if (polygon == null || polygon.length < 3) return false;

  const kilometersPerDegree = 111.32;
  final longitudeScale = kilometersPerDegree * math.cos(lat * math.pi / 180);
  final pointX = lng * longitudeScale;
  final pointY = lat * kilometersPerDegree;
  var nearestDistanceSquared = double.infinity;
  for (var i = 0; i < polygon.length; i++) {
    final start = polygon[i];
    final end = polygon[(i + 1) % polygon.length];
    final startX = start.longitude * longitudeScale;
    final startY = start.latitude * kilometersPerDegree;
    final endX = end.longitude * longitudeScale;
    final endY = end.latitude * kilometersPerDegree;
    final edgeX = endX - startX;
    final edgeY = endY - startY;
    final edgeLengthSquared = edgeX * edgeX + edgeY * edgeY;
    final projection = edgeLengthSquared == 0
        ? 0.0
        : (((pointX - startX) * edgeX + (pointY - startY) * edgeY) /
                  edgeLengthSquared)
              .clamp(0.0, 1.0)
              .toDouble();
    final deltaX = pointX - (startX + projection * edgeX);
    final deltaY = pointY - (startY + projection * edgeY);
    nearestDistanceSquared = math.min(
      nearestDistanceSquared,
      deltaX * deltaX + deltaY * deltaY,
    );
  }
  return nearestDistanceSquared <= expansionKm * expansionKm;
}
