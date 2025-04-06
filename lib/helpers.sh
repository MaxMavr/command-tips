#!/bin/bash

print_msg() {
    local color=$1; shift
    case $color in
        r) echo -e "\033[31m$*\033[0m" ;;
        g) echo -e "\033[32m$*\033[0m" ;;
        y) echo -e "\033[33m$*\033[0m" ;;
        *) echo -e "$*" ;;
    esac
}

get_last_cmd() {
    tail -n 1 "$HISTORY_FILE" 2>/dev/null || die "не удалось получить последнюю команду"
}

# Экранирование кавычек и запятых в CSV
encod_csv() {
    local input="$1"
    echo "$input" | sed 's/"/""/g'
}

decod_csv() {
    local input="$1"
    echo "$input" | sed 's/""/"/g'
}

die() {
    local error="$1"
    print_msg r "Ошибка: $error" >&2
    exit 1
}
 