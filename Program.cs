using Umbraco.Cms.Core;
using Umbraco.Cms.Web.Common.ApplicationBuilder;

var builder = WebApplication.CreateBuilder(args);

// Важно: НЕ создавайте директории в Program.cs!
// Umbraco сам создаст нужные директории через EssentialDirectoryCreator
// Удалите весь код создания директорий

// Просто логируем информацию для отладки
Console.WriteLine($"Content Root: {builder.Environment.ContentRootPath}");
Console.WriteLine($"Web Root: {builder.Environment.WebRootPath}");

// Настраиваем Umbraco - ТОЛЬКО ЭТО!
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