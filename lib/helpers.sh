#!/bin/bash

print_msg() {
    local color=$1
    case $color in
        r|g|y)
            shift
            local code
            case $color in
                r) code="31" ;;
                g) code="32" ;;
                y) code="33" ;;
            esac
            echo -e "\033[${code}m$*\033[0m"
            ;;
        *)
            echo -e "$*"
            ;;
    esac
}

die() {
    local error="$1"
    print_msg r "Ошибка: $error" >&2
    exit 1
}

init_db() {
    if [ ! -f "$DB_FILE" ]; then
        print_msg y "База данных не найдена. Инициализация..."
        touch "$DB_FILE"
    fi
}
