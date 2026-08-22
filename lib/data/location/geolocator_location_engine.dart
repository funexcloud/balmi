import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import 'location_engine.dart';

/// Default engine. Do not add paid flutter_background_geolocation here.
///
/// GPS is started from the **UI isolate**. geolocator's Android EventChannel
/// silently no-ops if its helper service is not bound yet (common in a
/// flutter_foreground_task isolate), which left testers on 0 points forever.
class GeolocatorLocationEngine implements LocationEngine {
  StreamController<LocationFix>? _controller;
  StreamSubscription<Position>? _sub;
  Timer? _retry;
  int _gen = 0;
  bool _forceLocationManager = false;
  Position? _lastPos;

  @override
  String? lastError;

  @override
  bool hasFix = false;

  @override
  Stream<LocationFix> get fixes =>
      _controller?.stream ?? const Stream.empty();

  LocationSettings _streamSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: _forceLocationManager,
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
  }

  LocationSettings _fixSettings({required Duration timeLimit}) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: _forceLocationManager,
        timeLimit: timeLimit,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: timeLimit,
    );
  }

  @override
  Future<void> start() async {
    await stop();
    final gen = ++_gen;
    hasFix = false;
    lastError = null;
    _forceLocationManager = false;
    _controller = StreamController<LocationFix>.broadcast();
    await _subscribe(gen);
    unawaited(_kickstart(gen));
    _retry?.cancel();
    _retry = Timer.periodic(const Duration(seconds: 8), (_) {
      if (gen != _gen || hasFix) return;
      unawaited(_kickstart(gen));
    });
  }

  @override
  Future<void> nudge() => _kickstart(_gen);

  Future<void> _subscribe(int gen) async {
    await _sub?.cancel();
    _sub = null;
    if (gen != _gen) return;
    try {
      _sub = Geolocator.getPositionStream(locationSettings: _streamSettings())
          .listen(
        (pos) {
          if (gen != _gen) return;
          _emit(pos);
        },
        onError: (Object error, StackTrace _) {
          if (gen != _gen) return;
          lastError = error.toString();
          if (!_forceLocationManager && Platform.isAndroid) {
            _forceLocationManager = true;
            unawaited(_subscribe(gen));
            unawaited(_kickstart(gen));
          }
        },
      );
    } catch (error) {
      lastError = error.toString();
      if (!_forceLocationManager && Platform.isAndroid) {
        _forceLocationManager = true;
        await _subscribe(gen);
      }
    }
  }

  Future<void> _kickstart(int gen) async {
    if (gen != _gen) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _fixSettings(
          timeLimit: const Duration(seconds: 20),
        ),
      );
      if (gen != _gen) return;
      _emit(pos);
      return;
    } catch (error) {
      if (gen != _gen) return;
      lastError = error.toString();
    }
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (gen != _gen) return;
      if (last != null) {
        _emit(last);
      }
    } catch (error) {
      if (gen != _gen) return;
      lastError ??= error.toString();
    }
  }

  void _emit(Position pos) {
    if (_lastPos != null &&
        _lastPos!.latitude == pos.latitude &&
        _lastPos!.longitude == pos.longitude &&
        _lastPos!.timestamp == pos.timestamp &&
        _lastPos!.accuracy == pos.accuracy) {
      return;
    }
    _lastPos = pos;
    hasFix = true;
    lastError = null;
    _controller?.add(
      LocationFix(
        ts: pos.timestamp,
        lat: pos.latitude,
        lng: pos.longitude,
        alt: pos.altitude,
        speedMs: pos.speed >= 0 ? pos.speed : null,
        speedAccuracyMs: pos.speedAccuracy >= 0 ? pos.speedAccuracy : null,
        hAccM: pos.accuracy,
        headingDeg: pos.heading,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _gen++;
    _retry?.cancel();
    _retry = null;
    await _sub?.cancel();
    _sub = null;
    _lastPos = null;
    hasFix = false;
    await _controller?.close();
    _controller = null;
  }
}
