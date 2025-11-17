using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StoreFront.Models;
using Microsoft.Azure.Cosmos;

namespace StoreFront.Pages;

public class ProductDetailsModel : PageModel
{
    [BindProperty]
    public Product? Product { get; set; }

    public async Task OnGetAsync(string id)
    {
    var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
        var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
        var containerName = Environment.GetEnvironmentVariable("PRODUCTS_CONTAINER_NAME");
        var client = new CosmosClient(connStr);
        var container = client.GetContainer(dbName, containerName);
        try
        {
            var response = await container.ReadItemAsync<Product>(id, new PartitionKey(id));
            Product = response.Resource;
        }
        catch
        {
            Product = null;
        }
    }

    public async Task<IActionResult> OnPostAsync(string id)
    {
        // Always fetch product from CosmosDB to ensure all fields are populated
    var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
        var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
        var containerName = Environment.GetEnvironmentVariable("PRODUCTS_CONTAINER_NAME");
        var client = new CosmosClient(connStr);
        var container = client.GetContainer(dbName, containerName);
        Product? product = null;
        try
        {
            var response = await container.ReadItemAsync<Product>(id, new PartitionKey(id));
            product = response.Resource;
        }
        catch
        {
            product = null;
        }

        var cartJson = HttpContext.Session.GetString("Cart");
        var cart = cartJson != null ? System.Text.Json.JsonSerializer.Deserialize<List<CartItem>>(cartJson) ?? new() : new();
        var existing = cart.FirstOrDefault(i => i.Product.id == id);
        if (existing != null)
            existing.Quantity++;
        else if (product != null)
            cart.Add(new CartItem { Product = product, Quantity = 1 });
        HttpContext.Session.SetString("Cart", System.Text.Json.JsonSerializer.Serialize(cart));
        return RedirectToPage("Cart");
    }
}
