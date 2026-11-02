#!/bin/bash
# ============================================================
# main.sh – L43 Duplicate File Finder
# Student: PRIYANSH SHAH | Roll: E41 | Div: G | Enrollment: 24004501210390
# Menu-driven shell script (while loop + case)
# ============================================================

# Ensure script operates relative to its directory
cd "$(dirname "$0")" || exit 1

# Source core library functions
if [ -f "lib/functions.sh" ]; then
    source lib/functions.sh
else
    echo "Fatal Error: 'lib/functions.sh' not found!" >&2
    exit 1
fi

# Ensure prerequisite directories exist
mkdir -p lib data/testfiles reports backups logs

# Handle Command-Line Arguments ($1)
case "$1" in
    --help)
        show_help
        exit 0
        ;;
    --backup)
        do_backup
        exit 0
        ;;
    --cron)
        cron_task
        exit 0
        ;;
    "")
        # No CLI argument passed; proceed to interactive menu
        ;;
    *)
        echo "Error: Unknown argument '$1'"
        echo "Try './main.sh --help' for available options."
        exit 1
        ;;
esac

# Interactive Menu Loop
while true; do
    echo
    echo "============================================================"
    echo "         L43 - DUPLICATE FILE FINDER (PRIYANSH SHAH)        "
    echo "============================================================"
    echo " 1) Compute md5sum for all files"
    echo " 2) Group duplicates"
    echo " 3) Move duplicates to _duplicates/ (no delete)"
    echo " 4) Report space saved (du)"
    echo " 5) Undo by moving them back"
    echo " 6) View data"
    echo " 7) Backup data (tar.gz)"
    echo " 8) View activity log"
    echo " 0) Exit"
    echo "============================================================"
    read -p "Select an option [0-8]: " ch

    # Input Validation: check if empty
    if [ -z "$ch" ]; then
        echo "Error: Input cannot be empty. Please select an option between 0 and 8."
        continue
    fi

    # Input Validation: check if valid single integer 0-8
    if [[ ! "$ch" =~ ^[0-8]$ ]]; then
        echo "Error: Invalid choice '$ch'. Please enter a number from 0 to 8."
        continue
    fi

    echo
    case "$ch" in
        1)
            feature_1
            ;;
        2)
            feature_2
            ;;
        3)
            feature_3
            ;;
        4)
            feature_4
            ;;
        5)
            feature_5
            ;;
        6)
            view_data
            ;;
        7)
            do_backup
            ;;
        8)
            view_log
            ;;
        0)
            echo "Exiting Duplicate File Finder. Goodbye!"
            log "main.sh: user exited session"
            break
            ;;
    esac

    echo
    read -p "Press [Enter] to return to the menu..." dummy
done
