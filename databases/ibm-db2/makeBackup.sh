#!/bin/bash

# Starting the new database backup
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting new database backup..."

# Load DB2 environment variables
if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi
. ~db2inst1/sqllib/db2profile

# This script will be executed by Veeam as a pre-job to ensure DB2 database is backed up before filesystem backup

# Backup path
DB_BACKUP_PATH='/backup/apollon/'

# Clear existing backups in the backup directory (only one version should remain)
echo "$(date '+%Y-%m-%d %H:%M:%S') - Clearing existing backups in ${DB_BACKUP_PATH}..."
find ${DB_BACKUP_PATH} ! -name 'db2backup.log' -type f -exec rm -f {} \;

# Perform DB2 database backup
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting DB2 backup..."
db2 "BACKUP DATABASE PPMS ONLINE TO ${DB_BACKUP_PATH} COMPRESS INCLUDE LOGS WITHOUT PROMPTING"

# Remove old transaction logs (older than 3 days)
echo "$(date '+%Y-%m-%d %H:%M:%S') - Removing old transaction logs..."
find /home/db2inst1/db2inst1/NODE0000/SQL00001/LOGSTREAM0000 -type f -mtime +3 -exec /bin/rm {} \;

# Remove old archive logs (older than 3 days)
echo "$(date '+%Y-%m-%d %H:%M:%S') - Removing old archive logs..."
find /home/db2inst1/db2arch/db2inst1/PPMS/NODE0000/LOGSTREAM0000/C0000000/ -type f -mtime +3 -exec /bin/rm {} \;
find /home/db2inst1/db2arch/db2inst1/PPMS/NODE0000/LOGSTREAM0000/C0000000 -name '*.LOG' -mtime +3 -exec rm {} \;

# Print the current date and time to log when the script ran
echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup script finished."
