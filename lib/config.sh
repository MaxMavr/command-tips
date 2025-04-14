# Меняй!
readonly VERSION="1.3.1"
readonly DB_FILE="$HOME/.tips_db.csv"
readonly CLEAN_MODE=0

readonly ID_TITLE="ID"
readonly COMMAND_TITLE="Команда"
readonly COMMENT_TITLE="Комментарий"
readonly TAGS_TITLE="Теги"
readonly TIMESTAMP_TITLE="Дата"

readonly TABLE_SEP="   "

# Нельзя менять
declare -A FIELD_TITLES=(
    ["id"]="$ID_TITLE"
    ["command"]="$COMMAND_TITLE"
    ["comment"]="$COMMENT_TITLE"
    ["tags"]="$TAGS_TITLE"
    ["timestamp"]="$TIMESTAMP_TITLE"
)
readonly FIELD_TITLES

readonly DICT_NAMES=("id" "command" "comment" "tags" "timestamp")
