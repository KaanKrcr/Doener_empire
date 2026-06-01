part of '../shop_detail_screen.dart';

// ── Sortiment-Tab ──────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  final Shop shop;
  const _ProductsTab({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CustomerMixCard(personality: shop.personality),
        const SizedBox(height: 12),
        for (final sp in shop.menu) ...[
          _ProductTile(shopId: shop.id, shopProduct: sp),
          const SizedBox(height: 8),
        ],
        // Gesperrte Produkte (brauchen Equipment)
        const SizedBox(height: 8),
        const PremiumSectionLabel(text: 'WEITERE PRODUKTE'),
        const SizedBox(height: 8),
        for (final pd in kAllProducts.where(
          (p) => !shop.menu.any((sp) => sp.productId == p.id),
        )) ...[
          PremiumDecisionSheet(
            child: Row(
              children: [
                Text(pd.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pd.name,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600)),
                      Text(
                        pd.requiredEquipmentId != null
                            ? 'Benötigt: ${kAllEquipment.firstWhere((e) => e.id == pd.requiredEquipmentId).name}'
                            : 'Nicht im Sortiment',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ProductTile extends ConsumerStatefulWidget {
  final String shopId;
  final ShopProduct shopProduct;
  const _ProductTile({required this.shopId, required this.shopProduct});

  @override
  ConsumerState<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<_ProductTile> {
  late double _price;
  late TextEditingController _textCtrl;
  final FocusNode _focus = FocusNode();

  // Sinnvolle Grenzen für die Texteingabe & den Slider
  double get _minPrice => 0.50;
  double get _maxPrice => 30.0;

  @override
  void initState() {
    super.initState();
    _price = widget.shopProduct.price;
    _textCtrl = TextEditingController(
      text: _price.toStringAsFixed(2).replaceAll('.', ','),
    );
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      // Beim Verlassen des Felds: Eingabe validieren + speichern
      _commitTextField();
    }
  }

  void _commitTextField() {
    final raw =
        _textCtrl.text.trim().replaceAll(',', '.').replaceAll('€', '').trim();
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      // Zurück auf gespeicherten Preis
      _resetTextField();
      return;
    }
    final clamped = parsed.clamp(_minPrice, _maxPrice);
    setState(() => _price = clamped);
    _resetTextField();
    ref.read(gameProvider.notifier).updateProductPrice(
        widget.shopId, widget.shopProduct.productId, clamped);
  }

  void _resetTextField() {
    _textCtrl.text = _price.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  void dispose() {
    _focus.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pd =
        kAllProducts.firstWhere((p) => p.id == widget.shopProduct.productId);
    final margin = _price - pd.ingredientCostPerUnit;
    final marginPct = pd.ingredientCostPerUnit > 0
        ? (margin / pd.ingredientCostPerUnit) * 100
        : 0.0;
    final demand =
        GameEngine.priceDemandFactor(price: _price, basePrice: pd.basePrice);
    final priceRatio = _price / pd.basePrice;

    // Demand-Stufen für Anzeige
    final (demandLabel, demandColor) = _demandStatus(demand, priceRatio);

    return PremiumDecisionSheet(
      borderColor: margin > 0 ? null : AppColors.danger.withAlpha(130),
      child: Column(
        children: [
          // ── Kopfzeile: Emoji + Name + Marge ─────────────────────────────
          Row(
            children: [
              Text(pd.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pd.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                      'Basispreis ${_fmt.format(pd.basePrice)} €  ·  '
                      'Zutaten ${_fmt.format(pd.ingredientCostPerUnit)} €',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Marge ${_fmt.format(margin)} € (${marginPct.toStringAsFixed(0)}%)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: margin > 0
                              ? AppColors.success
                              : AppColors.danger),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Preis-Eingabe (Text + Slider) ────────────────────────────────
          Row(
            children: [
              // Texteingabe mit Euro-Symbol
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _textCtrl,
                  focusNode: _focus,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    suffixText: '€',
                    suffixStyle: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _commitTextField(),
                  onTapOutside: (_) => _focus.unfocus(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _price.clamp(_minPrice, _maxPrice),
                  min: _minPrice,
                  max: _maxPrice,
                  divisions: 59, // 0,50€-Schritte
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  onChanged: (v) {
                    setState(() {
                      _price = v;
                      _resetTextField();
                    });
                  },
                  onChangeEnd: (v) {
                    ref
                        .read(gameProvider.notifier)
                        .updateProductPrice(widget.shopId, pd.id, v);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Nachfrage-Indikator ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: demandColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: demandColor.withAlpha(80)),
            ),
            child: Row(
              children: [
                Icon(
                  demand >= 1.0
                      ? Icons.trending_up
                      : (demand >= 0.5
                          ? Icons.trending_flat
                          : Icons.trending_down),
                  size: 16,
                  color: demandColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    demandLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: demandColor,
                    ),
                  ),
                ),
                Text(
                  '${(demand * 100).round()}% Nachfrage',
                  style: TextStyle(
                      fontSize: 11,
                      color: demandColor,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (margin <= 0) ...[
            const SizedBox(height: 10),
            const PremiumStatusHint(
              text: 'Verlustmarge — der Preis deckt die Zutatenkosten nicht.',
              tone: PremiumStatusTone.danger,
            ),
          ],
        ],
      ),
    );
  }

  /// Liefert (Beschreibung, Farbe) für einen gegebenen Demand-Wert.
  (String, Color) _demandStatus(double demand, double priceRatio) {
    if (priceRatio < 0.7) {
      return ('Sehr günstig — Marge leidet', AppColors.warning);
    } else if (priceRatio < 0.9) {
      return ('Günstig — viele Kunden', AppColors.success);
    } else if (priceRatio <= 1.1) {
      return ('Fair — guter Mix aus Kunden & Marge', AppColors.success);
    } else if (priceRatio <= 1.3) {
      return ('Etwas teuer — Kundenzahl sinkt', AppColors.warning);
    } else if (priceRatio <= 1.6) {
      return ('Teuer — viele Kunden gehen woanders hin', AppColors.warning);
    } else {
      return ('Wucher — kaum noch Kunden, Ruf leidet', AppColors.danger);
    }
  }
}

// ── Kundschafts-Mix ─────────────────────────────────────────────────────────

/// Zeigt, aus welchen Kundensegmenten sich die Laufkundschaft dieses Standorts
/// zusammensetzt, plus ein Hinweis auf die Preissensibilität.
class _CustomerMixCard extends StatelessWidget {
  final LocationPersonality personality;
  const _CustomerMixCard({required this.personality});

  @override
  Widget build(BuildContext context) {
    final mix = segmentMixFor(personality).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sensitivity = segmentPriceSensitivity(personality);
    final hint = sensitivity >= 1.08
        ? 'Preissensible Kundschaft — hohe Preise vertreiben sie schnell.'
        : sensitivity <= 0.92
            ? 'Preisunempfindlich — Premiumpreise gehen hier gut durch.'
            : 'Ausgewogene Kundschaft — fairer Preis funktioniert am besten.';

    return PremiumDecisionSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Stammkundschaft · ${personality.label}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in mix)
                _SegmentChip(segment: e.key, weight: e.value),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hint,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final CustomerSegment segment;
  final double weight;
  const _SegmentChip({required this.segment, required this.weight});

  @override
  Widget build(BuildContext context) {
    final d = segment.data;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '${d.emoji} ${d.label} ${(weight * 100).round()}%',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

