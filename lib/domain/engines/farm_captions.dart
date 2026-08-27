import '../../core/copy.dart';
import 'farm_life.dart';
import 'land_city.dart';

/// One-sentence farm captions for home / scene speech bubbles (tap to advance).
/// Dynamically incorporates day-of-week, time-of-day/climate, region, and farm state.
List<String> farmHomeCaptionLines({
  required List<FarmKind> buildings,
  required List<HerdKind> herds,
  required bool caredToday,
  DateTime? now,
  String? region,
  String? weather,
}) {
  final current = now ?? DateTime.now();
  final lines = <String>[];

  if (buildings.isEmpty && herds.isEmpty) {
    lines.add(BalmiCopy.landEmptyField);
    lines.add(BalmiCopy.landWalkHint);
  } else {
    if (buildings.contains(FarmKind.pastureFence) && herds.isEmpty) {
      lines.add(BalmiCopy.farmHomeReady);
    }
    if (herds.isNotEmpty) {
      lines.add(caredToday ? BalmiCopy.herdsFed : BalmiCopy.herdsHungry);
    } else if (!lines.contains(BalmiCopy.farmHomeReady)) {
      lines.add(caredToday ? BalmiCopy.wateredToday : BalmiCopy.herdsHungry);
    } else if (caredToday) {
      lines.add(BalmiCopy.wateredToday);
    } else {
      lines.add(BalmiCopy.landWalkHint);
    }
  }

  // Day-of-week contextual greeting
  lines.add(_dayOfWeekCaption(current));

  // Time-of-day & climate greeting
  lines.add(_timeOfDayCaption(current, weather: weather));

  // Regional context if available
  if (region != null && region.isNotEmpty) {
    lines.add('\'$region\' 주변을 걸으며 나만의 소중한 길을 기록해보세요.');
  }

  // Buildings & Herds summary
  for (final kind in FarmKind.tiers) {
    if (buildings.contains(kind)) {
      lines.add('${kind.label} · ${BalmiCopy.farmUnlocked}');
    }
  }
  for (final kind in HerdKind.tiers) {
    final n = herds.where((h) => h == kind).length;
    if (n > 0) {
      lines.add('${kind.label} $n');
    }
  }

  return lines;
}

String _dayOfWeekCaption(DateTime now) {
  switch (now.weekday) {
    case DateTime.monday:
      return '새로운 한 주가 시작되었어요! 상쾌한 월요일 산책으로 출발해요 ☀️';
    case DateTime.tuesday:
      return '화사한 화요일, 가벼운 발걸음으로 기분을 전환해 보세요 👟';
    case DateTime.wednesday:
      return '한 주의 중간 수요일! 산책으로 활력을 충전하세요 ✨';
    case DateTime.thursday:
      return '목요일의 활기찬 걸음이 목장을 더욱 푸르게 만들어요 🌾';
    case DateTime.friday:
      return '기분 좋은 금요일! 가벼운 산책으로 주말을 맞이해요 🎉';
    case DateTime.saturday:
      return '즐거운 토요일! 여유로운 발걸음으로 활력을 채워보세요 🎈';
    case DateTime.sunday:
    default:
      return '편안한 일요일, 마음을 돌보는 따뜻한 걸음을 남겨요 ☀️';
  }
}

String _timeOfDayCaption(DateTime now, {String? weather}) {
  if (weather != null && weather.isNotEmpty) {
    return '오늘 $weather 날씨에는 상쾌한 산책이 딱이에요!';
  }
  final hour = now.hour;
  if (hour >= 5 && hour < 12) {
    return '상쾌한 아침 공기를 마시며 기분 좋게 걸어보세요 ☀️';
  } else if (hour >= 12 && hour < 18) {
    return '따사로운 오후 햇살 속에서 여유롭게 걸어볼까요? 🌿';
  } else {
    return '잔잔한 밤공기 속 산책은 하루의 피로를 풀어줍니다 🌙';
  }
}
