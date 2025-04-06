#!/bin/bash

print_help() {
    echo -e "Command Tips v$VERSION"
    echo -e "Добаление"
    echo -e "    tips -a 'подсказка' ['комментарий']  Добавить подсказку"
    echo -e "    tips -j ['комментарий']              Добавить подсказку для поледней введёной команды"
    echo -e "Поиск"
    echo -e "    tips -s 'ключевое слово'             Поиск подсказок"
    echo -e "    tips -l                              Список всех подсказок"
    echo -e "Использование"
    echo -e "    tips -t 'Номер подсказки'            Вставить в ввод подсказку"
    echo -e "    tips -c                              Очистить все подсказки"
    echo -e "    tips -h                              Справка"
    echo -e "    tips -v                              Версия"
    echo
    echo -e "Расширенные флаги:"
    echo -e "    --clear    Очистка всех подсказок"
    echo -e "    --list     Показать все подсказки"
    echo -e "    --help     Показать справку"
    echo -e "    --count    Показать количество подсказок"
    echo
    echo -e "Файл подсказок: $TIPS_FILE"
    echo -e "Всего подсказок: $(count_tips)"
}

get_last_command() {
    tail -n 1 "$HISTORY_FILE" 2>/dev/null || echo "Не удалось получить последнюю команду"
}