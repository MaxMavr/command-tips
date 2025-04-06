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

count_tips() {
    wc -l < "$TIPS_FILE" | tr -d ' '
}

clear_tips() {
    > "$TIPS_FILE"
    print_message green "Все подсказки удалены"
}

search_tips() {
    local keyword="$1"
    if [ -z "$keyword" ]; then
        print_message red "Ошибка: Не указано ключевое слово для поиска"
        return 1
    fi
    
    grep -i --color=always "$keyword" "$TIPS_FILE" || \
        print_message yellow "Подсказки по запросу '$keyword' не найдены"
}

list_tips() {
    if [ ! -s "$TIPS_FILE" ]; then
        print_message yellow "Файл подсказок пуст"
        return
    fi
    
    print_message green "Список всех подсказок:"
    nl -w2 -s ". " "$TIPS_FILE"
}

add_tip() {
    local tip="$1"
    local comment="${2:-Без комментария}"
    
    if [ -z "$tip" ]; then
        print_message red "Ошибка: Не указана подсказка"
        return 1
    fi
    
    echo "$tip | $comment" >> "$TIPS_FILE"
    print_message green "Добавлено: '$tip' (Комментарий: $comment)"
}

get_last_command() {
    tail -n 1 "$HISTORY_FILE" 2>/dev/null || echo "Не удалось получить последнюю команду"
}