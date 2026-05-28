/// Marketing-Kampagnen-System.
///
/// Spieler bucht eine Kampagne für eine Filiale (oder zukünftig stadt-weit).
/// Während der Laufzeit wirken Effekte auf Kundenzahl und/oder Reputation.
/// Bei Ablauf wird die Kampagne automatisch entfernt.
///
/// Trade-offs:
/// * Günstig & lokal vs. teuer & weitreichend
/// * Kurz & stark vs. lang & sanft
/// * Reine Reichweite vs. Reputations-Aufbau
/// * Mit Risiko (viral) vs. ohne
class MarketingCampaign {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final double cost;
  final int durationDays; // 0 = einmalig / permanent
  final double customerBoost; // Multiplikator auf Kundenzahl (z.B. 0.20 = +20%)
  final double reputationBoostPerDay; // täglich +X auf Reputation
  final double reputationBoostOnce; // einmalig beim Buchen
  final double
      avgOrderValueMod; // z.B. -0.30 = 2-für-1-Aktion → 30% weniger pro Verkauf
  final double viralChance; // 0..1 — Chance pro Tag auf Bonus-Event
  final MarketingScope scope;
  final MarketingRisk risk;

  /// Direkte Markenbekanntheit-Erhöhung pro Tag (nur bei city/global-Kampagnen
  /// sinnvoll; shop-Kampagnen wirken über reputationBoostPerDay).
  final double brandAwarenessDelta;

  const MarketingCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.cost,
    required this.durationDays,
    required this.scope,
    this.customerBoost = 0,
    this.reputationBoostPerDay = 0,
    this.reputationBoostOnce = 0,
    this.avgOrderValueMod = 0,
    this.viralChance = 0,
    this.risk = MarketingRisk.low,
    this.brandAwarenessDelta = 0,
  });

  /// Wirkt die Kampagne über mehrere Tage (false = einmaliger Schub)?
  bool get hasDuration => durationDays > 0;

  /// Kosten pro Tag (informativ — Vollzahlung beim Buchen)
  double get costPerDay => durationDays > 0 ? cost / durationDays : cost;
}

enum MarketingScope {
  shop, // wirkt auf eine Filiale
  city, // wirkt auf alle Filialen einer Stadt (zukünftig)
  global, // wirkt auf alle Filialen (zukünftig)
}

enum MarketingRisk { low, medium, high }

/// Eine LAUFENDE Kampagne (Instanz im Shop).
class ActiveCampaign {
  final String campaignId;
  final int startDay;
  final int endDay; // exclusive — wenn currentDay >= endDay → abgelaufen

  const ActiveCampaign({
    required this.campaignId,
    required this.startDay,
    required this.endDay,
  });

  bool isActive(int currentDay) =>
      currentDay >= startDay && currentDay < endDay;

  int remainingDays(int currentDay) => (endDay - currentDay).clamp(0, 999);

  double progress(int currentDay) {
    final total = endDay - startDay;
    if (total <= 0) return 1.0;
    final elapsed = (currentDay - startDay).clamp(0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'startDay': startDay,
        'endDay': endDay,
      };

  factory ActiveCampaign.fromJson(Map<String, dynamic> j) => ActiveCampaign(
        campaignId: j['campaignId'] as String,
        startDay: j['startDay'] as int,
        endDay: j['endDay'] as int,
      );
}
