import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/room_post.dart';

class RoomLocationMap extends StatefulWidget {
  final RoomPost post;
  final double height;
  final bool showControls;

  const RoomLocationMap({
    super.key,
    required this.post,
    this.height = 260,
    this.showControls = true,
  });

  @override
  State<RoomLocationMap> createState() => _RoomLocationMapState();
}

class _RoomLocationMapState extends State<RoomLocationMap> {
  late final MapController _mapController;
  late final LatLng _coordinates;

  static const Color _primary = Color(0xFF087E6B);
  static const Color _ink = Color(0xFF142523);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _coordinates = _resolveCoordinates(widget.post);
  }

  /// Phân giải tọa độ thực tế dựa theo địa chỉ và quận huyện của phòng trọ
  static LatLng _resolveCoordinates(RoomPost post) {
    final text = '${post.address} ${post.district}'.toLowerCase();

    if (text.contains('hutech') ||
        text.contains('nguyễn gia trí') ||
        text.contains('d2') ||
        text.contains('ung văn khiêm')) {
      return const LatLng(10.8038, 106.7158);
    } else if (text.contains('điện biên phủ') || text.contains('bình thạnh')) {
      return const LatLng(10.8005, 106.7118);
    } else if (text.contains('quận 1') || text.contains('bến nghé') || text.contains('đinh tiên hoàng')) {
      return const LatLng(10.7769, 106.7009);
    } else if (text.contains('quận 3') || text.contains('võ văn tần') || text.contains('nam kỳ')) {
      return const LatLng(10.7828, 106.6872);
    } else if (text.contains('quận 7') || text.contains('rmit') || text.contains('phú mỹ hưng')) {
      return const LatLng(10.7326, 106.7003);
    } else if (text.contains('thủ đức') || text.contains('đại học quốc gia')) {
      return const LatLng(10.8504, 106.7719);
    } else if (text.contains('tân bình') || text.contains('cộng hòa')) {
      return const LatLng(10.8014, 106.6534);
    } else if (text.contains('gò vấp') || text.contains('quang trung')) {
      return const LatLng(10.8388, 106.6657);
    } else if (text.contains('phú nhuận') || text.contains('phan xích long')) {
      return const LatLng(10.7992, 106.6838);
    }

    // Tọa độ mặc định tại TP. Hồ Chí Minh
    return const LatLng(10.8016, 106.7145);
  }

  Future<void> _openGoogleMaps() async {
    final address = widget.post.address.trim().isNotEmpty
        ? widget.post.address.trim()
        : 'TP. Hồ Chí Minh';
    
    // Deep link Google Maps tìm kiếm theo địa chỉ và tọa độ
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$address (${_coordinates.latitude},${_coordinates.longitude})')}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở ứng dụng bản đồ.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xảy ra lỗi khi mở Google Maps.')),
        );
      }
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_coordinates, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_coordinates, currentZoom - 1);
  }

  void _recenter() {
    _mapController.move(_coordinates, 15.5);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            // Bản đồ OpenStreetMap tương tác
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _coordinates,
                initialZoom: 15.5,
                minZoom: 6.0,
                maxZoom: 18.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.roommate.hub',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _coordinates,
                      width: 100,
                      height: 80,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Vị trí phòng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFE53935),
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Nút điều khiển Map (Zoom +, Zoom -, Về tâm, Mở Google Maps)
            if (widget.showControls)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    _controlButton(
                      icon: Icons.add,
                      tooltip: 'Phóng to',
                      onPressed: _zoomIn,
                    ),
                    const SizedBox(height: 6),
                    _controlButton(
                      icon: Icons.remove,
                      tooltip: 'Thu nhỏ',
                      onPressed: _zoomOut,
                    ),
                    const SizedBox(height: 6),
                    _controlButton(
                      icon: Icons.my_location,
                      tooltip: 'Căn giữa phòng',
                      onPressed: _recenter,
                    ),
                    const SizedBox(height: 6),
                    _controlButton(
                      icon: Icons.open_in_new,
                      tooltip: 'Mở Google Maps',
                      color: _primary,
                      iconColor: Colors.white,
                      onPressed: _openGoogleMaps,
                    ),
                  ],
                ),
              ),

            // Nhãn OpenStreetMap
            Positioned(
              bottom: 6,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(color: _ink, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = Colors.white,
    Color iconColor = _ink,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: iconColor),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
