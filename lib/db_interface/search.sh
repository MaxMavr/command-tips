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
        tput cuf $(( max_length_id - ${#ids[$i]} ))
        echo -n "$TABLE_SEP"
        echo -n "${commands[$i]}"
        tput cuf $(( max_length_command - ${#commands[$i]}))
        echo -n "$TABLE_SEP"
        echo -n "${comments[$i]}"
        tput cuf $(( max_length_comment - ${#comments[$i]}))
        echo -n "$TABLE_SEP"
        echo "${tagss[$i]}"
    done
}