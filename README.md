# NTLauncher

NTLauncher - это простой bash-скрипт для управления Minecraft сервером. Он предоставляет удобный интерфейс для запуска, перезапуска и остановки сервера через консольное меню. Скрипт легко настроить и использовать, обеспечивая базовые функции для повседневного администрирования сервера Minecraft.

## Основные функции

- **Интерактивное меню**: Доступно через команду `root@launcher`, позволяющее перезагружать сервер или выйти из меню.
- **Автоматический запуск сервера**: Скрипт запускает сервер автоматически при запуске скрипта.
- **Перезапуск сервера**: При остановке сервера, скрипт предложит перезапустить его.
- **Управление через консоль**: Команды могут быть отправлены непосредственно в консоль сервера для управления его состоянием.

## Как использовать

1. **Настройка**: Убедитесь, что у вас установлен Java. Вы можете проверить версию Java с помощью команды:
   ```bash
   java -version
   ```

2. **Скрипт**: Скачайте скрипт `ntlauncher.sh` и предоставьте ему права на выполнение:
   ```bash
   chmod +x ntlauncher.sh
   ```

3. **Запуск**:
   - **Запустите скрипт**: Запустите скрипт, и он начнет автоматический запуск сервера и ожидание команд:
     ```bash
     ./ntlauncher.sh
     ```

4. **Команды**:
   - **`stop`**: Останавливает сервер и предлагает перезапустить его.
   - **`root@launcher`**: Введите эту команду, чтобы вызвать интерактивное меню NTLauncher.

5. **Меню NTLauncher**:
   - **1) Перезапустить сервер**: Перезагружает сервер, останавливая его и снова запуская.
   - **2) Выйти**: Выход из меню NTLauncher.

## Конфигурация

- **`SCRIPT_NAME`**: Имя скрипта (по умолчанию `ntlauncher.sh`).
- **`PIPE`**: Путь к именованному каналу (по умолчанию `/tmp/minecraft_pipe`).
- **`SERVER_JARFILE`**: Имя JAR-файла сервера (по умолчанию `server.jar`).
- **`SERVER_MEMORY`**: Память для выделения серверу (по умолчанию `1024M`).

## Примечания

- Убедитесь, что у вас есть соответствующие права для запуска серверных процессов.
- Папка с сервером должна содержать JAR-файл сервера с именем, указанным в переменной `SERVER_JARFILE`.

## Контрибьюции

Если у вас есть предложения по улучшению или исправлению ошибок, пожалуйста, создайте запрос на изменение (pull request) или откройте проблему (issue) на [странице репозитория](https://github.com/ваш_проект/NTLauncher).

## Лицензия

Этот проект лицензирован под лицензией MIT. Подробности смотрите в файле `LICENSE`.
