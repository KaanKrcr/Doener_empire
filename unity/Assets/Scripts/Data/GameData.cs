// Döner Empire 3D — Statische Spieldaten (Städte, Produkte)
// 1:1-Port aus lib/core/constants.dart.
// Hinweis: In Unity werden diese später idealerweise als ScriptableObjects
// gepflegt; vorerst als statische Listen für einfache Logik-Portierung & Tests.

using System.Collections.Generic;
using DoenerEmpire.Core;

namespace DoenerEmpire.Data
{
    public sealed class CityData
    {
        public string Id;
        public string Name;
        public string State;
        public int Population;
        public CityTier Tier;
        public double UnlockCost;
        public double RentBase;
        public int FootTrafficBase;
        public string Emoji;
    }

    public sealed class ProductData
    {
        public string Id;
        public string Name;
        public string Emoji;
        public double BasePrice;
        public double IngredientCostPerUnit;
        public ProductCategory Category;
        public bool IsDefault;
        public string RequiredEquipmentId; // null = keins
    }

    public static class GameData
    {
        // Startkapital & Referenzwerte (aus constants.dart)
        public const double StartingCash = 15000.0;
        public const double NationalAvgDoenerPrice = 8.03;
        public const double TickIntervalSeconds = 3.0;
        public const int HoursPerDay = 24;
        public const double DailyOpenHours = 14.0;

        public static readonly IReadOnlyList<CityData> AllCities = new List<CityData>
        {
            // ── Kleinstädte (Startstädte, kostenlos) ──
            new() { Id = "fulda", Name = "Fulda", State = "Hessen", Population = 68000,
                    Tier = CityTier.Klein, UnlockCost = 0, RentBase = 1200,
                    FootTrafficBase = 4500, Emoji = "🌿" },
            new() { Id = "bayreuth", Name = "Bayreuth", State = "Bayern", Population = 74000,
                    Tier = CityTier.Klein, UnlockCost = 0, RentBase = 1100,
                    FootTrafficBase = 4800, Emoji = "🎭" },
            new() { Id = "goettingen", Name = "Göttingen", State = "Niedersachsen", Population = 118000,
                    Tier = CityTier.Klein, UnlockCost = 0, RentBase = 1300,
                    FootTrafficBase = 6000, Emoji = "🎓" },

            // ── Mittelstädte (ab 30.000 € Gesamtumsatz) ──
            new() { Id = "augsburg", Name = "Augsburg", State = "Bayern", Population = 300000,
                    Tier = CityTier.Mittel, UnlockCost = 30000, RentBase = 2000,
                    FootTrafficBase = 10000, Emoji = "⛪" },
            new() { Id = "muenster", Name = "Münster", State = "NRW", Population = 315000,
                    Tier = CityTier.Mittel, UnlockCost = 30000, RentBase = 1900,
                    FootTrafficBase = 9500, Emoji = "🚲" },
            new() { Id = "braunschweig", Name = "Braunschweig", State = "Niedersachsen", Population = 248000,
                    Tier = CityTier.Mittel, UnlockCost = 50000, RentBase = 1700,
                    FootTrafficBase = 8500, Emoji = "🦁" },

            // ── Großstädte (ab 150.000 € Gesamtumsatz) ──
            new() { Id = "frankfurt", Name = "Frankfurt", State = "Hessen", Population = 750000,
                    Tier = CityTier.Gross, UnlockCost = 150000, RentBase = 4500,
                    FootTrafficBase = 22000, Emoji = "🏦" },
            new() { Id = "koeln", Name = "Köln", State = "NRW", Population = 1080000,
                    Tier = CityTier.Gross, UnlockCost = 150000, RentBase = 4000,
                    FootTrafficBase = 20000, Emoji = "⛩️" },
            new() { Id = "stuttgart", Name = "Stuttgart", State = "Baden-Württemberg", Population = 630000,
                    Tier = CityTier.Gross, UnlockCost = 200000, RentBase = 3800,
                    FootTrafficBase = 18000, Emoji = "🚗" },
            new() { Id = "duesseldorf", Name = "Düsseldorf", State = "NRW", Population = 620000,
                    Tier = CityTier.Gross, UnlockCost = 200000, RentBase = 4200,
                    FootTrafficBase = 19000, Emoji = "👗" },

            // ── Metropolen (ab 500.000 € Gesamtumsatz) ──
            new() { Id = "berlin", Name = "Berlin", State = "Berlin", Population = 3800000,
                    Tier = CityTier.Metropole, UnlockCost = 500000, RentBase = 7000,
                    FootTrafficBase = 50000, Emoji = "🐻" },
            new() { Id = "hamburg", Name = "Hamburg", State = "Hamburg", Population = 1800000,
                    Tier = CityTier.Metropole, UnlockCost = 500000, RentBase = 6500,
                    FootTrafficBase = 40000, Emoji = "⚓" },
            new() { Id = "muenchen", Name = "München", State = "Bayern", Population = 1500000,
                    Tier = CityTier.Metropole, UnlockCost = 750000, RentBase = 8000,
                    FootTrafficBase = 45000, Emoji = "🍺" },
        };

        public static readonly IReadOnlyList<ProductData> AllProducts = new List<ProductData>
        {
            new() { Id = "doener_fladen", Name = "Döner im Fladenbrot", Emoji = "🫓",
                    BasePrice = 6.50, IngredientCostPerUnit = 2.20,
                    Category = ProductCategory.Doener, IsDefault = true },
            new() { Id = "doener_duerum", Name = "Dürüm Döner", Emoji = "🌯",
                    BasePrice = 7.00, IngredientCostPerUnit = 2.40,
                    Category = ProductCategory.Doener, IsDefault = true },
            new() { Id = "veg_doener", Name = "Vegetarischer Döner", Emoji = "🥗",
                    BasePrice = 6.50, IngredientCostPerUnit = 1.80,
                    Category = ProductCategory.Doener, IsDefault = true },
            new() { Id = "doenerbox", Name = "Döner-Box", Emoji = "📦",
                    BasePrice = 9.50, IngredientCostPerUnit = 3.50,
                    Category = ProductCategory.Box, IsDefault = false,
                    RequiredEquipmentId = "fritteuse_standard" },
            new() { Id = "lahmacun", Name = "Lahmacun", Emoji = "🫓",
                    BasePrice = 4.00, IngredientCostPerUnit = 1.20,
                    Category = ProductCategory.Beilage, IsDefault = false,
                    RequiredEquipmentId = "ofen_lahmacun" },
            new() { Id = "pommes", Name = "Pommes", Emoji = "🍟",
                    BasePrice = 3.50, IngredientCostPerUnit = 0.80,
                    Category = ProductCategory.Beilage, IsDefault = false,
                    RequiredEquipmentId = "fritteuse_standard" },
            new() { Id = "ayran", Name = "Ayran", Emoji = "🥛",
                    BasePrice = 2.00, IngredientCostPerUnit = 0.50,
                    Category = ProductCategory.Getraenk, IsDefault = true },
            new() { Id = "cola", Name = "Cola / Fanta", Emoji = "🥤",
                    BasePrice = 2.50, IngredientCostPerUnit = 0.80,
                    Category = ProductCategory.Getraenk, IsDefault = true },
        };
    }
}
