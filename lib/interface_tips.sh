# Подсчет записей
count_tips() {
    tail -n +2 "$DB_FILE" | wc -l
}

add_tip() {
    local command="$1"
    local comment="$2"
    local tags="$3"

    local id=$(count_tips)
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "$id,\"$(encod_csv '$command')\",\"$(encod_csv '$comment')\",\"$(encod_csv '$tags')\",\"$timestamp\"" >> "$DB_FILE"
    print_msg g "Добавлена запись: $command #$id"

    if [[ -n "$comment" ]]; then
    print_msg g "     Комментарий: $comment"
    fi

    if [[ -n "$tags" ]]; then
    print_msg g "            Теги: $tags"
    fi
    exit 0
}

get_tip() {
    local id="$1"
    
    if [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]]; then
        die "неверный ID. Укажите числовой идентификатор подсказки."
    fi

    local tip=$(grep -w "^$id," "$DB_FILE" 2>/dev/null)

    if [[ -z "$tip" ]]; then
        die "подсказка с ID $id не найдена."
    fi

    IFS=$'\n' read -d '' -r -a fields < <(parse_csv_line "$tip")
    
    echo "${fields[*]:1}" | tr ' ' ','
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
        echo "id,command,comment,tags,last_used" > "$DB_FILE"
        print_msg g "База данных очищена"
    else
        print_msg r "Отменено"
    fi
}

# Добавление тегов
add_tags() {
    local id="$1"
    local tags="$2"
    
    awk -v id="$id" -v tags="$tags" 'BEGIN {FS=OFS=","} {
        if ($1 == "\""id"\"" || NR == 1) {
            if (NR == 1) print; 
            else {
                current_tags = substr($4, 2, length($4)-2)
                if (current_tags == "") new_tags = tags
                else new_tags = current_tags "," tags
                print $1,$2,$3,"\""new_tags"\"",$5
            }
        } else print
    }' "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"
    
    print_msg g "Теги добавлены к записи #$id"
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
#Todo Сделать вывод красывым
list_tips() {
    if [ ! -s "$DB_FILE" ]; then
        print_msg y "База данных пуста"
        return
    fi
    
    print_msg "ID\tКоманда\t\tКомментарий\t\tТеги"
    echo "------------------------------------------------------------"
    
    tail -n +2 "$DB_FILE" | while IFS=',' read -r id command comment tags last_used; do
        command=$(echo "$command" | tr -d '"')
        comment=$(echo "$comment" | tr -d '"')
        tags=$(echo "$tags" | tr -d '"')
        
        # Обрезаем длинные строки для лучшего отображения
        local short_cmd=$(echo "$command" | cut -c1-20)
        local short_comment=$(echo "$comment" | cut -c1-20)
        
        echo -e "$id\t$short_cmd\t\t$short_comment\t\t$tags"
    done
}

# Функция для вставки команды в консоль
insert_tip() {
    local id=$1
    local tip=$(get_tip $id)
    local command=$(tip[1])
    
    
    echo "Готово к выполнению: $command"
    # Для bash/zsh:
    printf '\e[0n%s' "$command"  # Это может работать не во всех терминалах
    # Альтернатива (если предыдущий вариант не работает):
    # echo -n "$command" | xclip -selection primary
    # Или для некоторых терминалов:
    # echo -n "$command" > /dev/tty
}

# Функция для копирования команды в буфер обмена
copy_tip() {
    local num=$1
    local command
    
    # Получаем команду по номеру (пропускаем заголовок)
    command=$(awk -F, -v num=$num 'NR==num+1 {print $2}' "$DB_FILE")
    
    if [[ -z "$command" ]]; then
        echo "Ошибка: команда с номером $num не найдена" >&2
        return 1
    fi
    
    # Копируем в буфер обмена (зависит от системы)
    if command -v xclip &> /dev/null; then
        echo -n "$command" | xclip -selection clipboard
        echo "Команда скопирована в буфер обмена"
    elif command -v pbcopy &> /dev/null; then
        echo -n "$command" | pbcopy
        echo "Команда скопирована в буфер обмена"
    else
        echo "Не найдены инструменты для работы с буфером обмена (xclip/pbcopy)" >&2
        return 1
    fi
}