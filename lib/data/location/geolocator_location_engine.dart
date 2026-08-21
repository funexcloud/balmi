import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import 'location_engine.dart';

/// Default engine. Do not add paid flutter_background_geolocation here.
class GeolocatorLocationEngine implements LocationEngine {
  StreamController<LocationFix>? _controller;
  StreamSubscription<Position>? _sub;

  @override
  Stream<LocationFix> get fixes =>
      _controller?.stream ?? const Stream.empty();

  LocationSettings _settings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
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

  @override
  Future<void> start() async {
    await stop();
    _controller = StreamController<LocationFix>.broadcast();
    _sub = Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (pos) {
        _controller?.add(
          LocationFix(
            ts: pos.timestamp,
            lat: pos.latitude,
            lng: pos.longitude,
            alt: pos.altitude,
            speedMs: pos.speed >= 0 ? pos.speed : null,
            hAccM: pos.accuracy,
            headingDeg: pos.heading,
          ),
        );
      },
      onError: (Object _, StackTrace _) {},
    );
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _controller?.close();
    _controller = null;
  }
}
