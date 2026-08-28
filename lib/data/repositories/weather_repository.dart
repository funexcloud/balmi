import 'package:flutter/foundation.dart';

import '../../domain/engines/farm_weather.dart';
import '../api/weather_api_client.dart';

class WeatherRepository {
  WeatherRepository({WeatherApiClient? client})
      : _client = client ?? const WeatherApiClient();

  final WeatherApiClient _client;
  FarmWeatherState? _cachedState;

  FarmWeatherState? get cachedWeather => _cachedState;

  Future<FarmWeatherState> getFarmWeather({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    final cached = _cachedState;
    if (!forceRefresh && cached != null) {
      final now = DateTime.now();
      final age = now.difference(cached.fetchedAt);
      final distThreshold = 0.01; // ~1km
      final latDiff = (cached.latitude - latitude).abs();
      final lngDiff = (cached.longitude - longitude).abs();

      if (age.inMinutes < 15 && latDiff < distThreshold && lngDiff < distThreshold) {
        return cached;
      }
    }

    final fetched = await _client.fetchWeather(
      latitude: latitude,
      longitude: longitude,
    );

    if (fetched != null) {
      _cachedState = fetched;
      return fetched;
    }

    return _cachedState ?? FarmWeatherState.fallback(lat: latitude, lng: longitude);
  }

  @visibleForTesting
  void setCachedForTest(FarmWeatherState state) {
    _cachedState = state;
  }
}
