import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../domain/engines/farm_weather.dart';

/// Compact farm weather card presenting current temp, feel, sun times, wind, rain & soil info.
class FarmWeatherCard extends StatelessWidget {
  const FarmWeatherCard({
    super.key,
    required this.weather,
    this.onRefresh,
    this.compact = false,
  });

  final FarmWeatherState weather;
  final VoidCallback? onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sunrFmt = DateFormat('HH:mm').format(weather.sunrise.toLocal());
    final sunsFmt = DateFormat('HH:mm').format(weather.sunset.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xF0FAF6F0), // Warm paper glass
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: BalmiColors.potato.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    weather.weatherType.iconGlyph,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${weather.weatherType.label} · ${weather.temperature.round()}°',
                    style: BalmiTheme.body(
                      size: 16,
                      weight: FontWeight.w800,
                      color: BalmiColors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '체감 ${weather.apparentTemperature.round()}°',
                    style: BalmiTheme.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: BalmiColors.potatoDk,
                    ),
                  ),
                ],
              ),
              if (onRefresh != null)
                GestureDetector(
                  onTap: onRefresh,
                  child: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: BalmiColors.sub,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '🌅 $sunrFmt · 🌇 $sunsFmt',
                style: BalmiTheme.body(size: 12, color: BalmiColors.ink),
              ),
              const SizedBox(width: 14),
              Text(
                '💧 강수 ${weather.precipitationProbability}% · 🌬️ ${weather.windSpeedMs}m/s',
                style: BalmiTheme.body(size: 12, color: BalmiColors.ink),
              ),
            ],
          ),
          if (weather.soilTemperature != null && weather.soilMoisture != null) ...[
            const SizedBox(height: 6),
            Text(
              '🌱 토양 ${weather.soilTemperature!.round()}° · 수분 ${weather.soilMoisture}%',
              style: BalmiTheme.body(
                size: 12,
                weight: FontWeight.w700,
                color: BalmiColors.sage,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
