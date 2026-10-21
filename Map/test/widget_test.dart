import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:map/models/location_model.dart';
import 'package:map/services/map_service.dart';
import 'package:map/main.dart';

void main() {
  group('LocationModel and TripRoute Model Tests', () {
    test('LocationModel parses JSON and converts to LatLng correctly', () {
      final json = {
        'lat': '10.776889',
        'lon': '106.700806',
        'display_name': 'Chợ Bến Thành, TP.HCM',
      };
      final loc = LocationModel.fromJson(json);
      expect(loc.latitude, 10.776889);
      expect(loc.longitude, 106.700806);
      expect(loc.displayName, 'Chợ Bến Thành, TP.HCM');
      expect(loc.toLatLng.latitude, 10.776889);
      expect(loc.toLatLng.longitude, 106.700806);
    });

    test('TripRoute formats distance and duration correctly', () {
      final route = TripRoute(
        distanceMeters: 12500,
        durationSeconds: 1500,
        points: [
          const LatLng(10.776889, 106.700806),
          const LatLng(10.7951, 106.7218),
        ],
      );
      expect(route.distanceKm, '12.5 km');
      expect(route.durationMinutes, '25 phút');
      expect(route.etaString, isNotEmpty);
      expect(route.points.length, 2);
    });

    test('TripRoute formats hours when duration exceeds 60 minutes', () {
      final route = TripRoute(
        distanceMeters: 120000,
        durationSeconds: 5400, // 90 mins -> 1 giờ 30 phút
        points: [],
      );
      expect(route.distanceKm, '120.0 km');
      expect(route.durationMinutes, '1 giờ 30 phút');
    });
  });

  group('MapService Offline Presets Tests', () {
    test('Finds preset locations without internet', () async {
      final service = MapService();
      final landmark = await service.searchLocation('landmark 81');
      expect(landmark, isNotNull);
      expect(landmark!.displayName, contains('Landmark 81'));

      final hanoi = await service.searchLocation('ha noi');
      expect(hanoi, isNotNull);
      expect(hanoi!.displayName, contains('Hà Nội'));

      final empty = await service.searchLocation('');
      expect(empty, isNull);
    });
  });

  testWidgets('Map App smoke test - renders title and actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Bản đồ & Tuyến đường (OSRM & GPS)'), findsOneWidget);
  });
}
