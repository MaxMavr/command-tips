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

# Экранирование в CSV
encod_csv() {
    local input="$1"
    echo "$input" | sed 's/"/""/g'
}

decod_csv() {
    local input="$1"
    echo "$input" | sed 's/""/"/g'
}

parse_csv_line() {
    local line="$1"
    local -a fields=()
    local field=""
    local in_quotes=false
    
    # Посимвольная обработка строки
    for (( i=0; i<${#line}; i++ )); do
        local char="${line:$i:1}"
        
        if [[ "$char" == '"' ]]; then
            if [[ "$in_quotes" == true && "${line:$i+1:1}" == '"' ]]; then
                field+='"'
                ((i++))
            else
                in_quotes=$(! $in_quotes)
            fi
        elif [[ "$char" == ',' && "$in_quotes" == false ]]; then
            fields+=("$(decod_csv "$field")")
            field=""
        else
            field+="$char"
        fi
    done
    
    fields+=("$(decod_csv "$field")")
    
    echo "${fields[@]}"
}
 