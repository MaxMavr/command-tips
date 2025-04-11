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
    
    raw_tip=$(awk -v id="$id" '/^id: / {if ($2 == id) {print; flag=1; next} else {flag=0}} flag' "$DB_FILE")

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
    check_db
    local query="$1"
    local all_tags="$2"
    local any_tags="$3"

    local -a ids=("${FIELD_TITLES[0]}") commands=("${FIELD_TITLES[1]}") comments=("${FIELD_TITLES[2]}") tagss=("${FIELD_TITLES[3]}")
    local max_length_id=0 max_length_command=0 max_length_comment=0

    for ((i=0; i<"$(count_tips)"; i++)); do
        local tip=$(get_tip $i)
        eval "$tip"

        local include=0

        local command="${tip[1]}"
        if [[ "$command" == *"$query"* && -n "$query" ]]; then
            include=1
        fi

        local tags="${tip[3]}"
        IFS=',' read -ra tags_array <<< "$tags"

        for j in "${!tags_array[@]}"; do
            tags_array[$j]=$(echo "${tags_array[$j]}" | tr -d '[:space:]')
        done

        # Проверка любого тега (OR логика)
        # if [[ $include -eq 0 && -n "$any_tags" ]]; then
        #     IFS=',' read -ra any_tags_array <<< "$any_tags"

        #     for j in "${!any_tags_array[@]}"; do
        #         any_tags_array[$j]=$(echo "${any_tags_array[$j]}" | tr -d '[:space:]')
        #     done

        #     for tag in "${any_tags_array[@]}"; do
        #         for t in "${tags_array[@]}"; do
        #             if [[ "$t" == "$tag" ]]; then
        #                 include=1
        #                 break 2
        #             fi
        #         done
        #     done
        # fi

        # Проверка всех тегов (AND логика)
        # if [[ $include -eq 0 && -n "$all_tags" ]]; then
        #     IFS=',' read -ra all_tags_array <<< "$all_tags"
            
        #     for j in "${!all_tags_array[@]}"; do
        #         all_tags_array[$j]=$(echo "${all_tags_array[$j]}" | tr -d '[:space:]')
        #     done

        #     include=1

        #     for tag in "${all_tags_array[@]}"; do
        #         for t in "${tags_array[@]}"; do
        #             if [[ "$t" != "$tag" ]]; then
        #                 include=0
        #                 break 2
        #             fi
        #         done
        #     done
        # fi

        if [[ $include -eq 1 ]]; then
            ids+=("${tip[0]}")
            commands+=("$command")
            comments+=("${tip[2]}")
            tagss+=("$tags")

            (( ${#tip[0]} > max_length_id )) && max_length_id=${#tip[0]}
            (( ${#tip[1]} > max_length_command )) && max_length_command=${#tip[1]}
            (( ${#tip[2]} > max_length_comment )) && max_length_comment=${#tip[2]}
        fi
    done

    for ((i=0; i<${#ids[@]}; i++)); do
        echo -n "${ids[$i]}"
        tput cuf $(( max_length_id - ${#ids[$i]} + SPACE ))
        echo -n "${commands[$i]}"
        tput cuf $(( max_length_command - ${#commands[$i]} + SPACE ))
        echo -n "${comments[$i]}"
        tput cuf $(( max_length_comment - ${#comments[$i]} + SPACE ))
        echo "${tagss[$i]}"
    done
}

# Показать все записи
list_tips() {
    check_db

    local -a ids=("${FIELD_TITLES[0]}") commands=("${FIELD_TITLES[1]}") comments=("${FIELD_TITLES[2]}") tagss=("${FIELD_TITLES[3]}")
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
        tput cuf $(( max_length_id - ${#ids[$i]} + SPACE ))
        echo -n "${commands[$i]}"
        tput cuf $(( max_length_command - ${#commands[$i]} + SPACE ))
        echo -n "${comments[$i]}"
        tput cuf $(( max_length_comment - ${#comments[$i]} + SPACE ))
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
        tput cuf $(( offset - ${#tip[i]} + SPACE ))
    done
    echo
}

copy_tip() {
    local tip=$(get_tip "$1")
    eval "$tip"
    local command="${tip[1]}"

    if command -v xclip &> /dev/null; then
        echo -n "$command" | xclip -selection clipboard
        print_msg g "Команда скопирована в буфер обмена (xclip): $command"
    elif command -v pbcopy &> /dev/null; then
        echo -n "$command" | pbcopy
        print_msg g "Команда скопирована в буфер обмена (pbcopy): $command"
    else
        die "Ошибка: не найдены xclip или pbcopy для копирования в буфер"
    fi
}

insert_tip() {
    local tip=$(get_tip $1)
    eval "$tip"
    local command="${tip[1]}"
    
    if [ -n "$TMUX" ]; then
        # Если внутри tmux
        tmux send-keys -t "$TMUX_PANE" "$command"
    else
        # Для обычного терминала (зависит от терминала)
        if [ -n "$SSH_TTY" ] || [ "$(tty | cut -c 1-8)" = "/dev/pts" ]; then
            # Работает для многих терминалов (xterm, gnome-terminal и т.д.)
            printf '\e]51;["call","Terminal","insert",{"text":"%s"}]\a' "$command"
        else
            # Альтернативный метод (может не работать везде)
            echo -n "$command" > /dev/tty
        fi
    fi
}