#!/bin/bash

# Константы
readonly DB_FILE="$HOME/.tips_db.csv"
readonly HISTORY_FILE="$HOME/.bash_history"
readonly VERSION="1.2"

# Инициализация базы данных
init_db() {
    if [ ! -f "$DB_FILE" ]; then
        print_msg y "База данных не найдена. Инициализация..."
        touch "$DB_FILE"
    fi
}
