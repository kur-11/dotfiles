#!/bin/bash

if [[ "$1" =~ https?://(.*\.)?youtube.com/.* ]] && command -v mpv &>/dev/null; then
    mpv "$1"
elif command -v xdg-open &>/dev/null; then
    xdg-open "$1"
elif command -v open &>/dev/null; then
    open "$1"
elif command -v w3m &>/dev/null; then
    w3m "$1"
fi
