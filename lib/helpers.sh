#!/bin/bash

print_msg() {
    local color=$1; shift
    case $color in
        r) printf "\033[31m$*\033[0m" ;;
        g) printf "\033[32m$*\033[0m" ;;
        y) printf "\033[33m$*\033[0m" ;;
        *) printf "$*" ;;
    esac
}