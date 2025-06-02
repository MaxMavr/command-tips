search_tips() {
    check_db

    local query="$1"
    local all_tags="$2"
    local any_tags="$3"

    local -a ids=("$ID_TITLE") commands=("$COMMAND_TITLE") comments=("$COMMENT_TITLE") tagss=("$TAGS_TITLE")
    local max_length_id=0 max_length_command=0 max_length_comment=0

    for ((i=1; i<="$(count_tips)"; i++)); do
        raw_tip=$(get_tip "$i") || { continue; }
        eval "$raw_tip"

        local include=0

        local command="${tip[command]}"
        local comment="${tip[comment]}"
        if [[ -n "$query" && ( "$comment" == *"$query"* || "$command" == *"$query"* ) ]]; then
            include=1
        fi

        local tags="${tip[tags]}"
        IFS=',' read -ra tags_array <<< "$tags"

        for j in "${!tags_array[@]}"; do
            tags_array[$j]=$(echo "${tags_array[$j]}" | tr -d '[:space:]')
        done

        # Проверка любого тега (OR логика)
        if [[ $include -eq 0 && -n "$any_tags" ]]; then
            IFS=',' read -ra any_tags_array <<< "$any_tags"

            for j in "${!any_tags_array[@]}"; do
                any_tags_array[$j]=$(echo "${any_tags_array[$j]}" | tr -d '[:space:]')
            done

            for tag in "${any_tags_array[@]}"; do
                for t in "${tags_array[@]}"; do
                    if [[ "$t" == "$tag" ]]; then
                        include=1
                        break 2
                    fi
                done
            done
        fi

        # Проверка всех тегов (AND логика)
        if [[ $include -eq 0 && -n "$all_tags" ]]; then
            IFS=',' read -ra all_tags_array <<< "$all_tags"
            
            for j in "${!all_tags_array[@]}"; do
                all_tags_array[$j]=$(echo "${all_tags_array[$j]}" | tr -d '[:space:]')
            done

            local all_include=1

            for tag in "${all_tags_array[@]}"; do
                local found=0
                for t in "${tags_array[@]}"; do
                    if [[ "$t" == "$tag" ]]; then
                        found=1
                        break
                    fi
                done

                if [[ $found -eq 0 ]]; then
                    all_include=0
                    break
                fi
            done

            if [[ $all_include -eq 1 ]]; then
                include=1
            fi
        fi

        if [[ $include -eq 1 ]]; then
            ids+=("${tip[id]}")
            commands+=("$command")
            comments+=("$comment")
            tagss+=("$tags")

            (( ${#tip[id]} > max_length_id )) && max_length_id=${#tip[id]}
            (( ${#tip[command]} > max_length_command )) && max_length_command=${#tip[command]}
            (( ${#tip[comment]} > max_length_comment )) && max_length_comment=${#tip[comment]}
        fi
    done

    if [[ ${#ids[@]} -eq 1 ]]; then
        [[ "$CLEAN_MODE" -eq 0 ]] && { print_msg "Не нашёл ни одной записи"; exit 0; }
    fi

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
}