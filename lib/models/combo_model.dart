/// Menü-Angebote / Kombos (z.B. Mittagsmenü).
///
/// Ein Kombo bündelt mehrere Produkte zu einem Angebot. Konzernweit aktivierbar,
/// wirkt aber nur in Filialen, die ALLE benötigten Produkte führen
/// (koppelt an die Equipment-/Produkt-Progression). Aktive Kombos kosten eine
/// kleine Tagespauschale (Werbung/Aushang), bringen aber mehr Kundschaft und
/// größere Bestellungen.
class MenuCombo {
  final String id;
  final String name;
  final String emoji;
  final String description;

  /// Produkt-IDs, die eine Filiale (aktiv im Menü) führen muss, damit das
  /// Angebot dort greift.
  final List<String> productIds;

  /// Additiver Kunden-Multiplikator (Deal lockt Laufkundschaft).
  final double customerBoost;

  /// Additiver Bestellwert-Multiplikator (größere Bestellungen / Bundle).
  final double avgOrderBoost;

  /// Täglicher Reputations-Beitrag (Leute mögen Angebote).
  final double reputationPerDay;

  /// Konzernweite Tagespauschale, solange das Angebot aktiv ist.
  final double dailyCost;

  const MenuCombo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.productIds,
    required this.customerBoost,
    required this.avgOrderBoost,
    required this.reputationPerDay,
    required this.dailyCost,
  });
}

const List<MenuCombo> kAllCombos = [
  MenuCombo(
    id: 'mittagsmenu',
    name: 'Mittagsmenü',
    emoji: '🍱',
    description: 'Döner + Pommes + Cola zum Vorteilspreis. Zieht die '
        'Mittagspausen-Kundschaft an.',
    productIds: ['doener_fladen', 'pommes', 'cola'],
    customerBoost: 0.06,
    avgOrderBoost: 0.10,
    reputationPerDay: 0.004,
    dailyCost: 45,
  ),
  MenuCombo(
    id: 'studenten_deal',
    name: 'Studenten-Deal',
    emoji: '🎓',
    description: 'Günstiges Dürüm + Ayran. Studenten lieben den Preis.',
    productIds: ['doener_duerum', 'ayran'],
    customerBoost: 0.08,
    avgOrderBoost: 0.05,
    reputationPerDay: 0.003,
    dailyCost: 35,
  ),
  MenuCombo(
    id: 'familienbox',
    name: 'Familienbox',
    emoji: '👨‍👩‍👧',
    description: 'Große Döner-Box + Pommes + Cola für die ganze Familie.',
    productIds: ['doenerbox', 'pommes', 'cola'],
    customerBoost: 0.05,
    avgOrderBoost: 0.14,
    reputationPerDay: 0.005,
    dailyCost: 60,
  ),
  MenuCombo(
    id: 'veggie_kombo',
    name: 'Veggie-Kombo',
    emoji: '🥗',
    description: 'Vegetarischer Döner + Ayran. Gesund und im Trend.',
    productIds: ['veg_doener', 'ayran'],
    customerBoost: 0.05,
    avgOrderBoost: 0.06,
    reputationPerDay: 0.006,
    dailyCost: 35,
  ),
  MenuCombo(
    id: 'snack_attacke',
    name: 'Snack-Attacke',
    emoji: '🍟',
    description: 'Pommes + Ayran für den kleinen Hunger zwischendurch.',
    productIds: ['pommes', 'ayran'],
    customerBoost: 0.06,
    avgOrderBoost: 0.04,
    reputationPerDay: 0.003,
    dailyCost: 30,
  ),
  MenuCombo(
    id: 'doppel_doener',
    name: 'Doppel-Döner-Deal',
    emoji: '🥙',
    description: 'Döner im Fladen + Dürüm — zwei für hungrige Gäste.',
    productIds: ['doener_fladen', 'doener_duerum'],
    customerBoost: 0.07,
    avgOrderBoost: 0.12,
    reputationPerDay: 0.004,
    dailyCost: 50,
  ),
];

MenuCombo? comboById(String id) {
  for (final c in kAllCombos) {
    if (c.id == id) return c;
  }
  return null;
}
