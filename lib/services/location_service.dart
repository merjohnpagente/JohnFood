import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final String etaText;
  const RouteResult(this.points, this.etaText);
}

class LocationService {
  final Map<String, RouteResult> _routeCache = {};
  DateTime _lastSearch = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Position> current() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return Geolocator.getCurrentPosition();
  }

  /// Nominatim, only on user action, max 1 req/sec.
  Future<List<Map<String, dynamic>>> searchAddress(String q) async {
    final now = DateTime.now();
    if (now.difference(_lastSearch).inMilliseconds < 1000) {
      await Future.delayed(const Duration(milliseconds: 400));
    }
    _lastSearch = DateTime.now();
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'limit': '5',
      'countrycodes': 'ph',
    });
    final res = await http.get(uri, headers: {'User-Agent': 'JohnFoods/1.0'});
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  /// OSRM public server with straight-line + ETA fallback. Cached.
  Future<RouteResult> route(LatLng from, LatLng to) async {
    final key = '${from.latitude},${from.longitude}-${to.latitude},${to.longitude}';
    if (_routeCache.containsKey(key)) return _routeCache[key]!;
    final fallback = RouteResult(
      [from, to],
      _eta(const Distance()(from, to)),
    );
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'JohnFoods/1.0'});
      if (res.statusCode != 200) return fallback;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = (body['routes'] as List?) ?? [];
      if (routes.isEmpty) return fallback;
      final coords = ((routes.first as Map)['geometry'] as Map)['coordinates'] as List;
      final pts = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
      final secs = ((routes.first as Map)['duration'] as num?)?.toDouble() ?? 0;
      final r = RouteResult(pts, '${(secs / 60).ceil()} min');
      _routeCache[key] = r;
      return r;
    } catch (_) {
      return fallback;
    }
  }

  String _eta(double meters) => '${(meters / 500).ceil()} min';
}
