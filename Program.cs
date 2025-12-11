var builder = WebApplication.CreateBuilder(args);

// Создаем директории при запуске
var contentRootPath = builder.Environment.ContentRootPath;
var webRootPath = builder.Environment.WebRootPath;

Console.WriteLine("Creating directories...");

try
{
    // App_Data для SQLite
    var appDataPath = Path.Combine(contentRootPath, "App_Data");
    if (!Directory.Exists(appDataPath))
    {
        Directory.CreateDirectory(appDataPath);
        Console.WriteLine($"Created: {appDataPath}");
    }

    // Media directory
    var mediaPath = Path.Combine(webRootPath, "media");
    if (!Directory.Exists(mediaPath))
    {
        Directory.CreateDirectory(mediaPath);
        Console.WriteLine($"Created: {mediaPath}");
    }

    // Проверяем права
    File.WriteAllText(Path.Combine(appDataPath, "test.txt"), "test");
    File.Delete(Path.Combine(appDataPath, "test.txt"));
    Console.WriteLine("Write permission OK");
}
catch (Exception ex)
{
    Console.WriteLine($"Directory error: {ex.Message}");
}

// Настраиваем Umbraco
builder.CreateUmbracoBuilder()
    .AddBackOffice()
    .AddWebsite()
    .AddDeliveryApi()
    .AddComposers()
    .Build();

var app = builder.Build();

await app.BootUmbracoAsync();

app.UseUmbraco()
    .WithMiddleware(u =>
    {
        u.UseBackOffice();
        u.UseWebsite();
    })
    .WithEndpoints(u =>
    {
        u.UseBackOfficeEndpoints();
        u.UseWebsiteEndpoints();
    });

await app.RunAsync();