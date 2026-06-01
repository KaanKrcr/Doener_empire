// Döner Empire 3D — KI-Konkurrenz
// Port aus lib/models/competitor_model.dart.
// RNG ist injizierbar (System.Random), damit Verhalten deterministisch testbar
// ist; Verteilungslogik entspricht dem Dart-Original.

using System;
using System.Collections.Generic;
using DoenerEmpire.Core;

namespace DoenerEmpire.Models
{
    public static class CompetitorPersonalityInfo
    {
        public static string Tagline(CompetitorPersonality p) => p switch
        {
            CompetitorPersonality.CheapMass => "\"Döner für alle, billig & schnell\"",
            CompetitorPersonality.Balanced => "\"Solide. Lecker. Bezahlbar.\"",
            CompetitorPersonality.Premium => "\"Premium-Döner. Bio. Authentisch.\"",
            CompetitorPersonality.Aggressive => "\"Wir wachsen wo andere sterben.\"",
            CompetitorPersonality.Traditional => "\"Seit 1985. Echtes Handwerk.\"",
            _ => "",
        };

        public static string Emoji(CompetitorPersonality p) => p switch
        {
            CompetitorPersonality.CheapMass => "💸",
            CompetitorPersonality.Balanced => "⚖️",
            CompetitorPersonality.Premium => "💎",
            CompetitorPersonality.Aggressive => "⚔️",
            CompetitorPersonality.Traditional => "🏛️",
            _ => "",
        };
    }

    public sealed class Competitor
    {
        public string Id;
        public string Name;
        public string CityId;
        public CompetitorPersonality Personality;
        public int ShopCount = 1;
        public double Reputation = 3.0;
        public double PriceLevel = 1.0;
        public double MarketShare = 0.15;
        public int DaysSinceLastAction = 0;

        public string ShortStatus()
        {
            var repLabel = Reputation >= 4.0 ? "starker Ruf"
                : Reputation >= 3.0 ? "okayer Ruf"
                : "schwächelt";
            var priceLabel = PriceLevel >= 1.15 ? "teuer"
                : PriceLevel <= 0.85 ? "günstig"
                : "normal";
            return $"{ShopCount} Filialen · {repLabel} · {priceLabel}";
        }
    }

    /// <summary>Namens-Pool für KI-Konkurrenten (deutsch-türkisch).</summary>
    public static class CompetitorNames
    {
        public static readonly IReadOnlyList<string> All = new List<string>
        {
            "Mehmet's Grill", "Berlin Kebap Haus", "Anatolia Express", "Bosporus Imbiss",
            "King Döner", "Istanbul Grillhaus", "Sultan's Pide", "Goldener Spieß",
            "Marmara Snack", "Yilmaz Family Kebap", "Topkapi Imbiss", "Döner-Express 24",
            "Pasha Grill", "Efes Imbiss", "Kebap Kralı", "Mama Mehmet",
            "Bistro Anadolu", "Best Döner", "Döner Time", "Star Kebap",
        };
    }

    public sealed class CompetitorFactory
    {
        private readonly Random _rng;
        private readonly HashSet<string> _usedNames = new();

        public CompetitorFactory(Random rng = null)
        {
            _rng = rng ?? new Random();
        }

        private string UniqueName()
        {
            var available = new List<string>();
            foreach (var n in CompetitorNames.All)
                if (!_usedNames.Contains(n)) available.Add(n);
            var pool = available.Count == 0 ? CompetitorNames.All : available;
            var pick = pool[_rng.Next(pool.Count)];
            _usedNames.Add(pick);
            return pick;
        }

        public Competitor Create(
            string id,
            string cityId,
            CompetitorPersonality? personality = null,
            int? shopCount = null)
        {
            var values = (CompetitorPersonality[])Enum.GetValues(typeof(CompetitorPersonality));
            var pers = personality ?? values[_rng.Next(values.Length)];

            double price, rep;
            switch (pers)
            {
                case CompetitorPersonality.CheapMass:
                    price = 0.75 + _rng.NextDouble() * 0.10;
                    rep = 2.3 + _rng.NextDouble() * 0.7;
                    break;
                case CompetitorPersonality.Balanced:
                    price = 0.95 + _rng.NextDouble() * 0.10;
                    rep = 3.0 + _rng.NextDouble() * 0.7;
                    break;
                case CompetitorPersonality.Premium:
                    price = 1.20 + _rng.NextDouble() * 0.15;
                    rep = 3.8 + _rng.NextDouble() * 0.7;
                    break;
                case CompetitorPersonality.Aggressive:
                    price = 0.85 + _rng.NextDouble() * 0.15;
                    rep = 2.8 + _rng.NextDouble() * 0.7;
                    break;
                case CompetitorPersonality.Traditional:
                default:
                    price = 1.00 + _rng.NextDouble() * 0.10;
                    rep = 3.5 + _rng.NextDouble() * 0.8;
                    break;
            }

            return new Competitor
            {
                Id = id,
                Name = UniqueName(),
                CityId = cityId,
                Personality = pers,
                ShopCount = shopCount ?? (1 + _rng.Next(2)),
                Reputation = Math.Round(rep, 2),
                PriceLevel = Math.Round(price, 2),
                MarketShare = 0.15 + _rng.NextDouble() * 0.20,
            };
        }
    }
}
