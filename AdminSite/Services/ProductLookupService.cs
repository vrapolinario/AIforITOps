using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;
using AdminSite.Models;

public class ProductLookupService
{
    private readonly Container _productsContainer;

    public ProductLookupService(string connStr, string dbName, string productsContainerName)
    {
        var client = new CosmosClient(connStr);
        _productsContainer = client.GetContainer(dbName, productsContainerName);
    }

    public async Task<Dictionary<string, string>> GetProductNamesAsync(IEnumerable<string> productIds)
    {
        var dict = new Dictionary<string, string>();
        foreach (var id in productIds)
        {
            var query = new QueryDefinition("SELECT c.id, c.Name FROM c WHERE c.id = @id").WithParameter("@id", id);
            var iterator = _productsContainer.GetItemQueryIterator<Product>(query);
            while (iterator.HasMoreResults)
            {
                var response = await iterator.ReadNextAsync();
                foreach (var prod in response.Resource)
                {
                    dict[prod.id] = prod.Name ?? "";
                }
            }
        }
        return dict;
    }
}
