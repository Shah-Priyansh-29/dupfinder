#!/bin/bash
# ============================================================
# populate_testdata.sh - Generate realistic test files with intentional duplicates
# ============================================================
TARGET_DIR="data/testfiles"
mkdir -p "$TARGET_DIR"

# Content 1: Students CSV
CONTENT_CSV="StudentID,StudentName,Course,Marks,Grade
E01,Aarav Patel,Linux Lab,88,A
E02,Diya Sharma,Linux Lab,92,A+
E15,Rohan Mehta,Linux Lab,76,B
E41,Priyansh Shah,Linux Lab,95,A+
E52,Ananya Joshi,Linux Lab,84,B+"

echo "$CONTENT_CSV" > "$TARGET_DIR/students_sem5.csv"
echo "$CONTENT_CSV" > "$TARGET_DIR/students_sem5_backup.csv"
echo "$CONTENT_CSV" > "$TARGET_DIR/students_sem5_copy.csv"

# Content 2: Database Config
CONTENT_CFG="[Database]
host = 127.0.0.1
port = 5432
dbname = linux_lab_db
user = dbadmin
pool_size = 20
timeout = 30"

echo "$CONTENT_CFG" > "$TARGET_DIR/database_config.cfg"
echo "$CONTENT_CFG" > "$TARGET_DIR/database_config_dup.cfg"

# Content 3: Project Notes
CONTENT_NOTES="Linux Project L43: Duplicate File Finder
Features to verify:
1. md5sum checksum calculation
2. Duplicate grouping via sort and uniq -w 32
3. Safe relocation to _duplicates/
4. du storage savings calculation
5. Undo rollback"

echo "$CONTENT_NOTES" > "$TARGET_DIR/project_notes.txt"
echo "$CONTENT_NOTES" > "$TARGET_DIR/project_notes_copy.txt"

# Content 4: Server Access Log
CONTENT_LOG="2026-10-28 10:15:22 GET /index.html 200 4520
2026-10-28 10:15:35 GET /api/status 200 128
2026-10-28 10:16:01 POST /api/login 200 512
2026-10-28 10:17:44 GET /dashboard 200 8920"

echo "$CONTENT_LOG" > "$TARGET_DIR/server_access.log"
echo "$CONTENT_LOG" > "$TARGET_DIR/server_access_old.log"

# Content 5: System Metrics JSON
CONTENT_JSON='{"hostname":"lab-workstation-04","cpu_usage_pct":18.4,"memory_used_mb":4120,"disk_free_gb":142.8,"status":"healthy"}'

echo "$CONTENT_JSON" > "$TARGET_DIR/system_metrics.json"
echo "$CONTENT_JSON" > "$TARGET_DIR/system_metrics_copy.json"

# 15 Unique Non-Duplicate Files
echo "RollNo,Subject,MidtermMarks,MaxMarks
E41,Operating Systems,28,30
E41,Database Management,27,30
E41,Computer Networks,29,30" > "$TARGET_DIR/grades_midterm.csv"

echo "Course Syllabus: Linux Systems Programming
Unit 1: Bash Scripting, Shell Variables, Control Structures
Unit 2: Text Filters: grep, sed, awk, cut, sort, uniq
Unit 3: File Management, Permissions, Inodes, du, df
Unit 4: Process Management, Signals, Crontab Automation" > "$TARGET_DIR/course_syllabus.txt"

echo "LINUX CHEATSHEET
- md5sum <file>       : Generate 32-hex MD5 digest
- sort -k1,1          : Sort text by first column
- uniq -w 32 -d       : Show duplicate lines by first 32 characters
- du -sh <folder>     : Show disk usage in human format
- tar -czf <out> <in> : Create gzipped tarball archive" > "$TARGET_DIR/linux_commands_cheatsheet.txt"

echo "Date,RollNo,StudentName,Status
2026-10-20,E41,Priyansh Shah,Present
2026-10-21,E41,Priyansh Shah,Present
2026-10-27,E41,Priyansh Shah,Present" > "$TARGET_DIR/lab_attendance.csv"

echo "[Network]
primary_gateway = 192.168.1.1
dns_primary = 8.8.8.8
dns_secondary = 1.1.1.1
subnet_mask = 255.255.255.0" > "$TARGET_DIR/network_hosts.cfg"

echo '{"theme":"dark","editor":"nano","tab_size":4,"auto_save":true,"telemetry":false}' > "$TARGET_DIR/app_settings.json"

echo "2026-10-28 08:30:12 [WARN] High memory usage detected on core 2
2026-10-28 08:35:40 [INFO] Garbage collection cycle complete, freed 180MB" > "$TARGET_DIR/error_trace.log"

echo "# Bash Scripting Quick Guide
- Use #!/bin/bash as shebang
- Quote variables: \"\$VAR\"
- Use [[ ]] for robust conditional checks
- Redirect standard output and error with >> file 2>&1" > "$TARGET_DIR/bash_scripting_guide.md"

echo "Presentation Outline - Sem 5 Linux Project
1. Problem statement & real-world storage challenges
2. Checksum hashing theory (MD5 vs SHA256)
3. Filter pipeline: find -> md5sum -> sort -> uniq -w 32
4. Non-destructive duplicate relocation
5. Verification of du storage reclaim & cron automation" > "$TARGET_DIR/final_presentation_outline.txt"

echo "FacultyID,FacultyName,Department,Email,OfficeRoom
F101,Prof. Dr. Verma,Computer Engineering,verma@university.edu,C-302
F104,Prof. Desai,Information Technology,desai@university.edu,C-310" > "$TARGET_DIR/faculty_contacts.csv"

echo "HARDWARE CONFIGURATION
Processor: Intel Core i7 12th Gen / 16 Virtual Cores
RAM: 16 GB DDR4 @ 3200 MHz
Storage: 512 GB NVMe SSD
OS: Ubuntu 22.04 LTS (WSL2)" > "$TARGET_DIR/hardware_specs.txt"

echo "# UFW Firewall Rules
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp" > "$TARGET_DIR/firewall_rules.cfg"

echo "Module                  Size  Used by
ext4                  987136  2
crc32c_intel           24576  3
nvme                   49152  4
tcp_bbr                20480  1" > "$TARGET_DIR/kernel_modules.log"

echo "Algorithm Design Notes:
Time Complexity of Duplicate Finder:
1. md5sum: O(N * M) where N = number of files, M = avg file size
2. sort: O(N log N) comparison sort on 32-character hashes
3. uniq -w 32: O(N) linear scan over sorted hashes
Total Time Complexity: O(N*M + N log N)" > "$TARGET_DIR/algorithm_design.txt"

echo "# Submission Checklist
- [x] main.sh executable with menu options 0 to 8
- [x] lib/functions.sh with all 5 features implemented
- [x] data/testfiles with >= 20 files including copies
- [x] tar -czf backup working
- [x] crontab line tested with --cron
- [x] README.md completed
- [x] Tarball created: E41_L43_dupfinder.tar.gz" > "$TARGET_DIR/project_submission_checklist.md"

echo "Successfully created $(ls -1 "$TARGET_DIR" | wc -l) test files in $TARGET_DIR."

