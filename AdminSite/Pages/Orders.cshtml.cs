using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;
using AdminSite.Models;

public class OrdersModel : PageModel
{
    public List<Order> Orders { get; set; } = new();

    public async Task OnGetAsync()
    {
        var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
        var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
        var ordersContainerName = Environment.GetEnvironmentVariable("ORDERS_CONTAINER_NAME");
        var client = new CosmosClient(connStr);
        var container = client.GetContainer(dbName, ordersContainerName);
        var query = "SELECT * FROM c";
        var iterator = container.GetItemQueryIterator<Order>(query);
        var orders = new List<Order>();
        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            orders.AddRange(response.Resource);
        }
        Orders = orders;
    }
}
