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

  factory StockState.fromJson(Map<String, dynamic> j) => StockState(
        isPublic: j['isPublic'] as bool? ?? false,
        ipoDay: (j['ipoDay'] as num?)?.toInt() ?? 0,
        sharePrice: (j['sharePrice'] as num?)?.toDouble() ?? 0,
        totalShares: (j['totalShares'] as num?)?.toInt() ?? 0,
        playerShares: (j['playerShares'] as num?)?.toInt() ?? 0,
        priceHistory: ((j['priceHistory'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
        lastQuarterProfit:
            (j['lastQuarterProfit'] as num?)?.toDouble() ?? 0,
        analystExpectation:
            (j['analystExpectation'] as num?)?.toDouble() ?? 0,
        lastQuarterDay: (j['lastQuarterDay'] as num?)?.toInt() ?? 0,
      );
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
  final double expectation;       // Analysten-Prognose
  final double priceMovePercent;  // Aktienkurs-Bewegung in %
  final String headline;          // Marketing-Schlagzeile

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
