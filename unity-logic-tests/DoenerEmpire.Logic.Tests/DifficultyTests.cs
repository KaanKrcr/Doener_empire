using Xunit;
using DoenerEmpire.Core;
using DoenerEmpire.Models;

namespace DoenerEmpire.Logic.Tests
{
    public class DifficultyTests
    {
        [Fact]
        public void AllFourDifficultiesPresent()
        {
            Assert.Equal(4, DifficultyData.Modifiers.Count);
            foreach (GameDifficulty d in System.Enum.GetValues(typeof(GameDifficulty)))
            {
                Assert.True(DifficultyData.Modifiers.ContainsKey(d));
            }
        }

        [Fact]
        public void NormalIsAllNeutral()
        {
            var n = DifficultyData.Get(GameDifficulty.Normal);
            Assert.Equal(1.0, n.HrRecruitmentSpeedMultiplier);
            Assert.Equal(1.0, n.CandidateQualityMultiplier);
            Assert.Equal(1.0, n.CandidateSalaryMultiplier);
            Assert.Equal(1.0, n.CompetitorAggressivenessMultiplier);
            Assert.Equal(1.0, n.CustomerPriceSensitivityMultiplier);
            Assert.Equal(1.0, n.ProgressSpeedMultiplier);
            Assert.Equal(1.0, n.ReputationPenaltyMultiplier);
            Assert.Equal(1.0, n.EconomicPressureMultiplier);
        }

        [Fact]
        public void ExactValuesMatchFlutterTable()
        {
            var e = DifficultyData.Get(GameDifficulty.Easy);
            Assert.Equal(0.60, e.CompetitorAggressivenessMultiplier);
            Assert.Equal(0.65, e.CustomerPriceSensitivityMultiplier);
            Assert.Equal(1.35, e.ProgressSpeedMultiplier);

            var imp = DifficultyData.Get(GameDifficulty.Impossible);
            Assert.Equal(1.90, imp.CompetitorAggressivenessMultiplier);
            Assert.Equal(1.65, imp.CustomerPriceSensitivityMultiplier);
            Assert.Equal(0.60, imp.ProgressSpeedMultiplier);
            Assert.Equal(1.45, imp.CandidateSalaryMultiplier);
        }

        // "Härter = größer"-Achsen: easy < normal < hard < impossible
        [Fact]
        public void HarderIsBiggerAxesAreMonotonic()
        {
            var e = DifficultyData.Get(GameDifficulty.Easy);
            var n = DifficultyData.Get(GameDifficulty.Normal);
            var h = DifficultyData.Get(GameDifficulty.Hard);
            var i = DifficultyData.Get(GameDifficulty.Impossible);

            Assert.True(e.CompetitorAggressivenessMultiplier < n.CompetitorAggressivenessMultiplier);
            Assert.True(n.CompetitorAggressivenessMultiplier < h.CompetitorAggressivenessMultiplier);
            Assert.True(h.CompetitorAggressivenessMultiplier < i.CompetitorAggressivenessMultiplier);

            Assert.True(e.CustomerPriceSensitivityMultiplier < n.CustomerPriceSensitivityMultiplier);
            Assert.True(h.CustomerPriceSensitivityMultiplier < i.CustomerPriceSensitivityMultiplier);

            Assert.True(e.CandidateSalaryMultiplier < n.CandidateSalaryMultiplier);
            Assert.True(h.CandidateSalaryMultiplier < i.CandidateSalaryMultiplier);

            Assert.True(e.ReputationPenaltyMultiplier < n.ReputationPenaltyMultiplier);
            Assert.True(h.EconomicPressureMultiplier < i.EconomicPressureMultiplier);
        }

        // "Härter = kleiner"-Achsen: easy > normal > hard > impossible
        [Fact]
        public void HarderIsSmallerAxesAreMonotonic()
        {
            var e = DifficultyData.Get(GameDifficulty.Easy);
            var n = DifficultyData.Get(GameDifficulty.Normal);
            var h = DifficultyData.Get(GameDifficulty.Hard);
            var i = DifficultyData.Get(GameDifficulty.Impossible);

            Assert.True(e.HrRecruitmentSpeedMultiplier > n.HrRecruitmentSpeedMultiplier);
            Assert.True(n.HrRecruitmentSpeedMultiplier > h.HrRecruitmentSpeedMultiplier);
            Assert.True(h.HrRecruitmentSpeedMultiplier > i.HrRecruitmentSpeedMultiplier);

            Assert.True(e.CandidateQualityMultiplier > n.CandidateQualityMultiplier);
            Assert.True(h.CandidateQualityMultiplier > i.CandidateQualityMultiplier);

            Assert.True(e.ProgressSpeedMultiplier > n.ProgressSpeedMultiplier);
            Assert.True(h.ProgressSpeedMultiplier > i.ProgressSpeedMultiplier);
        }

        [Fact]
        public void LabelsAndDescriptionsNonEmpty()
        {
            foreach (GameDifficulty d in System.Enum.GetValues(typeof(GameDifficulty)))
            {
                Assert.False(string.IsNullOrWhiteSpace(DifficultyData.Label(d)));
                Assert.False(string.IsNullOrWhiteSpace(DifficultyData.ShortDescription(d)));
            }
        }

        [Fact]
        public void FromNameMatchesDartSemantics()
        {
            Assert.Equal(GameDifficulty.Easy, DifficultyData.FromName("easy"));
            Assert.Equal(GameDifficulty.Impossible, DifficultyData.FromName("impossible"));
            Assert.Equal(GameDifficulty.Normal, DifficultyData.FromName(null));
            Assert.Equal(GameDifficulty.Normal, DifficultyData.FromName("bogus"));
        }
    }
}
