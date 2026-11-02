#!/bin/bash
# ============================================================
# lib/functions.sh – Core functions for L43 Duplicate File Finder
# Student: PRIYANSH SHAH | Roll: E41 | Div: G | Enrollment: 24004501210390
# ============================================================

DATA="data/testfiles"
DUP_DIR="data/testfiles/_duplicates"
UNDO_LOG="logs/moved_files.txt"
LOG="logs/activity.log"

# Write formatted timestamped message to activity log
log() {
    mkdir -p logs
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$LOG"
}

# Check data folder exists and contains files
check_data() {
    if [ ! -d "$DATA" ]; then
        echo "Error: Data folder not found at '$DATA'."
        return 1
    fi
    local count
    count=$(find "$DATA" -maxdepth 1 -type f 2>/dev/null | wc -l)
    if [ "$count" -eq 0 ]; then
        echo "Warning: No regular files found in '$DATA'."
        return 1
    fi
    return 0
}

show_help() {
    echo "============================================================"
    echo "         L43 DUPLICATE FILE FINDER - COMMAND LINE HELP"
    echo "============================================================"
    echo "Usage:"
    echo "  ./main.sh            -> Open interactive menu"
    echo "  ./main.sh --help     -> Display this help message"
    echo "  ./main.sh --backup   -> Create tar.gz backup of data/ folder"
    echo "  ./main.sh --cron     -> Execute scheduled duplicate report scan"
    echo "============================================================"
}

view_data() {
    check_data || return 1
    echo "------------------------------------------------------------"
    echo "Listing files in: $DATA"
    echo "------------------------------------------------------------"
    ls -lh "$DATA" | grep -v '^total'
    local total_files
    total_files=$(find "$DATA" -maxdepth 1 -type f | wc -l)
    echo "------------------------------------------------------------"
    echo "Total files: $total_files"
    log "view_data: inspected $total_files files"
}

do_backup() {
    mkdir -p backups
    local f="backups/data_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$f" data/
    local size
    size=$(du -h "$f" | cut -f1)
    echo "------------------------------------------------------------"
    echo "Backup successfully created: $f"
    echo "Backup archive size: $size"
    echo "------------------------------------------------------------"
    log "do_backup: created archive $f (size: $size)"
}

view_log() {
    if [ -f "$LOG" ]; then
        echo "------------------------------------------------------------"
        echo "Recent Activity Log (Last 15 entries):"
        echo "------------------------------------------------------------"
        tail -n 15 "$LOG"
    else
        echo "No activity recorded yet in '$LOG'."
    fi
}

# ------------------------------------------------------------
# FEATURE 1: Compute md5sum for all files
# Commands used: find, md5sum, sort
# ------------------------------------------------------------
feature_1() {
    echo "============================================================"
    echo "FEATURE 1: Compute MD5 Checksums for All Files"
    echo "============================================================"
    check_data || return 1

    echo "Scanning regular files in '$DATA'..."
    echo "----------------------------------------------------------------------------------"
    printf "%-34s %-10s %s\n" "MD5 Checksum" "Size" "File Name"
    echo "----------------------------------------------------------------------------------"

    local total_count=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local hash="${line%% *}"
        local filepath="${line#*  }"
        local filename
        filename=$(basename "$filepath")
        local filesize
        filesize=$(du -h "$filepath" 2>/dev/null | cut -f1)

        printf "%-34s %-10s %s\n" "$hash" "$filesize" "$filename"
        total_count=$((total_count + 1))
    done < <(find "$DATA" -maxdepth 1 -type f -exec md5sum {} + 2>/dev/null | sort -k1,1)

    echo "----------------------------------------------------------------------------------"
    echo "Total files scanned: $total_count"
    log "feature_1: computed md5sum for $total_count files"
}

# ------------------------------------------------------------
# FEATURE 2: Group duplicates
# Commands used: find, md5sum, sort, uniq -w
# ------------------------------------------------------------
feature_2() {
    echo "============================================================"
    echo "FEATURE 2: Group Duplicate Files"
    echo "============================================================"
    check_data || return 1

    local tmp_sums="reports/.all_sums.tmp"
    local tmp_dups="reports/.dup_hashes.tmp"
    mkdir -p reports

    find "$DATA" -maxdepth 1 -type f -exec md5sum {} + 2>/dev/null | sort -k1,1 > "$tmp_sums"
    uniq -w 32 -d "$tmp_sums" | awk '{print $1}' > "$tmp_dups"

    local dup_groups
    dup_groups=$(wc -l < "$tmp_dups" | tr -d ' ')

    if [ "$dup_groups" -eq 0 ]; then
        echo "No duplicate files found in '$DATA'. All files have unique contents."
        rm -f "$tmp_sums" "$tmp_dups"
        log "feature_2: scan completed - no duplicates found"
        return 0
    fi

    echo "Found $dup_groups duplicate group(s) sharing identical MD5 checksums:"
    echo "----------------------------------------------------------------------------------"

    local group_idx=1
    local total_redundant=0

    while IFS= read -r hash; do
        [ -z "$hash" ] && continue
        echo "Group #$group_idx [MD5: $hash]:"
        
        local count=0
        while IFS= read -r row; do
            local fpath="${row#*  }"
            local fname
            fname=$(basename "$fpath")
            local fsize
            fsize=$(du -h "$fpath" | cut -f1)
            echo "   --> $fname ($fsize)"
            count=$((count + 1))
        done < <(grep "^$hash" "$tmp_sums")

        local redundant=$((count - 1))
        total_redundant=$((total_redundant + redundant))
        echo "   (Total copies: $count | Redundant duplicates: $redundant)"
        echo
        group_idx=$((group_idx + 1))
    done < "$tmp_dups"

    rm -f "$tmp_sums" "$tmp_dups"

    echo "----------------------------------------------------------------------------------"
    echo "Summary: $dup_groups duplicate group(s) | $total_redundant total redundant files"
    log "feature_2: identified $dup_groups duplicate groups ($total_redundant redundant files)"
}

# ------------------------------------------------------------
# FEATURE 3: Move duplicates to _duplicates/ (no delete)
# Commands used: find, md5sum, sort, uniq -w, mv, mkdir
# ------------------------------------------------------------
feature_3() {
    echo "============================================================"
    echo "FEATURE 3: Move Duplicates to _duplicates/ (No Delete)"
    echo "============================================================"
    check_data || return 1

    mkdir -p "$DUP_DIR" logs reports
    local tmp_sums="reports/.all_sums.tmp"
    local tmp_dups="reports/.dup_hashes.tmp"

    find "$DATA" -maxdepth 1 -type f -exec md5sum {} + 2>/dev/null | sort -k1,1 > "$tmp_sums"
    uniq -w 32 -d "$tmp_sums" | awk '{print $1}' > "$tmp_dups"

    local dup_groups
    dup_groups=$(wc -l < "$tmp_dups" | tr -d ' ')

    if [ "$dup_groups" -eq 0 ]; then
        echo "No duplicate files found to move."
        rm -f "$tmp_sums" "$tmp_dups"
        return 0
    fi

    touch "$UNDO_LOG"
    local moved_count=0
    echo "Processing duplicate groups and safely relocating redundant copies..."
    echo "Destination folder: $DUP_DIR"
    echo "----------------------------------------------------------------------------------"

    while IFS= read -r hash; do
        [ -z "$hash" ] && continue
        
        local is_first=1
        while IFS= read -r row; do
            local fpath="${row#*  }"
            local fname
            fname=$(basename "$fpath")

            if [ "$is_first" -eq 1 ]; then
                echo "[KEEP ORIGINAL] $fname"
                is_first=0
            else
                local target_dest="$DUP_DIR/$fname"
                if [ -e "$target_dest" ]; then
                    local base="${fname%.*}"
                    local ext="${fname##*.}"
                    if [ "$base" = "$ext" ]; then
                        target_dest="$DUP_DIR/${base}_$(date +%s%N)"
                    else
                        target_dest="$DUP_DIR/${base}_$(date +%s%N).$ext"
                    fi
                fi

                mv "$fpath" "$target_dest"
                echo "   --> [MOVED] $fname => $(basename "$target_dest")"
                echo "$fpath|$target_dest|$hash" >> "$UNDO_LOG"
                moved_count=$((moved_count + 1))
            fi
        done < <(grep "^$hash" "$tmp_sums")
        echo
    done < "$tmp_dups"

    rm -f "$tmp_sums" "$tmp_dups"

    echo "----------------------------------------------------------------------------------"
    echo "Relocation complete: Moved $moved_count duplicate file(s) into '$DUP_DIR'."
    echo "Originals remain intact in '$DATA'. Undo mapping logged in '$UNDO_LOG'."
    log "feature_3: moved $moved_count duplicate files to $DUP_DIR"
}

# ------------------------------------------------------------
# FEATURE 4: Report space saved (du)
# Commands used: du, ls, wc, cut
# ------------------------------------------------------------
feature_4() {
    echo "============================================================"
    echo "FEATURE 4: Report Space Saved (du)"
    echo "============================================================"

    if [ ! -d "$DUP_DIR" ]; then
        echo "No duplicates folder exists at '$DUP_DIR'."
        echo "Run Feature 3 first to move duplicate files."
        return 0
    fi

    local count
    count=$(find "$DUP_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)

    if [ "$count" -eq 0 ]; then
        echo "The duplicate isolation directory '$DUP_DIR' is currently empty."
        echo "No disk space is currently held by isolated duplicates."
        return 0
    fi

    local total_saved
    total_saved=$(du -sh "$DUP_DIR" | cut -f1)

    echo "Storage Savings Summary:"
    echo "----------------------------------------------------------------------------------"
    printf "%-35s : %s\n" "Duplicate directory" "$DUP_DIR"
    printf "%-35s : %s\n" "Total duplicate files moved" "$count"
    printf "%-35s : %s\n" "Total storage reclaimed in data/" "$total_saved"
    echo "----------------------------------------------------------------------------------"
    echo "Detailed breakdown of moved duplicate files:"
    ls -lh "$DUP_DIR" | grep -v '^total'
    echo "----------------------------------------------------------------------------------"
    log "feature_4: reported $total_saved saved across $count files"
}

# ------------------------------------------------------------
# FEATURE 5: Undo by moving them back
# Commands used: mv, rm, rmdir, log
# ------------------------------------------------------------
feature_5() {
    echo "============================================================"
    echo "FEATURE 5: Undo Duplicate Relocation (Move Back)"
    echo "============================================================"

    if [ ! -f "$UNDO_LOG" ] || [ ! -s "$UNDO_LOG" ]; then
        if [ -d "$DUP_DIR" ] && [ "$(find "$DUP_DIR" -maxdepth 1 -type f | wc -l)" -gt 0 ]; then
            echo "Undo manifest not found, but files detected in '$DUP_DIR'. Restoring directly..."
            local restored=0
            for f in "$DUP_DIR"/*; do
                [ -f "$f" ] || continue
                local fname
                fname=$(basename "$f")
                mv "$f" "$DATA/$fname"
                echo "Restored: $fname => $DATA/"
                restored=$((restored + 1))
            done
            rmdir "$DUP_DIR" 2>/dev/null
            echo "Restored $restored file(s) to '$DATA'."
            log "feature_5: direct restore of $restored files from $DUP_DIR"
            return 0
        fi
        echo "Nothing to undo! No records found in '$UNDO_LOG' and '$DUP_DIR' is empty."
        return 0
    fi

    local restored_count=0
    echo "Restoring duplicate files to their original locations..."
    echo "----------------------------------------------------------------------------------"

    while IFS='|' read -r orig_path moved_path hash; do
        [ -z "$moved_path" ] && continue
        if [ -f "$moved_path" ]; then
            mv "$moved_path" "$orig_path"
            echo "Restored: $(basename "$moved_path") => $orig_path"
            restored_count=$((restored_count + 1))
        else
            echo "Warning: File not found at '$moved_path' (already moved or deleted)."
        fi
    done < "$UNDO_LOG"

    rm -f "$UNDO_LOG"
    if [ -d "$DUP_DIR" ]; then
        rmdir "$DUP_DIR" 2>/dev/null
    fi

    echo "----------------------------------------------------------------------------------"
    echo "Undo complete: Successfully restored $restored_count file(s) to '$DATA'."
    log "feature_5: successfully undone relocation, restored $restored_count files"
}

# ------------------------------------------------------------
# CRON TASK: Scheduled duplicate scan (report-only mode)
# Schedule: Every Sunday at 3 AM (0 3 * * 0)
# ------------------------------------------------------------
cron_task() {
    mkdir -p reports logs
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="reports/dup_report_$(date +%Y%m%d_%H%M%S).txt"

    echo "============================================================" > "$report_file"
    echo "  L43 DUPLICATE FILE FINDER - SCHEDULED AUDIT REPORT" >> "$report_file"
    echo "  Run Time: $timestamp" >> "$report_file"
    echo "  Target Folder: $DATA" >> "$report_file"
    echo "============================================================" >> "$report_file"
    echo >> "$report_file"

    if [ ! -d "$DATA" ]; then
        echo "Error: Data folder '$DATA' not found." >> "$report_file"
        echo "$timestamp | CRON ERROR: Data folder not found" >> reports/cron_output.txt
        log "cron_task failed: $DATA not found"
        return 1
    fi

    local tmp_sums="reports/.cron_sums.tmp"
    find "$DATA" -maxdepth 1 -type f -exec md5sum {} + 2>/dev/null | sort -k1,1 > "$tmp_sums"

    local total_files
    total_files=$(wc -l < "$tmp_sums" | tr -d ' ')

    local tmp_dups="reports/.cron_dups.tmp"
    uniq -w 32 -d "$tmp_sums" | awk '{print $1}' > "$tmp_dups"

    local dup_groups
    dup_groups=$(wc -l < "$tmp_dups" | tr -d ' ')

    echo "Total files checked: $total_files" >> "$report_file"
    echo "Duplicate groups detected: $dup_groups" >> "$report_file"
    echo >> "$report_file"

    if [ "$dup_groups" -eq 0 ]; then
        echo "Status: CLEAN. No duplicate files detected." >> "$report_file"
    else
        echo "DUPLICATE GROUPS BREAKDOWN:" >> "$report_file"
        echo "------------------------------------------------------------" >> "$report_file"
        while IFS= read -r hash; do
            [ -z "$hash" ] && continue
            echo "MD5 Checksum: $hash" >> "$report_file"
            grep "^$hash" "$tmp_sums" | while IFS= read -r line; do
                local fpath="${line#*  }"
                local fsize
                fsize=$(du -h "$fpath" | cut -f1)
                echo "   - $(basename "$fpath") ($fsize)" >> "$report_file"
            done >> "$report_file"
            echo >> "$report_file"
        done < "$tmp_dups"
    fi

    rm -f "$tmp_sums" "$tmp_dups"

    echo "Report generated and saved to: $report_file"
    echo "$timestamp | CRON SUCCESS: Checked $total_files files, found $dup_groups duplicate groups -> $report_file" >> reports/cron_output.txt
    log "cron_task completed: $total_files files checked, $dup_groups dup groups found"
}
