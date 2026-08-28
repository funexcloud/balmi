import 'dart:convert';
import 'dart:io';

import '../../domain/engines/farm_weather.dart';

class WeatherApiClient {
  const WeatherApiClient({this.client});

  final HttpClient? client;

  Future<FarmWeatherState?> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final hc = client ?? HttpClient();
    hc.connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current':
            'temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m,soil_temperature_0cm,soil_moisture_0_to_1cm',
        'daily': 'sunrise,sunset,precipitation_probability_max',
        'timezone': 'auto',
      });

      final req = await hc.getUrl(uri);
      final resp = await req.close();
      if (resp.statusCode != 200) return null;

      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final current = json['current'] as Map<String, dynamic>?;
      final daily = json['daily'] as Map<String, dynamic>?;

      if (current == null) return null;

      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 24.0;
      final appTemp =
          (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
      final code = (current['weather_code'] as num?)?.toInt() ?? 0;
      final humidity =
          (current['relative_humidity_2m'] as num?)?.toInt() ?? 50;
      final windKmh = (current['wind_speed_10m'] as num?)?.toDouble() ?? 8.0;
      final windMs = windKmh / 3.6; // convert km/h to m/s

      final soilTemp = (current['soil_temperature_0cm'] as num?)?.toDouble();
      final soilMoistRaw =
          (current['soil_moisture_0_to_1cm'] as num?)?.toDouble();
      final soilMoisture =
          soilMoistRaw != null ? (soilMoistRaw * 100).round() : null;

      var precipProb = 0;
      var sunrise = DateTime.now();
      var sunset = DateTime.now();

      if (daily != null) {
        final probs = daily['precipitation_probability_max'] as List?;
        if (probs != null && probs.isNotEmpty) {
          precipProb = (probs.first as num?)?.toInt() ?? 0;
        }

        final sunrises = daily['sunrise'] as List?;
        if (sunrises != null && sunrises.isNotEmpty) {
          sunrise = DateTime.tryParse(sunrises.first.toString()) ?? sunrise;
        }

        final sunsets = daily['sunset'] as List?;
        if (sunsets != null && sunsets.isNotEmpty) {
          sunset = DateTime.tryParse(sunsets.first.toString()) ?? sunset;
        }
      }

      return FarmWeatherState(
        temperature: temp,
        apparentTemperature: appTemp,
        weatherType: FarmWeatherType.fromCode(code),
        precipitationProbability: precipProb,
        humidity: humidity,
        windSpeedMs: double.parse(windMs.toStringAsFixed(1)),
        sunrise: sunrise,
        sunset: sunset,
        soilTemperature: soilTemp != null
            ? double.parse(soilTemp.toStringAsFixed(1))
            : null,
        soilMoisture: soilMoisture,
        fetchedAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return null;
    } finally {
      if (client == null) hc.close();
    }
  }
}
