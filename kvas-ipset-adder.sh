#!/opt/bin/bash

REPO_URL="https://github.com/GhostRooter0953/discord-voice-ips/archive/refs/heads/light.zip"
DEST_DIR="/opt/tmp"
ZIP_FILE="$DEST_DIR/light.zip"
EXTRACTED_DIR="$DEST_DIR/discord-voice-ips-light"
SCRIPT_TO_RUN="discord-voice-ips-light/ipset_adder.sh auto"

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

echo "Выдача прав на выполнение для всех .sh файлов и изменение первой строки..."
find "$EXTRACTED_DIR" -type f -name "*.sh" | while read SCRIPT_FILE; do
    chmod +x "$SCRIPT_FILE"

    sed -i '1s|^#!.*|#!/opt/bin/bash|' "$SCRIPT_FILE"
done

CRON_JOB="$SCRIPT_TO_RUN"
CRONTAB_OUTPUT=$(crontab -l 2>/dev/null)

if echo "$CRONTAB_OUTPUT" | grep -qF "$CRON_JOB"; then
    echo "Задание уже существует в crontab."
else
    read -p "Задание не найдено. Хотите добавить его? (y/n): " ADD_JOB

    if [[ $ADD_JOB =~ ^[Yy]$ ]]; then
        read -p "Когда выполнять задачу? (введите 'midnight' для выполнения в 00:00 по МСК или 'reboot' для выполнения при каждом перезапуске сервера): " TIME_OPTION

        if [[ $TIME_OPTION == "midnight" ]]; then
            CRON_ENTRY="0 0 * * * $EXTRACTED_DIR/$SCRIPT_TO_RUN"
            (crontab -l ; echo "$CRON_ENTRY") | crontab -
            echo "Задание добавлено: выполнение каждый день в полночь по МСК:"
            crontab -l
        elif [[ $TIME_OPTION == "reboot" ]]; then
            CRON_ENTRY="@reboot $EXTRACTED_DIR/$SCRIPT_TO_RUN"
            (crontab -l ; echo "$CRON_ENTRY") | crontab -
            echo "Задание добавлено: выполнение при каждом перезапуске сервера:"
            crontab -l
        else
            echo "Некорректный ввод. Задание не добавлено."
        fi

    else
        echo "Задание не будет добавлено."
    fi
fi

echo "Скрипт завершён успешно!"
