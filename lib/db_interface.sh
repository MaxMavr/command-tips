# Подсчет записей
count_tips() {
    local count=$(grep -c "^id:" "$DB_FILE")
    echo "$count"
}

add_tip() {
    local command="$1"
    local comment="$2"
    local tags="$3"

    local id=$(count_tips)
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "id: $id" >> "$DB_FILE"
    echo "command: $command" >> "$DB_FILE"
    echo "comment: $comment" >> "$DB_FILE"
    echo "tags: $tags" >> "$DB_FILE"
    echo "timestamp: $timestamp" >> "$DB_FILE"

    print_msg g "Добавлена запись: $command #$id"

    if [[ -n "$comment" ]]; then
    print_msg g "     Комментарий: $comment"
    fi

    if [[ -n "$tags" ]]; then
    print_msg g "            Теги: $tags"
    fi
}

get_tip() {
    local id="$1"
    
    [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]] && die "неверный ID. Укажите числовой идентификатор подсказки."
    
    raw_tip=$(grep -Pzo "id: $id(\n|.)*?(?=\nid:|\$)" "$DB_FILE" | tr -d '\0')

    [ -z "$raw_tip" ] && echo "запись с ID $id не найдена"

    # Извлекаем отдельные поля
    command=$(echo "$raw_tip" | grep -Po "(?<=command: ).*")
    comment=$(echo "$raw_tip" | grep -Po "(?<=comment: ).*")
    tags=$(echo "$raw_tip" | grep -Po "(?<=tags: ).*")
    timestamp=$(echo "$raw_tip" | grep -Po "(?<=timestamp: ).*")

    # Формируем и выводим список tip
    local -a tip=("$id" "$command" "$comment" "$tags" "$timestamp")
    declare -p tip
}

edit_tip() {
    local num=$1
    local field="$2"
    local new_value="$3"
    local date=$(date +"%Y-%m-%d %H:%M:%S")
    local tempfile=$(mktemp)
    
    # Обрабатываем CSV с запятыми как разделителями
    awk -v num="$num" -v field="$field" -v new_value="$new_value" -v date="$date" \
        'BEGIN{FS=OFS=","} {
            # Пропускаем заголовок
            if (NR == 1) {print; next}
            
            # Если это нужная строка
            if (NR-1 == num) {
                # Определяем какое поле нужно обновить
                if (field == "command") $2 = new_value
                else if (field == "comment") $3 = new_value
                else if (field == "tags") $4 = new_value
                
                # Всегда обновляем дату последнего использования
                $5 = date
            }
            print
        }' "$DB_FILE" > "$tempfile"
    
    mv "$tempfile" "$DB_FILE"
}

remove_tags() {
    local remove_tags_num= "$1"
    local remove_tags= "$2"
    local tip=$(get_tip "$remove_tags_num")

    IFS=$'\n' read -ra fields <<< "$tip"
    IFS=',' read -ra current_tags <<< "${parts[3]}"
    IFS=',' read -ra remove_tags <<< "$remove_tags"

    local new_tags=()

    for tag in "${current_tags[@]}"; do
        local should_remove=0
        for remove_tag in "${remove_tags[@]}"; do
            if [[ "$tag" == "$remove_tag" ]]; then
                should_remove=1
                break
            fi
        done
        
        if (( ! should_remove )); then
            new_tags+=("$tag")
        fi
    done
    
    edit_tip "$remove_tags_num" tags "$(IFS=','; echo "${new_tags[*]}")"
    print_msg g "Теги \"$remove_tags\" удалены из записи $remove_tags_num."
}

# Очистка базы
clear_tips() {
    read -p "Вы уверены, что хотите полностью очистить базу данных? (y/N) " confirm
    if [[ "$confirm" =~ [yY] ]]; then
        > "$DB_FILE"
        print_msg g "База данных очищена"
    else
        print_msg r "Отменено"
    fi
}

# Поиск
search_tips() {
    local query="$1"
    
    awk -F, -v query="$query" 'BEGIN {IGNORECASE=1} NR == 1 {next} {
        cmd = substr($2, 2, length($2)-2)
        comment = substr($3, 2, length($3)-2)
        tags = substr($4, 2, length($4)-2)
        
        if (cmd ~ query || comment ~ query || tags ~ query) {
            printf "\033[1;34m#%s\033[0m: %s", substr($1, 2, length($1)-2), cmd
            if (comment != "") printf " \033[1;30m(%s)\033[0m", comment
            if (tags != "") printf " \033[1;32m[%s]\033[0m", tags
            printf "\n"
        }
    }' "$DB_FILE"
}

# Фильтр по тегам (AND)
filter_tags() {
    check_db
    local tags="$1"
    
    awk -F, -v tags="$tags" 'BEGIN {
        split(tags, required_tags, ",")
    } NR == 1 {next} {
        current_tags = substr($4, 2, length($4)-2)
        split(current_tags, tag_arr, ",")
        
        all_found = 1
        for (i in required_tags) {
            found = 0
            for (j in tag_arr) {
                if (required_tags[i] == tag_arr[j]) {
                    found = 1
                    break
                }
            }
            if (!found) {
                all_found = 0
                break
            }
        }
        
        if (all_found) {
            printf "\033[1;34m#%s\033[0m: %s", substr($1, 2, length($1)-2), substr($2, 2, length($2)-2)
            comment = substr($3, 2, length($3)-2)
            if (comment != "") printf " \033[1;30m(%s)\033[0m", comment
            printf " \033[1;32m[%s]\033[0m\n", current_tags
        }
    }' "$DB_FILE"
}

# Фильтр по любому тегу (OR)
filter_any_tags() {
    check_db
    local tags="$1"
    
    awk -F, -v tags="$tags" 'BEGIN {
        split(tags, search_tags, ",")
    } NR == 1 {next} {
        current_tags = substr($4, 2, length($4)-2)
        split(current_tags, tag_arr, ",")
        
        any_found = 0
        for (i in search_tags) {
            for (j in tag_arr) {
                if (search_tags[i] == tag_arr[j]) {
                    any_found = 1
                    break
                }
            }
            if (any_found) break
        }
        
        if (any_found) {
            printf "\033[1;34m#%s\033[0m: %s", substr($1, 2, length($1)-2), substr($2, 2, length($2)-2)
            comment = substr($3, 2, length($3)-2)
            if (comment != "") printf " \033[1;30m(%s)\033[0m", comment
            printf " \033[1;32m[%s]\033[0m\n", current_tags
        }
    }' "$DB_FILE"
}

# Показать все записи
list_tips() {
    if [ ! -s "$DB_FILE" ]; then
        print_msg y "База данных пуста"
        exit 0
    fi

    local -a ids=("ID") commands=("Команда") comments=("Комментарий") tagss=("Теги")
    local max_length_id=0 max_length_command=0 max_length_comment=0
    local count_tips="$(count_tips)"

    for ((i=0; i<$count_tips; i++)); do
        local tip=$(get_tip $i)
        eval "$tip"

        ids+=("${tip[0]}")
        commands+=("${tip[1]}")
        comments+=("${tip[2]}")
        tagss+=("${tip[3]}")

        (( ${#tip[0]} > max_length_id )) && max_length_id=${#tip[0]}
        (( ${#tip[1]} > max_length_command )) && max_length_command=${#tip[1]}
        (( ${#tip[2]} > max_length_comment )) && max_length_comment=${#tip[2]}
    done

    for ((i=0; i<(($count_tips + 1)); i++)); do
        echo -n "${ids[$i]}"
        tput cuf $((max_length_id - ${#ids[$i]} + 3))
        echo -n "${commands[$i]}"
        tput cuf $((max_length_command - ${#commands[$i]} + 3))
        echo -n "${comments[$i]}"
        tput cuf $((max_length_comment - ${#comments[$i]} + 3))
        echo "${tagss[$i]}"
    done
}

# Показать полную информацию о записи
info_tip() {
    local tip=$(get_tip $1)
    eval "$tip"
    local offset=0

    echo

    for ((i=0; i<${#tip[@]}; i++)); do
        local offset=$(( ${#tip[i]} > ${#FIELD_TITLES[i]} ? ${#tip[i]} : ${#FIELD_TITLES[i]} ))
        tput sc
        tput cuu 1
        echo -n "${FIELD_TITLES[$i]}"
        tput rc
        echo -n "${tip[$i]}"
        tput cuf $(( offset - ${#tip[i]} + 3 ))
    done
    echo
}