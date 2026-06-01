// Döner Empire 3D — Kern-Enums
// Portiert aus lib/models/*.dart und lib/core/constants.dart.
//
// WICHTIG (Save-Kompatibilität): Flutter serialisiert Enums über `enum.name`
// (camelCase), z.B. "cheapMass", "klein", "touristic", "metropole".
// C#-Enums sind PascalCase. Beim JSON-(De)Serialisieren MUSS auf die
// Dart-Strings gemappt werden — dafür unten je Enum eine ToDartName()/
// FromDartName()-Hilfe. SaveService nutzt ausschließlich diese.

namespace DoenerEmpire.Core
{
    public enum GameDifficulty { Easy, Normal, Hard, Impossible }

    public enum CityTier { Klein, Mittel, Gross, Metropole }

    public enum LocationPersonality
    {
        Touristic, Business, Transit, Residential, University, Nightlife
    }

    public enum ProductCategory { Doener, Box, Beilage, Getraenk }

    public enum EquipmentCategory { Spiess, Kasse, Sonstiges }

    public enum CompetitorPersonality
    {
        CheapMass, Balanced, Premium, Aggressive, Traditional
    }

    public enum MarketingScope { Shop, City, Global }

    public enum MarketingRisk { Low, Medium, High }

    public enum ShopSizeTier { Klein, Mittel, Gross, Flagship }

    /// <summary>
    /// Mapping C#-Enum &lt;-&gt; Dart-`enum.name`-String für JSON-Kompatibilität.
    /// Die Dart-Namen sind camelCase; mehrteilige wie "cheapMass" werden explizit
    /// behandelt, der Rest ist lowercase des C#-Namens.
    /// </summary>
    public static class EnumNames
    {
        // GameDifficulty: easy/normal/hard/impossible
        public static string ToDart(GameDifficulty v) => v.ToString().ToLowerInvariant();

        public static GameDifficulty DifficultyFromDart(string raw)
            => raw switch
            {
                "easy" => GameDifficulty.Easy,
                "hard" => GameDifficulty.Hard,
                "impossible" => GameDifficulty.Impossible,
                _ => GameDifficulty.Normal,
            };

        // CityTier: klein/mittel/gross/metropole
        public static string ToDart(CityTier v) => v.ToString().ToLowerInvariant();

        public static CityTier CityTierFromDart(string raw)
            => raw switch
            {
                "mittel" => CityTier.Mittel,
                "gross" => CityTier.Gross,
                "metropole" => CityTier.Metropole,
                _ => CityTier.Klein,
            };

        // LocationPersonality: touristic/business/transit/residential/university/nightlife
        public static string ToDart(LocationPersonality v) => v.ToString().ToLowerInvariant();

        public static LocationPersonality LocationFromDart(string raw)
            => raw switch
            {
                "business" => LocationPersonality.Business,
                "transit" => LocationPersonality.Transit,
                "residential" => LocationPersonality.Residential,
                "university" => LocationPersonality.University,
                "nightlife" => LocationPersonality.Nightlife,
                _ => LocationPersonality.Touristic,
            };

        // ProductCategory: doener/box/beilage/getraenk
        public static string ToDart(ProductCategory v) => v.ToString().ToLowerInvariant();

        // EquipmentCategory: spiess/kasse/sonstiges
        public static string ToDart(EquipmentCategory v) => v.ToString().ToLowerInvariant();

        // CompetitorPersonality: cheapMass/balanced/premium/aggressive/traditional
        public static string ToDart(CompetitorPersonality v)
            => v == CompetitorPersonality.CheapMass ? "cheapMass" : v.ToString().ToLowerInvariant();

        public static CompetitorPersonality CompetitorFromDart(string raw)
            => raw switch
            {
                "cheapMass" => CompetitorPersonality.CheapMass,
                "premium" => CompetitorPersonality.Premium,
                "aggressive" => CompetitorPersonality.Aggressive,
                "traditional" => CompetitorPersonality.Traditional,
                _ => CompetitorPersonality.Balanced,
            };

        // MarketingScope: shop/city/global
        public static string ToDart(MarketingScope v) => v.ToString().ToLowerInvariant();

        // MarketingRisk: low/medium/high
        public static string ToDart(MarketingRisk v) => v.ToString().ToLowerInvariant();

        // ShopSizeTier: klein/mittel/gross/flagship
        public static string ToDart(ShopSizeTier v) => v.ToString().ToLowerInvariant();

        public static ShopSizeTier ShopSizeFromDart(string raw)
            => raw switch
            {
                "mittel" => ShopSizeTier.Mittel,
                "gross" => ShopSizeTier.Gross,
                "flagship" => ShopSizeTier.Flagship,
                _ => ShopSizeTier.Klein,
            };
    }
}
