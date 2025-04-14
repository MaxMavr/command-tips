add_tip() {
    local command="$1"
    local comment="$2"
    local tags="$3"
    
    save_tip "$command" "$comment" "$tags"

    if [[ "$CLEAN_MODE" -eq 0 ]]; then
        print_msg g "Добавлена запись: $command #$id"

        if [[ -n "$comment" ]]; then
        print_msg g "     Комментарий: $comment"
        fi

        if [[ -n "$tags" ]]; then
        print_msg g "            Теги: $tags"
        fi
    fi
}

edit_tip() {
    local id=$1
    raw_tip=$(get_tip "$1") || { die "запись с ID $1 не найдена\nИли неверный ID. Укажите числовой идентификатор подсказки."; }
    eval "$raw_tip"

    local field="$2"
    local command=("${tip["command"]}")
    local comment=("${tip["comment"]}")
    local tags=("${tip["tags"]}")

    if [[ -z "$field" ]]; then
        read -e -i "$command" -p "$COMMAND_TITLE: " command
        read -e -i "$comment" -p "$COMMENT_TITLE: " comment
        read -e -i "$tags" -p "$TAGS_TITLE: " tags
    else
        case "$field" in
            c|cmd|command)
                read -e -i "$command" -p "$COMMAND_TITLE: " command
                ;;
            m|cmt|comment)
                read -e -i "$comment" -p "$COMMENT_TITLE: " comment
                ;;
            t|tag|tags)
                read -e -i "$tags" -p "$TAGS_TITLE: " tags
                ;;
            *)
                die "Неизвестное поле: $field\nИспользуйте tips --help для просмотра справки"
                ;;
        esac
    fi

    save_tip "$command" "$comment" "$tags" "$id"

    [[ "$CLEAN_MODE" -eq 0 ]] && { print_msg g "Подсказка #$id исправлена"; }
}

remove_comment() {
    local id=$1
    raw_tip=$(get_tip "$1") || { die "запись с ID $1 не найдена\nИли неверный ID. Укажите числовой идентификатор подсказки."; }
    eval "$raw_tip"

    local command=("${tip["command"]}")
    local tags=("${tip["tags"]}")

    save_tip "$command" "" "$tags" "$id"

    [[ "$CLEAN_MODE" -eq 0 ]] && { print_msg g "Коментарий подсказки #$id удалён"; }
}

remove_tags() {
    local id=$1
    raw_tip=$(get_tip "$id") || { die "Запись с ID $id не найдена\nИли неверный ID. Укажите числовой идентификатор подсказки."; }
    eval "$raw_tip"

    local remove_tags="$2"

    local command="${tip["command"]}"
    local comment="${tip["comment"]}"
    
    if [[ -z "$remove_tags" ]]; then
        save_tip "$command" "$comment" "" "$id"
        [[ "$CLEAN_MODE" -eq 0 ]] && { print_msg g "Все теги подсказки #$id удалены"; }
        return 0
    fi
    
    local tags="${tip["tags"]}"

    remove_tags=$(clear_tags "$remove_tags")
    tags=$(clear_tags "$tags")

    IFS=$'\n' read -rd '' -a remove_tags_array <<< "$remove_tags"
    IFS=$'\n' read -rd '' -a tags_array <<< "$tags"

    local -a remaining_tags
    for tag in "${tags_array[@]}"; do
        if [[ ! " ${remove_tags_array[@]} " =~ " $tag " ]]; then
            remaining_tags+=("$tag")
        fi
    done

    local updated_tags=$(IFS=','; echo "${remaining_tags[*]}")
    save_tip "$command" "$comment" "$updated_tags" "$id"

    [[ "$CLEAN_MODE" -eq 0 ]] && { print_msg g "Теги ${remove_tags} подсказки #$id удалены"; }
}

clear_tips() {
    [[ "$CLEAN_MODE" -eq 1 ]] && { > "$DB_FILE"; exit 0; }

    read -p "Вы уверены, что хотите полностью очистить файл подсказок? (д/Н) " confirm
    if [[ "$confirm" =~ [yYдД] ]]; then
        > "$DB_FILE"
        print_msg g "База данных очищена"
    else
        print_msg r "Отменено"
    fi
}

delete_tip() {
    local id=$1

    [[ "$CLEAN_MODE" -eq 1 ]] && { sed -i "${id}s/.*/ /" "$DB_FILE"; exit 0; }

    read -p "Вы уверены, что хотите удалить подсказку #$id? (д/Н) " confirm
    if [[ "$confirm" =~ [yYдД] ]]; then
        sed -i "${id}s/.*/ /" "$DB_FILE"
        print_msg g "Подсказка #$id удалена"
    else
        print_msg r "Отменено"
    fi
}
