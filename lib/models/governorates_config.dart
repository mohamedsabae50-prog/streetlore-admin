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
    luxorGovernorate,
    redSeaGovernorate,
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
    LatLng(31.3350, 30.0950),
    LatLng(31.2600, 30.1400),
    LatLng(31.1200, 30.0800),
    LatLng(30.9500, 29.9800),
    LatLng(30.8000, 29.8500),
    LatLng(30.7800, 29.5500),
    LatLng(30.8800, 29.4800),
    LatLng(31.0500, 29.6800),
    LatLng(31.1600, 29.8200),
    LatLng(31.2800, 29.9500),
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
    LatLng(30.2600, 30.7500),
    LatLng(30.2800, 31.1500),
    LatLng(30.2800, 31.5200),
    LatLng(30.2200, 31.8800),
    LatLng(29.9200, 31.8800),
    LatLng(29.6000, 31.5000),
    LatLng(29.5500, 31.1800),
    LatLng(29.7800, 30.8200),
    LatLng(30.0200, 30.7200),
  ],
);

const luxorGovernorate = GovernorateConfig(
  id: 'luxor',
  nameEn: 'Luxor & Aswan',
  nameAr: 'الأقصر وأسوان',
  centerLat: 24.9500,
  centerLng: 32.7600,
  defaultZoom: 8.8,
  boundaryPolygon: [
    LatLng(25.9000, 32.3000),
    LatLng(25.9000, 33.1500),
    LatLng(25.2000, 33.2500),
    LatLng(24.5000, 33.4500),
    LatLng(23.8000, 33.5500),
    LatLng(22.1500, 32.1000),
    LatLng(22.1500, 31.3500),
    LatLng(23.1000, 31.4500),
    LatLng(24.1500, 32.2500),
    LatLng(25.2500, 32.2500),
  ],
);

const redSeaGovernorate = GovernorateConfig(
  id: 'red_sea',
  nameEn: 'Hurghada & Marsa Alam',
  nameAr: 'الغردقة ومرسى علم',
  centerLat: 26.8500,
  centerLng: 33.9500,
  defaultZoom: 8.8,
  boundaryPolygon: [
    LatLng(29.1000, 32.2500),
    LatLng(29.1000, 33.1500),
    LatLng(27.6000, 34.1500),
    LatLng(26.2000, 34.6500),
    LatLng(24.8000, 35.3500),
    LatLng(24.0500, 35.6500),
    LatLng(24.0500, 34.4500),
    LatLng(25.2000, 34.1000),
    LatLng(26.3500, 33.4000),
    LatLng(27.5000, 33.0500),
  ],
);

String normalizeGovernorateId(String governorateId) {
  final normalized = governorateId.trim().toLowerCase();
  return switch (normalized) {
    'giza' => 'cairo',
    'aswan' || 'أسوان' => 'luxor',
    'hurghada' || 'marsa_alam' => 'red_sea',
    _ => normalized,
  };
}

const Map<String, GovernorateConfig> governoratesConfig = {
  'alexandria': alexandriaGovernorate,
  'cairo': cairoGovernorate,
  'luxor': luxorGovernorate,
  'red_sea': redSeaGovernorate,
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
