namespace AdminSite.Models;

public class Order
{
    public string id { get; set; } = string.Empty;
    public List<CartItem> Items { get; set; } = new();
    public decimal Total { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class CartItem
{
    public Product Product { get; set; } = new();
    public int Quantity { get; set; } = 1;
}
