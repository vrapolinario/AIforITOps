using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;
using AdminSite.Models;

public class OrdersModel : PageModel
{
    public List<Order> Orders { get; set; } = new();
    public Dictionary<string, string> ProductNames { get; set; } = new();

    public async Task OnGetAsync()
    {
        var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
        var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
        var ordersContainerName = Environment.GetEnvironmentVariable("ORDERS_CONTAINER_NAME");
        var productsContainerName = Environment.GetEnvironmentVariable("PRODUCTS_CONTAINER_NAME");
        var client = new CosmosClient(connStr);
        var container = client.GetContainer(dbName, ordersContainerName);
        var query = "SELECT * FROM c";
        var iterator = container.GetItemQueryIterator<Order>(query);
        var orders = new List<Order>();
        var productIds = new HashSet<string>();
        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            orders.AddRange(response.Resource);
        }
        Orders = orders;
        // Collect all product IDs from all orders
        foreach (var order in Orders)
        {
            foreach (var item in order.Items)
            {
                if (!string.IsNullOrEmpty(item.ProductId))
                    productIds.Add(item.ProductId);
            }
        }
        // Lookup product names
        if (!string.IsNullOrEmpty(productsContainerName))
        {
            var lookup = new ProductLookupService(connStr, dbName, productsContainerName);
            ProductNames = await lookup.GetProductNamesAsync(productIds);
        }
    }
}
