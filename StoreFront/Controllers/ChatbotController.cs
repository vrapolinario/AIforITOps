using Microsoft.AspNetCore.Mvc;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;

namespace StoreFront.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatbotController : ControllerBase
    {
        private readonly ILogger<ChatbotController> _logger;
        private readonly HttpClient _httpClient;

        public ChatbotController(ILogger<ChatbotController> logger, HttpClient httpClient)
        {
            _logger = logger;
            _httpClient = httpClient;
        }
    [HttpPost]
    public async Task<IActionResult> Post([FromBody] ChatbotRequest request)
    {
            if (string.IsNullOrWhiteSpace(request?.Question))
            {
                return BadRequest(new ChatbotResponse { Answer = "Please enter a question." });
            }

            _logger.LogInformation("ChatbotController: Received POST /api/chatbot request");
            try
            {
                try {
                    _logger.LogInformation("ChatbotController: Reading Foundry secrets from mounted files...");
                    string endpoint = System.IO.File.ReadAllText("/mnt/secrets-store-foundry/FoundryEndpoint").Trim();
                    string apiKey = System.IO.File.ReadAllText("/mnt/secrets-store-foundry-api-key/FoundryApiKey").Trim();
                    string deployment = System.IO.File.ReadAllText("/mnt/secrets-store-foundry-model-deployment/FoundryModelDeployment").Trim();
                    var url = $"{endpoint.TrimEnd('/')}/openai/v1/chat/completions";
                    _logger.LogInformation("ChatbotController: Calling Foundry model deployment {Deployment}", deployment);
                    var payload = new
                    {
                        model = deployment,
                        messages = new[] {
                            new { role = "system", content = "You are a helpful assistant for the StoreFront. Only answer questions about furniture products sold in the store. If asked about anything else, reply: 'Sorry, I can only answer questions about furniture products.'" },
                            new { role = "user", content = request.Question }
                        },
                        max_tokens = 256
                    };
                    using var message = new HttpRequestMessage(HttpMethod.Post, url);
                    message.Headers.Add("api-key", apiKey);
                    message.Content = JsonContent.Create(payload);
                    using var response = await _httpClient.SendAsync(message, HttpContext.RequestAborted);
                    _logger.LogInformation("ChatbotController: Foundry response status code: {StatusCode}", response.StatusCode);
                    response.EnsureSuccessStatusCode();
                    var json = await response.Content.ReadAsStringAsync();
                    using var doc = JsonDocument.Parse(json);
                    var answer = doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString();
                    _logger.LogInformation("ChatbotController: Foundry model returned an answer");
                    return Ok(new ChatbotResponse { Answer = answer ?? "Sorry, I couldn't answer your question." });
                } catch (Exception innerEx) {
                    _logger.LogError(innerEx, "ChatbotController: Error reading secrets or calling the Foundry model");
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
        public string Question { get; set; } = string.Empty;
    }
    public class ChatbotResponse
    {
        public string Answer { get; set; } = string.Empty;
    }
}
