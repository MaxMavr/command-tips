get_tip() {
    local num=$1
    sed -n "${num}p" "$TIPS_FILE"
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