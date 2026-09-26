#!/usr/bin/env bash
set -euo pipefail

### =========================
### Configuration
### =========================

INSTALL_DIR="$HOME/.local/share/"
BIN_DIR="/usr/local/bin"

LOCAL_USER="${SUDO_USER:-$(logname)}"
POKEDEX_FILE="$HOME/.local/share/pokegodex/pokedex.txt"
POKEDEX_HASH="$POKEDEX_FILE.sha256"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

UNINSTALL=false
GEN_SPECIFIC=false
GEN=""

### =========================
### Flag parsing
### =========================

while [ $# -gt 0 ]; do
    case "$1" in
        --gen)
            GEN_SPECIFIC=true
            gen="$2"
            shift

            [[ "$gen" =~ ^[0-9]+(-[0-9]+)?$ ]] || {
                echo "Error: --gen must be N or N-M (1–8)"
                exit 1
            }

            IFS=- read -r start end <<< "$gen"
            end=${end:-$start}

            (( start >= 1 && end <= 8 && start <= end )) || {
                echo "Error: generations must be between 1 and 8"
                exit 1
            }

            GEN="$gen"
            ;;
        --uninstall)
            UNINSTALL=true
            ;;
        *)
            echo "Unknown flag: $1"
            exit 1
            ;;
    esac
    shift
done

### =========================
### Helpers
### =========================

check_dependency() {
    local bin="$1" hint="$2"
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "Error: '$bin' not found on PATH."
        echo "  Install it first: $hint"
        exit 1
    fi
}

hook_line() {
    if [[ "$GEN_SPECIFIC" == true ]]; then
        echo "pokegodex --gen $GEN"
    else
        echo "pokegodex"
    fi
}

### =========================
### Install (also used for updates: re-run this to pull in new files)
### =========================

install() {
    echo "Installing pokegodex"

    check_dependency pokego "https://github.com/rubiin/pokego"
    check_dependency fastfetch "https://github.com/fastfetch-cli/fastfetch"
    check_dependency python3 "your distro's package manager"

    sudo -u "$LOCAL_USER" mkdir -p "$INSTALL_DIR/pokegodex"
    sudo -u "$LOCAL_USER" touch "$POKEDEX_FILE"

    # Copy the scripts + generation lists in. trainer.json is only seeded on
    # first install so an update never wipes an existing trainer profile.
    sudo -u "$LOCAL_USER" cp -rf "$SCRIPT_DIR/gen_files" "$INSTALL_DIR/pokegodex/"
    sudo -u "$LOCAL_USER" cp "$SCRIPT_DIR/pokegodex" "$SCRIPT_DIR/pokedex.py" \
        "$SCRIPT_DIR/trainer.py" "$SCRIPT_DIR/achievements.py" "$INSTALL_DIR/pokegodex/"

    if [ ! -f "$INSTALL_DIR/pokegodex/trainer.json" ]; then
        sudo -u "$LOCAL_USER" cp "$SCRIPT_DIR/trainer.json" "$INSTALL_DIR/pokegodex/"
    fi

    sudo -u "$LOCAL_USER" mkdir -p "$INSTALL_DIR/pokegodex/cache/api_data" "$INSTALL_DIR/pokegodex/cache/sprite_data"

    chmod +x "$INSTALL_DIR/pokegodex/pokegodex" "$INSTALL_DIR/pokegodex/pokedex.py"

    # create symlinks in /usr/local/bin
    rm -f "$BIN_DIR/pokedex" "$BIN_DIR/pokegodex"
    ln -s "$INSTALL_DIR/pokegodex/pokegodex" "$BIN_DIR/pokegodex"
    ln -s "$INSTALL_DIR/pokegodex/pokedex.py" "$BIN_DIR/pokedex"

    if [ ! -s "$POKEDEX_FILE" ] && [ ! -f "$POKEDEX_HASH" ]; then
        sudo -u "$LOCAL_USER" touch "$POKEDEX_HASH"
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$POKEDEX_FILE" > "$POKEDEX_HASH"
        else
            shasum -a 256 "$POKEDEX_FILE" > "$POKEDEX_HASH"
        fi
    fi
    chmod 444 "$POKEDEX_FILE"

    echo "-------------------------------------------------------"
    echo " Pokegodex installed successfully!"
    echo "-------------------------------------------------------"

    if ! python3 -c "import readchar" >/dev/null 2>&1; then
        echo -e "\033[33mNote: the 'readchar' Python library is required to run the pokedex.\033[0m"
        echo ""
        echo "  Standard: pip3 install -r requirements.txt"
        echo "  Linux:    sudo apt install python3-readchar (on Debian/Ubuntu)"
        echo "-------------------------------------------------------"
    fi

    echo "This installer does not touch your ~/.zshrc. To catch a Pokemon on"
    echo "every new shell, add this line yourself (e.g. near the end of ~/.zshrc,"
    echo "whenever you already call fastfetch, if at all):"
    echo ""
    echo "    $(hook_line)"
    echo ""
    echo "Then run: source ~/.zshrc"
}

### =========================
### Uninstall
### =========================

uninstall() {
    echo "Removing pokegodex"
    rm -rf "$INSTALL_DIR/pokegodex"
    rm -f "$BIN_DIR/pokegodex" "$BIN_DIR/pokedex"

    echo ""
    echo "Since this installer never edited ~/.zshrc, there's nothing to restore"
    echo "there. If you added a 'pokegodex' line yourself, remove it manually."
    echo ""
    echo "pokego and fastfetch were installed by you separately, so they're left alone."
}

### =========================
### Entry point
### =========================

if [[ "$UNINSTALL" == true ]]; then
    uninstall
else
    install
fi
