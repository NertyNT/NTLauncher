#!/bin/bash

# Память для сервера Minecraft в МБ
SERVER_MEMORY=2048
SERVER_JARFILE="server.jar"

# Путь к именованному каналу
PIPE="/tmp/minecraft_pipe"

# Создаем именованный канал, если он не существует
if [[ ! -p $PIPE ]]; then
    mkfifo $PIPE
fi

# Функция для запуска Minecraft сервера
start_minecraft_server() {
    tail -f $PIPE | java -Xms128M -Xmx${SERVER_MEMORY}M -jar ${SERVER_JARFILE} nogui
}

# Функция для меню NTLauncher
ntlauncher_menu() {
    clear
    echo "=========================="
    echo " NTLauncher Menu"
    echo "=========================="
    echo "1) Перезагрузить Minecraft сервер"
    echo "2) Вернуться к консоли сервера"
    echo "3) Выйти"
    echo "=========================="
    read -p "Выберите действие [1-3]: " choice

    case $choice in
        1)
            echo "Перезагрузка Minecraft сервера..."
            pkill -f 'java -Xms'
            sleep 5
            start_minecraft_server &
            ;;
        2)
            echo "Возвращаемся к консоли сервера..."
            ;;
        3)
            echo "Выход из меню NTLauncher..."
            exit 0
            ;;
        *)
            echo "Неверный выбор, попробуйте снова."
            ;;
    esac
    read -n 1 -s -r -p "Нажмите любую клавишу, чтобы продолжить..."
}

# Функция для предложения перезапуска после команды stop
prompt_restart() {
    echo "Сервер остановлен. Запустить сервер снова? [y/n] (по умолчанию y через 5 секунд)"
    read -t 5 -p "Ваш выбор: " answer

    # Если ответ не был получен в течение 5 секунд, выбираем "y"
    answer=${answer:-y}

    if [[ $answer == "y" || $answer == "Y" ]]; then
        start_minecraft_server &
    else
        echo "Сервер не будет перезапущен."
        exit 0
    fi
}

# Запуск Minecraft сервера в фоновом режиме
start_minecraft_server &

# Основной цикл для обработки команд
while true; do
    read -p "" input
    if [ "$input" == "root@launcher" ]; then
        ntlauncher_menu
    else
        if [ "$input" == "stop" ]; then
            echo "$input" > $PIPE
            sleep 5  # Ожидаем завершения сервера
            prompt_restart
        else
            echo "$input" > $PIPE
        fi
    fi
done
