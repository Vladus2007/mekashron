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

# ПРОВЕРЯЕМ существующих пользователей (для отладки)
RUN echo "Existing users:" && cat /etc/passwd | grep -E ":(1000|appuser):"

# Создаем пользователя только если его нет
RUN if ! id -u appuser >/dev/null 2>&1; then \
        useradd -m -u 1001 appuser; \
        echo "Created user appuser with UID 1001"; \
    else \
        echo "User appuser already exists"; \
    fi

# ИЛИ просто используем существующего пользователя (альтернатива)
# USER 1000:1000  # если пользователь с UID 1000 уже существует

# Создаем необходимые директории
RUN mkdir -p /app/wwwroot/media \
    && mkdir -p /app/wwwroot/umbraco \
    && mkdir -p /app/App_Data \
    && mkdir -p /app/Data

# Устанавливаем правильные права
RUN chown -R appuser:appuser /app \
    && chmod -R 755 /app/wwwroot/media \
    && chmod -R 755 /app/App_Data \
    && chmod -R 755 /app/wwwroot/umbraco

# Создаем entrypoint скрипт
RUN echo '#!/bin/sh\n\
set -e\n\
echo "Starting Umbraco with SQLite..."\n\
\n\
# Создаем директории при запуске если их нет\n\
for dir in /app/wwwroot/media /app/wwwroot/umbraco /app/App_Data /app/Data; do\n\
    if [ ! -d "\$dir" ]; then\n\
        mkdir -p "\$dir"\n\
        echo "Created directory: \$dir"\n\
    fi\n\
done\n\
\n\
# Устанавливаем правильные права\n\
chown -R appuser:appuser /app 2>/dev/null || true\n\
chmod -R 755 /app/wwwroot/media 2>/dev/null || true\n\
chmod -R 755 /app/App_Data 2>/dev/null || true\n\
\n\
echo "Running as user: \$(whoami)"\n\
echo "Current directory: \$(pwd)"\n\
echo "Directory contents:"\n\
ls -la\n\
\n\
# Запускаем приложение\n\
exec dotnet MyProject1.dll "\$@"' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

USER appuser

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]