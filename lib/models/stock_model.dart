/// Aktien-System für den Börsengang.
///
/// Nach IPO (Initial Public Offering) wird das Unternehmen handelbar.
/// Der Aktienkurs schwankt basierend auf:
/// - Quartalsergebnis (Gewinn vs. Erwartung der Analysten)
/// - Markenbekanntheit
/// - Anzahl Filialen
/// - Reputation
///
/// Spieler bekommt beim IPO einen großen Cash-Schub im Tausch gegen
/// Anteile (max 49% Ausgabe, sonst Kontrollverlust).
class StockState {
  /// Ist das Unternehmen an der Börse?
  final bool isPublic;

  /// Tag an dem IPO erfolgte (0 wenn nicht public)
  final int ipoDay;

  /// Aktuelle Bewertung pro Aktie (€)
  final double sharePrice;

  /// Wie viele Aktien existieren insgesamt?
  final int totalShares;

  /// Wie viele Aktien gehören dem Spieler? (Rest = Streubesitz)
  final int playerShares;

  /// Historie der Aktienkurse für Chart (letzte 60 Tage)
  final List<double> priceHistory;

  /// Letztes Quartalsergebnis (Gewinn der letzten 90 Tage)
  final double lastQuarterProfit;

  /// Analysten-Erwartung für nächstes Quartal
  final double analystExpectation;

  /// Tag des letzten Quartalsberichts
  final int lastQuarterDay;

  const StockState({
    this.isPublic = false,
    this.ipoDay = 0,
    this.sharePrice = 0,
    this.totalShares = 0,
    this.playerShares = 0,
    this.priceHistory = const [],
    this.lastQuarterProfit = 0,
    this.analystExpectation = 0,
    this.lastQuarterDay = 0,
  });

  /// Marktkapitalisierung = sharePrice × totalShares
  double get marketCap => sharePrice * totalShares;

  /// Anteil des Spielers (0..1)
  double get playerShareRatio =>
      totalShares == 0 ? 1.0 : playerShares / totalShares;

  /// Hat der Spieler noch Kontrolle (>=51%)?
  bool get hasControl => playerShareRatio >= 0.51;

  /// Wert des Spieler-Pakets
  double get playerStockValue => sharePrice * playerShares;

  StockState copyWith({
    bool? isPublic,
    int? ipoDay,
    double? sharePrice,
    int? totalShares,
    int? playerShares,
    List<double>? priceHistory,
    double? lastQuarterProfit,
    double? analystExpectation,
    int? lastQuarterDay,
  }) {
    return StockState(
      isPublic: isPublic ?? this.isPublic,
      ipoDay: ipoDay ?? this.ipoDay,
      sharePrice: sharePrice ?? this.sharePrice,
      totalShares: totalShares ?? this.totalShares,
      playerShares: playerShares ?? this.playerShares,
      priceHistory: priceHistory ?? this.priceHistory,
      lastQuarterProfit: lastQuarterProfit ?? this.lastQuarterProfit,
      analystExpectation: analystExpectation ?? this.analystExpectation,
      lastQuarterDay: lastQuarterDay ?? this.lastQuarterDay,
    );
  }

  Map<String, dynamic> toJson() => {
        'isPublic': isPublic,
        'ipoDay': ipoDay,
        'sharePrice': sharePrice,
        'totalShares': totalShares,
        'playerShares': playerShares,
        'priceHistory': priceHistory,
        'lastQuarterProfit': lastQuarterProfit,
        'analystExpectation': analystExpectation,
        'lastQuarterDay': lastQuarterDay,
      };

  factory StockState.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v, [double fallback = 0.0]) {
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    int toInt(dynamic v, [int fallback = 0]) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool toBool(dynamic v, [bool fallback = false]) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      return fallback;
    }

    final rawHistory = j['priceHistory'];
    final history = rawHistory is List
        ? rawHistory.map((e) => toDouble(e)).toList()
        : <double>[];

    return StockState(
      isPublic: toBool(j['isPublic']),
      ipoDay: toInt(j['ipoDay']),
      sharePrice: toDouble(j['sharePrice']),
      totalShares: toInt(j['totalShares']),
      playerShares: toInt(j['playerShares']),
      priceHistory: history,
      lastQuarterProfit: toDouble(j['lastQuarterProfit']),
      analystExpectation: toDouble(j['analystExpectation']),
      lastQuarterDay: toInt(j['lastQuarterDay']),
    );
  }
}

/// Quartalsbericht — Zusammenfassung der letzten 90 Tage.
class QuarterlyReport {
  final int day;
  final double revenue;
  final double profit;
  final int customers;
  final int shopsAtStart;
  final int shopsAtEnd;
  final double brandAwarenessChange;
  final double expectation; // Analysten-Prognose
  final double priceMovePercent; // Aktienkurs-Bewegung in %
  final String headline; // Marketing-Schlagzeile

  const QuarterlyReport({
    required this.day,
    required this.revenue,
    required this.profit,
    required this.customers,
    required this.shopsAtStart,
    required this.shopsAtEnd,
    required this.brandAwarenessChange,
    required this.expectation,
    required this.priceMovePercent,
    required this.headline,
  });

  bool get beatsExpectation => profit > expectation;
}

/// IPO-Voraussetzungen
class IPORequirements {
  static const int minShops = 10;
  static const double minBrandAwareness = 35;
  static const double minTotalRevenue = 300000;
}
