#!/bin/bash

terminal_width=$(tput cols)

usage() {
    echo Usage: "${0##/}" leftDir rightDir
    echo Shows difference between each dir
    exit 0
}

error_exit() {
    echo "$@" >&2
    exit 1
}

get_files() {
    local left="$1" right="$2" current="$3" f trimmed
    for f in "${left%%/}/${current%%/}/"*; do
        trimmed="${f/"$left/"//}"
        if [ -d "$f" ]; then
            get_files "$left" "$right" "${trimmed%%/}/"
        else
            echo "${trimmed#/}"
        fi
    done
}

print_diff() {
    local left="$1" right="$2" relative="$3"
    if [ ! -f "$left/$relative" ]; then
        printf "\n"
        echo "+++ File added: ${right%%/}/$relative"
        printf "\n\n"
    elif [ ! -f "$right/$relative" ]; then
        printf "\n"
        echo "--- File removed: ${left%%/}/$relative"
        printf "\n\n"
    else
        result=$(diff -I '^package' "$left/$relative" "$right/$relative")
        if [ -n "$result" ]; then
            printf "### %s\n%s\n" "$relative" "$result"
            printf "%*s\n\n" "$terminal_width" "" | tr " " "="
        fi
    fi
}

array_exists() {
    printf '%s\n' "$1" | grep -qx "$2"
    return $?
}

[ -n "$1" ] && [ -n "$2" ] || usage

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

[ -d "$1" ] || error_exit "cannot stat dir: $1"
[ -d "$2" ] || error_exit "cannot stat dir: $2"

printf "%s <|> %s\n\n" "$1" "$2"

file_list=()

while IFS= read -r line; do
  if ! array_exists "${file_list[@]}" "$line"; then
    file_list+=("$line")
  fi
done < <(get_files "${1}" "${2}" "")

while IFS= read -r line; do
  if ! array_exists "${file_list[@]}" "$line"; then
    file_list+=("$line")
  fi
done < <(get_files "${2}" "${1}" "")

for relative in "${file_list[@]}"; do
    print_diff "$1" "$2" "$relative"
done
