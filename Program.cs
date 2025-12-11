using Umbraco.Cms.Core;
using Umbraco.Cms.Web.Common.ApplicationBuilder;

var builder = WebApplication.CreateBuilder(args);

// Настройка путей для Render
var contentRootPath = builder.Environment.ContentRootPath;
var webRootPath = builder.Environment.WebRootPath;

Console.WriteLine($"Content Root: {contentRootPath}");
Console.WriteLine($"Web Root: {webRootPath}");

// Создаем необходимые директории при запуске
var directories = new[]
{
    Path.Combine(webRootPath, "media"),
    Path.Combine(webRootPath, "umbraco"),
    Path.Combine(contentRootPath, "App_Data"),
    Path.Combine(contentRootPath, "umbraco", "Logs"),
    Path.Combine(contentRootPath, "Data")
};

foreach (var directory in directories)
{
    if (!Directory.Exists(directory))
    {
        Directory.CreateDirectory(directory);
        Console.WriteLine($"Created directory: {directory}");
    }
}

// Проверяем и создаем SQLite базу данных
var dbPath = Path.Combine(contentRootPath, "App_Data", "Umbraco.sqlite.db");
if (!File.Exists(dbPath))
{
    Console.WriteLine($"SQLite database not found at: {dbPath}");
    Console.WriteLine("Umbraco will create it during installation");
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