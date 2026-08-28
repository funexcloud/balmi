import 'package:flutter/foundation.dart';

enum FarmWeatherType {
  sunny,
  partlyCloudy,
  cloudy,
  fog,
  rain,
  snow,
  thunder;

  String get label => switch (this) {
        sunny => '맑음',
        partlyCloudy => '대체로 맑음',
        cloudy => '흐림',
        fog => '안개',
        rain => '비',
        snow => '눈',
        thunder => '천둥번개',
      };

  String get iconGlyph => switch (this) {
        sunny => '☀️',
        partlyCloudy => '⛅',
        cloudy => '☁️',
        fog => '🌫️',
        rain => '🌧️',
        snow => '❄️',
        thunder => '⚡',
      };

  static FarmWeatherType fromCode(int code) {
    if (code == 0) return FarmWeatherType.sunny;
    if (code >= 1 && code <= 3) return FarmWeatherType.partlyCloudy;
    if (code >= 45 && code <= 48) return FarmWeatherType.fog;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return FarmWeatherType.rain;
    }
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return FarmWeatherType.snow;
    }
    if (code >= 95 && code <= 99) return FarmWeatherType.thunder;
    return FarmWeatherType.partlyCloudy;
  }
}

@immutable
class FarmWeatherState {
  const FarmWeatherState({
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherType,
    required this.precipitationProbability,
    required this.humidity,
    required this.windSpeedMs,
    required this.sunrise,
    required this.sunset,
    this.soilTemperature,
    this.soilMoisture,
    required this.fetchedAt,
    required this.latitude,
    required this.longitude,
  });

  final double temperature;
  final double apparentTemperature;
  final FarmWeatherType weatherType;
  final int precipitationProbability;
  final int humidity;
  final double windSpeedMs;
  final DateTime sunrise;
  final DateTime sunset;
  final double? soilTemperature;
  final int? soilMoisture;
  final DateTime fetchedAt;
  final double latitude;
  final double longitude;

  bool isDayAt(DateTime time) {
    return time.isAfter(sunrise) && time.isBefore(sunset);
  }

  bool get isDay => isDayAt(DateTime.now());

  static FarmWeatherState fallback({
    double lat = 37.5665,
    double lng = 126.9780,
  }) {
    final now = DateTime.now();
    return FarmWeatherState(
      temperature: 24.0,
      apparentTemperature: 26.0,
      weatherType: FarmWeatherType.sunny,
      precipitationProbability: 20,
      humidity: 64,
      windSpeedMs: 2.4,
      sunrise: DateTime(now.year, now.month, now.day, 5, 48),
      sunset: DateTime(now.year, now.month, now.day, 19, 2),
      soilTemperature: 21.0,
      soilMoisture: 31,
      fetchedAt: now,
      latitude: lat,
      longitude: lng,
    );
  }
}
