#!/bin/bash

# Function to count total files and directories
count_files_and_dirs() {
    find "$1" -type f | wc -l
}

count_dirs() {
    find "$1" -type d | wc -l
}

rename_folders() {
    local dir="$1"
    for entry in "$dir"/*; do
        if [ -d "$entry" ]; then
            local dirname=$(basename "$entry")
            local parentdir=$(dirname "$entry")

            # Convert to lowercase and replace spaces with hyphens
            local newname=$(echo "$dirname" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

            # Ensure new name doesn't conflict with an existing directory
            if [[ "$dirname" != "$newname" && ! -e "$parentdir/$newname" ]]; then
                mv "$entry" "$parentdir/$newname"
                entry="$parentdir/$newname" # Update reference to renamed directory
            fi

            # Recursively process subdirectories
            rename_folders "$entry"
        fi
    done
}

# Start renaming process
start_dir="${1:-.}"

# Ensure directory exists
if [ ! -d "$start_dir" ]; then
    echo "Error: Directory '$start_dir' does not exist."
    exit 1
fi

# Count before renaming
initial_files=$(count_files_and_dirs "$start_dir")
initial_dirs=$(count_dirs "$start_dir")

echo "Starting folder renaming..."
rename_folders "$start_dir"
echo "Renaming completed."

# Count after renaming
final_files=$(count_files_and_dirs "$start_dir")
final_dirs=$(count_dirs "$start_dir")

# Validate file and folder counts
echo "Verification:"
echo "Files before: $initial_files | Files after: $final_files"
echo "Directories before: $initial_dirs | Directories after: $final_dirs"

if [[ "$initial_files" -ne "$final_files" ]] || [[ "$initial_dirs" -ne "$final_dirs" ]]; then
    echo "⚠ WARNING: File or directory count mismatch! Please check for errors."
    exit 2
else
    echo "✅ Verification successful: No files or directories were lost."
fi
