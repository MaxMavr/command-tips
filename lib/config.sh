#!/bin/bash

# Константы в верхнем регистре
readonly TIPS_FILE=~/.command_tips
readonly HISTORY_FILE=~/.bash_history
readonly TIPS_FORMAT="%d|%s|%s|%s|%s"  # номер|команда|комментарий|теги|дата_создания

readonly VERSION="1.2"

# Инициализация файла подсказок
init_tips_file() {
    [ ! -f "$TIPS_FILE" ] && touch "$TIPS_FILE"
}