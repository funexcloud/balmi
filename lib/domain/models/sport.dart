enum Sport {
  walk,
  run;

  String get wire => name;

  static Sport fromWire(String value) {
    return value == run.wire ? run : walk;
  }
}

enum SessionStatus {
  recording,
  closed,
  recovered;

  String get wire => name;

  static SessionStatus fromWire(String value) {
    return switch (value) {
      'closed' => closed,
      'recovered' => recovered,
      _ => recording,
    };
  }
}
