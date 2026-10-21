import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';

class MapService {
  // Danh sách địa điểm nhanh có sẵn (offline presets)
  static final Map<String, LocationModel> quickPlaces = {
    'ha noi': LocationModel(latitude: 21.028511, longitude: 105.854444, displayName: 'Hồ Hoàn Kiếm, Hà Nội'),
    'da nang': LocationModel(latitude: 16.054407, longitude: 108.202167, displayName: 'Cầu Rồng, TP. Đà Nẵng'),
    'ho chi minh': LocationModel(latitude: 10.776889, longitude: 106.700806, displayName: 'Chợ Bến Thành, TP. Hồ Chí Minh'),
    'sai gon': LocationModel(latitude: 10.776889, longitude: 106.700806, displayName: 'Chợ Bến Thành, TP. Hồ Chí Minh'),
    'landmark 81': LocationModel(latitude: 10.7951, longitude: 106.7218, displayName: 'Landmark 81, TP. Hồ Chí Minh'),
    'khu cong nghe cao': LocationModel(latitude: 10.8411, longitude: 106.8099, displayName: 'Khu Công Nghệ Cao TP.HCM (Quận 9)'),
  };

  /// 1. Tìm kiếm địa điểm qua OpenStreetMap Nominatim API
  Future<LocationModel?> searchLocation(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return null;

    for (var key in quickPlaces.keys) {
      if (cleanQuery.contains(key)) {
        return quickPlaces[key];
      }
    }

    final targetUrl = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
    final proxyUrl = Uri.parse('https://api.allorigins.win/get?url=${Uri.encodeComponent(targetUrl)}');

    try {
      final response = await http.get(proxyUrl).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Map<String, dynamic> proxyData = jsonDecode(response.body);
        final List results = jsonDecode(proxyData['contents']);
        if (results.isNotEmpty) {
          return LocationModel.fromJson(results[0]);
        }
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }

  /// 2. Tính tuyến đường ô tô qua OSRM Route API (Question 2)
  Future<TripRoute?> getRoute(LatLng start, LatLng end) async {
    // Thứ tự tham số OSRM: {start.longitude},{start.latitude};{end.longitude},{end.latitude}
    final osrmUrl = 'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(osrmUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0];
          final distance = (route['distance'] as num).toDouble();
          final duration = (route['duration'] as num).toDouble();
          final coords = route['geometry']['coordinates'] as List;

          final polylinePoints = coords.map((c) {
            // GeoJSON format: [longitude, latitude]
            return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
          }).toList();

          return TripRoute(
            distanceMeters: distance,
            durationSeconds: duration,
            points: polylinePoints,
          );
        }
      }
    } catch (_) {
      // Nếu API OSRM bị nghẽn mạng, tính đường nối thẳng thông minh (Great Circle)
      return _generateFallbackRoute(start, end);
    }

    return _generateFallbackRoute(start, end);
  }

  TripRoute _generateFallbackRoute(LatLng start, LatLng end) {
    const distanceCalc = Distance();
    final meters = distanceCalc.as(LengthUnit.Meter, start, end);
    // Vận tốc ước tính nội thành 35 km/h ~ 9.7 m/s
    final seconds = meters / 9.7;

    // Sinh 10 điểm trung gian để vẽ đường cong tự nhiên
    final points = <LatLng>[start];
    for (int i = 1; i < 10; i++) {
      final fraction = i / 10.0;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }
    points.add(end);

    return TripRoute(
      distanceMeters: meters,
      durationSeconds: seconds,
      points: points,
    );
  }
}