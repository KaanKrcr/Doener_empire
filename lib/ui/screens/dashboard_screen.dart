import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/sound_service.dart';
import '../../models/game_state.dart';
import '../../models/campaign_model.dart';
import '../../models/branding_model.dart';
import '../../providers/game_provider.dart';
import '../../services/game_engine.dart';
import 'campaign_screen.dart';
import '../widgets/animated_money.dart';
import '../widgets/mission_banner.dart';
import '../widgets/day_end_dialog.dart';
import '../widgets/money_pulse.dart';
import '../widgets/pressable.dart';
import '../widgets/bankruptcy_dialog.dart';
import '../widgets/quarterly_report_dialog.dart';
import '../widgets/weekly_report_dialog.dart';

final _fmtInt = NumberFormat('#,##0', 'de_DE');
const _kWeekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _kFeedbackFormUrl =
    'https://docs.google.com/forms/d/e/1FAIpQLSd266LTUL-vKR4jLKv7fxXXy-BvsSxChM87O-n7Z4sceWhjvQ/viewform';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _endingDay = false;

  Future<void> _endDay() async {
    if (_endingDay) return;
    HapticFeedback.mediumImpact();
    SoundService.play(Sfx.dayend);
    setState(() => _endingDay = true);
    final notifier = ref.read(gameProvider.notifier);
    notifier.endDay();
    final result = notifier.lastDayResult;
    if (result != null && mounted) {
      await DayEndDialog.show(context, result);
      if (result.missionCompleted != null && mounted) {
        await MissionCompletedDialog.show(context, result.missionCompleted!);
      }
      if (result.quarterlyReport != null && mounted) {
        await QuarterlyReportDialog.show(context, result.quarterlyReport!);
      }
      if (result.chapterCompleted != null && mounted) {
        await CampaignChapterDialog.show(context, result.chapterCompleted!);
      }
      if (result.weeklyReport != null && mounted) {
        await WeeklyReportDialog.show(context, result.weeklyReport!);
      }
      if (result.taxPaid > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '💸 Steuern (30 Tage): −${_fmtInt.format(result.taxPaid)} €'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      if (result.challengeMet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🎯 Tagesaufgabe geschafft! +${_fmtInt.format(result.challengeReward)} €'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      notifier.clearLastDayResult();
    }
    if (mounted) setState(() => _endingDay = false);
  }

  Future<void> _openFeedbackForm() async {
    final uri = Uri.parse(_kFeedbackFormUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback-Link konnte nicht geöffnet werden.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Sofort-Mission-Listener ─────────────────────────────────────────
    // Wenn eine Mission *mittendrin* erfüllt wird (z.B. nach Filial-Eröffnung),
    // zeigen wir den großen Glückwunsch-Dialog sofort.
    ref.listen(instantMissionProvider, (prev, next) {
      if (next != null && mounted) {
        MissionCompletedDialog.show(context, next).then((_) {
          // Stream zurücksetzen für nächste Mission
          ref.read(instantMissionProvider.notifier).state = null;
        });
      }
    });

    // ── Story-Kampagne: Kapitel live abgeschlossen ──────────────────────
    ref.listen(instantChapterProvider, (prev, next) {
      if (next != null && mounted) {
        CampaignChapterDialog.show(context, next).then((_) {
          ref.read(instantChapterProvider.notifier).state = null;
        });
      }
    });

    // ── Insolvenz-Listener ─────────────────────────────────────────────
    // Cash unter 0 → Pleite-Dialog mit Kredit-/Schließungs-/Game-Over-Optionen.
    // Triggert beim ÜBERGANG von >=0 zu <0 (nicht jeden Tick wenn schon negativ).
    ref.listen(gameProvider, (prev, next) {
      if (next == null) return;
      final wasOk = prev == null || prev.cash >= 0;
      final isNowBad = next.cash < 0;
      if (wasOk && isNowBad && mounted) {
        BankruptcyDialog.show(context);
      }
    });

    final game = ref.watch(gameProvider);
    if (game == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Live-Werte für heute (laufender Tag, noch nicht in history)
    final dailyRevenue = ref.watch(dailyRevenueProvider);
    final dailyCosts = ref.watch(dailyCostsProvider);
    final dailyProfit = ref.watch(dailyProfitProvider);
    final customersToday = GameEngine.totalCustomersToday(game);
    final activeChapter = ref.watch(activeChapterProvider);
    final chapterProgress = ref.watch(activeChapterProgressProvider);
    final specialId = GameEngine.dailySpecialProductId(game.currentDay);
    final specialProduct = kAllProducts.firstWhere(
      (p) => p.id == specialId,
      orElse: () => kAllProducts.first,
    );
    final brandTheme = brandThemeById(game.activeThemeId);
    final alerts = GameEngine.shopAlerts(game);
    final challenge = GameEngine.dailyChallenge(game.currentDay);

    // Daten aus History für Trend-Vergleiche
    final history = game.history;
    final yesterday = history.isNotEmpty ? history.last : null;
    final last7 =
        history.length >= 7 ? history.sublist(history.length - 7) : history;

    final yRevenue = yesterday?.revenue ?? 0;
    final yCustomers = yesterday?.customers ?? 0;
    final w7Customers = last7.fold(0, (s, r) => s + r.customers);

    // Beliebtheit = mittlere Reputation über Filialen
    final avgReputation = game.shops.isEmpty
        ? 0.0
        : game.shops.fold(0.0, (s, sh) => s + sh.reputation) /
            game.shops.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeaderBar(game: game),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _FeedbackButton(
                  onPressed: _openFeedbackForm,
                ),
              ),
            ),

            // ── Kontostand Karte (mit Pulse-Glow) ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: MoneyPulse(
                  cash: game.cash,
                  child: _CashCard(
                    cash: game.cash,
                    dailyRevenue: dailyRevenue,
                    dailyCosts: dailyCosts,
                    dailyProfit: dailyProfit,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 420.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic)
                    .shimmer(
                      delay: 600.ms,
                      duration: 1600.ms,
                      color: Colors.white.withAlpha(40),
                    ),
              ),
            ),

            // ── Hinweise / Warnungen ────────────────────────────────────
            if (alerts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _AlertsCard(
                    alerts: alerts,
                    onTapShop: (id) => context.push('/shop/$id'),
                  ),
                ),
              ),

            // ── Mission-Banner ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: MissionBanner(),
              ),
            ),

            // ── Story-Kampagne-Banner ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _CampaignBanner(
                  chapter: activeChapter,
                  progress: chapterProgress,
                  onTap: () => context.push('/campaign'),
                ),
              ),
            ),

            // ── Heute: Tagesspecial + Tagesaufgabe ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _TodayCard(
                  specialEmoji: specialProduct.emoji,
                  specialName: specialProduct.name,
                  challengeEmoji: challenge.emoji,
                  challengeLabel: challenge.label,
                  challengeReward: challenge.reward,
                ),
              ),
            ),

            // ── Tag-Ende-Button ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _DayEndButton(
                  loading: _endingDay,
                  hasShops: game.shops.isNotEmpty,
                  onPressed: _endDay,
                ),
              ),
            ),

            // ── Heutige Kennzahlen (Kunden + Umsatz + Beliebtheit) ────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                delegate: SliverChildListDelegate([
                  _MetricCard(
                    emoji: '👥',
                    label: 'Kunden heute',
                    value: _fmtInt.format(customersToday),
                    sub: _trendLabel(customersToday.toDouble(),
                        yCustomers.toDouble(), 'gestern'),
                    trend: _trendIcon(
                        customersToday.toDouble(), yCustomers.toDouble()),
                    accent: AppColors.accent,
                  ).animate().fadeIn(delay: 60.ms, duration: 360.ms).slideY(
                      begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                  _MetricCard(
                    emoji: '💰',
                    label: 'Umsatz heute',
                    value: '${_fmtInt.format(dailyRevenue)} €',
                    sub: _trendLabel(dailyRevenue, yRevenue, 'gestern'),
                    trend: _trendIcon(dailyRevenue, yRevenue),
                    accent: AppColors.gold,
                  ).animate().fadeIn(delay: 120.ms, duration: 360.ms).slideY(
                      begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                  _MetricCard(
                    emoji: '📅',
                    label: 'Kunden 7 Tage',
                    value: _fmtInt.format(w7Customers),
                    sub: last7.isEmpty
                        ? 'Noch keine Daten'
                        : 'Ø ${_fmtInt.format(w7Customers / last7.length)} / Tag',
                    trend: null,
                    accent: AppColors.secondary,
                  ).animate().fadeIn(delay: 180.ms, duration: 360.ms).slideY(
                      begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                  _MetricCard(
                    emoji: '⭐',
                    label: 'Beliebtheit',
                    value: '${avgReputation.toStringAsFixed(1)} / 5',
                    sub: _reputationLabel(avgReputation),
                    trend: null,
                    accent: AppColors.cream,
                  ).animate().fadeIn(delay: 240.ms, duration: 360.ms).slideY(
                      begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                ]),
              ),
            ),

            // ── Wochen-Übersicht (Umsatz 7 Tage) ──────────────────────
            if (last7.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child:
                      _WeekRevenueCard(records: last7, today: game.currentDay),
                ),
              ),

            // ── KPI Karten ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.7,
                ),
                delegate: SliverChildListDelegate([
                  _KpiCard(
                    icon: Icons.storefront_rounded,
                    iconColor: AppColors.primary,
                    label: 'Filialen',
                    value: '${game.shopCount}',
                  ),
                  _KpiCard(
                    icon: Icons.people_rounded,
                    iconColor: AppColors.accent,
                    label: 'Mitarbeiter',
                    value: '${game.employeeCount}',
                  ),
                  _KpiCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.success,
                    label: 'Gesamtumsatz',
                    value: '${_fmtInt.format(game.totalRevenue)} €',
                  ),
                  _KpiCard(
                    icon: Icons.account_balance_rounded,
                    iconColor: game.activeLoansTotal > 0
                        ? AppColors.warning
                        : AppColors.textMuted,
                    label: 'Kredite',
                    value: game.activeLoansTotal > 0
                        ? '-${_fmtInt.format(game.activeLoansTotal)} €'
                        : 'Keine',
                  ),
                  _KpiCard(
                    icon: Icons.campaign_rounded,
                    iconColor: AppColors.gold,
                    label: 'Marke',
                    value:
                        '${game.brand.brandAwareness.toStringAsFixed(0)}/100',
                  ),
                  _KpiCard(
                    icon: Icons.emoji_events_rounded,
                    iconColor: AppColors.secondary,
                    label: 'Trophäen',
                    value: '${game.achievementIds.length}',
                  ),
                ]),
              ),
            ),

            // ── Filialen ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FILIALEN',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (game.shops.isNotEmpty)
                      Text(
                        '${game.shops.length} gesamt',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (game.shops.isEmpty)
              const SliverToBoxAdapter(child: _EmptyShopsCard())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final shop = game.shops[i];
                    final revenue = GameEngine.calculateDailyRevenue(shop,
                        day: game.currentDay, state: game);
                    final costs = GameEngine.calculateDailyCosts(shop,
                        day: game.currentDay, state: game);
                    final profit = revenue - costs;
                    final customers = GameEngine.calculateDailyCustomers(shop,
                        day: game.currentDay, state: game);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Pressable(
                        onTap: () => context.push('/shop/${shop.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Spieß-Icon mit Glow
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          brandTheme.accent,
                                          brandTheme.accentDark,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              brandTheme.accent.withAlpha(80),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text('🥙',
                                          style: TextStyle(fontSize: 26)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shop.displayName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          shop.wasAcquired &&
                                                  shop.acquiredHint != null
                                              ? '${shop.locationName} · ${shop.acquiredHint}'
                                              : shop.locationName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _ShopMini(
                                      icon: Icons.people_outline,
                                      label: _fmtInt.format(customers),
                                      sub: 'Kunden',
                                      color: AppColors.accent),
                                  const SizedBox(width: 16),
                                  _ShopMini(
                                      icon: Icons.euro,
                                      label: _fmtInt.format(revenue),
                                      sub: 'Umsatz',
                                      color: AppColors.gold),
                                  const SizedBox(width: 16),
                                  _ShopMini(
                                      icon: profit >= 0
                                          ? Icons.trending_up
                                          : Icons.trending_down,
                                      label: _fmtInt.format(profit),
                                      sub: 'Profit',
                                      color: profit >= 0
                                          ? AppColors.success
                                          : AppColors.danger),
                                  const SizedBox(width: 16),
                                  _ShopMini(
                                      icon: Icons.star,
                                      label: shop.reputation.toStringAsFixed(1),
                                      sub: 'Rep.',
                                      color: AppColors.cream),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                            delay: (60 * i).ms,
                            duration: 340.ms,
                            curve: Curves.easeOut)
                        .slideX(
                            begin: 0.08,
                            end: 0,
                            curve: Curves.easeOutCubic);
                  },
                  childCount: game.shops.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  static String _trendLabel(double now, double before, String beforeLabel) {
    if (before == 0) return 'Noch keine Daten';
    final diff = now - before;
    final pct = (diff / before * 100).abs();
    final sign = diff >= 0 ? '+' : '−';
    return '$sign${pct.toStringAsFixed(0)}% vs. $beforeLabel';
  }

  static _Trend? _trendIcon(double now, double before) {
    if (before == 0) return null;
    if (now > before * 1.03) return _Trend.up;
    if (now < before * 0.97) return _Trend.down;
    return _Trend.flat;
  }

  static String _reputationLabel(double r) {
    if (r >= 4.5) return 'Stadt-Liebling';
    if (r >= 4.0) return 'Sehr beliebt';
    if (r >= 3.5) return 'Gut bekannt';
    if (r >= 2.5) return 'Mittelmäßig';
    if (r >= 1.5) return 'Schlechter Ruf';
    return 'Katastrophal';
  }
}

enum _Trend { up, down, flat }

class _HeaderBar extends StatelessWidget {
  final GameState game;
  const _HeaderBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final weekday = _kWeekdays[game.currentDay % 7];
    final season = GameEngine.seasonForDay(game.currentDay);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tag ${game.currentDay}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        weekday,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(36),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${season.emoji} ${season.label}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  game.companyName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text('🏪', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${game.shopCount}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FeedbackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.feedback_outlined, size: 18),
        label: const Text('Feedback geben'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cream,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _CashCard extends StatelessWidget {
  final double cash;
  final double dailyRevenue;
  final double dailyCosts;
  final double dailyProfit;

  const _CashCard({
    required this.cash,
    required this.dailyRevenue,
    required this.dailyCosts,
    required this.dailyProfit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(70),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'KASSE',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withAlpha(180),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedMoney(
            amount: cash,
            fontSize: 40,
            color: Colors.white,
            fontFamily: AppTheme.displayFont,
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withAlpha(40)),
          const SizedBox(height: 16),
          Row(
            children: [
              _CashStat(
                label: 'Einnahmen/Tag',
                value: '+${_fmtInt.format(dailyRevenue)} €',
                color: AppColors.cream,
              ),
              const SizedBox(width: 24),
              _CashStat(
                label: 'Kosten/Tag',
                value: '-${_fmtInt.format(dailyCosts)} €',
                color: Colors.white.withAlpha(200),
              ),
              const SizedBox(width: 24),
              _CashStat(
                label: 'Profit/Tag',
                value:
                    '${dailyProfit >= 0 ? "+" : ""}${_fmtInt.format(dailyProfit)} €',
                color: dailyProfit >= 0
                    ? AppColors.cream
                    : Colors.white.withAlpha(200),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CashStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;
  final _Trend? trend;
  final Color accent;

  const _MetricCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
    required this.trend,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    Color trendColor = AppColors.textMuted;
    IconData? trendIcon;
    if (trend == _Trend.up) {
      trendColor = AppColors.success;
      trendIcon = Icons.trending_up_rounded;
    } else if (trend == _Trend.down) {
      trendColor = AppColors.danger;
      trendIcon = Icons.trending_down_rounded;
    } else if (trend == _Trend.flat) {
      trendColor = AppColors.textSecondary;
      trendIcon = Icons.trending_flat_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (trendIcon != null)
                Icon(trendIcon, size: 14, color: trendColor),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.display(size: 23, weight: FontWeight.w800, color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: trendIcon != null ? trendColor : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRevenueCard extends StatelessWidget {
  final List<DailyRecord> records;
  final int today;
  const _WeekRevenueCard({required this.records, required this.today});

  @override
  Widget build(BuildContext context) {
    final maxR =
        records.fold<double>(0, (m, r) => r.revenue > m ? r.revenue : m);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'UMSATZ LETZTE TAGE',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_fmtInt.format(records.fold(0.0, (s, r) => s + r.revenue))} €',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final r in records)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _fmtInt.format(r.revenue),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: maxR > 0
                                ? (r.revenue / maxR * 50).clamp(2.0, 50.0)
                                : 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.gold],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _kWeekdays[r.day % 7],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyShopsCard extends StatelessWidget {
  const _EmptyShopsCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(80),
                    AppColors.gold.withAlpha(40)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('🥙', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Noch keine Filialen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gehe zu Städte und eröffne\ndeine erste Filiale.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _ShopMini({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const Spacer(),
          Text(
            value,
            style: AppText.display(size: 19, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CampaignBanner extends StatelessWidget {
  final CampaignChapter? chapter;
  final double progress;
  final VoidCallback onTap;

  const _CampaignBanner({
    required this.chapter,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final complete = chapter == null;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withAlpha(40),
              AppColors.gold.withAlpha(26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withAlpha(70)),
        ),
        child: Row(
          children: [
            Text(complete ? '👑' : (chapter!.emoji),
                style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complete ? 'KAMPAGNE' : 'KAPITEL ${chapter!.number}',
                    style: AppText.label(color: AppColors.gold, size: 10),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    complete ? 'Imperium vollendet 👑' : chapter!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(size: 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: complete ? 1.0 : progress,
                      minHeight: 5,
                      backgroundColor: AppColors.bg.withAlpha(120),
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final List<ShopAlert> alerts;
  final void Function(String shopId) onTapShop;
  const _AlertsCard({required this.alerts, required this.onTapShop});

  @override
  Widget build(BuildContext context) {
    final hasDanger = alerts.any((a) => a.level == AlertLevel.danger);
    final accent = hasDanger ? AppColors.danger : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text('HINWEISE', style: AppText.label(color: accent, size: 10)),
            ],
          ),
          const SizedBox(height: 8),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: a.shopId != null ? () => onTapShop(a.shopId!) : null,
                child: Row(
                  children: [
                    Icon(
                      a.level == AlertLevel.danger
                          ? Icons.error_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 15,
                      color: a.level == AlertLevel.danger
                          ? AppColors.danger
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (a.shopId != null)
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kompakte „Heute"-Karte: Tagesspecial + Tagesaufgabe in einer Karte
/// (statt zwei separater Banner).
class _TodayCard extends StatelessWidget {
  final String specialEmoji;
  final String specialName;
  final String challengeEmoji;
  final String challengeLabel;
  final double challengeReward;

  const _TodayCard({
    required this.specialEmoji,
    required this.specialName,
    required this.challengeEmoji,
    required this.challengeLabel,
    required this.challengeReward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _TodayRow(
            emoji: specialEmoji,
            label: 'TAGESSPECIAL',
            labelColor: AppColors.gold,
            value: specialName,
            chipText: '+Nachfrage',
            chipColor: AppColors.gold,
          ),
          const Divider(color: AppColors.border, height: 16),
          _TodayRow(
            emoji: challengeEmoji,
            label: 'TAGESAUFGABE',
            labelColor: AppColors.accent,
            value: challengeLabel,
            chipText: '+${_fmtInt.format(challengeReward)} €',
            chipColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  final String emoji;
  final String label;
  final Color labelColor;
  final String value;
  final String chipText;
  final Color chipColor;

  const _TodayRow({
    required this.emoji,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.chipText,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.label(color: labelColor, size: 9)),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            chipText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: chipColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayEndButton extends StatelessWidget {
  final bool loading;
  final bool hasShops;
  final VoidCallback onPressed;

  const _DayEndButton({
    required this.loading,
    required this.hasShops,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (loading || !hasShops) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bg,
          disabledBackgroundColor: AppColors.bgCard,
          disabledForegroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.bg,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.nights_stay_rounded, size: 20),
        label: Text(
          loading
              ? 'Wird abgerechnet...'
              : hasShops
                  ? 'Tag beenden  ·  Kasse machen'
                  : 'Erst Filiale eröffnen',
        ),
      ),
    );
  }
}
