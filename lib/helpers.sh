#!/bin/bash

print_message() {
    local color=$1; shift
    case $color in
        red)    echo -e "\033[31m$*\033[0m" ;;
        green)  echo -e "\033[32m$*\033[0m" ;;
        yellow) echo -e "\033[33m$*\033[0m" ;;
        *)      echo -e "$*" ;;
    esac
}