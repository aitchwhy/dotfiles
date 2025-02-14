# CONFIGS_DIR="$HOME/.config"
/opt/homebrew/bin/fd -H -t l . "$HOME/.config" | while read -r link; do
    if [ ! -e "$(readlink -f "$link")" ]; then
        echo "Found dead symlink @ $link --- removing..."
        unlink $link
    fi
    echo "Finished symlink $link ---> $(readlink -f $link)"
done