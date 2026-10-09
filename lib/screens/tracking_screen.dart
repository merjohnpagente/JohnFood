import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/formatters.dart';
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
  static const _labels = ['Confirmed', 'Preparing', 'On the way', 'Delivered'];
  static const _icons = [
    Icons.receipt_rounded,
    Icons.restaurant_rounded,
    Icons.delivery_dining_rounded,
    Icons.home_rounded,
  ];

  String _headline(String status) {
    switch (status) {
      case 'pending':
        return 'Your order is confirmed!';
      case 'preparing':
        return 'Your food is being prepared!';
      case 'on_the_way':
        return 'Your order is on the way!';
      case 'delivered':
        return 'Enjoy your meal!';
      case 'cancelled':
        return 'Order cancelled';
      default:
        return 'Tracking your order';
    }
  }

  void _details(Order o) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Details',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final it in o.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${it.qty}x  ${it.name}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Text(formatPeso(it.price * it.qty),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(formatPeso(o.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
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
            return const EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'Order not found.');
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Entrance(
                    child: Column(
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: const BoxDecoration(
                            color: AppColors.tint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            o.status == 'delivered'
                                ? Icons.check_circle_rounded
                                : Icons.delivery_dining_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(_headline(o.status),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        const Text('Estimated arrival time',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            o.status == 'delivered'
                                ? 'Delivered'
                                : (_route?.etaText ?? 'Preparing route'),
                            key: ValueKey(
                                _route?.etaText ?? o.status),
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusChip(o.status),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _steps.length; i++) ...[
                        Expanded(
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 300),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: i <= idx
                                      ? AppColors.primary
                                      : AppColors.border,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  i < idx
                                      ? Icons.check_rounded
                                      : _icons[i],
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _labels[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: i <= idx
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < _steps.length - 1)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 16),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 300),
                                height: 3,
                                decoration: BoxDecoration(
                                  color: i < idx
                                      ? AppColors.primary
                                      : AppColors.border,
                                  borderRadius:
                                      BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _details(o),
                      child: const Text('View Order Details'),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: rider ?? dest,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.merjdev.johnfoods',
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
                                child: const Icon(
                                    Icons.delivery_dining_rounded,
                                    color: Color(0xFFFF5722),
                                    size: 36),
                              ),
                          ],
                        ),
                        const RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                                'OpenStreetMap contributors',
                                prependCopyright: true),
                          ],
                        ),
                      ],
                    ),
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
