# Скрипт автоматического импорта IP-адресов в IPset

## Описание

По мотивам **[репо](https://github.com/GhostRooter0953/discord-voice-ips)**, этот скрипт предназначен для автоматизации процесса скачивания, распаковки и обновления списка IP-адресов в IPset с последующим добавлением задания в `crontab`. Задание может быть настроено для выполнения каждый день в 00:00 по МСК или при перезапуске устройства. Скрипт нацелен на роутеры с установленным **[KVAS](https://github.com/qzeleza/kvas)**.

## Функциональность

- **Скачивание архива** с репозитория GitHub.
- **Распаковка содержимого архива** в целевой директории.
- **Присвоение прав на выполнение скриптам** внутри распакованной директории.
- **Добавление задания в crontab** для автоматического обновления IPset:
  - Выполнение каждый день в полночь (00:00 по МСК).
  - Выполнение при каждом перезапуске устройства.
- **Проверка наличия задания** в `crontab` для предотвращения дублирования.

## Структура скрипта

1. **Переменные:**
   - `REPO_URL` — URL архива с репозитория GitHub.
   - `DEST_DIR` — целевая директория для скачивания и распаковки.
   - `ZIP_FILE` — путь к скачанному архиву.
   - `EXTRACTED_DIR` — директория, куда распаковывается содержимое архива.
   - `SCRIPT_TO_RUN` — имя скрипта для запуска IPset (с аргументом `auto`).

2. **Шаги выполнения:**
   - Если существует старая версия распакованного архива, она удаляется.
   - Скачивается архив по указанному URL.
   - Архив распаковывается в целевую директорию.
   - Присваиваются права на выполнение для всех `.sh` файлов.
   - В начале всех `.sh` файлов заменяется путь к оболочке на `#!/opt/bin/bash`.
   - Проверяется наличие строк `SHELL` и `PATH` в crontab. Если их нет, они добавляются.
   - Проверяется наличие задания в `crontab`:
     - Если задание уже существует, новое задание не добавляется.
     - Если задание не найдено, предлагается выбор между выполнением в полночь или при перезапуске устройства.
   - Обновлённый crontab сохраняется.

## Как использовать

1. Скачайте или клонируйте репозиторий на ваше устройство.
2. Убедитесь, что у вас установлены все необходимые зависимости (например, `curl`, `unzip` и `bash`).
3. Запустите скрипт:
    ```bash
    ./kvas-ipset-adder.sh
    ```
5. Следуйте инструкциям в терминале:
   - Скрипт предложит изменить аргумент для запуска скрипта импорта IP-адресов (если `ipset` список, что создал сам КВАС, у вас называется отлично от `unblock` - передаём в качестве аргумента название списка).
   - Нажмите Enter, чтобы оставить значение по умолчанию, или введите новый аргумент (имя листа IPset).
   - Если задание на обновление IPset уже существует, скрипт сообщит вам об этом.
   - Если задание не найдено, вам будет предложено выбрать время для его выполнения (полночь или перезапуск).

## Пример использования crontab

1. **Выполнение при каждом перезапуске устройства:**
    ```crontab
    SHELL=/opt/bin/bash
    PATH=/opt/bin:/usr/sbin:/usr/bin:/bin:/sbin:/opt/sbin
    @reboot cd /opt/tmp/discord-voice-ips-light && /opt/bin/bash ipset-adder.sh auto
    ```

2. **Выполнение каждый день в 00:00 по МСК:**
    ```crontab
    SHELL=/opt/bin/bash
    PATH=/opt/bin:/usr/sbin:/usr/bin:/bin:/sbin:/opt/sbin
    0 0 * * * cd /opt/tmp/discord-voice-ips-light && /opt/bin/bash ipset-adder.sh auto
    ```

3. **Выполнение каждый день в 00:00 по МСК и при перезапуске устройства:**
    ```crontab
    SHELL=/opt/bin/bash
    PATH=/opt/bin:/usr/sbin:/usr/bin:/bin:/sbin:/opt/sbin
    @reboot cd /opt/tmp/discord-voice-ips-light && /opt/bin/bash ipset-adder.sh auto
    0 0 * * * cd /opt/tmp/discord-voice-ips-light && /opt/bin/bash ipset-adder.sh auto
    ```

## Пример использования скрипта

```bash
    # ./kvas-ipset-adder.sh good_list
    Скачивание https://github.com/GhostRooter0953/discord-voice-ips/archive/refs/heads/light.zip...
    Распаковка /opt/tmp/light.zip в /opt/tmp...
    Выдача прав на выполнение скриптов...
    Некоторые или все задания на авто-импорт списков в IPset отсутствуют
    Выберите, какие задания вы хотите добавить:
    1. Полночь каждый день
    2. При перезагрузке
    3. Полночь каждый день и при перезагрузке
    0. Не добавлять
    Введите номер варианта (0-3): 2
    Задание добавлено: выполнение при каждом перезапуске роутера
    Импортируем списки в IPset лист сейчас? (y/n): y
    Запуск импорта...
    
    Запущен режим list. Используем IPset лист: good_list
    Генерируем списки в формате IPset из:
     - ./main_domains/discord-main-ip-list
     - ./voice_domains/discord-voice-ip-list
    IPset лист good_list создан
    Загружено 1486 IP адреса(ов) в IPset лист good_list
    Приехали
```

## Дополнительная информация

**Выбор аргумента для запуска скрипта импорта IP-адресов:**

- Аргумент определяет режим работы скрипта `ipset-adder.sh`
- Возможные варианты:
  - `auto` — автоматический режим с использованием списка unblock
  - `list <имя>` — использование указанного списка IPset

При запуске `kvas-ipset-adder.sh` вы можете указать этот аргумент или изменить его в интерактивном режиме

**Список основных доменов с тэгами**

- Если уже пользуетесь 'заквасками': из `kvas-tags/tags.list` можно взять тэг `discord` (_все основные домены +пара сабдоменов_) и утащить в свой тэг лист
- Если не знаете что это: список из фолдера - `kvas-tags/tags.list`, необходимо скопировать с заменой по пути `/opt/apps/kvas/etc/conf/tags.list`
  - Затем выполнить `kvas add tags` и выбрать номер тэга относящийся к `discord`:
    ```bash
    root@Ultra:/opt/tmp# kvas add tags
    ----------------------------------------------------------------------------------------------------------------------------------------
    Список заквасок для добавления:
    ----------------------------------------------------------------------------------------------------------------------------------------
    1. kvas                                                                                                                     ОТСУТСТВУЕТ
    2. microsoft                                                                                                                ОТСУТСТВУЕТ
    3. youtube                                                                                                                  ОТСУТСТВУЕТ
    4. docker                                                                                                                   ОТСУТСТВУЕТ
    5. games                                                                                                                    ОТСУТСТВУЕТ
    6. ai                                                                                                                       ОТСУТСТВУЕТ
    7. discord                                                                                                                  ОТСУТСТВУЕТ
    8. instagram                                                                                                                ОТСУТСТВУЕТ
    9. facebook                                                                                                                 ОТСУТСТВУЕТ
    10. twitter                                                                                                                 ОТСУТСТВУЕТ
    11. telegram                                                                                                                ОТСУТСТВУЕТ
    12. cloudflare                                                                                                              ОТСУТСТВУЕТ
    13. torrent                                                                                                                 ОТСУТСТВУЕТ
    14. spotify                                                                                                                 ОТСУТСТВУЕТ
    15. sony                                                                                                                    ОТСУТСТВУЕТ
    ----------------------------------------------------------------------------------------------------------------------------------------
    Выберите номер закваски из списка [1-15], A:Все, Q:Выход: 7
    ```
  - Функционал работает начиная с версии `kvas_1.1.9-beta_3`
 
## To Do

- Режим проверки и актуализации ip в ipset списке (на случай, если адреса голосовых серверов и etc изменятся, скрипт бы по крону актуализировал их)
- Доработка аргументов и реализация 'других' режимов работы скрипта, повышение гибкости
---
