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
    [[ "$CLEAN_MODE" -eq 0 ]] && { print_msg r "Ошибка: $error" >&2; }
    exit 1
}

init_db() {
    if [ ! -f "$DB_FILE" ]; then
        [[ "$CLEAN_MODE" -eq 0 ]] && { print_msg y "База данных не найдена. Инициализация..."; }
        touch "$DB_FILE"
    fi
}

check_db() {
    if [ ! -s "$DB_FILE" ]; then
        [[ "$CLEAN_MODE" -eq 0 ]] && { print_msg y "База данных пуста"; }
        exit 0
    fi
}

get_free_id_db() {
    local empty_line=$(grep -n '^[[:space:]]*$' "$DB_FILE" | head -n 1 | cut -d: -f1)
    echo "$empty_line"
}

clear_tags() {
    local tags="$1"
    IFS=',' read -ra tags_array <<< "$tags"

    for i in "${!tags_array[@]}"; do
        tags_array[$i]=$(printf '%s' "${tags_array[$i]}" | tr -d '[:space:]')
    done

    printf '%s\n' "${tags_array[@]}"
}