var builder = WebApplication.CreateBuilder(args);

// Создаем необходимые директории для Umbraco
var mediaPath = Path.Combine(builder.Environment.WebRootPath, "media");
var appDataPath = Path.Combine(builder.Environment.ContentRootPath, "App_Data");

if (!Directory.Exists(mediaPath))
    Directory.CreateDirectory(mediaPath);
if (!Directory.Exists(appDataPath))
    Directory.CreateDirectory(appDataPath);

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