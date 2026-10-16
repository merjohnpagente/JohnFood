import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/error_mapper.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';
import 'review_sheet.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _loc = LocationService();
  final _map = MapController();
  RouteResult? _route;
  LatLng? _routedFrom;
  LatLng? _lastRider;
  String? _lastStatus;
  bool _follow = false;
  bool _routePending = false;
  bool _routedForDelivery = false;

  static const _steps = ['pending', 'preparing', 'on_the_way', 'delivered'];
  static const _labels = ['Confirmed', 'Preparing', 'On the way', 'Delivered'];

  /// Human-readable remaining distance.
  static String _meters(double m) {
    if (m < 1000) return '${m.round()} m away';
    return '${(m / 1000).toStringAsFixed(1)} km away';
  }
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
      case 'assigned':
        return 'A rider is assigned!';
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canRate = o.status == 'delivered' && uid.isNotEmpty;
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
                    if (canRate)
                      IconButton(
                        icon: const Icon(Icons.star_outline_rounded,
                            color: AppColors.accent),
                        tooltip: 'Rate this item',
                        onPressed: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => ReviewSheet(
                              orderId: o.id,
                              userId: uid,
                              foodId: it.foodId,
                            ),
                          );
                        },
                      ),
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
              message: 'Could not load this order. '
                  '${friendlyError(snap.error!)}',
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
          // Local ping when the status changes while tracking.
          if (_lastStatus != null && _lastStatus != o.status) {
            try {
              NotificationService()
                  .showLocal('Order ${o.status}', _headline(o.status));
            } catch (_) {}
          }
          _lastStatus = o.status;
          // Route refresh, guarded so a moving rider cannot queue requests
          // against the public OSRM server. Runs after the frame instead of
          // during build.
          final needsRoute = rider != null &&
              !_routePending &&
              (_route == null ||
                  _routedFrom == null ||
                  o.status == 'on_the_way' && !_routedForDelivery ||
                  const Distance()(_routedFrom!, rider) > 1000);
          if (needsRoute) {
            _routePending = true;
            if (o.status == 'on_the_way') _routedForDelivery = true;
            final from = rider;
            final target = dest;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loc.route(from, target).then((r) {
                if (!mounted) return;
                setState(() {
                  _route = r;
                  _routedFrom = from;
                  _routePending = false;
                });
              }).catchError((_) {
                _routePending = false;
              });
            });
          }
          // Keep the rider marker centred while following.
          if (_follow && rider != null) {
            final moved = _lastRider == null ||
                const Distance()(_lastRider!, rider) > 15;
            if (moved) {
              _lastRider = rider;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _map.move(rider, 15.5);
              });
            }
          }
          final liveRider = rider != null &&
              (o.status == 'assigned' ||
                  o.status == 'preparing' ||
                  o.status == 'on_the_way');
          final remainingMeters =
              rider == null ? null : const Distance()(rider, dest);
          final idx = o.status == 'cancelled'
              ? -1
              : o.status == 'assigned'
                  ? 0
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
                        if (liveRider && remainingMeters != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.near_me_rounded,
                                  size: 14, color: AppColors.muted),
                              const SizedBox(width: 4),
                              Text(
                                _meters(remainingMeters),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                        if (liveRider && rider == null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Waiting for your rider to share location.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                        if (liveRider) ...[
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _follow = !_follow);
                              if (_follow && rider != null) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) _map.move(rider, 15.5);
                                });
                              }
                            },
                            icon: Icon(
                              _follow
                                  ? Icons.my_location_rounded
                                  : Icons.location_searching_rounded,
                              size: 16,
                              color: _follow
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                            label: Text(
                              _follow ? 'Following rider' : 'Follow rider',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _follow
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                        if ((o.paymentMethod == 'GCash' ||
                                o.paymentMethod == 'Maya') &&
                            !o.paymentVerified &&
                            (o.status == 'pending' ||
                                o.status == 'assigned'))
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Waiting for payment verification. Preparation starts after admin confirms.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.muted),
                            ),
                          ),
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
                      mapController: _map,
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
                                  color: AppColors.primary),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: dest,
                              child: const Icon(Icons.location_pin,
                                  color: AppColors.error, size: 36),
                            ),
                            if (rider != null)
                              Marker(
                                point: rider,
                                child: const Icon(
                                    Icons.delivery_dining_rounded,
                                    color: AppColors.primary,
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
