using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

public class StoreFrontModel : PageModel
{
    public List<Product> Products { get; set; } = new List<Product>();
    public async Task OnGet()
    {
        Products = await GetProductsFromCosmosDbAsync();
    }

    private async Task<List<Product>> GetProductsFromCosmosDbAsync()
    {
    var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
        var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
        var containerName = Environment.GetEnvironmentVariable("PRODUCTS_CONTAINER_NAME");
        var client = new Microsoft.Azure.Cosmos.CosmosClient(connStr);
        var container = client.GetContainer(dbName, containerName);
        var query = "SELECT * FROM c";
        var iterator = container.GetItemQueryIterator<Product>(query);
        var products = new List<Product>();
        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            products.AddRange(response.Resource);
        }
        return products;
    }
    public class Product
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        public string ImageUrl { get; set; }
    }
}
