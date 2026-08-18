using System.Net.Http.Json;
using System.Text.Json;

namespace AdminSite.Services;

public sealed class FoundryChatClient(HttpClient httpClient)
{
    public async Task<string?> GenerateProductDescriptionAsync(string? productName, CancellationToken cancellationToken)
    {
        var endpoint = File.ReadAllText("/mnt/secrets-store-foundry/FoundryEndpoint").Trim();
        var apiKey = File.ReadAllText("/mnt/secrets-store-foundry-api-key/FoundryApiKey").Trim();
        var deployment = File.ReadAllText("/mnt/secrets-store-foundry-model-deployment/FoundryModelDeployment").Trim();

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"{endpoint.TrimEnd('/')}/openai/v1/chat/completions");
        request.Headers.Add("api-key", apiKey);
        request.Content = JsonContent.Create(new
        {
            model = deployment,
            messages = new[]
            {
                new { role = "user", content = $"Write a compelling product description for: {productName}" }
            },
            max_tokens = 100,
            temperature = 0.7
        });

        using var response = await httpClient.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();

        using var document = JsonDocument.Parse(await response.Content.ReadAsStreamAsync(cancellationToken));
        return document.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString();
    }
}