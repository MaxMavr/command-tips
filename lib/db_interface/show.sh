# TODO Вывод работает некорректно 
# TODO Почему то tput cuf $(( max_length_id - ${#ids[$i]} )) не правильно счиатет отступ
list_tips() {
    check_db

    local -a ids=("$ID_TITLE") commands=("$COMMAND_TITLE") comments=("$COMMENT_TITLE") tagss=("$TAGS_TITLE")
    local max_length_id=${#ID_TITLE} max_length_command=${#COMMAND_TITLE} max_length_comment=${#COMMENT_TITLE}

    for ((i=1; i<="$(count_tips)"; i++)); do
        raw_tip=$(get_tip "$i") || { continue; }
        eval "$raw_tip"

        ids+=("${tip[id]}")
        commands+=("${tip[command]}")
        comments+=("${tip[comment]}")
        tagss+=("${tip[tags]}")

        (( ${#tip[id]} > max_length_id )) && max_length_id=${#tip[id]}
        (( ${#tip[command]} > max_length_command )) && max_length_command=${#tip[command]}
        (( ${#tip[comment]} > max_length_comment )) && max_length_comment=${#tip[comment]}
    done

    for ((i=0; i<${#ids[@]}; i++)); do
        tput cuf $(( max_length_id - ${#ids[$i]} )) 
        echo -n "${ids[$i]}"
        echo -n "$TABLE_SEP"
        echo -n "${commands[$i]}"
        tput cuf $(( max_length_command - ${#commands[$i]} )) 
        echo -n "$TABLE_SEP"
        echo -n "${comments[$i]}"
        tput cuf $(( max_length_comment - ${#comments[$i]} )) 
        echo -n "$TABLE_SEP"
        echo "${tagss[$i]}"
    done

    # echo "$max_length_id"
    # echo "$max_length_command"
    # echo "$max_length_comment"

    # for ((i=0; i<${#ids[@]}; i++)); do
    #     printf "%-${max_length_id}s%s" "${ids[$i]}" "$TABLE_SEP"
    #     printf "%-${max_length_command}s%s" "${commands[$i]}" "$TABLE_SEP"
    #     printf "%-${max_length_comment}s%s" "${comments[$i]}" "$TABLE_SEP"
    #     printf "%s\n" "${tagss[$i]}"
    # done
}

info_tip() {
    raw_tip=$(get_tip "$1") || { die "запись с ID $1 не найдена\nИли неверный ID. Укажите числовой идентификатор подсказки."; }
    eval "$raw_tip"

    echo
    for name in "${DICT_NAMES[@]}"; do
        local offset=$(( ${#tip[$name]} > ${#FIELD_TITLES[$name]} ? ${#tip[$name]} : ${#FIELD_TITLES[$name]} ))
        tput sc
        tput cuu 1
        echo -n "${FIELD_TITLES[$name]}"
        tput rc
        echo -n "${tip[$name]}"
        tput cuf $(( offset - ${#tip[$name]} ))
        echo -n "$TABLE_SEP"
    done
    echo
}
