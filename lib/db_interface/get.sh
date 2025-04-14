# copy_tip() {
#     local tip=$(get_tip "$1")
#     eval "$tip"
#     local command="${tip[1]}"

#     if command -v xclip &> /dev/null; then
#         echo -n "$command" | xclip -selection clipboard
#         print_msg g "Команда скопирована в буфер обмена (xclip): $command"
#     elif command -v pbcopy &> /dev/null; then
#         echo -n "$command" | pbcopy
#         print_msg g "Команда скопирована в буфер обмена (pbcopy): $command"
#     else
#         die "Ошибка: не найдены xclip или pbcopy для копирования в буфер"
#     fi
# }

# insert_tip() {
#     local tip=$(get_tip $1)
#     eval "$tip"
#     local command="${tip[1]}"
    
#     if [ -n "$TMUX" ]; then
#         # Если внутри tmux
#         tmux send-keys -t "$TMUX_PANE" "$command"
#     else
#         # Для обычного терминала (зависит от терминала)
#         if [ -n "$SSH_TTY" ] || [ "$(tty | cut -c 1-8)" = "/dev/pts" ]; then
#             # Работает для многих терминалов (xterm, gnome-terminal и т.д.)
#             printf '\e]51;["call","Terminal","insert",{"text":"%s"}]\a' "$command"
#         else
#             # Альтернативный метод (может не работать везде)
#             echo -n "$command" > /dev/tty
#         fi
#     fi
# }