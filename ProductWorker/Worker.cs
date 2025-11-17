using System.Text.Json.Serialization;
using System.Text.Json.Serialization;
namespace ProductWorker;


public class Worker : BackgroundService
{
    private readonly ILogger<Worker> _logger;

    public Worker(ILogger<Worker> logger)
    {
        _logger = logger;
    }

    private Azure.Messaging.ServiceBus.ServiceBusProcessor _processor;
    private Microsoft.Azure.Cosmos.CosmosClient _cosmosClient;
    private Microsoft.Azure.Cosmos.Container _productsContainer;
    private Microsoft.Azure.Cosmos.Container _ordersContainer;
    private Microsoft.Azure.Cosmos.Container _container; // legacy

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
    var sbConn = System.IO.File.ReadAllText("/mnt/secrets-store-sb/ServiceBusConnectionString");
    var sbQueue = Environment.GetEnvironmentVariable("SERVICEBUS_QUEUE_NAME");
    var cosmosConn = System.IO.File.ReadAllText("/mnt/secrets-store/CosmosDBConnectionString");
    var cosmosDb = Environment.GetEnvironmentVariable("COSMOSDB_DATABASE_NAME");
    var productsContainerName = Environment.GetEnvironmentVariable("PRODUCTS_CONTAINER_NAME");
    var ordersContainerName = Environment.GetEnvironmentVariable("ORDERS_CONTAINER_NAME");

    var client = new Azure.Messaging.ServiceBus.ServiceBusClient(sbConn);
    _processor = client.CreateProcessor(sbQueue, new Azure.Messaging.ServiceBus.ServiceBusProcessorOptions());
    _processor.ProcessMessageAsync += MessageHandler;
    _processor.ProcessErrorAsync += ErrorHandler;
    await _processor.StartProcessingAsync(stoppingToken);

    _cosmosClient = new Microsoft.Azure.Cosmos.CosmosClient(cosmosConn);
    _productsContainer = _cosmosClient.GetContainer(cosmosDb, productsContainerName);
    _ordersContainer = _cosmosClient.GetContainer(cosmosDb, ordersContainerName);
    _container = _productsContainer; // For legacy code, but update usages below

        // Keep the worker running until cancellation is requested
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(1000, stoppingToken);
        }
    }

    private async Task MessageHandler(Azure.Messaging.ServiceBus.ProcessMessageEventArgs args)
    {
        var body = args.Message.Body.ToString();
        _logger.LogInformation($"Received Service Bus message: {body}");
        // Try to deserialize as Order message first
        try
        {
            var order = System.Text.Json.JsonSerializer.Deserialize<OrderMessageDTO>(body);
            if (order != null && order.Items != null)
            {
                // Save order to Orders container
                await _ordersContainer.UpsertItemAsync(order);
                foreach (var item in order.Items)
                {
                    _logger.LogInformation($"Processing order item: ProductId={item.ProductId}, Quantity={item.Quantity}");
                    // Get product from Products container
                    var response = await _productsContainer.ReadItemAsync<Product>(item.ProductId, new Microsoft.Azure.Cosmos.PartitionKey(item.ProductId));
                    var product = response.Resource;
                    // Decrement quantity
                    int oldQty = product.Quantity;
                    product.Quantity -= item.Quantity;
                    if (product.Quantity < 0) product.Quantity = 0;
                    await _productsContainer.UpsertItemAsync(product);
                    _logger.LogInformation($"Updated inventory: ProductId={product.id}, OldQty={oldQty}, NewQty={product.Quantity}");
                }
                await args.CompleteMessageAsync(args.Message);
                _logger.LogInformation("Order processed and inventory updated.");
                return;
            }
        }
        catch (Exception ex) { _logger.LogError(ex, "Error processing order message"); }

        var msg = System.Text.Json.JsonSerializer.Deserialize<ProductMessage>(body);
        if (msg != null)
        {
            _logger.LogInformation($"Processing product message: Action={msg.Action}, ProductId={msg.Product.id}");
            switch (msg.Action)
            {
                case "Add":
                case "Edit":
                    await _productsContainer.UpsertItemAsync(msg.Product);
                    _logger.LogInformation($"Product upserted: ProductId={msg.Product.id}");
                    break;
                case "Delete":
                    await _productsContainer.DeleteItemAsync<Product>(msg.Product.id, new Microsoft.Azure.Cosmos.PartitionKey(msg.Product.id));
                    _logger.LogInformation($"Product deleted: ProductId={msg.Product.id}");
                    break;
            }
        }
        await args.CompleteMessageAsync(args.Message);
    }

    private Task ErrorHandler(Azure.Messaging.ServiceBus.ProcessErrorEventArgs args)
    {
        _logger.LogError(args.Exception, "Service Bus error");
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_processor != null)
            await _processor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
    }

    public class ProductMessage
    {
        public string Action { get; set; }
        public Product Product { get; set; }
    }

    public class Product
    {
    public string id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public decimal Price { get; set; }
    [JsonConverter(typeof(JsonBase64ByteArrayConverter))]
    public byte[] ImageData { get; set; }
    public int Quantity { get; set; }
    }

    public class OrderMessageDTO
    {
        public string id { get; set; }
        public List<OrderProductDTO> Items { get; set; }
        public decimal Total { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class OrderProductDTO
    {
        public string ProductId { get; set; }
        public int Quantity { get; set; }
    }
}
