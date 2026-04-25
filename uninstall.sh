#!/usr/bin/env bash
## Forgejo Uninstall Script
## Stops and removes the Forgejo container and (optionally) its data folder.
## Companion to setup.sh.

# stop the script if anything fails
set -euo pipefail


# ---- COLORS ----
BOLD='\033[1m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'


# ---- Logging helpers ----
log(){
    echo -e "${BLUE}[INFO]${NC} $*" ;
}

fine(){
    echo -e "${GREEN}[ OK]${NC} $*" ;
}

err(){
    echo -e "${RED}[FAILED]${NC} $*" ;
}

warn(){
    echo -e "${YELLOW}[WARN]${NC} $*" ;
}

banner(){
    echo -e "${CYAN}${BOLD}";
    echo "╔════════════════════════════════════════════════════════════════╗";
    echo "║                  Forgejo Uninstall Script                     ║";
    echo "║                                                               ║";
    echo "║    Removes the container. Asks before touching your data.     ║";
    echo "╚════════════════════════════════════════════════════════════════╝";
    echo -e "${NC}";
}

spacer(){
    echo -e "${CYAN}--------------------------------------------------------------${NC}";
}


# helper for asking with a default
input(){
    local question="$1"
    local default="$2"
    local answer
    read -rp "$(echo -e "${CYAN}[?]${NC} ${question} [${default}]: ")" answer
    echo "${answer:-$default}"
}

# yes/no prompt with a default
approve(){
    local msg="$1"
    local default="${2:-N}"
    read -rp "$(echo -e "${YELLOW}[??]${NC} ${msg} [y/N]: ")" choice
    choice="${choice:-$default}"
    [[ "$choice" == "y" || "$choice" == "Y" ]] && return 0 || return 1
}


# ──────────────────────────────────────────────────────────────────────────────
#  Main
# ──────────────────────────────────────────────────────────────────────────────
main(){
    banner

    # ask where the forgejo folder lives. default matches setup.sh
    FOLDER=$(input "Path to Forgejo folder" "./Forgejo")
    FOLDER="$(realpath -m "$FOLDER")"

    if [[ ! -d "$FOLDER" ]]; then
        warn "Folder '$FOLDER' does not exist. Will still try to clean up the container."
    fi

    # stop & remove the container if it's around
    spacer
    log "Removing the forgejo container..."
    spacer

    if docker ps -a --format '{{.Names}}' | grep -qx "forgejo"; then
        docker stop forgejo >/dev/null 2>&1 || true
        docker rm forgejo   >/dev/null 2>&1 || true
        fine "Container removed."
    else
        warn "No 'forgejo' container found. Skipping container removal."
    fi

    # remove the docker network if compose left it behind
    if docker network ls --format '{{.Name}}' | grep -qE 'forgejo$'; then
        log "Removing leftover Forgejo docker network..."
        docker network rm "$(docker network ls --format '{{.Name}}' | grep -E 'forgejo$' | head -n1)" >/dev/null 2>&1 || true
        fine "Network removed."
    fi

    # the scary part: ask before nuking the data
    if [[ -d "$FOLDER" ]]; then
        echo ""
        warn "Folder '$FOLDER' still exists. It contains all your repos, the database, and config."
        if approve "Delete the folder and all Forgejo data?"; then
            rm -rf "$FOLDER"
            fine "Folder deleted. Forgejo is gone."
        else
            log "Folder kept. You can delete it manually whenever you want."
        fi
    fi

    echo ""
    echo -e "${GREEN}${BOLD}Uninstall complete.${NC}"
    echo ""
}

main "$@"
