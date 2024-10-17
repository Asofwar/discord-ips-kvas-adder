#!/opt/bin/bash

REPO_URL="https://github.com/GhostRooter0953/discord-voice-ips/archive/refs/heads/light.zip"
DEST_DIR="/opt/tmp"
ZIP_FILE="$DEST_DIR/light.zip"
EXTRACTED_DIR="$DEST_DIR/discord-voice-ips-light"
SCRIPT_TO_RUN="ipset-adder.sh auto"

CRON_SHELL_PATH="SHELL=/opt/bin/bash"
CRON_PATH="PATH=/opt/bin:/usr/sbin:/usr/bin:/bin:/sbin:/opt/sbin"

if [ -d "$EXTRACTED_DIR" ]; then
    rm -rf "$EXTRACTED_DIR" > /dev/null 2>&1
fi

echo "Скачивание $REPO_URL..."
curl -L -o "$ZIP_FILE" "$REPO_URL" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Ошибка при скачивании файла."
    exit 1
fi

echo "Распаковка $ZIP_FILE в $DEST_DIR..."
unzip -o "$ZIP_FILE" -d "$DEST_DIR" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Ошибка при распаковке архива."
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

if echo "$CRONTAB_OUTPUT" | grep -qF "$REBOOT_CRON_ENTRY" || echo "$CRONTAB_OUTPUT" | grep -qF "$MIDNIGHT_CRON_ENTRY"; then
    echo "Задание на импорт списков в ipset уже существует в crontab."
else
    read -p "Задание на импорт списков в ipset не найдено. Добавляем? (y/n): " ADD_JOB

    if [[ $ADD_JOB =~ ^[Yy]$ ]]; then
        read -p "Когда выполнять задачу? (введите 'midnight' для выполнения в 00:00 по МСК или 'reboot' для выполнения при каждом перезапуске сервера): " TIME_OPTION

        if [[ $TIME_OPTION == "midnight" ]]; then
            CRON_ENTRY="$MIDNIGHT_CRON_ENTRY"
            CRONTAB_OUTPUT="$CRONTAB_OUTPUT"$'\n'"$CRON_ENTRY"
            echo "Задание добавлено: выполнение каждый день в полночь по МСК."
        elif [[ $TIME_OPTION == "reboot" ]]; then
            CRON_ENTRY="$REBOOT_CRON_ENTRY"
            CRONTAB_OUTPUT="$CRONTAB_OUTPUT"$'\n'"$CRON_ENTRY"
            echo "Задание добавлено: выполнение при каждом перезапуске."
        else
            echo "Некорректный ввод. Задание не добавлено."
        fi

        echo "$CRONTAB_OUTPUT" | crontab -
    else
        echo "Задание не будет добавлено."
    fi
fi

echo "Приехали."
