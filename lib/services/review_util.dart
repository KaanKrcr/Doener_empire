import 'dart:math';
import '../models/game_state.dart';
import '../models/shop_model.dart';
import '../models/quality_model.dart';
import '../models/employee_model.dart';
import '../core/constants.dart';

/// Eine prozedural erzeugte Kundenbewertung.
class CustomerReview {
  final int stars; // 1..5
  final String author;
  final String text;
  final String shopName;
  const CustomerReview({
    required this.stars,
    required this.author,
    required this.text,
    required this.shopName,
  });
}

/// Erzeugt deterministische (pro Tag stabile) Bewertungen, abgeleitet aus
/// Reputation, Preisniveau und Zutaten-Qualität der Filialen.
List<CustomerReview> generateReviews(GameState state, {int count = 4}) {
  if (state.shops.isEmpty) return const [];
  final rng = Random(state.currentDay * 7919 + state.shops.length);
  final names = [...kMaleNames, ...kFemaleNames];

  final out = <CustomerReview>[];
  for (var i = 0; i < count; i++) {
    final shop = state.shops[rng.nextInt(state.shops.length)];
    final ratio = _avgPriceRatio(shop);
    final premium = _avgPremium(shop, state); // -1..1

    double stars = shop.reputation;
    if (ratio > 1.2) {
      stars -= 1.0;
    } else if (ratio < 0.95) {
      stars += 0.3;
    }
    stars += premium * 0.4;
    stars += rng.nextDouble() * 1.5 - 0.75;
    final s = stars.clamp(1.0, 5.0).round();

    out.add(CustomerReview(
      stars: s,
      author: names[rng.nextInt(names.length)],
      text: _pickText(s, ratio: ratio, premium: premium, rng: rng),
      shopName: shop.displayName,
    ));
  }
  return out;
}

double _avgPriceRatio(Shop shop) {
  final active = shop.menu.where((p) => p.isActive).toList();
  if (active.isEmpty) return 1.0;
  double sum = 0;
  int n = 0;
  for (final sp in active) {
    final pd = kAllProducts.where((p) => p.id == sp.productId);
    if (pd.isEmpty || pd.first.basePrice <= 0) continue;
    sum += sp.price / pd.first.basePrice;
    n++;
  }
  return n == 0 ? 1.0 : sum / n;
}

/// −1 (überwiegend günstig) .. +1 (überwiegend premium)
double _avgPremium(Shop shop, GameState state) {
  final active = shop.menu.where((p) => p.isActive).toList();
  if (active.isEmpty) return 0;
  double sum = 0;
  for (final sp in active) {
    final q = ingredientQualityFromName(state.productQuality[sp.productId]);
    sum += switch (q) {
      IngredientQuality.budget => -1.0,
      IngredientQuality.standard => 0.0,
      IngredientQuality.premium => 1.0,
    };
  }
  return sum / active.length;
}

const _positive = [
  'Bester Döner der Stadt! Komme immer wieder.',
  'Mega lecker und das Fleisch frisch — top!',
  'Freundlicher Service, schnelle Bedienung. 👌',
  'Hier stimmt einfach alles. Klare Empfehlung!',
];
const _neutral = [
  'Solider Döner, nichts Besonderes, aber okay.',
  'Ganz gut, beim nächsten Mal vielleicht mehr Soße.',
  'Durchschnitt — sättigt, aber haut nicht um.',
];
const _negative = [
  'Lange Wartezeit und lauwarm. Schade.',
  'War schon mal besser hier. Eher mau.',
  'Nicht mein Favorit, da gibt es Bessere.',
];
const _tooExpensive = [
  'Für den Preis erwarte ich ehrlich mehr.',
  'Lecker, aber ganz schön teuer geworden.',
];
const _cheapGood = [
  'Top Preis-Leistung — günstig und gut!',
  'Für das Geld wirklich in Ordnung.',
];
const _premiumPraise = [
  'Man schmeckt die guten Zutaten. Premium!',
  'Qualität merkt man — frische Zutaten.',
];

String _pickText(int stars,
    {required double ratio, required double premium, required Random rng}) {
  if (ratio > 1.2 && stars <= 3 && rng.nextBool()) {
    return _tooExpensive[rng.nextInt(_tooExpensive.length)];
  }
  if (ratio < 0.95 && stars >= 3 && rng.nextBool()) {
    return _cheapGood[rng.nextInt(_cheapGood.length)];
  }
  if (premium > 0.4 && stars >= 4 && rng.nextBool()) {
    return _premiumPraise[rng.nextInt(_premiumPraise.length)];
  }
  if (stars >= 4) return _positive[rng.nextInt(_positive.length)];
  if (stars == 3) return _neutral[rng.nextInt(_neutral.length)];
  return _negative[rng.nextInt(_negative.length)];
}
