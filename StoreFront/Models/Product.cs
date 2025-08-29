namespace StoreFront.Models;

public class Product
{
    public string id { get; set; } = string.Empty;
    public string? Name { get; set; }
    public string? Description { get; set; }
    public decimal Price { get; set; }
    [System.Text.Json.Serialization.JsonConverter(typeof(JsonBase64ByteArrayConverter))]
    public byte[]? ImageData { get; set; }
    public int Quantity { get; set; }
}
