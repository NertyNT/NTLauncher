#!/bin/bash

# Путь к директории вашего Minecraft сервера
SERVER_DIR="/path/to/your/minecraft/server"

# Имя jar-файла сервера
SERVER_JAR="server.jar"

# Минимальное и максимальное количество выделенной памяти (например, 1G и 2G)
MIN_MEMORY="1G"
MAX_MEMORY="2G"

# Лог-файл для записи вывода сервера (опционально)
LOG_FILE="server.log"

# Переходим в директорию сервера
cd "$SERVER_DIR" || { echo "Не удалось найти директорию $SERVER_DIR"; exit 1; }

# Запуск сервера с выделением памяти и записью лога (если указано)
echo "Запуск Minecraft сервера..."
java -Xms$MIN_MEMORY -Xmx$MAX_MEMORY -jar $SERVER_JAR nogui | tee -a $LOG_FILE

# Если нужен автоперезапуск сервера при его завершении (например, при сбое), добавьте этот цикл:
# while true
# do
#     echo "Запуск Minecraft сервера..."
#     java -Xms$MIN_MEMORY -Xmx$MAX_MEMORY -jar $SERVER_JAR nogui | tee -a $LOG_FILE
#     echo "Сервер завершил работу. Перезапуск через 10 секунд..."
#     sleep 10
# done
