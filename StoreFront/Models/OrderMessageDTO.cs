namespace StoreFront.Models
{
    public class OrderMessageDTO
    {
        public string id { get; set; } = string.Empty;
        public List<OrderProductDTO> Items { get; set; } = new();
        public decimal Total { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class OrderProductDTO
    {
        public string ProductId { get; set; } = string.Empty;
        public int Quantity { get; set; }
    }
}
