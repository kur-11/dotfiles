#!/bin/bash

cache_dir="$HOME/.newsboat/cache"
install -Dd "$cache_dir"

find "$cache_dir" -mmin +60 -delete

get() {
    local sum=$(echo "$1" | md5sum | cut -d' ' -f1)
    local cache="$cache_dir/$sum"
    [[ -f "$cache" ]] \
        || curl -Ss -o "$cache" "$1"
    cat "$cache"
}

channel_id=$(get "$1" | pup '[itemprop="channelId"] attr{content}')

if [[ -n "$channel_id" ]]; then
    get "https://www.youtube.com/feeds/videos.xml?channel_id=$channel_id"
fi
