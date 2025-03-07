# 📌 Скрипт автоматического импорта IP-адресов в IPset

## 📖 Описание

По мотивам **[репо](https://github.com/GhostRooter0953/discord-voice-ips)**, этот скрипт предназначен для автоматизации процесса скачивания, распаковки и обновления списка IP-адресов в IPset с последующим добавлением задания в `crontab`. Задание может быть настроено для выполнения каждый день в 00:00 по МСК или при перезапуске устройства. Скрипт нацелен на роутеры с установленным **[KVAS](https://github.com/qzeleza/kvas)**.

## 🛠 Функциональность

- **Определение версии КВАСа** по наличию IPset листа `KVAS_LIST`, что указывает на бету (_в релизном же создаётся лист `unblock`_).
- **Скачивание архива** с репозитория GitHub в зависимости от версии КВАС (_если используется бета, архив стянется с ветки [light](https://github.com/GhostRooter0953/discord-voice-ips/tree/light), а если установлена релизная, то с [light-no-timeout](https://github.com/GhostRooter0953/discord-voice-ips/tree/light-no-timeout)_).
- **Распаковка содержимого архива** в целевой директории.
- **Присвоение прав на выполнение скриптам** внутри распакованной директории.
- **Добавление задания в crontab** для автоматического обновления IPset:
  - Выполнение каждый день в полночь (_00:00 по МСК_).
  - Выполнение при каждом перезапуске устройства.
- **Проверка наличия задания** в `crontab` для предотвращения дублирования.

## ⚙️ Структура скрипта

1. **Переменные:**
   - `REPO_URL` — URL архива с репозитория GitHub.
   - `DEST_DIR` — целевая директория для скачивания и распаковки.
   - `ZIP_FILE` — путь к скачанному архиву.
   - `EXTRACTED_DIR` — директория, куда распаковывается содержимое архива.
   - `SCRIPT_TO_RUN` — имя скрипта для работающего с IPset.

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

## 🚀 Как использовать

1. Убедитесь, что у вас установлены все необходимые зависимости (_`curl`, `unzip`, `bash`, еtc_).
2. Скачайте или клонируйте репозиторий на ваш роутер. Можно таким образом:
    ```bash
    curl -sSL https://github.com/GhostRooter0953/discord-ips-kvas-adder/archive/refs/heads/master.zip \
    | unzip -p - discord-ips-kvas-adder-master/discord-ips-kvas-adder.sh > /opt/tmp/discord-ips-kvas-adder.sh && \
    chmod +x /opt/tmp/discord-ips-kvas-adder.sh
    ```
3. Запустите скрипт:
    ```bash
    ./discord-ips-kvas-adder.sh
    ```
5. Следуйте инструкциям в терминале:
   - Скрипт предложит изменить аргумент для запуска скрипта импорта IP-адресов
   - Нажмите Enter, чтобы оставить предложенное значение по умолчанию или введите имя листа IPset.
   - Если задание на обновление IPset уже существует, скрипт сообщит вам об этом.
   - Если задание не найдено, вам будет предложено выбрать время для его выполнения (_полночь или перезапуск_).

## 🚀 Пример использования crontab

1. **Выполнение при каждом перезапуске устройства:**
    ```crontab
    SHELL=/opt/bin/bash
    PATH=/opt/bin:/usr/sbin:/usr/bin:/bin:/sbin:/opt/sbin
    @reboot cd /opt/tmp/discord-voice-ips-light && /opt/bin/bash ipset-adder.sh unblock
    ```
    _пример для релизной версии KVAS_

2. **Выполнение каждый день в 00:00 по МСК:**
    ```crontab
    SHELL=/opt/bin/bash
    PATH=/opt/bin:/usr/sbin:/usr/bin:/bin:/sbin:/opt/sbin
    0 0 * * * cd /opt/tmp/discord-voice-ips-light && /opt/bin/bash ipset-adder.sh KVAS_LIST
    ```
    _пример для актуальной версии KVAS_

3. **Выполнение каждый день в 00:00 по МСК и при перезапуске устройства:**
    ```crontab
    SHELL=/opt/bin/bash
    PATH=/opt/bin:/usr/sbin:/usr/bin:/bin:/sbin:/opt/sbin
    @reboot cd /opt/tmp/discord-voice-ips-light && /opt/bin/bash ipset-adder.sh unblock
    0 0 * * * cd /opt/tmp/discord-voice-ips-light && /opt/bin/bash ipset-adder.sh unblock
    ```
    _пример для релизной версии KVAS_

## 🚀 Пример использования скрипта

```bash
    # ./discord-ips-kvas-adder.sh KVAS_LIST
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
    
    Запущен режим list. Используем IPset лист: KVAS_LIST
    Генерируем списки в формате IPset из:
     - ./main_domains/discord-main-ip-list
     - ./voice_domains/discord-voice-ip-list
    IPset лист KVAS_LIST уже существует
    Загружено 1486 IP адреса(ов) в IPset лист KVAS_LIST
    Приехали
```

## 🔥 Дополнительная информация

### 🔻 Выбор аргумента для запуска скрипта импорта IP-адресов

- Аргумент определяет для какого IPset листа будет сгенерирован и импортирован список с IP адресами Discord. Пример:
```bash
./discord-ips-kvas-adder.sh KVAS_LIST
```
- В скрипте реализована автоматическая 'проверка' версии KVAS при запуске в интерактивном режиме. Логика которого: отсутствие IPset листа `KVAS_LIST` указывает на релизную версию, а значит будет стянут репо с ветки [light-no-timeout](https://github.com/GhostRooter0953/discord-voice-ips/tree/light-no-timeout). В противном случае скрипт посчитает, что установлена актуальная версия KVAS и стянет репо с ветки [light](https://github.com/GhostRooter0953/discord-voice-ips/tree/light). Пример работы в интерактивном режиме (_оверрайдится имя IPset-листа по умолчанию_):
```bash
# ./discord-ips-kvas-adder.sh
Какой IPset лист используем? (по умолчанию 'KVAS_LIST'):
```

### 🔻 Список основных доменов с тэгами

A. Если уже пользуетесь 'заквасками', то вы можете из `kvas-tags/tags.list` взять тэг `discord` (_все основные домены +пара сабдоменов_) и утащить в свой тэг лист.  
B. Если не знаете что это такое.. Тооо вы можете облегчить себе добавление основных доменов и их резолвом/актуализацией IP следующим образом:  
  - Скопировать список из фолдера `kvas-tags/tags.list` (_из этой же репо_) с заменой по пути `/opt/apps/kvas/etc/conf/tags.list` (_на роутере с KVAS_)
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
  - Функционал работает начиная с бета-версии `kvas_1.1.9-beta_3`
 
## 🔧 To Do

- Режим проверки и актуализации ip в ipset списке (на случай, если адреса голосовых серверов и etc изменятся, скрипт бы по крону актуализировал их)
- Доработка аргументов и реализация 'других' режимов работы скрипта, повышение гибкости

---
