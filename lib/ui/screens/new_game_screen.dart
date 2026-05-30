import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/difficulty_model.dart';
import '../../models/scenario_model.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';

class NewGameScreen extends ConsumerStatefulWidget {
  const NewGameScreen({super.key});

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _founderCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  GameDifficulty _selectedDifficulty = GameDifficulty.normal;
  bool _tutorialEnabled = true;
  Scenario _scenario = kScenarios.first;
  bool _loading = false;

  @override
  void dispose() {
    _founderCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await ref.read(gameProvider.notifier).startNewGame(
          _companyCtrl.text.trim(),
          _founderCtrl.text.trim(),
          difficulty: _selectedDifficulty,
          tutorialEnabled: _tutorialEnabled,
          startCash: _scenario.startCash,
          startingLoanAmount: _scenario.startingLoan,
        );
    if (mounted) context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Neues Spiel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    Text('🥙', style: TextStyle(fontSize: 72)),
                    SizedBox(height: 12),
                    Text(
                      'Dein Döner-Imperium beginnt\nmit einem einzigen Laden.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              const _SectionLabel('Szenario'),
              const SizedBox(height: 8),
              const Text(
                'Wähle deine Ausgangslage. Szenarien setzen Startkapital, '
                'Schwierigkeit und Tutorial.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final scenario in kScenarios) ...[
                _ScenarioTile(
                  scenario: scenario,
                  selected: _scenario.id == scenario.id,
                  onTap: () => setState(() {
                    _scenario = scenario;
                    _selectedDifficulty = scenario.difficulty;
                    _tutorialEnabled = scenario.tutorialEnabled;
                  }),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 30),

              const _SectionLabel('Dein Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _founderCtrl,
                decoration: const InputDecoration(
                  hintText: 'z.B. Mustafa Yilmaz',
                  prefixIcon:
                      Icon(Icons.person_outline, color: AppColors.textMuted),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Bitte deinen Namen eingeben'
                    : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              const _SectionLabel('Firmenname'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  hintText: 'z.B. Sultan Döner GmbH',
                  prefixIcon: Icon(Icons.storefront_outlined,
                      color: AppColors.textMuted),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Bitte einen Firmennamen eingeben'
                    : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 40),

              const _SectionLabel('Schwierigkeit'),
              const SizedBox(height: 8),
              const Text(
                'Wähle die passende Herausforderung. Die Stufe beeinflusst HR, Konkurrenz, Kunden und Progress.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              for (final difficulty in GameDifficulty.values) ...[
                _DifficultyTile(
                  difficulty: difficulty,
                  selected: _selectedDifficulty == difficulty,
                  onTap: () => setState(() => _selectedDifficulty = difficulty),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 30),

              const _SectionLabel('Tutorial / Onboarding'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      value: _tutorialEnabled,
                      onChanged: (value) =>
                          setState(() => _tutorialEnabled = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Geführtes Tutorial aktivieren',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Schritt-für-Schritt-Missionen für den Spielstart.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tutorialEnabled
                          ? 'Empfohlen für neue Spielstände. Du kannst es später jederzeit pausieren.'
                          : 'Tutorial wird übersprungen. Du kannst es später in den Einstellungen fortsetzen.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Startkapital Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined,
                          color: AppColors.gold),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Startkapital',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                        Text(
                            '${NumberFormat('#,##0', 'de_DE').format(_scenario.startCash)} €',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold)),
                        if (_scenario.startingLoan > 0)
                          Text(
                            'inkl. ${NumberFormat('#,##0', 'de_DE').format(_scenario.startingLoan)} € Startkredit',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.danger),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Du startest in',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Text('🌿  Fulda',
                            style: TextStyle(color: AppColors.textPrimary)),
                        SizedBox(width: 16),
                        Text('🎭  Bayreuth',
                            style: TextStyle(color: AppColors.textPrimary)),
                        SizedBox(width: 16),
                        Text('🎓  Göttingen',
                            style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('Größere Städte werden durch Wachstum freigeschaltet.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _start,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Imperium gründen  🚀'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  final Scenario scenario;
  final bool selected;
  final VoidCallback onTap;

  const _ScenarioTile({
    required this.scenario,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha((0.12 * 255).round())
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scenario.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scenario.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  final GameDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha((0.12 * 255).round())
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    difficulty.shortDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
