
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;
using AdminSite.Models;

public class AddProductModel : PageModel
{
    [BindProperty]
    public Product Product { get; set; } = new Product();

    public void OnGet() { }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
            return Page();

        // Handle image upload
        var imageFile = Request.Form.Files["ImageFile"];
        if (imageFile != null && imageFile.Length > 0)
        {
            using (var ms = new MemoryStream())
            {
                await imageFile.CopyToAsync(ms);
                Product.ImageData = ms.ToArray();
            }
        }

        // Ensure Product.id is set (use Guid for uniqueness)
        if (string.IsNullOrEmpty(Product.id))
            Product.id = Guid.NewGuid().ToString();

        var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
        var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
        var containerName = Environment.GetEnvironmentVariable("PRODUCTS_CONTAINER_NAME");
        var client = new Microsoft.Azure.Cosmos.CosmosClient(connStr);
        var container = client.GetContainer(dbName, containerName);
        await container.UpsertItemAsync(Product, new Microsoft.Azure.Cosmos.PartitionKey(Product.id));
        return RedirectToPage("Admin");
    }
}
