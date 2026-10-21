import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';
import '../services/map_service.dart';

enum SelectingMode { start, destination }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final MapService _mapService = MapService();

  // Chế độ chọn điểm: Đang chọn Điểm đi (A) hay Điểm đến (B)
  SelectingMode _selectingMode = SelectingMode.destination;

  // Điểm xuất phát (Mặc định: Chợ Bến Thành, TP.HCM)
  LatLng _startPoint = const LatLng(10.776889, 106.700806);
  String _startName = 'Chợ Bến Thành, TP.HCM';

  // Điểm đến (Mặc định: Landmark 81, TP.HCM)
  LatLng _endPoint = const LatLng(10.7951, 106.7218);
  String _endName = 'Landmark 81, TP.HCM';

  TripRoute? _currentRoute;
  bool _isLoading = false;

  // Real-time tracking simulation (Question 3)
  bool _isTracking = false;
  Timer? _trackingTimer;
  int _trackingIndex = 0;
  LatLng? _movingPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateRoute();
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _calculateRoute() async {
    setState(() => _isLoading = true);
    final route = await _mapService.getRoute(_startPoint, _endPoint);
    if (!mounted) return;
    setState(() {
      _currentRoute = route;
      _isLoading = false;
      _movingPosition = _startPoint;
    });
  }

  void _swapPoints() {
    setState(() {
      final tempPos = _startPoint;
      final tempName = _startName;
      _startPoint = _endPoint;
      _startName = _endName;
      _endPoint = tempPos;
      _endName = tempName;
      _movingPosition = _startPoint;
    });
    _calculateRoute();
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < 18.0) {
      _mapController.move(_mapController.camera.center, currentZoom + 1.0);
    }
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > 3.0) {
      _mapController.move(_mapController.camera.center, currentZoom - 1.0);
    }
  }

  void _fitRoute() {
    if (_currentRoute != null && _currentRoute!.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(_currentRoute!.points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 150, bottom: 280, left: 40, right: 40),
        ),
      );
    } else {
      final bounds = LatLngBounds.fromPoints([_startPoint, _endPoint]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 150, bottom: 280, left: 40, right: 40),
        ),
      );
    }
  }

  void _centerToStart() {
    _mapController.move(_startPoint, 15.0);
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final result = await _mapService.searchLocation(query);

    setState(() => _isLoading = false);

    if (result != null) {
      final newPos = result.toLatLng;
      setState(() {
        if (_selectingMode == SelectingMode.start) {
          _startPoint = newPos;
          _startName = result.displayName;
          _movingPosition = newPos;
        } else {
          _endPoint = newPos;
          _endName = result.displayName;
        }
      });
      _mapController.move(newPos, 14.0);
      await _calculateRoute();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy địa điểm! Thử tìm: landmark 81, ha noi, da nang, khu cong nghe cao')),
        );
      }
    }
  }

  void _toggleTracking() {
    if (_isTracking) {
      _trackingTimer?.cancel();
      setState(() => _isTracking = false);
    } else {
      if (_currentRoute == null || _currentRoute!.points.isEmpty) return;
      setState(() {
        _isTracking = true;
        _trackingIndex = 0;
      });

      _trackingTimer?.cancel();
      _trackingTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
        if (_currentRoute == null || _trackingIndex >= _currentRoute!.points.length) {
          timer.cancel();
          if (mounted) {
            setState(() => _isTracking = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã tới điểm đến!'), backgroundColor: Colors.green),
            );
          }
          return;
        }

        final pos = _currentRoute!.points[_trackingIndex];
        if (mounted) {
          setState(() {
            _movingPosition = pos;
            _trackingIndex++;
          });
          _mapController.move(pos, _mapController.camera.zoom);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ & Tuyến đường (OSRM & GPS)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.stop_circle : Icons.navigation, color: _isTracking ? Colors.red : Colors.green),
            tooltip: _isTracking ? 'Dừng theo dõi GPS' : 'Bật theo dõi GPS mô phỏng (Q3)',
            onPressed: _toggleTracking,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _startPoint,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (tapPosition, point) {
                // Cho phép người dùng chạm lên bản đồ để chọn Điểm xuất phát hoặc Điểm đến
                setState(() {
                  if (_selectingMode == SelectingMode.start) {
                    _startPoint = point;
                    _startName = 'Tọa độ: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                    _movingPosition = point;
                  } else {
                    _endPoint = point;
                    _endName = 'Tọa độ: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                  }
                });
                _calculateRoute();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.topic_map',
              ),
              if (_currentRoute != null && _currentRoute!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _currentRoute!.points,
                      color: Colors.blueAccent,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Điểm bắt đầu (Point A)
                  Marker(
                    point: _startPoint,
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.trip_origin, color: Colors.green, size: 36),
                  ),
                  // Điểm kết thúc (Point B)
                  Marker(
                    point: _endPoint,
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                  // Phương tiện di chuyển theo thời gian thực (Question 3)
                  if (_movingPosition != null)
                    Marker(
                      point: _movingPosition!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 28),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Thanh tìm kiếm & Bộ chọn Điểm đi (A) / Điểm đến (B)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          _selectingMode == SelectingMode.start ? Icons.trip_origin : Icons.search,
                          color: _selectingMode == SelectingMode.start ? Colors.blue : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: _selectingMode == SelectingMode.start
                                  ? 'Tìm điểm xuất phát (A)...'
                                  : 'Tìm điểm đến (B)...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: _handleSearch,
                          ),
                        ),
                        _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () => _handleSearch(_searchController.text),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectingMode = SelectingMode.start),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _selectingMode == SelectingMode.start ? Colors.blue.shade600 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.trip_origin, size: 14, color: _selectingMode == SelectingMode.start ? Colors.white : Colors.blue.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Điểm đi (A)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _selectingMode == SelectingMode.start ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectingMode = SelectingMode.destination),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _selectingMode == SelectingMode.destination ? Colors.red.shade600 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: _selectingMode == SelectingMode.destination ? Colors.white : Colors.red.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Điểm đến (B)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _selectingMode == SelectingMode.destination ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.swap_vert, color: Colors.indigo, size: 20),
                        tooltip: 'Hoán đổi điểm đi (A) và điểm đến (B)',
                        onPressed: _swapPoints,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Phím điều khiển Zoom & Căn chỉnh màn hình
          Positioned(
            right: 16,
            bottom: 275,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nút căn vừa trọn vẹn lộ trình
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fit_screen, color: Colors.indigo, size: 20),
                    tooltip: 'Căn trọn lộ trình (Fit route)',
                    onPressed: _fitRoute,
                  ),
                ),
                const SizedBox(height: 8),
                // Nút định vị về điểm xuất phát
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.blue, size: 20),
                    tooltip: 'Về điểm xuất phát (A)',
                    onPressed: _centerToStart,
                  ),
                ),
                const SizedBox(height: 8),
                // Nút Phóng to (+) / Thu nhỏ (-)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black87, size: 20),
                        tooltip: 'Phóng to (+)',
                        onPressed: _zoomIn,
                      ),
                      const SizedBox(
                        width: 24,
                        child: Divider(height: 1, thickness: 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.black87, size: 20),
                        tooltip: 'Thu nhỏ (-)',
                        onPressed: _zoomOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bảng thông tin lộ trình & ETA (Question 2 & Question 3)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tuyến đường (OSRM Engine)',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isTracking) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('GPS Live', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.trip_origin, size: 14, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Điểm đi (A): $_startName',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Điểm đến (B): $_endName',
                            style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_currentRoute != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric(Icons.straighten, 'Quãng đường', _currentRoute!.distanceKm, Colors.indigo),
                          _buildMetric(Icons.access_time, 'Thời gian lái', _currentRoute!.durationMinutes, Colors.orange),
                          _buildMetric(Icons.flag, 'Giờ đến (ETA)', _currentRoute!.etaString, Colors.green),
                        ],
                      )
                    else if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                    else
                      const Text('Chạm lên map để đổi điểm và tính toán lại.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                            label: Text(_isTracking ? 'Dừng GPS' : 'Mô phỏng xe chạy (Q3)'),
                            onPressed: _toggleTracking,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Tính lại tuyến đường',
                          onPressed: _calculateRoute,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}