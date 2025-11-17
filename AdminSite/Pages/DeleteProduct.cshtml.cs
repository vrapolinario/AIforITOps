
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;
using AdminSite.Models;

public class DeleteProductModel : PageModel
{
    [BindProperty]
    public Product Product { get; set; } = new Product();

    public async Task<IActionResult> OnGetAsync(string id)
    {
    var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
        var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
        var containerName = Environment.GetEnvironmentVariable("PRODUCTS_CONTAINER_NAME");
        var client = new Microsoft.Azure.Cosmos.CosmosClient(connStr);
        var container = client.GetContainer(dbName, containerName);
        try
        {
            var response = await container.ReadItemAsync<Product>(id, new Microsoft.Azure.Cosmos.PartitionKey(id));
            Product = response.Resource;
        }
        catch
        {
            Product = new Product();
        }
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
    var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
        var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
        var containerName = Environment.GetEnvironmentVariable("PRODUCTS_CONTAINER_NAME");
        var client = new Microsoft.Azure.Cosmos.CosmosClient(connStr);
        var container = client.GetContainer(dbName, containerName);
    await container.DeleteItemAsync<Product>(Product.id, new Microsoft.Azure.Cosmos.PartitionKey(Product.id));
        return RedirectToPage("Admin");
    }
}
