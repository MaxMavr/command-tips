#!/bin/bash

# Константы
readonly DB_FILE="$HOME/.tips_db.csv"
readonly HISTORY_FILE="$HOME/.bash_history"
readonly VERSION="1.2"

# Инициализация файла подсказок
# Инициализация базы данных
init_db() {
    if [ ! -f "$DB_FILE" ]; then
        touch "$DB_FILE"
        echo "id,command,comment,tags,last_used" > "$DB_FILE"
        print_msg y "База данных не найдена. Инициализация..."
    fi
}

get_last_cmd() {
    tail -n 1 "$HISTORY_FILE" 2>/dev/null || print_msg r "Не удалось получить последнюю команду"
}
