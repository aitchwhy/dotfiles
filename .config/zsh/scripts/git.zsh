

function find_large_files() {
    git rev-list --all --objects | \                                                                                                           09:05  on Mac OS
    while read sha1 filename; do
    if [ -n "$filename" ]; then
        size=$(git cat-file -s $sha1 2>/dev/null || echo 0)
        echo "$size $filename"
    fi
    done | sort -nr | head -20
}
