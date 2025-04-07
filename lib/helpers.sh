#!/bin/bash

print_msg() {
    local color=$1
    case $color in
        r|g|y) 
            shift  # Удаляем цвет из аргументов
            local code
            case $color in
                r) code="31" ;;
                g) code="32" ;;
                y) code="33" ;;
            esac
            echo -e "\033[${code}m$*\033[0m"
            ;;
        *) 
            # Если первый аргумент не цвет, печатаем всё как есть
            echo -e "$*"
            ;;
    esac
}

get_last_cmd() {
    tail -n 1 "$HISTORY_FILE" 2>/dev/null || die "не удалось получить последнюю команду"
}

die() {
    local error="$1"
    print_msg r "Ошибка: $error" >&2
    exit 1
}