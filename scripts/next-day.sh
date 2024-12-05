#!/usr/bin/env bash

set -euo pipefail

BOLD='\033[1m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}$1${NC}"; }

info "🔍 Finding next day to create..."
next_day=$(ls -d day* 2>/dev/null | sort -V | tail -n1 | sed 's/day0*//' || echo 0)
next_day=$((next_day + 1))

info "📦 Creating ${BOLD}day$(printf "%02d" "$next_day")${NC}..."
new-day "$next_day"
