using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;
using AdminSite.Models;
using Azure;
using Azure.AI.Inference;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text;
using Azure;

 [IgnoreAntiforgeryToken]
public class AddProductModel : PageModel
{
    private readonly ILogger<AddProductModel> _logger;
    [BindProperty]
    public Product Product { get; set; } = new Product();

    public AddProductModel(ILogger<AddProductModel> logger)
    {
        _logger = logger;
    }

    // Removed OpenAI endpoint handler

    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> OnPostGenerateDescriptionAsync()
    {
        _logger.LogInformation("OnPostGenerateDescriptionAsync called in AddProductModel");
        try
        {
            string body;
            using (var reader = new StreamReader(Request.Body))
                body = await reader.ReadToEndAsync();
            _logger.LogInformation($"Request body: {body}");
            var name = JsonDocument.Parse(body).RootElement.GetProperty("name").GetString();

            var apiKey = System.IO.File.ReadAllText("/mnt/secrets-store-openai-key/OpenAIAPIKey");
            var endpoint = System.IO.File.ReadAllText("/mnt/secrets-store-openai/OpenAIEndpoint");
            var deploymentName = System.IO.File.ReadAllText("/mnt/secrets-store-openai-deployment/OpenAIDeploymentName");

            var client = new ChatCompletionsClient(
                new Uri($"{endpoint}/openai/deployments/{deploymentName}"),
                new AzureKeyCredential(apiKey),
                new AzureAIInferenceClientOptions()
            );

            var requestOptions = new ChatCompletionsOptions()
            {
                Messages =
                {
                    new ChatRequestUserMessage($"Write a compelling product description for: {name}")
                },
                MaxTokens = 100,
                Temperature = 0.7f,
                NucleusSamplingFactor = 1.0f,
                Model = deploymentName
            };

            Response<ChatCompletions> response = client.Complete(requestOptions);
            var desc = response.Value.Content;
            _logger.LogInformation($"AI description response: {desc}");
            return new JsonResult(new { description = desc });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception in OnPostGenerateDescriptionAsync");
            return new JsonResult(new { description = "" });
        }
    }

    public void OnGet() { }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
            return Page();

        // Handle image upload
        var imageFile = Request.Form.Files["ImageFile"];
        if (imageFile != null && imageFile.Length > 0)
        {
            if (imageFile.Length > 1024 * 1024) // 1024 KB limit
            {
                ModelState.AddModelError("ImageFile", "Image size must be 1024 KB or less.");
                return Page();
            }
            using (var ms = new MemoryStream())
            {
                await imageFile.CopyToAsync(ms);
                Product.ImageData = ms.ToArray();
            }
        }

        // Truncate description to 4000 characters to avoid CosmosDB size errors
        if (!string.IsNullOrEmpty(Product.Description) && Product.Description.Length > 4000)
            Product.Description = Product.Description.Substring(0, 4000);

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
