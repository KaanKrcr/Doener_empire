using Xunit;
using DoenerEmpire.Core;

namespace DoenerEmpire.Logic.Tests
{
    // Sichert die Save-Kompatibilität: C#-Enum <-> Dart-`enum.name`-String.
    public class EnumMappingTests
    {
        [Fact]
        public void CompetitorPersonalityRoundTrips()
        {
            Assert.Equal("cheapMass", EnumNames.ToDart(CompetitorPersonality.CheapMass));
            Assert.Equal("balanced", EnumNames.ToDart(CompetitorPersonality.Balanced));
            Assert.Equal("premium", EnumNames.ToDart(CompetitorPersonality.Premium));
            Assert.Equal("aggressive", EnumNames.ToDart(CompetitorPersonality.Aggressive));
            Assert.Equal("traditional", EnumNames.ToDart(CompetitorPersonality.Traditional));

            foreach (CompetitorPersonality v in System.Enum.GetValues(typeof(CompetitorPersonality)))
            {
                Assert.Equal(v, EnumNames.CompetitorFromDart(EnumNames.ToDart(v)));
            }
        }

        [Fact]
        public void CityTierRoundTrips()
        {
            Assert.Equal("klein", EnumNames.ToDart(CityTier.Klein));
            Assert.Equal("metropole", EnumNames.ToDart(CityTier.Metropole));
            foreach (CityTier v in System.Enum.GetValues(typeof(CityTier)))
            {
                Assert.Equal(v, EnumNames.CityTierFromDart(EnumNames.ToDart(v)));
            }
        }

        [Fact]
        public void LocationPersonalityRoundTrips()
        {
            Assert.Equal("touristic", EnumNames.ToDart(LocationPersonality.Touristic));
            foreach (LocationPersonality v in System.Enum.GetValues(typeof(LocationPersonality)))
            {
                Assert.Equal(v, EnumNames.LocationFromDart(EnumNames.ToDart(v)));
            }
        }

        [Fact]
        public void ShopSizeTierRoundTrips()
        {
            Assert.Equal("flagship", EnumNames.ToDart(ShopSizeTier.Flagship));
            foreach (ShopSizeTier v in System.Enum.GetValues(typeof(ShopSizeTier)))
            {
                Assert.Equal(v, EnumNames.ShopSizeFromDart(EnumNames.ToDart(v)));
            }
        }

        [Fact]
        public void DifficultyRoundTrips()
        {
            foreach (GameDifficulty v in System.Enum.GetValues(typeof(GameDifficulty)))
            {
                Assert.Equal(v, EnumNames.DifficultyFromDart(EnumNames.ToDart(v)));
            }
        }

        [Fact]
        public void UnknownDartNameFallsBackSafely()
        {
            Assert.Equal(CompetitorPersonality.Balanced, EnumNames.CompetitorFromDart("???"));
            Assert.Equal(CityTier.Klein, EnumNames.CityTierFromDart("???"));
            Assert.Equal(LocationPersonality.Touristic, EnumNames.LocationFromDart("???"));
            Assert.Equal(ShopSizeTier.Klein, EnumNames.ShopSizeFromDart("???"));
        }
    }
}
