// Döner Empire 3D — Schwierigkeits-Modell
// 1:1-Port aus lib/models/difficulty_model.dart (Stand: aktuelles Tuning §3.3).

using System.Collections.Generic;
using DoenerEmpire.Core;

namespace DoenerEmpire.Models
{
    public readonly struct DifficultyModifiers
    {
        public readonly double HrRecruitmentSpeedMultiplier;
        public readonly double CandidateQualityMultiplier;
        public readonly double CandidateSalaryMultiplier;
        public readonly double CompetitorAggressivenessMultiplier;
        public readonly double CustomerPriceSensitivityMultiplier;
        public readonly double ProgressSpeedMultiplier;
        public readonly double ReputationPenaltyMultiplier;
        public readonly double EconomicPressureMultiplier;

        public DifficultyModifiers(
            double hrRecruitmentSpeedMultiplier,
            double candidateQualityMultiplier,
            double candidateSalaryMultiplier,
            double competitorAggressivenessMultiplier,
            double customerPriceSensitivityMultiplier,
            double progressSpeedMultiplier,
            double reputationPenaltyMultiplier,
            double economicPressureMultiplier)
        {
            HrRecruitmentSpeedMultiplier = hrRecruitmentSpeedMultiplier;
            CandidateQualityMultiplier = candidateQualityMultiplier;
            CandidateSalaryMultiplier = candidateSalaryMultiplier;
            CompetitorAggressivenessMultiplier = competitorAggressivenessMultiplier;
            CustomerPriceSensitivityMultiplier = customerPriceSensitivityMultiplier;
            ProgressSpeedMultiplier = progressSpeedMultiplier;
            ReputationPenaltyMultiplier = reputationPenaltyMultiplier;
            EconomicPressureMultiplier = economicPressureMultiplier;
        }
    }

    public static class DifficultyData
    {
        public static readonly IReadOnlyDictionary<GameDifficulty, DifficultyModifiers> Modifiers =
            new Dictionary<GameDifficulty, DifficultyModifiers>
            {
                [GameDifficulty.Easy] = new DifficultyModifiers(
                    hrRecruitmentSpeedMultiplier: 1.60,
                    candidateQualityMultiplier: 1.25,
                    candidateSalaryMultiplier: 0.80,
                    competitorAggressivenessMultiplier: 0.60,
                    customerPriceSensitivityMultiplier: 0.65,
                    progressSpeedMultiplier: 1.35,
                    reputationPenaltyMultiplier: 0.60,
                    economicPressureMultiplier: 0.75),
                [GameDifficulty.Normal] = new DifficultyModifiers(
                    hrRecruitmentSpeedMultiplier: 1.00,
                    candidateQualityMultiplier: 1.00,
                    candidateSalaryMultiplier: 1.00,
                    competitorAggressivenessMultiplier: 1.00,
                    customerPriceSensitivityMultiplier: 1.00,
                    progressSpeedMultiplier: 1.00,
                    reputationPenaltyMultiplier: 1.00,
                    economicPressureMultiplier: 1.00),
                [GameDifficulty.Hard] = new DifficultyModifiers(
                    hrRecruitmentSpeedMultiplier: 0.70,
                    candidateQualityMultiplier: 0.85,
                    candidateSalaryMultiplier: 1.20,
                    competitorAggressivenessMultiplier: 1.40,
                    customerPriceSensitivityMultiplier: 1.30,
                    progressSpeedMultiplier: 0.80,
                    reputationPenaltyMultiplier: 1.30,
                    economicPressureMultiplier: 1.25),
                [GameDifficulty.Impossible] = new DifficultyModifiers(
                    hrRecruitmentSpeedMultiplier: 0.45,
                    candidateQualityMultiplier: 0.70,
                    candidateSalaryMultiplier: 1.45,
                    competitorAggressivenessMultiplier: 1.90,
                    customerPriceSensitivityMultiplier: 1.65,
                    progressSpeedMultiplier: 0.60,
                    reputationPenaltyMultiplier: 1.70,
                    economicPressureMultiplier: 1.55),
            };

        public static DifficultyModifiers Get(GameDifficulty d)
            => Modifiers.TryGetValue(d, out var m) ? m : Modifiers[GameDifficulty.Normal];

        public static string Label(GameDifficulty d) => d switch
        {
            GameDifficulty.Easy => "Einfach",
            GameDifficulty.Normal => "Mittel / Normal",
            GameDifficulty.Hard => "Schwer",
            GameDifficulty.Impossible => "Unmöglich",
            _ => "Mittel / Normal",
        };

        public static string ShortDescription(GameDifficulty d) => d switch
        {
            GameDifficulty.Easy =>
                "Aktive HR-Hilfe, günstige Talente und tolerantere Kundschaft.",
            GameDifficulty.Normal => "Ausgewogenes Standard-Balancing.",
            GameDifficulty.Hard =>
                "Teurere Talente, aggressivere Konkurrenz und klarere Fehlerfolgen.",
            GameDifficulty.Impossible =>
                "Hoher Druck, sehr preissensible Kunden und langsamer Fortschritt.",
            _ => "Ausgewogenes Standard-Balancing.",
        };

        public static GameDifficulty FromName(string raw)
            => EnumNames.DifficultyFromDart(raw ?? "normal");
    }
}
