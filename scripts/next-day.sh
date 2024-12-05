#!/usr/bin/env bash

set -euo pipefail

NC='\033[0m'
BOLD='\033[1m'

RED='\033[0;31m'
BLUE='\033[0;34m'

info() { echo -e "${BLUE}$1${NC}"; }
error() { echo -e "\n${RED}$1${NC}" >&2; }

repo_root=$(git rev-parse --show-toplevel)
current_dir=$(pwd)
if [ "$repo_root" != "$current_dir" ]; then
    error "🏠 Must be run from repository root"
    exit 1
fi

info "🔍 Finding next day to create..."
next_day=$(ls -d day* 2>/dev/null | sort -V | tail -n1 | sed 's/day0*//' || echo 0)
next_day=$((next_day + 1))

info "📦 Creating ${BOLD}day$(printf "%02d" "$next_day")${NC}..."
new-day "$next_day"
