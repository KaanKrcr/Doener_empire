enum TutorialStep {
  openFirstShop,
  understandLocationValues,
  changeProductPrice,
  hireFirstEmployee,
  endFirstDay,
  readDayReport,
  viewDashboardMetrics,
  openEmpireMenu,
  understandHrCompetitionGrowth,
  finishTutorial,
}

const int kTutorialStepCount = 10;

TutorialStep tutorialStepFromIndex(int index) {
  if (index <= 0) return TutorialStep.openFirstShop;
  if (index >= TutorialStep.values.length) return TutorialStep.finishTutorial;
  return TutorialStep.values[index];
}

extension TutorialStepMeta on TutorialStep {
  String get title {
    return switch (this) {
      TutorialStep.openFirstShop => 'Erste Filiale eröffnen',
      TutorialStep.understandLocationValues => 'Standortwerte verstehen',
      TutorialStep.changeProductPrice => 'Produktpreis ändern',
      TutorialStep.hireFirstEmployee => 'Mitarbeiter einstellen',
      TutorialStep.endFirstDay => 'Ersten Tag abschließen',
      TutorialStep.readDayReport => 'Tagesbericht lesen',
      TutorialStep.viewDashboardMetrics => 'Dashboard-Kennzahlen ansehen',
      TutorialStep.openEmpireMenu => 'Imperium-Menü öffnen',
      TutorialStep.understandHrCompetitionGrowth => 'HR, Konkurrenz, Wachstum',
      TutorialStep.finishTutorial => 'Tutorial abschließen',
    };
  }

  String get description {
    return switch (this) {
      TutorialStep.openFirstShop =>
        'Wechsle zu Städte und eröffne deine erste Filiale.',
      TutorialStep.understandLocationValues =>
        'Prüfe Miete, Nachfrage und Konkurrenz am Standort.',
      TutorialStep.changeProductPrice =>
        'Passe in einer Filiale mindestens einen Produktpreis an.',
      TutorialStep.hireFirstEmployee =>
        'Stelle einen ersten Mitarbeiter aus dem Bewerberpool ein.',
      TutorialStep.endFirstDay =>
        'Beende den Tag für Umsatz, Kosten und Reputation.',
      TutorialStep.readDayReport =>
        'Lies den Tagesabschluss und bestätige ihn.',
      TutorialStep.viewDashboardMetrics =>
        'Sieh dir Kasse, Kunden und Tagesprofit an.',
      TutorialStep.openEmpireMenu =>
        'Öffne das Imperium-Menü für deinen Gesamtfortschritt.',
      TutorialStep.understandHrCompetitionGrowth =>
        'Prüfe kurz HR, Konkurrenz und Wachstumsoptionen.',
      TutorialStep.finishTutorial =>
        'Schließe das Tutorial ab und spiele frei weiter.',
    };
  }

  String get hint {
    return switch (this) {
      TutorialStep.openFirstShop => 'Tipp: Tab "Städte"',
      TutorialStep.understandLocationValues =>
        'Vergleiche die Werte vor der Standortwahl.',
      TutorialStep.changeProductPrice =>
        'Preise veränderst du in den Filialdetails.',
      TutorialStep.hireFirstEmployee =>
        'Mitarbeiter findest du in der Filiale.',
      TutorialStep.endFirstDay => 'Nutze den goldenen Button im Dashboard.',
      TutorialStep.readDayReport => 'Schließe den Tagesbericht nach dem Lesen.',
      TutorialStep.viewDashboardMetrics =>
        'Achte auf Gewinn, Kunden und aktuelle Kosten.',
      TutorialStep.openEmpireMenu => 'Tipp: Tab "Imperium"',
      TutorialStep.understandHrCompetitionGrowth =>
        'Öffne den Konzern-Tab für HR und Expansion.',
      TutorialStep.finishTutorial =>
        'Du bist bereit für den Ausbau deines Imperiums.',
    };
  }

  String? get actionLabel {
    return switch (this) {
      TutorialStep.understandLocationValues => 'Weiter',
      TutorialStep.viewDashboardMetrics => 'Kennzahlen angesehen',
      TutorialStep.understandHrCompetitionGrowth => 'Weiter',
      TutorialStep.finishTutorial => 'Tutorial beenden',
      _ => null,
    };
  }

  String get whyItMatters {
    return switch (this) {
      TutorialStep.openFirstShop =>
        'Ohne Filiale entstehen keine Einnahmen. Das ist dein Startpunkt für alles Weitere.',
      TutorialStep.understandLocationValues =>
        'Standortwerte bestimmen, wie schnell eine Filiale profitabel wird und wie viel Risiko du trägst.',
      TutorialStep.changeProductPrice =>
        'Preisentscheidungen beeinflussen Nachfrage und Marge direkt. Das ist einer der wichtigsten Hebel.',
      TutorialStep.hireFirstEmployee =>
        'Personal sorgt für Kapazität und Servicequalität. Ohne Team wächst die Filiale nicht stabil.',
      TutorialStep.endFirstDay =>
        'Der Tagesabschluss zeigt dir, ob dein Setup wirtschaftlich funktioniert.',
      TutorialStep.readDayReport =>
        'Im Bericht erkennst du früh, ob Preise, Personal oder Kosten angepasst werden müssen.',
      TutorialStep.viewDashboardMetrics =>
        'Das Dashboard hilft dir, schnelle Entscheidungen datenbasiert zu treffen.',
      TutorialStep.openEmpireMenu =>
        'Im Imperium-Bereich siehst du Fortschritt, Ziele und wichtige Langzeitwerte.',
      TutorialStep.understandHrCompetitionGrowth =>
        'HR, Konkurrenz und Wachstum sind zentrale Systeme für deinen langfristigen Erfolg.',
      TutorialStep.finishTutorial =>
        'Mit dem Abschluss kennst du die Kernmechaniken und kannst eigenständig optimieren.',
    };
  }

  int? get targetTabIndex {
    return switch (this) {
      TutorialStep.openFirstShop => 1,
      TutorialStep.understandLocationValues => 1,
      TutorialStep.changeProductPrice => 1,
      TutorialStep.hireFirstEmployee => 1,
      TutorialStep.endFirstDay => 0,
      TutorialStep.readDayReport => 0,
      TutorialStep.viewDashboardMetrics => 0,
      TutorialStep.openEmpireMenu => 2,
      TutorialStep.understandHrCompetitionGrowth => 3,
      TutorialStep.finishTutorial => null,
    };
  }
}
