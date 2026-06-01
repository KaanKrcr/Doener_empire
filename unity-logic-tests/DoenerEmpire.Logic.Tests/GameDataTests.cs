using System.Linq;
using Xunit;
using DoenerEmpire.Core;
using DoenerEmpire.Data;

namespace DoenerEmpire.Logic.Tests
{
    public class GameDataTests
    {
        [Fact]
        public void HasThirteenCities()
        {
            Assert.Equal(13, GameData.AllCities.Count);
        }

        [Fact]
        public void ThreeFreeStartingCities()
        {
            var klein = GameData.AllCities.Where(c => c.Tier == CityTier.Klein).ToList();
            Assert.Equal(3, klein.Count);
            Assert.All(klein, c => Assert.Equal(0, c.UnlockCost));
        }

        [Fact]
        public void FuldaValuesMatchFlutter()
        {
            var fulda = GameData.AllCities.Single(c => c.Id == "fulda");
            Assert.Equal("Fulda", fulda.Name);
            Assert.Equal(CityTier.Klein, fulda.Tier);
            Assert.Equal(1200, fulda.RentBase);
            Assert.Equal(4500, fulda.FootTrafficBase);
            Assert.Equal(68000, fulda.Population);
        }

        [Fact]
        public void MunichIsMostExpensiveMetropole()
        {
            var muc = GameData.AllCities.Single(c => c.Id == "muenchen");
            Assert.Equal(CityTier.Metropole, muc.Tier);
            Assert.Equal(750000, muc.UnlockCost);
            Assert.Equal(8000, muc.RentBase);
        }

        [Fact]
        public void EachTierHasExpectedCount()
        {
            Assert.Equal(3, GameData.AllCities.Count(c => c.Tier == CityTier.Klein));
            Assert.Equal(3, GameData.AllCities.Count(c => c.Tier == CityTier.Mittel));
            Assert.Equal(4, GameData.AllCities.Count(c => c.Tier == CityTier.Gross));
            Assert.Equal(3, GameData.AllCities.Count(c => c.Tier == CityTier.Metropole));
        }

        [Fact]
        public void HasEightProductsFiveDefault()
        {
            Assert.Equal(8, GameData.AllProducts.Count);
            Assert.Equal(5, GameData.AllProducts.Count(p => p.IsDefault));
        }

        [Fact]
        public void DoenerFladenValuesMatchFlutter()
        {
            var d = GameData.AllProducts.Single(p => p.Id == "doener_fladen");
            Assert.Equal(6.50, d.BasePrice);
            Assert.Equal(2.20, d.IngredientCostPerUnit);
            Assert.Equal(ProductCategory.Doener, d.Category);
            Assert.True(d.IsDefault);
        }

        [Fact]
        public void EquipmentGatedProductsHaveRequirement()
        {
            var box = GameData.AllProducts.Single(p => p.Id == "doenerbox");
            Assert.Equal("fritteuse_standard", box.RequiredEquipmentId);
            var lahmacun = GameData.AllProducts.Single(p => p.Id == "lahmacun");
            Assert.Equal("ofen_lahmacun", lahmacun.RequiredEquipmentId);
        }

        [Fact]
        public void StartingCashMatchesFlutter()
        {
            Assert.Equal(15000.0, GameData.StartingCash);
            Assert.Equal(8.03, GameData.NationalAvgDoenerPrice);
        }
    }
}
