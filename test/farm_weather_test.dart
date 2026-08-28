import 'package:balmi/data/repositories/weather_repository.dart';
import 'package:balmi/domain/engines/farm_weather.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FarmWeatherType', () {
    test('maps Open-Meteo weather codes correctly', () {
      expect(FarmWeatherType.fromCode(0), FarmWeatherType.sunny);
      expect(FarmWeatherType.fromCode(2), FarmWeatherType.partlyCloudy);
      expect(FarmWeatherType.fromCode(45), FarmWeatherType.fog);
      expect(FarmWeatherType.fromCode(61), FarmWeatherType.rain);
      expect(FarmWeatherType.fromCode(73), FarmWeatherType.snow);
      expect(FarmWeatherType.fromCode(95), FarmWeatherType.thunder);
    });

    test('provides correct icons and labels', () {
      expect(FarmWeatherType.sunny.label, '맑음');
      expect(FarmWeatherType.sunny.iconGlyph, '☀️');
      expect(FarmWeatherType.rain.iconGlyph, '🌧️');
      expect(FarmWeatherType.snow.iconGlyph, '❄️');
    });
  });

  group('FarmWeatherState', () {
    test('calculates day and night correctly based on sunrise and sunset', () {
      final sunrise = DateTime(2026, 8, 28, 5, 48);
      final sunset = DateTime(2026, 8, 28, 19, 2);
      final state = FarmWeatherState(
        temperature: 24,
        apparentTemperature: 26,
        weatherType: FarmWeatherType.sunny,
        precipitationProbability: 20,
        humidity: 64,
        windSpeedMs: 2.4,
        sunrise: sunrise,
        sunset: sunset,
        soilTemperature: 21,
        soilMoisture: 31,
        fetchedAt: DateTime.now(),
        latitude: 35.5384,
        longitude: 129.3114,
      );

      expect(state.isDayAt(DateTime(2026, 8, 28, 12, 0)), isTrue);
      expect(state.isDayAt(DateTime(2026, 8, 28, 4, 0)), isFalse);
      expect(state.isDayAt(DateTime(2026, 8, 28, 21, 0)), isFalse);
    });

    test('fallback weather state contains required defaults', () {
      final fb = FarmWeatherState.fallback(lat: 35.5384, lng: 129.3114);
      expect(fb.temperature, 24.0);
      expect(fb.apparentTemperature, 26.0);
      expect(fb.weatherType, FarmWeatherType.sunny);
      expect(fb.soilTemperature, 21.0);
      expect(fb.soilMoisture, 31);
    });
  });

  group('WeatherRepository', () {
    test('uses cached data if fetched within 15 minutes and location under threshold', () async {
      final repo = WeatherRepository();
      final initial = FarmWeatherState.fallback(lat: 35.5384, lng: 129.3114);
      repo.setCachedForTest(initial);

      final result = await repo.getFarmWeather(
        latitude: 35.5385, // tiny shift < 1km
        longitude: 129.3115,
      );

      expect(result.temperature, initial.temperature);
      expect(result.apparentTemperature, initial.apparentTemperature);
    });
  });
}
