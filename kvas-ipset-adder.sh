#!/opt/bin/bash

REPO_URL="https://github.com/GhostRooter0953/discord-voice-ips/archive/refs/heads/light.zip"
DEST_DIR="/opt/tmp"
ZIP_FILE="$DEST_DIR/light.zip"
EXTRACTED_DIR="$DEST_DIR/discord-voice-ips-light"

ARGUMENT="${1:-auto}"

if [ -z "$1" ]; then
    read -p "Какой IPset лист используем? (по умолчанию будет использоваться 'unblock'): " NEW_ARG
    if [ -n "$NEW_ARG" ]; then
        ARGUMENT="$NEW_ARG"
    fi
fi

if [ "$ARGUMENT" = "auto" ]; then
    SCRIPT_TO_RUN="ipset-adder.sh auto"
else
    SCRIPT_TO_RUN="ipset-adder.sh list $ARGUMENT"
fi

CRON_SHELL_PATH="SHELL=/opt/bin/bash"
CRON_PATH="PATH=/opt/bin:/usr/sbin:/usr/bin:/bin:/sbin:/opt/sbin"

if [ -d "$EXTRACTED_DIR" ]; then
    rm -rf "$EXTRACTED_DIR" > /dev/null 2>&1
fi

echo "Скачивание $REPO_URL..."
curl -L -o "$ZIP_FILE" "$REPO_URL" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Ошибка при загрузке репозитория"
    exit 1
fi

echo "Распаковка $ZIP_FILE в $DEST_DIR..."
unzip -o "$ZIP_FILE" -d "$DEST_DIR" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Ошибка при распаковке репозитория"
    exit 1
fi

rm "$ZIP_FILE" > /dev/null 2>&1

echo "Выдача прав на выполнение скриптов..."
find "$EXTRACTED_DIR" -type f -name "*.sh" | while read SCRIPT_FILE; do
    chmod +x "$SCRIPT_FILE"
    sed -i '1s|^#!.*|#!/opt/bin/bash|' "$SCRIPT_FILE"
done

CRONTAB_OUTPUT=$(crontab -l 2>/dev/null)

if ! echo "$CRONTAB_OUTPUT" | grep -qF "$CRON_SHELL_PATH"; then
    CRONTAB_OUTPUT="$CRON_SHELL_PATH"$'\n'"$CRONTAB_OUTPUT"
fi

if ! echo "$CRONTAB_OUTPUT" | grep -qF "$CRON_PATH"; then
    CRONTAB_OUTPUT="$CRON_PATH"$'\n'"$CRONTAB_OUTPUT"
fi

REBOOT_CRON_ENTRY="@reboot cd $EXTRACTED_DIR && /opt/bin/bash $SCRIPT_TO_RUN"
MIDNIGHT_CRON_ENTRY="0 0 * * * cd $EXTRACTED_DIR && /opt/bin/bash $SCRIPT_TO_RUN"

MIDNIGHT_CRON_EXISTS=false
REBOOT_CRON_EXISTS=false

if echo "$CRONTAB_OUTPUT" | grep -qF "$MIDNIGHT_CRON_ENTRY"; then
    MIDNIGHT_CRON_EXISTS=true
fi

if echo "$CRONTAB_OUTPUT" | grep -qF "$REBOOT_CRON_ENTRY"; then
    REBOOT_CRON_EXISTS=true
fi

if $MIDNIGHT_CRON_EXISTS && $REBOOT_CRON_EXISTS; then
    echo "Задания на авто-импорт списков в IPset уже существуют в crontab (полночь и при перезагрузке)"
else
    echo "Некоторые или все задания на авто-импорт списков в IPset отсутствуют"
    echo "Выберите, какие задания вы хотите добавить:"
    OPTIONS=()
    if ! $MIDNIGHT_CRON_EXISTS && ! $REBOOT_CRON_EXISTS; then
        echo "1. Полночь каждый день"
        echo "2. При перезагрузке"
        echo "3. Полночь каждый день и при перезагрузке"
        echo "0. Не добавлять"
        read -p "Введите номер варианта (0-3): " TIME_OPTION
        case $TIME_OPTION in
            1)
                CRONTAB_OUTPUT="$CRONTAB_OUTPUT"$'\n'"$MIDNIGHT_CRON_ENTRY"
                echo "Задание добавлено: выполнение каждый день в 00:00 MSK"
                ;;
            2)
                CRONTAB_OUTPUT="$CRONTAB_OUTPUT"$'\n'"$REBOOT_CRON_ENTRY"
                echo "Задание добавлено: выполнение при каждом перезапуске роутера"
                ;;
            3)
                CRONTAB_OUTPUT="$CRONTAB_OUTPUT"$'\n'"$MIDNIGHT_CRON_ENTRY"
                CRONTAB_OUTPUT="$CRONTAB_OUTPUT"$'\n'"$REBOOT_CRON_ENTRY"
                echo "Задания добавлены: выполнение каждый день в 00:00 MSK и при каждом перезапуске роутера"
                ;;
            0)
                echo "Задания не будут добавлены."
                ;;
            *)
                echo "Некорректный ввод. Задания не будут добавлены."
                ;;
        esac
    else
        if ! $MIDNIGHT_CRON_EXISTS; then
            echo "1. Добавить задание на выполнение каждый день в 00:00 по МСК"
        fi
        if ! $REBOOT_CRON_EXISTS; then
            echo "2. Добавить задание на выполнение при каждом перезапуске"
        fi
        echo "0. Не добавлять"
        read -p "Введите номер варианта: " TIME_OPTION
        case $TIME_OPTION in
            1)
                if ! $MIDNIGHT_CRON_EXISTS; then
                    CRONTAB_OUTPUT="$CRONTAB_OUTPUT"$'\n'"$MIDNIGHT_CRON_ENTRY"
                    echo "Задание добавлено: выполнение каждый день в 00:00 MSK"
                else
                    echo "Задание уже существует."
                fi
                ;;
            2)
                if ! $REBOOT_CRON_EXISTS; then
                    CRONTAB_OUTPUT="$CRONTAB_OUTPUT"$'\n'"$REBOOT_CRON_ENTRY"
                    echo "Задание добавлено: выполнение при каждом перезапуске роутера"
                else
                    echo "Задание уже существует."
                fi
                ;;
            0)
                echo "Задания не будут добавлены."
                ;;
            *)
                echo "Некорректный ввод. Задания не будут добавлены."
                ;;
        esac
    fi

    if [[ "$TIME_OPTION" =~ ^[1-3]$ ]]; then
        echo "$CRONTAB_OUTPUT" | crontab -
    fi
fi

read -p "Импортируем списки в IPset лист сейчас? (y/n): " RUN_NOW

if [[ $RUN_NOW =~ ^[Yy]$ ]]; then
    echo "Запуск импорта..."
    cd "$EXTRACTED_DIR"
    /opt/bin/bash $SCRIPT_TO_RUN
else
    echo "Пропускаем импорт..."
fi

echo "Приехали"
