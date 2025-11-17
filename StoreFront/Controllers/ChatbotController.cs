using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace StoreFront.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatbotController : ControllerBase
    {
    private readonly ILogger<ChatbotController> _logger;

    public ChatbotController(ILogger<ChatbotController> logger)
        {
            _logger = logger;
        }
    [HttpPost]
    public async Task<IActionResult> Post([FromBody] ChatbotRequest request)
    {
            _logger.LogInformation($"ChatbotController: Received POST /api/chatbot request. Question: {request?.Question}");
            try
            {
                try {
                    _logger.LogInformation("ChatbotController: Reading OpenAI secrets from mounted files...");
                    string endpoint = System.IO.File.ReadAllText("/mnt/secrets-store-openai/OpenAIEndpoint").Trim();
                    string apiKey = System.IO.File.ReadAllText("/mnt/secrets-store-openai-key/OpenAIAPIKey").Trim();
                    string deployment = System.IO.File.ReadAllText("/mnt/secrets-store-openai-deployment/OpenAIDeploymentName").Trim();
                    _logger.LogInformation($"ChatbotController: endpoint={endpoint}, deployment={deployment}, apiKey length={apiKey?.Length}");

                    using var client = new HttpClient();
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
                    var url = $"{endpoint}/openai/deployments/{deployment}/chat/completions?api-version=2023-03-15-preview";
                    _logger.LogInformation($"ChatbotController: OpenAI request URL: {url}");
                    var payload = new
                    {
                        messages = new[] {
                            new { role = "system", content = "You are a helpful assistant for the StoreFront. Only answer questions about furniture products sold in the store. If asked about anything else, reply: 'Sorry, I can only answer questions about furniture products.'" },
                            new { role = "user", content = request.Question }
                        },
                        max_tokens = 256
                    };
                    var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
                    var response = await client.PostAsync(url, content);
                    _logger.LogInformation($"ChatbotController: OpenAI response status code: {response.StatusCode}");
                    response.EnsureSuccessStatusCode();
                    var json = await response.Content.ReadAsStringAsync();
                    _logger.LogInformation($"ChatbotController: OpenAI response JSON: {json}");
                    using var doc = JsonDocument.Parse(json);
                    var answer = doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString();
                    _logger.LogInformation($"ChatbotController: OpenAI answer: {answer}");
                    return Ok(new ChatbotResponse { Answer = answer ?? "Sorry, I couldn't answer your question." });
                } catch (Exception innerEx) {
                    _logger.LogError(innerEx, "ChatbotController: Error reading secrets or calling OpenAI API");
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing chatbot request");
                return StatusCode(500, new ChatbotResponse { Answer = "Sorry, there was an error processing your request." });
            }
        }
    }

    public class ChatbotRequest
    {
        public string Question { get; set; }
    }
    public class ChatbotResponse
    {
        public string Answer { get; set; }
    }
}
