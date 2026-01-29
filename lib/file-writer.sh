#!/bin/bash
# File writer for direct mode
# Parses <write_file> tags from agent output and writes files

write_files_from_output() {
    local output="$1"
    local project_dir="${2:-.}"
    local files_written=()

    # Extract all <write_file> blocks
    while IFS= read -r line; do
        if [[ "$line" =~ \<write_file[[:space:]]+path=\"([^\"]+)\"\> ]]; then
            local file_path="${BASH_REMATCH[1]}"
            local full_path="$project_dir/$file_path"
            local file_content=""
            local in_file=true

            # Read until </write_file>
            while IFS= read -r content_line; do
                if [[ "$content_line" =~ \</write_file\> ]]; then
                    break
                fi
                file_content+="$content_line"$'\n'
            done

            # Create parent directory if needed
            local dir_path=$(dirname "$full_path")
            mkdir -p "$dir_path"

            # Write the file
            echo "$file_content" > "$full_path"
            files_written+=("$file_path")

            echo "[AGENT-PROGRESS] 📝 Wrote file: $file_path" >&2
        fi
    done <<< "$output"

    # Return list of files written
    if [ ${#files_written[@]} -gt 0 ]; then
        printf '%s\n' "${files_written[@]}"
        return 0
    else
        return 1
    fi
}

# Check if output contains write_file tags
has_file_writes() {
    local output="$1"
    [[ "$output" =~ \<write_file ]]
}

export -f write_files_from_output
export -f has_file_writes
