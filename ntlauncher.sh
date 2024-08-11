#!/bin/bash

# Цветовые переменные
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m' # Без цвета

# Конфигурация
PIPE=/tmp/minecraft_pipe
SERVER_MEMORY=1024
SERVER_DIR=""  # Переменная для хранения пути к серверу

# Убедитесь, что PIPE существует
if [ ! -p "$PIPE" ]; then
    mkfifo "$PIPE"
fi

# Флаг для отслеживания состояния меню
in_menu=false

# Функция для отображения заголовка
show_header() {
    echo -e "${BLUE}+===========================================+${NC}"
    echo -e "${BLUE}|                                           |${NC}"
    echo -e "${BLUE}| ${WHITE}Naspeh Technologies${BLUE}               |${NC}"
    echo -e "${BLUE}|                                           |${NC}"
    echo -e "${BLUE}+===========================================+${NC}"
}

# Функция для запуска Minecraft сервера
start_minecraft_server() {
    SERVER_DIR=$1  # Сохраняем путь к серверу

    local server_jarfile="server.jar"  # Убедитесь, что jar-файл называется именно так в папке сервера

    if [ -d "$SERVER_DIR" ] && [ -f "$SERVER_DIR/$server_jarfile" ]; then
        cd "$SERVER_DIR" || exit 1
        show_header
        tail -f "$PIPE" | java -Xms128M -Xmx${SERVER_MEMORY}M -jar "$server_jarfile" nogui
    else
        echo -e "${RED}Ошибка: Указанная папка или jar-файл сервера не найдены.${NC}"
        exit 1
    fi
}

# Функция для предложения перезапуска после команды stop
prompt_restart() {
    echo -e "${YELLOW}Сервер остановлен. Запустить сервер снова? [y/n] (по умолчанию y через 5 секунд)${NC}"
    read -t 5 -p "$(echo -e "${RED}root@launcher:${NC}") " answer

    # Если ответ не был получен в течение 5 секунд, выбираем "y"
    answer=${answer:-y}

    if [[ $answer == "y" || $answer == "Y" ]]; then
        start_minecraft_server "$SERVER_DIR" &
    else
        echo -e "${YELLOW}Сервер не будет перезапущен.${NC}"
        exit 0
    fi
}

# Функция для показа меню NTLauncher
ntlauncher_menu() {
    in_menu=true
    show_header
    echo -e "${GREEN}+---------------------------+${NC}"
    echo -e "${GREEN}| ${WHITE} NTLauncher Menu ${GREEN}         |${NC}"
    echo -e "${GREEN}+---------------------------+${NC}"
    echo -e "${GREEN}| ${WHITE}1) Перезагрузить сервер  ${GREEN}|${NC}"
    echo -e "${GREEN}| ${WHITE}2) Вернуться к консоли   ${GREEN}|${NC}"
    echo -e "${GREEN}| ${WHITE}3) Выйти                 ${GREEN}|${NC}"
    echo -e "${GREEN}+---------------------------+${NC}"
    read -p "$(echo -e "${RED}root@launcher:${NC}") " choice

    case $choice in
        1)
            echo -e "${YELLOW}Перезагрузка Minecraft сервера...${NC}"
            pkill -f 'java -Xms'
            sleep 5
            start_minecraft_server "$SERVER_DIR" &
            ;;
        2)
            echo -e "${YELLOW}Возвращаемся к консоли сервера...${NC}"
            in_menu=false
            ;;
        3)
            echo -e "${YELLOW}Выход из меню NTLauncher...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}root@launcher: ${RED}Неверный выбор, попробуйте снова.${NC}"
            ;;
    esac
    # Возврат к командному режиму
    read -n 1 -s -r -p "$(echo -e "${RED}root@launcher:${NC}") Нажмите любую клавишу, чтобы продолжить..."
    in_menu=false
}

# Основной цикл для обработки команд
while true; do
    if [ "$in_menu" = true ]; then
        read -p "$(echo -e "${RED}root@launcher:${NC}") " input
    else
        read -p "" input
    fi

    if [[ "$input" =~ ^start[[:space:]]+(.+)$ ]]; then
        server_dir="${BASH_REMATCH[1]}"
        start_minecraft_server "$server_dir" &
    elif [ "$input" == "stop" ]; then
        echo "$input" > "$PIPE"
        sleep 5  # Ожидаем завершения сервера
        prompt_restart
    elif [ "$input" == "root@launcher" ] && [ "$in_menu" = false ]; then
        ntlauncher_menu
    else
        if [ "$in_menu" = false ]; then
            echo "$input" > "$PIPE"
        fi
    fi
done
