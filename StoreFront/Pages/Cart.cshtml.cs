using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using StoreFront.Models;

namespace StoreFront.Pages;


public class CartModel : PageModel
{
    public List<StoreFront.Models.CartItem> CartItems { get; set; } = new();

    public void OnGet()
    {
        CartItems = GetCartFromSession();
    }

    public IActionResult OnPostIncrease(string id)
    {
        var cart = GetCartFromSession();
        var item = cart.FirstOrDefault(i => i.Product.id == id);
        if (item != null)
            item.Quantity++;
        SaveCartToSession(cart);
        return RedirectToPage();
    }

    public IActionResult OnPostRemove(string id)
    {
    var cart = GetCartFromSession();
    cart.RemoveAll(i => i.Product.id == id);
    SaveCartToSession(cart);
    return RedirectToPage();
    }

    public IActionResult OnPostCheckout()
    {
        // Checkout logic: save order to CosmosDB
        var cart = GetCartFromSession();
        // Diagnostic logging for image data
        foreach (var item in cart)
        {
            var imgLen = item.Product.ImageData != null ? item.Product.ImageData.Length : 0;
            System.Diagnostics.Debug.WriteLine($"[CHECKOUT] Product ID: {item.Product.id}, ImageData Length: {imgLen}");
        }
        if (cart.Count > 0)
        {
            var connStr = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
            var dbName = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
            var ordersContainerName = Environment.GetEnvironmentVariable("ORDERS_CONTAINER_NAME");
            var client = new Microsoft.Azure.Cosmos.CosmosClient(connStr);
            var container = client.GetContainer(dbName, ordersContainerName);
            var order = new Models.Order
            {
                id = Guid.NewGuid().ToString(),
                Items = cart,
                Total = cart.Sum(i => i.Product.Price * i.Quantity),
                CreatedAt = DateTime.UtcNow
            };
            container.UpsertItemAsync(order, new Microsoft.Azure.Cosmos.PartitionKey(order.id)).GetAwaiter().GetResult();

            // Prepare lightweight DTO for Service Bus
            var orderMessage = new OrderMessageDTO
            {
                id = order.id,
                Total = order.Total,
                CreatedAt = order.CreatedAt,
                Items = order.Items.Select(i => new OrderProductDTO
                {
                    ProductId = i.Product.id,
                    Quantity = i.Quantity
                }).ToList()
            };

            var serviceBusConnStr = System.IO.File.ReadAllText("/mnt/secrets-store-sb/ServiceBusConnectionString");
            var queueName = Environment.GetEnvironmentVariable("SERVICEBUS_QUEUE_NAME");
            if (!string.IsNullOrEmpty(serviceBusConnStr) && !string.IsNullOrEmpty(queueName))
            {
                var clientBus = new Azure.Messaging.ServiceBus.ServiceBusClient(serviceBusConnStr);
                var sender = clientBus.CreateSender(queueName);
                var orderJson = System.Text.Json.JsonSerializer.Serialize(orderMessage);
                var message = new Azure.Messaging.ServiceBus.ServiceBusMessage(orderJson);
                sender.SendMessageAsync(message).GetAwaiter().GetResult();
            }
        }
        SaveCartToSession(new List<CartItem>());
        return RedirectToPage();
    }

    private List<CartItem> GetCartFromSession()
    {
    var cartJson = HttpContext.Session.GetString("Cart");
    return cartJson != null ? System.Text.Json.JsonSerializer.Deserialize<List<StoreFront.Models.CartItem>>(cartJson) ?? new() : new();
    }

    private void SaveCartToSession(List<CartItem> cart)
    {
    var cartJson = System.Text.Json.JsonSerializer.Serialize(cart);
    HttpContext.Session.SetString("Cart", cartJson);
    }
}
