#!/bin/bash

# Скрипт для запуска сервера с автоматическим освобождением порта

PORT=${PORT:-8080}

echo "🔍 Проверка порта $PORT..."

# Освободить порт если занят
if lsof -ti:$PORT > /dev/null; then
    echo "⚠️  Порт $PORT занят, освобождаю..."
    lsof -ti:$PORT | xargs kill -9 2>/dev/null
    sleep 1
fi

# Проверить что порт свободен
if lsof -ti:$PORT > /dev/null; then
    echo "❌ Не удалось освободить порт $PORT"
    echo "Пожалуйста, завершите процесс вручную:"
    echo "  lsof -ti:$PORT | xargs kill -9"
    exit 1
fi

echo "✅ Порт $PORT свободен"
echo "🚀 Запуск сервера..."
echo ""

# Запустить сервер
node server.js