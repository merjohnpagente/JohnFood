import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _loc = LocationService();
  RouteResult? _route;

  static const _steps = ['pending', 'preparing', 'on_the_way', 'delivered'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track order')),
      body: StreamBuilder<Order?>(
        stream: OrderService().watchOrder(widget.orderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorState(
              message: 'Could not load this order.',
              onRetry: () => setState(() {}),
            );
          }
          final o = snap.data;
          if (o == null) {
            return const EmptyState(icon: Icons.receipt_long_outlined, message: 'Order not found.');
          }
          final rider = o.riderLat != null && o.riderLng != null
              ? LatLng(o.riderLat!, o.riderLng!)
              : null;
          final dest = o.customerLat != null && o.customerLng != null
              ? LatLng(o.customerLat!, o.customerLng!)
              : const LatLng(14.5995, 120.9842);
          if (rider != null && _route == null) {
            _loc.route(rider, dest).then((r) {
              if (mounted) setState(() => _route = r);
            });
          }
          final idx = o.status == 'cancelled'
              ? -1
              : _steps.indexOf(o.status).clamp(0, 3);
          return ContentWidth(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      StatusChip(o.status),
                      const SizedBox(width: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(_route?.etaText ?? 'Preparing route',
                            key: ValueKey(_route?.etaText ?? 'none')),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (var i = 0; i < _steps.length; i++) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: i <= idx ? const Color(0xFFFF5722) : const Color(0xFFEFE8E3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            i < idx
                                ? Icons.check_rounded
                                : [
                                    Icons.receipt_rounded,
                                    Icons.restaurant_rounded,
                                    Icons.delivery_dining_rounded,
                                    Icons.home_rounded
                                  ][i],
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        if (i < _steps.length - 1)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 3,
                              color: i < idx
                                  ? const Color(0xFFFF5722)
                                  : const Color(0xFFEFE8E3),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: rider ?? dest,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.merjdev.johnfoods',
                      ),
                      if (_route != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                                points: _route!.points,
                                strokeWidth: 4,
                                color: const Color(0xFFFF5722)),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: dest,
                            child: const Icon(Icons.location_pin,
                                color: Color(0xFFC62828), size: 36),
                          ),
                          if (rider != null)
                            Marker(
                              point: rider,
                              child: const Icon(Icons.delivery_dining_rounded,
                                  color: Color(0xFFFF5722), size: 36),
                            ),
                        ],
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                              'OpenStreetMap contributors', prependCopyright: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
