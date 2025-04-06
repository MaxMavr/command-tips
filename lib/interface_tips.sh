# Подсчет записей
count_tips() {
    tail -n +2 "$DB_FILE" | wc -l
}

# Добавление записи
# Добавить запись
add_tip() {
    local command=encod_csv "$1"
    local comment=encod_csv "$2"
    local tags=encod_csv "$3"
    
    local id=$(($(wc -l < "$DB_FILE")))
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "$id,\"$command\",\"$comment\",\"$tags\",\"$timestamp\"" >> "$DB_FILE"
    print_msg g "Добавлена запись #$id: $command"

    if [[ -n "$comment" ]]; then
    print_msg g "     Комментарий: $comment"
    fi

    if [[ -n "$tags" ]]; then
    print_msg g "           Теги: $tags"
    fi
    exit 0
}

add_last_cmd() {
    local last_cmd=$(get_last_cmd)
    add_tip "$last_cmd" "$1"
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
list_tips() {
    if [ ! -s "$DB_FILE" ]; then
        echo "База данных пуста"
        return
    fi
    
    echo -e "ID\tКоманда\t\tКомментарий\t\tТеги"
    echo "------------------------------------------------------------"
    
    tail -n +2 "$DB_FILE" | while IFS=',' read -r id command comment tags last_used; do
        command=$(echo "$command" | tr -d '"')
        comment=$(echo "$comment" | tr -d '"')
        tags=$(echo "$tags" | tr -d '"')
        
        # Обрезаем длинные строки для лучшего отображения
        local short_cmd=$(echo "$command" | cut -c1-20)
        local short_comment=$(echo "$comment" | cut -c1-20)
        
        echo -e "$id\t$short_cmd\t$short_comment\t$tags"
    done
}