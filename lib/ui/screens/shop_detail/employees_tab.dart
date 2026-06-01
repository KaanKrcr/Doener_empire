part of '../shop_detail_screen.dart';

// ── Personal-Tab ──────────────────────────────────────────────────────────

class _EmployeesTab extends ConsumerWidget {
  final Shop shop;
  final double cash;
  const _EmployeesTab({required this.shop, required this.cash});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxEmp = GameEngine.maxEmployeesForShop(shop);
    final atMax = shop.employees.length >= maxEmp;
    final peakShift = GameEngine.peakShiftForPersonality(shop.personality);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── HR-Manager Toggle ──────────────────────────────────────────
        PremiumDecisionSheet(
          borderColor:
              shop.autoHire ? AppColors.gold.withAlpha(80) : AppColors.border,
          child: Row(
            children: [
              const Text('🧑‍💼', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HR-Manager',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      shop.autoHire
                          ? 'Stellt bei Engpass automatisch ein (skalierende Recruiter-Gebühr: 1.5x bis 3.0x Tagesgehalt).'
                          : 'Off - du stellst alle Mitarbeiter selbst ein.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: shop.autoHire,
                activeThumbColor: AppColors.gold,
                onChanged: (_) =>
                    ref.read(gameProvider.notifier).toggleAutoHire(shop.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Personal-Kapazitäts-Indikator ───────────────────────────────
        PremiumDecisionSheet(
          borderColor:
              atMax ? AppColors.warning.withAlpha(90) : AppColors.border,
          child: Row(
            children: [
              Icon(
                atMax ? Icons.groups_rounded : Icons.group_add_rounded,
                color: atMax ? AppColors.warning : AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      atMax
                          ? 'Personal-Cap erreicht'
                          : 'Mitarbeiter ${shop.employees.length}/$maxEmp',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color:
                            atMax ? AppColors.warning : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      atMax
                          ? 'Diese Filiale hat Platz für maximal $maxEmp Personen. Nutze "Filiale ausbauen" für mehr Personal-Cap.'
                          : 'Noch ${maxEmp - shop.employees.length} freie Stelle${maxEmp - shop.employees.length == 1 ? "" : "n"}.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress-Balken
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: shop.employees.length / maxEmp,
                    minHeight: 6,
                    backgroundColor: AppColors.bg,
                    color: atMax ? AppColors.warning : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (shop.employees.isNotEmpty) ...[
          const SizedBox(height: 10),
          _MoraleCard(morale: shop.morale),
        ],
        const SizedBox(height: 16),

        // Aktuelle Mitarbeiter
        if (shop.employees.isNotEmpty) ...[
          const PremiumSectionLabel(text: 'AKTUELLE MITARBEITER'),
          const SizedBox(height: 8),
          for (final emp in shop.employees) ...[
            _EmployeeCard(
              employee: emp,
              peakShift: peakShift,
              onFire: () {
                ref.read(gameProvider.notifier).fireEmployee(shop.id, emp.id);
              },
              onTrain: () => _openTraining(context, shop.id, emp.id),
              onSetShift: (sh) => ref
                  .read(gameProvider.notifier)
                  .setEmployeeShift(shop.id, emp.id, sh),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
        ],

        // Stellen ausschreiben
        const PremiumSectionLabel(text: 'STELLENAUSSCHREIBUNG'),
        const SizedBox(height: 8),
        for (final type in kEmployeeTypes) ...[
          _HireCard(
            type: type,
            disabled: atMax,
            onPostJob: () {
              if (atMax) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Filiale voll besetzt ($maxEmp/$maxEmp). Baue die Filiale aus oder eröffne eine weitere.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              _openCandidates(context, ref, type);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _openCandidates(
      BuildContext context, WidgetRef ref, EmployeeTypeData type) {
    final game = ref.read(gameProvider);
    if (game == null) return;
    final hrMods = HrEngine.recruitmentModifiers(game);
    final candidateCount =
        (3 * hrMods.refreshSpeedMultiplier).round().clamp(2, 6);

    // HR-/Schwierigkeits-basierte Kandidaten generieren
    final candidates = HrEngine.generateCandidatesForRole(
      game,
      count: candidateCount,
      forcedType: type,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CandidatePicker(
        type: type,
        candidates: candidates,
        onPick: (cand) {
          Navigator.pop(ctx);
          ref.read(gameProvider.notifier).hireEmployee(shop.id, cand);
          // Kurze Snackbar oben — verdeckt keine Buttons unten.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${cand.name} eingestellt ${type.emoji}'),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              dismissDirection: DismissDirection.horizontal,
            ),
          );
        },
      ),
    );
  }

  void _openTraining(BuildContext context, String shopId, String employeeId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TrainingSheet(shopId: shopId, employeeId: employeeId),
    );
  }
}

// ── Training Bottom Sheet ─────────────────────────────────────────────────

/// Bezahlte Kurse: hebt eine Fähigkeit des Mitarbeiters gegen Cash an.
/// Liest den Spielstand live, damit Kosten und Werte nach jedem Kurs aktuell
/// bleiben.
class _TrainingSheet extends ConsumerWidget {
  final String shopId;
  final String employeeId;
  const _TrainingSheet({required this.shopId, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    Employee? emp;
    if (game != null) {
      for (final s in game.shops) {
        if (s.id != shopId) continue;
        for (final e in s.employees) {
          if (e.id == employeeId) emp = e;
        }
      }
    }
    if (game == null || emp == null) {
      return const SizedBox.shrink();
    }
    final employee = emp;

    return Container(
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🎓 Training · ${employee.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Verfügbar: ${_fmt.format(game.cash)} €',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          for (final skill in EmployeeSkill.values) ...[
            _TrainingRow(
              skill: skill,
              employee: employee,
              cost: HrEngine.trainingCost(game, employee, skill),
              canAfford:
                  game.cash >= HrEngine.trainingCost(game, employee, skill),
              onTrain: () {
                ref
                    .read(gameProvider.notifier)
                    .trainEmployee(shopId, employeeId, skill);
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TrainingRow extends StatelessWidget {
  final EmployeeSkill skill;
  final Employee employee;
  final double cost;
  final bool canAfford;
  final VoidCallback onTrain;

  const _TrainingRow({
    required this.skill,
    required this.employee,
    required this.cost,
    required this.canAfford,
    required this.onTrain,
  });

  @override
  Widget build(BuildContext context) {
    final value = HrEngine.skillValue(employee, skill);
    final maxed = !HrEngine.canTrain(employee, skill);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(skill.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(
                  maxed ? 'Maximum erreicht' : 'Stufe $value → ${value + 1}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (maxed)
            const Text('✓ Max',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700))
          else
            ElevatedButton(
              onPressed: canAfford ? onTrain : null,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text('${_fmtInt.format(cost)} €'),
            ),
        ],
      ),
    );
  }
}

// ── Kandidaten-Auswahl Bottom Sheet ───────────────────────────────────────

class _CandidatePicker extends StatelessWidget {
  final EmployeeTypeData type;
  final List<Employee> candidates;
  final void Function(Employee) onPick;

  const _CandidatePicker({
    required this.type,
    required this.candidates,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag-handle
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
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bewerber für ${type.title}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                    Text('${candidates.length} Kandidaten haben sich beworben',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final c in candidates) ...[
            _CandidateCard(
              candidate: c,
              onPick: () => onPick(c),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Employee candidate;
  final VoidCallback onPick;

  const _CandidateCard({required this.candidate, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kopf: Name, Sterne, Gehalt
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(140),
                      AppColors.primaryDark.withAlpha(120)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    candidate.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        )),
                    Row(
                      children: [
                        for (int i = 0; i < 5; i++)
                          Icon(
                            i < candidate.starRating
                                ? Icons.star
                                : Icons.star_outline,
                            size: 12,
                            color: AppColors.gold,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _archetypeLabel(candidate),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (candidate.isSpecialCandidate) ...[
                      const SizedBox(height: 2),
                      Text(
                        candidate.origin.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmt.format(candidate.salaryPerDay)} €',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                  const Text('pro Tag',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Traits (4 horizontale Bars)
          _TraitBar(
              label: 'Geschwindigkeit',
              value: candidate.speed,
              icon: Icons.bolt,
              color: AppColors.warning),
          const SizedBox(height: 6),
          _TraitBar(
              label: 'Freundlichkeit',
              value: candidate.friendliness,
              icon: Icons.sentiment_very_satisfied,
              color: AppColors.accent),
          const SizedBox(height: 6),
          _TraitBar(
              label: 'Zuverlässigkeit',
              value: candidate.reliability,
              icon: Icons.verified_outlined,
              color: AppColors.cream),
          const SizedBox(height: 6),
          _TraitBar(
              label: 'Erfahrung',
              value: candidate.experience,
              icon: Icons.workspace_premium_outlined,
              color: AppColors.gold),

          if (candidate.traits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in candidate.traits) _PersonalityChip(trait: t),
              ],
            ),
          ],
          if (candidate.isSpecialCandidate) ...[
            const SizedBox(height: 8),
            Text(
              candidate.origin.description,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.handshake_outlined, size: 18),
              label: const Text('Einstellen'),
            ),
          ),
        ],
      ),
    );
  }

  String _archetypeLabel(Employee e) {
    final avg = e.overallScore;
    if (avg >= 0.75) return 'Profi';
    if (avg >= 0.55) return 'Erfahren';
    if (avg >= 0.4) return 'Solide';
    return 'Anfänger';
  }
}

class _TraitBar extends StatelessWidget {
  final String label;
  final int value; // 1..10
  final IconData icon;
  final Color color;

  const _TraitBar({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / 10).clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 22,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onFire;
  final VoidCallback onTrain;
  final EmployeeShift? peakShift;
  final ValueChanged<EmployeeShift> onSetShift;

  const _EmployeeCard({
    required this.employee,
    required this.onFire,
    required this.onTrain,
    required this.peakShift,
    required this.onSetShift,
  });

  @override
  Widget build(BuildContext context) {
    final type = kEmployeeTypes.firstWhere((t) => t.id == employee.typeId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(type.title,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Row(
                      children: [
                        for (int i = 0; i < 5; i++)
                          Icon(
                            i < employee.starRating
                                ? Icons.star
                                : Icons.star_outline,
                            size: 12,
                            color: AppColors.gold,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          '${_fmt.format(employee.salaryPerDay)} €/Tag',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Training',
                icon: const Icon(Icons.school_outlined,
                    color: AppColors.accent, size: 20),
                onPressed: onTrain,
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    color: AppColors.danger, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.bgCard,
                      title: Text('${employee.name} entlassen?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Abbrechen')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onFire();
                          },
                          child: const Text('Entlassen'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          // Trait-Mini-Anzeige
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniTrait(
                  icon: Icons.bolt,
                  value: employee.speed,
                  color: AppColors.warning),
              const SizedBox(width: 8),
              _MiniTrait(
                  icon: Icons.sentiment_very_satisfied,
                  value: employee.friendliness,
                  color: AppColors.accent),
              const SizedBox(width: 8),
              _MiniTrait(
                  icon: Icons.verified_outlined,
                  value: employee.reliability,
                  color: AppColors.cream),
              const SizedBox(width: 8),
              _MiniTrait(
                  icon: Icons.workspace_premium_outlined,
                  value: employee.experience,
                  color: AppColors.gold),
            ],
          ),
          // Persönlichkeits-Traits
          if (employee.traits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in employee.traits) _PersonalityChip(trait: t),
                if (employee.daysEmployed > 30)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cream.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📅 ${employee.daysEmployed} Tage',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (peakShift != null) ...[
            const SizedBox(height: 10),
            _ShiftSelector(
              current: employee.shift,
              peak: peakShift!,
              onSelect: onSetShift,
            ),
          ],
        ],
      ),
    );
  }
}

/// Kompakte Schicht-Auswahl: hebt die zur Stoßzeit passende Schicht hervor.
class _ShiftSelector extends StatelessWidget {
  final EmployeeShift current;
  final EmployeeShift peak;
  final ValueChanged<EmployeeShift> onSelect;
  const _ShiftSelector({
    required this.current,
    required this.peak,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Schicht',
          style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final sh in EmployeeShift.values)
                _ShiftChip(
                  shift: sh,
                  selected: sh == current,
                  isPeak: sh == peak,
                  onTap: () => onSelect(sh),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShiftChip extends StatelessWidget {
  final EmployeeShift shift;
  final bool selected;
  final bool isPeak;
  final VoidCallback onTap;
  const _ShiftChip({
    required this.shift,
    required this.selected,
    required this.isPeak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.border;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(30) : AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          '${shift.emoji} ${shift.label}${isPeak ? " ⭐" : ""}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Team-Moral-Anzeige der Filiale (Burnout-Warnung bei niedriger Moral).
class _MoraleCard extends StatelessWidget {
  final double morale;
  const _MoraleCard({required this.morale});

  @override
  Widget build(BuildContext context) {
    final (label, color) = morale >= 0.8
        ? ('Top-Stimmung', AppColors.success)
        : morale >= 0.65
            ? ('Gute Stimmung', AppColors.success)
            : morale >= 0.5
                ? ('Solide', AppColors.accent)
                : morale >= 0.4
                    ? ('Angespannt', AppColors.warning)
                    : ('Burnout-Gefahr', AppColors.danger);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Text('🙂', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Team-Moral',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: morale.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.bg,
                    color: color,
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

class _PersonalityChip extends StatelessWidget {
  final PersonalityTrait trait;
  const _PersonalityChip({required this.trait});

  @override
  Widget build(BuildContext context) {
    final color = trait.isPositive ? AppColors.accent : AppColors.danger;
    return Tooltip(
      message: trait.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trait.emoji, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Text(
              trait.label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTrait extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  const _MiniTrait(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HireCard extends StatelessWidget {
  final EmployeeTypeData type;
  final VoidCallback onPostJob;
  final bool disabled;

  const _HireCard({
    required this.type,
    required this.onPostJob,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(type.description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    'ab ${_fmt.format(type.baseSalaryPerDay)} €/Tag',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onPostJob,
              icon: Icon(disabled ? Icons.block : Icons.search, size: 16),
              label: Text(disabled ? 'Voll' : 'Bewerber'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
                backgroundColor: disabled ? AppColors.bgSurface : null,
                foregroundColor: disabled ? AppColors.textMuted : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
