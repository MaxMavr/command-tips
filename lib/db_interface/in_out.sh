count_tips() {
    if [[ -f "$DB_FILE" ]]; then
        wc -l < "$DB_FILE"
    else
        echo 0
    fi
}

save_tip() {
    local command="$1"
    local comment="$2"
    local tags="$3"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local id="$4"

    tags=$(echo "$tags" | sed -E 's/[[:space:]]*,[[:space:]]*/, /g; s/^[[:space:]]*,[[:space:]]*//; s/[[:space:]]*,[[:space:]]*$//')

    echo "--- $id"
    id=${id:-$(get_free_id_db)}
    echo "--- $id"
    id=${id:-$(( $(count_tips) + 1 ))}
    echo "--- $id"

    declare -A tip=(
    ["id"]="$id"
    ["command"]="$command"
    ["comment"]="$comment"
    ["tags"]="$tags"
    ["timestamp"]="$timestamp"
    )

    serialized=$(sed 's|/|\\/|g' <<< "$(declare -p tip)")
    
    if [[ $id -gt $(count_tips) ]]; then
        echo "$serialized" >> "$DB_FILE"
    else
        sed -i "${id}s/.*/$serialized/" "$DB_FILE"
    fi
}

get_tip() {
    local id="$1"
    
    [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]] && { return 1; }
    
    local tip=$(sed -n "${id}p" "$DB_FILE")

    [[ -z "${tip// }" ]] && { return 1; }
    
    echo "$tip"
}
