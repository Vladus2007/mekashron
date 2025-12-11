# Базовый образ ASP.NET Core 10.0
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Устанавливаем SQLite
RUN apt-get update && apt-get install -y sqlite3 libsqlite3-dev && rm -rf /var/lib/apt/lists/*

# Этап сборки
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["MyProject1.csproj", "."]
RUN dotnet restore "./MyProject1.csproj"
COPY . .
RUN dotnet build "./MyProject1.csproj" -c Release -o /app/build

# Этап публикации
FROM build AS publish
RUN dotnet publish "./MyProject1.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Финальный этап
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Создаем директории с правильными правами ДО копирования файлов
RUN mkdir -p /app/wwwroot/media \
    && mkdir -p /app/wwwroot/umbraco \
    && mkdir -p /app/App_Data \
    && chmod -R 777 /app/App_Data \  # Временные права для отладки
    && chmod -R 777 /app/wwwroot/media

# Создаем SQLite файл заранее с правильными правами
RUN touch /app/App_Data/Umbraco.sqlite.db \
    && chmod 666 /app/App_Data/Umbraco.sqlite.db

ENTRYPOINT ["dotnet", "MyProject1.dll"]