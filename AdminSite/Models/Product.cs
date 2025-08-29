namespace AdminSite.Models
{
    public class Product
    {
    public string id { get; set; } = string.Empty; // CosmosDB requires lowercase 'id' as string
    public string? Name { get; set; }
    public string? Description { get; set; }
    public decimal Price { get; set; }
    [System.Text.Json.Serialization.JsonConverter(typeof(JsonBase64ByteArrayConverter))]
    public byte[]? ImageData { get; set; } // Store image as byte array
    public int Quantity { get; set; }
    }
}
