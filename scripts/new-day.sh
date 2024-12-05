#!/usr/bin/env bash

set -euo pipefail

NC='\033[0m'
BOLD='\033[1m'

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
LIGHT_GREY='\033[0;37m'
GREY='\033[0;90m'

info() { echo -e "${BLUE}$1${NC}"; }
success() { echo -e "\n${GREEN}$1${NC}"; }
error() { echo -e "\n${RED}$1${NC}" >&2; }

repo_root=$(git rev-parse --show-toplevel)
current_dir=$(pwd)
if [ "$repo_root" != "$current_dir" ]; then
    error "🏠 Must be run from repository root"
    exit 1
fi

if [ $# -ne 1 ] || ! [[ $1 =~ ^[0-9]+$ ]]; then
    error "🎅 Ho ho ho! Please provide a day number"
    exit 1
fi

# Check if AOC_SESSION is set
if [ -z "${AOC_SESSION:-}" ]; then
    error "🔑 Missing session cookie! Set AOC_SESSION environment variable"
    exit 1
fi

# Pad day number with leading zero if needed
day_num=$(printf "%02d" "$1")
day_name="day${day_num}"

info "⬇️  Downloading puzzle input for ${BOLD}$day_name${NC}..."

# Create temporary files
temp_input=$(mktemp)
temp_output=$(mktemp)

# Download input first
if ! curl --fail --silent --show-error --cookie "session=${AOC_SESSION}" \
     --output "$temp_input" \
     "https://adventofcode.com/2024/day/$1/input" 2> "$temp_output"; then
    error "🌐 Network error: Failed to download input:"
    echo -e "${GREY}$(cat "$temp_output")${NC}" >&2
    rm "$temp_input" "$temp_output"
    exit 1
fi

if [ $? -ne 0 ]; then
    error "🌐 Network error: Failed to download input"
    rm "$temp_input" "$temp_output"
    exit 1
fi

success "📥 Input downloaded successfully"
info "🛠️  Creating Gleam project ${BOLD}$day_name${NC}..."

# Run gleam and capture output to temp file
if ! gleam new "$day_name" --skip-git --skip-github > "$temp_output" 2>&1; then
    error "🚨 Failed to create Gleam project:"
    echo -e "${GREY}$(cat "$temp_output")${NC}" >&2
    rm "$temp_input" "$temp_output"
    exit 1
fi

add_dependency() {
    local dep="$1"
    if ! gleam add $dep > "$temp_output" 2>&1; then
        error "🚨 Failed to add $dep dependency:"
        echo -e "${GREY}$(cat "$temp_output")${NC}" >&2
        rm "$temp_input" "$temp_output"
        exit 1
    fi
}

cd "$day_name"
add_dependency simplifile
cd ..

rm "$day_name/README.md"
mv "$temp_input" "$day_name/input.txt"
touch "$day_name/small-in.txt"

cp templates/day.gleam "$day_name/src/day${day_num}.gleam"
sed "s/__DAY_NUM__/$day_num/g" templates/day_test.gleam > "$day_name/test/day${day_num}_test.gleam"

rm "$temp_output"
success "🎄 All ready for day $day_num! Let's solve some puzzles! ⭐"
echo -e "   ${GREY}.. Problem available at: ${LIGHT_GREY}${BOLD}https://adventofcode.com/2024/day/$1${NC}"
