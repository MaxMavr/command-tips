#!/bin/bash

# Константы
readonly DB_FILE="$HOME/.tips_db.csv"
readonly HISTORY_FILE="$HOME/.bash_history"
readonly VERSION="1.2"

# Инициализация базы данных
init_db() {
    if [ ! -f "$DB_FILE" ]; then
        touch "$DB_FILE"
        echo "id,command,comment,tags,last_used" > "$DB_FILE"
        print_msg y "База данных не найдена. Инициализация..."
    fi
}
