import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/game_state.dart';
import '../../providers/game_provider.dart';

final _fmt = NumberFormat('#,##0', 'de_DE');
final _fmt2 = NumberFormat('#,##0.00', 'de_DE');
const _uuid = Uuid();

class BankScreen extends ConsumerWidget {
  const BankScreen({super.key});

  static const _loanOptions = [
    (amount: 5000.0, days: 30, rate: 0.08, label: 'Schnellkredit'),
    (amount: 20000.0, days: 90, rate: 0.06, label: 'Betriebskredit'),
    (amount: 50000.0, days: 180, rate: 0.05, label: 'Wachstumskredit'),
    (amount: 150000.0, days: 365, rate: 0.04, label: 'Großkredit'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider)!;
    final activeLoans = game.loans.where((l) => !l.isPaidOff).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('🏦  Bank'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Aktueller Kontostand
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.bgCard, AppColors.bgSurface],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.gold, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Verfügbares Kapital',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    Text('${_fmt.format(game.cash)} €',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Aktive Kredite
          if (activeLoans.isNotEmpty) ...[
            const Text(
              'LAUFENDE KREDITE',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warning,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final loan in activeLoans)
              _ActiveLoanCard(
                loan: loan,
                cash: game.cash,
                currentDay: game.currentDay,
                onExtraPayment: (amount) {
                  ref
                      .read(gameProvider.notifier)
                      .extraLoanPayment(loan.id, amount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Sondertilgung von ${_fmt.format(amount)} € geleistet')),
                  );
                },
                onPayOff: () {
                  final payoff = loan.earlyPayoffAmount(game.currentDay);
                  if (game.cash < payoff) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Nicht genug Kapital. Benötigt: ${_fmt.format(payoff)} €')),
                    );
                    return;
                  }
                  ref.read(gameProvider.notifier).payOffLoan(loan.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Kredit für ${_fmt.format(payoff)} € abgelöst! 🎉')),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],

          // Kredit aufnehmen
          const Text(
            'KREDIT AUFNEHMEN',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 2,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final opt in _loanOptions)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmt.format(opt.amount)} €  ·  ${opt.days} Tage  ·  ${(opt.rate * 100).toStringAsFixed(0)}% p.a.',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                        Text(
                          'Rückzahlung: ${_fmt2.format(opt.amount * (1 + opt.rate * opt.days / 365) / opt.days)} €/Tag',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _takeLoan(context, ref, opt.amount,
                        opt.rate, opt.days, opt.label, game.currentDay),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: Text('${_fmt.format(opt.amount)} €'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          const Center(
            child: Text(
              '⚠️  Kredite müssen täglich zurückgezahlt werden.\n'
              'Sondertilgung & vorzeitige Ablösung sind möglich.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _takeLoan(
    BuildContext context,
    WidgetRef ref,
    double amount,
    double rate,
    int days,
    String label,
    int currentDay,
  ) {
    final dailyPayment = amount * (1 + rate * days / 365) / days;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('$label aufnehmen?'),
        content: Text(
          'Betrag: ${_fmt.format(amount)} €\n'
          'Laufzeit: $days Tage\n'
          'Zinssatz: ${(rate * 100).toStringAsFixed(1)}% p.a.\n\n'
          'Tägliche Rate: ${_fmt2.format(dailyPayment)} €',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final loan = Loan(
                id: _uuid.v4(),
                amount: amount,
                interestRate: rate,
                durationDays: days,
                dayTaken: currentDay,
              );
              ref.read(gameProvider.notifier).takeLoan(loan);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${_fmt.format(amount)} € Kredit erhalten!')),
              );
            },
            child: const Text('Kredit aufnehmen'),
          ),
        ],
      ),
    );
  }
}

class _ActiveLoanCard extends StatelessWidget {
  final Loan loan;
  final double cash;
  final int currentDay;
  final void Function(double amount) onExtraPayment;
  final VoidCallback onPayOff;

  const _ActiveLoanCard({
    required this.loan,
    required this.cash,
    required this.currentDay,
    required this.onExtraPayment,
    required this.onPayOff,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = loan.remainingDays(currentDay);
    final earlyPayoff = loan.earlyPayoffAmount(currentDay);
    final canPayoff = cash >= earlyPayoff;
    final canPartial = cash >= 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_outlined,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fmt.format(loan.amount)} € Kredit',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(loan.interestRate * 100).toStringAsFixed(1)}% p.a.  ·  noch $daysLeft Tage',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmt.format(loan.remainingDebt)} €',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                  const Text('Restschuld',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: loan.progress,
            backgroundColor: AppColors.border,
            color: AppColors.warning,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LoanInfoRow(
                  label: 'Tägl. Rate',
                  value: '${_fmt2.format(loan.dailyPayment)} €',
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _LoanInfoRow(
                  label: 'Bezahlt',
                  value: '${_fmt.format(loan.amountPaid)} €',
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: _LoanInfoRow(
                  label: 'Bei Ablösung',
                  value: '${_fmt.format(earlyPayoff)} €',
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      canPartial ? () => _showExtraPayment(context) : null,
                  icon: const Icon(Icons.add_card_outlined, size: 16),
                  label: const Text('Sondertilgung'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canPayoff ? () => _confirmPayOff(context) : null,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Ablösen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmPayOff(BuildContext context) {
    final payoff = loan.earlyPayoffAmount(currentDay);
    final saved = loan.remainingDebt - payoff;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Kredit komplett ablösen?'),
        content: Text(
          'Du zahlst jetzt einmalig:\n'
          '${_fmt.format(payoff)} €\n\n'
          'Ersparte Zinsen: ${_fmt.format(saved)} €\n'
          'Restkapital danach: ${_fmt.format(cash - payoff)} €',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              Navigator.pop(ctx);
              onPayOff();
            },
            child: const Text('Ja, ablösen'),
          ),
        ],
      ),
    );
  }

  void _showExtraPayment(BuildContext context) {
    final maxAmount = cash < loan.remainingDebt ? cash : loan.remainingDebt;
    double selected = (maxAmount * 0.25).clamp(100, maxAmount);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sondertilgung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verfügbar: ${_fmt.format(cash)} €  ·  '
                'Restschuld: ${_fmt.format(loan.remainingDebt)} €',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '${_fmt.format(selected)} €',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: selected.clamp(100, maxAmount),
                min: 100,
                max: maxAmount,
                divisions: 50,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                onChanged: (v) => setSt(() => selected = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final q in [0.25, 0.5, 1.0])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () => setSt(() =>
                              selected = (maxAmount * q).clamp(100, maxAmount)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child:
                              Text(q == 1.0 ? 'Max' : '${(q * 100).round()}%'),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onExtraPayment(selected);
                  },
                  child: Text('${_fmt.format(selected)} € zurückzahlen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LoanInfoRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            )),
      ],
    );
  }
}
