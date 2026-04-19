#!/bin/bash
set -euo pipefail

RED='\033[31m'
YELLOW='\033[33m'
RESET='\033[0m'

log() {
    echo "[$(date +'%H:%M:%S')] $1"
}

if [ -z "${1:-}" ]; then
    echo -e "${RED}Error: You must provide a directory.${RESET}"
    exit 1
fi

DIR=$1

log "Starting scan in: $DIR"

find "$DIR" -name '*.html' | {
    
    TOTAL_FILES=0
    TOTAL_ISSUES=0
    CLEAN_FILES=0

    while read -r file; do
        TOTAL_FILES=$((TOTAL_FILES + 1))
        ISSUES_IN_THIS_FILE=0

        if grep -i "<img" "$file" | grep -v -i "alt=" > /dev/null; then
            echo -e "${RED}[ERROR]${RESET} $file: Found <img> without alt="
            ISSUES_IN_THIS_FILE=$((ISSUES_IN_THIS_FILE + 1))
        fi

        INPUT_COUNT=$(grep -c -i "<input" "$file" || true)
        LABEL_COUNT=$(grep -c -i "<label" "$file" || true)
        
        if [ "$INPUT_COUNT" -gt "$LABEL_COUNT" ]; then
            echo -e "${YELLOW}[WARNING]${RESET} $file: More inputs ($INPUT_COUNT) than labels ($LABEL_COUNT)."
            ISSUES_IN_THIS_FILE=$((ISSUES_IN_THIS_FILE + 1))
        fi

        HEADINGS=$(grep -o -E "h[1-3]" "$file" || true)
        
        SEEN_H1=0
        SEEN_H2=0

        for h in $HEADINGS; do
            if [ "$h" == "h1" ]; then SEEN_H1=1; fi
            if [ "$h" == "h2" ]; then SEEN_H2=1; fi

            if [ "$h" == "h2" ] && [ "$SEEN_H1" -eq 0 ]; then
                echo -e "${RED}[ERROR]${RESET} $file: <h2> found before <h1>"
                ISSUES_IN_THIS_FILE=$((ISSUES_IN_THIS_FILE + 1))
            fi
            
            if [ "$h" == "h3" ] && [ "$SEEN_H2" -eq 0 ]; then
                echo -e "${RED}[ERROR]${RESET} $file: <h3> found before <h2>"
                ISSUES_IN_THIS_FILE=$((ISSUES_IN_THIS_FILE + 1))
            fi
        done

        TOTAL_ISSUES=$((TOTAL_ISSUES + ISSUES_IN_THIS_FILE))
        if [ "$ISSUES_IN_THIS_FILE" -eq 0 ]; then
            CLEAN_FILES=$((CLEAN_FILES + 1))
        fi

    done

    log "Audit Complete."
    echo "Files Scanned: $TOTAL_FILES"
    echo "Total Issues:  $TOTAL_ISSUES"
    echo "Perfect Files: $CLEAN_FILES"
}
