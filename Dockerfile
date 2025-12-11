# Базовый образ ASP.NET Core 10.0
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

# Устанавливаем SQLite и другие зависимости
RUN apt-get update && apt-get install -y \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Этап сборки
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Копируем и восстанавливаем зависимости
COPY ["MyProject1.csproj", "."]
RUN dotnet restore "./MyProject1.csproj"

# Копируем все файлы и собираем
COPY . .
RUN dotnet build "./MyProject1.csproj" -c Release -o /app/build

# Этап публикации
FROM build AS publish
RUN dotnet publish "./MyProject1.csproj" -c Release -o /app/publish \
    --no-restore \
    -p:UseAppHost=false \
    -p:EnableCompressionInSingleFile=true

# Финальный этап
FROM base AS final
WORKDIR /app

# Копируем опубликованные файлы
COPY --from=publish /app/publish .

# Создаем пользователя для безопасности
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# Создаем необходимые директории
RUN mkdir -p /app/wwwroot/media \
    && mkdir -p /app/wwwroot/umbraco \
    && mkdir -p /app/App_Data \
    && mkdir -p /app/Data \
    && chown -R appuser:appuser /app/wwwroot \
    && chown -R appuser:appuser /app/App_Data

# Устанавливаем правильные права для SQLite файла
RUN chmod 755 /app/App_Data

# Создаем entrypoint скрипт
RUN echo '#!/bin/sh\n\
# Создаем директории при запуске\n\
mkdir -p /app/wwwroot/media\n\
mkdir -p /app/wwwroot/umbraco\n\
mkdir -p /app/App_Data\n\
mkdir -p /app/Data\n\
\n\
# Устанавливаем правильные права\n\
chown -R appuser:appuser /app/wwwroot/media\n\
chown -R appuser:appuser /app/App_Data\n\
chmod -R 755 /app/wwwroot/media\n\
chmod -R 755 /app/App_Data\n\
\n\
# Переключаемся на непривилегированного пользователя\n\
exec dotnet MyProject1.dll "$@"' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

USER appuser

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]