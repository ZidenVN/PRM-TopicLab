import 'package:latlong2/latlong.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String displayName;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      displayName: json['display_name'] ?? '',
    );
  }

  LatLng get toLatLng => LatLng(latitude, longitude);
}

class TripRoute {
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> points;

  TripRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
  });

  String get distanceKm => '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  
  String get durationMinutes {
    final mins = (durationSeconds / 60).round();
    if (mins < 60) return '$mins phút';
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    return '$hours giờ $remainingMins phút';
  }

  String get etaString {
    final eta = DateTime.now().add(Duration(seconds: durationSeconds.round()));
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(eta.hour)}:${twoDigits(eta.minute)}';
  }
}