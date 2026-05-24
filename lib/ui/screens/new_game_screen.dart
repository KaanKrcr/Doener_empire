import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
              Center(
                child: Column(
                  children: [
                    const Text('🥙', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    const Text(
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

              _SectionLabel('Dein Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _founderCtrl,
                decoration: const InputDecoration(
                  hintText: 'z.B. Mustafa Yilmaz',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Bitte deinen Namen eingeben' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              _SectionLabel('Firmenname'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  hintText: 'z.B. Sultan Döner GmbH',
                  prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.textMuted),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Bitte einen Firmennamen eingeben' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 40),

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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Startkapital',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                        Text('15.000 €',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold)),
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
                    Text('Du startest in', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Text('🌿  Fulda', style: TextStyle(color: AppColors.textPrimary)),
                        SizedBox(width: 16),
                        Text('🎭  Bayreuth', style: TextStyle(color: AppColors.textPrimary)),
                        SizedBox(width: 16),
                        Text('🎓  Göttingen', style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('Größere Städte werden durch Wachstum freigeschaltet.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
