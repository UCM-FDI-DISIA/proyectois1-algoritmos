#!/bin/sh
printf '\033c\033]0;%s\a' Feudalia
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Feudalia_Linux.x86_64" "$@"
