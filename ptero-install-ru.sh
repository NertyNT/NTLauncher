#!/bin/bash
# ============================================================
#  Pterodactyl Panel + Wings — Russian-friendly installer
#  - Яндекс зеркало вместо archive.ubuntu.com
#  - Без PPA ondrej (PHP 8.1 из стандартных реп Ubuntu 22.04)
#  - Часовой пояс: Europe/Moscow (авто)
#  - Регион Wings: ru (авто)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
info() { echo -e "${CYAN}[..] $*${NC}"; }
warn() { echo -e "${YELLOW}[!!] $*${NC}"; }
err()  { echo -e "${RED}[ERR] $*${NC}"; exit 1; }

# ── Root check ───────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "Запусти скрипт от root: sudo bash ptero-install-ru.sh"

# ── Ubuntu 22.04 check ───────────────────────────────────────
. /etc/os-release
[[ "$VERSION_ID" != "22.04" ]] && err "Скрипт рассчитан на Ubuntu 22.04 (у тебя $VERSION_ID)"

# ── Banner ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Pterodactyl RU Installer — Panel + Wings         ║${NC}"
echo -e "${CYAN}║     Зеркало: Яндекс МСК | PHP 8.1 | TZ: Moscow      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Сбор параметров ──────────────────────────────────────────
read -rp "Домен панели (например: panel.example.com): " PANEL_DOMAIN
[[ -z "$PANEL_DOMAIN" ]] && err "Домен не может быть пустым"

read -rp "E-mail администратора: " ADMIN_EMAIL
[[ -z "$ADMIN_EMAIL" ]] && err "Email не может быть пустым"

read -rp "Имя пользователя администратора: " ADMIN_USER
[[ -z "$ADMIN_USER" ]] && err "Имя пользователя не может быть пустым"

read -rp "Имя администратора (First name): " ADMIN_FIRSTNAME
read -rp "Фамилия администратора (Last name): " ADMIN_LASTNAME

while true; do
    read -rsp "Пароль администратора (мин. 8 символов): " ADMIN_PASS; echo
    read -rsp "Повтори пароль: " ADMIN_PASS2; echo
    [[ "$ADMIN_PASS" == "$ADMIN_PASS2" && ${#ADMIN_PASS} -ge 8 ]] && break
    warn "Пароли не совпадают или слишком короткий. Попробуй ещё раз."
done

read -rp "Домен Wings (например: wings.example.com): " WINGS_DOMAIN
[[ -z "$WINGS_DOMAIN" ]] && err "Домен Wings не может быть пустым"

DB_PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)
info "Пароль БД сгенерирован автоматически: $DB_PASS"
echo ""

read -rp "Всё верно? Начать установку? (y/N): " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && err "Установка отменена"

# ── Яндекс зеркало ───────────────────────────────────────────
info "Настройка зеркала Яндекс МСК..."
cat > /etc/apt/sources.list << 'EOF'
deb http://mirror.yandex.ru/ubuntu jammy main restricted universe multiverse
deb http://mirror.yandex.ru/ubuntu jammy-updates main restricted universe multiverse
deb http://mirror.yandex.ru/ubuntu jammy-backports main restricted universe multiverse
deb http://mirror.yandex.ru/ubuntu jammy-security main restricted universe multiverse
EOF

# Убираем старый ondrej PPA если остался
rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list
ok "Зеркало настроено"

# ── apt update ───────────────────────────────────────────────
info "Обновление пакетной базы..."
apt-get update -q
ok "Пакетная база обновлена"

# ── Зависимости ──────────────────────────────────────────────
info "Установка зависимостей..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
    curl wget git unzip tar \
    nginx \
    mariadb-server \
    redis-server \
    php8.1 php8.1-cli php8.1-common php8.1-gd php8.1-mysql \
    php8.1-mbstring php8.1-bcmath php8.1-xml php8.1-fpm \
    php8.1-curl php8.1-zip php8.1-intl php8.1-readline \
    ufw
ok "Зависимости установлены"

# ── Часовой пояс ─────────────────────────────────────────────
info "Установка часового пояса Europe/Moscow..."
timedatectl set-timezone Europe/Moscow
ok "Часовой пояс: $(timedatectl | grep 'Time zone')"

# ── Composer ─────────────────────────────────────────────────
if ! command -v composer &>/dev/null; then
    info "Установка Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    ok "Composer установлен"
fi

# ── MariaDB ──────────────────────────────────────────────────
info "Настройка MariaDB..."
systemctl enable --now mariadb

mysql -u root << SQL
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
ok "База данных настроена"

# ── Pterodactyl Panel ─────────────────────────────────────────
info "Скачивание Pterodactyl Panel..."
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -sLo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
ok "Panel скачана"

info "Установка PHP-зависимостей (Composer)..."
cp .env.example .env
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction -q
ok "Composer зависимости установлены"

info "Генерация ключа приложения..."
php artisan key:generate --force

info "Настройка .env..."
php artisan p:environment:setup \
    --author="$ADMIN_EMAIL" \
    --url="http://$PANEL_DOMAIN" \
    --timezone="Europe/Moscow" \
    --cache=redis \
    --session=redis \
    --queue=redis \
    --redis-host=127.0.0.1 \
    --redis-pass="" \
    --redis-port=6379 \
    --no-interaction

info "Настройка базы данных в .env..."
php artisan p:environment:database \
    --host=127.0.0.1 \
    --port=3306 \
    --database=panel \
    --username=pterodactyl \
    --password="$DB_PASS" \
    --no-interaction

info "Миграция базы данных..."
php artisan migrate --seed --force

info "Создание администратора..."
php artisan p:user:make \
    --email="$ADMIN_EMAIL" \
    --username="$ADMIN_USER" \
    --name-first="$ADMIN_FIRSTNAME" \
    --name-last="$ADMIN_LASTNAME" \
    --password="$ADMIN_PASS" \
    --admin=1 \
    --no-interaction

chown -R www-data:www-data /var/www/pterodactyl
ok "Panel настроена"

# ── Очередь (pteroq) ─────────────────────────────────────────
info "Настройка сервиса очереди..."
cat > /etc/systemd/system/pteroq.service << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now pteroq
ok "Очередь запущена"

# ── Cron ─────────────────────────────────────────────────────
info "Добавление крон-задачи..."
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
ok "Cron настроен"

# ── Nginx ────────────────────────────────────────────────────
info "Настройка Nginx..."
cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.access.log;
    error_log  /var/log/nginx/pterodactyl.error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
nginx -t && systemctl enable --now nginx && systemctl reload nginx
ok "Nginx настроен"

# ── UFW ──────────────────────────────────────────────────────
info "Настройка UFW..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
ufw allow 2022/tcp
echo "y" | ufw enable
ok "UFW настроен"

# ── Wings ─────────────────────────────────────────────────────
info "Установка Wings..."
mkdir -p /etc/pterodactyl /var/log/pterodactyl /tmp/pterodactyl

WINGS_URL=$(curl -s https://api.github.com/repos/pterodactyl/wings/releases/latest \
    | grep "browser_download_url" | grep "linux_amd64" | cut -d '"' -f 4)

curl -sLo /usr/local/bin/wings "$WINGS_URL"
chmod +x /usr/local/bin/wings
ok "Wings бинарник установлен"

info "Настройка сервиса Wings..."
cat > /etc/systemd/system/wings.service << 'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service network-online.target
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# ── Docker ────────────────────────────────────────────────────
info "Установка Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
ok "Docker установлен"

systemctl enable wings
ok "Wings установлен (конфигурацию добавь через панель)"

# ── Итог ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              УСТАНОВКА ЗАВЕРШЕНА!                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Панель:${NC}      http://$PANEL_DOMAIN"
echo -e "  ${CYAN}Логин:${NC}       $ADMIN_USER"
echo -e "  ${CYAN}Email:${NC}       $ADMIN_EMAIL"
echo -e "  ${CYAN}Пароль БД:${NC}   $DB_PASS"
echo -e "  ${CYAN}TZ:${NC}          Europe/Moscow"
echo ""
echo -e "  ${YELLOW}Следующий шаг:${NC}"
echo -e "  1. Зайди в панель → Admin → Nodes → Add Node"
echo -e "  2. Заполни данные Wings-сервера (домен: $WINGS_DOMAIN)"
echo -e "  3. Скопируй конфиг Wings из панели"
echo -e "  4. Вставь в /etc/pterodactyl/config.yml"
echo -e "  5. systemctl start wings"
echo ""
