#!/usr/bin/env bash

set -euo pipefail

# Colors and formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
error() { echo -e "${RED}$1${NC}" >&2; }

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
curl --fail --silent --cookie "session=${AOC_SESSION}" \
     --output "$temp_input" \
     "https://adventofcode.com/2024/day/$1/input"

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
    cat "$temp_output"
    rm "$temp_input" "$temp_output"
    exit 1
fi

cd "$day_name"
if ! gleam add simplifile --dev > "$temp_output" 2>&1; then
    error "🚨 Failed to simplifile add dependency:"
    cat "$temp_output"
    rm "$temp_input" "$temp_output"
    exit 1
fi
cd ..

rm "$day_name/README.md"
mv "$temp_input" "$day_name/input.txt"
touch "$day_name/small-in.txt"

cp templates/day.gleam "$day_name/src/day${day_num}.gleam"
sed "s/__DAY_NUM__/$day_num/g" templates/day_test.gleam > "$day_name/test/day${day_num}_test.gleam"

rm "$temp_output"
success "🎄 All ready for day $day_num! Let's solve some puzzles! ⭐"