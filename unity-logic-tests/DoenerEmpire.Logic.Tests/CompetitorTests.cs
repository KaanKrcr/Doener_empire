using System;
using Xunit;
using DoenerEmpire.Core;
using DoenerEmpire.Models;

namespace DoenerEmpire.Logic.Tests
{
    public class CompetitorTests
    {
        // Seedbarer RNG → deterministische, reproduzierbare Tests.
        private static CompetitorFactory Factory(int seed = 12345)
            => new CompetitorFactory(new Random(seed));

        [Theory]
        [InlineData(CompetitorPersonality.CheapMass, 0.75, 0.85, 2.3, 3.0)]
        [InlineData(CompetitorPersonality.Balanced, 0.95, 1.05, 3.0, 3.7)]
        [InlineData(CompetitorPersonality.Premium, 1.20, 1.35, 3.8, 4.5)]
        [InlineData(CompetitorPersonality.Aggressive, 0.85, 1.00, 2.8, 3.5)]
        [InlineData(CompetitorPersonality.Traditional, 1.00, 1.10, 3.5, 4.3)]
        public void PriceAndRepWithinPersonalityRanges(
            CompetitorPersonality p, double priceMin, double priceMax,
            double repMin, double repMax)
        {
            var f = Factory();
            // Mehrere Stichproben prüfen, dass die Verteilung in den Grenzen bleibt.
            for (var i = 0; i < 200; i++)
            {
                var c = f.Create($"c{i}", "fulda", p);
                Assert.InRange(c.PriceLevel, priceMin, priceMax);
                Assert.InRange(c.Reputation, repMin, repMax);
                Assert.InRange(c.MarketShare, 0.15, 0.35);
                Assert.InRange(c.ShopCount, 1, 2);
                Assert.Equal(p, c.Personality);
                Assert.Equal("fulda", c.CityId);
            }
        }

        [Fact]
        public void NamesAreUniqueUntilPoolExhausted()
        {
            var f = Factory();
            var seen = new System.Collections.Generic.HashSet<string>();
            // Pool hat 20 Namen → erste 20 müssen eindeutig sein.
            for (var i = 0; i < 20; i++)
            {
                var c = f.Create($"c{i}", "berlin");
                Assert.DoesNotContain(c.Name, seen);
                seen.Add(c.Name);
            }
            Assert.Equal(20, seen.Count);
        }

        [Fact]
        public void ShortStatusReflectsState()
        {
            var c = new Competitor
            {
                ShopCount = 3,
                Reputation = 4.2,
                PriceLevel = 1.2,
            };
            var s = c.ShortStatus();
            Assert.Contains("3 Filialen", s);
            Assert.Contains("starker Ruf", s);
            Assert.Contains("teuer", s);
        }

        [Fact]
        public void TaglineAndEmojiForAllPersonalities()
        {
            foreach (CompetitorPersonality p in Enum.GetValues(typeof(CompetitorPersonality)))
            {
                Assert.False(string.IsNullOrWhiteSpace(CompetitorPersonalityInfo.Tagline(p)));
                Assert.False(string.IsNullOrWhiteSpace(CompetitorPersonalityInfo.Emoji(p)));
            }
        }
    }
}
