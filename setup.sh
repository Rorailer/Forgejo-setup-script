#!/usr/bin/env bash
## This is a Forgejo Setup Script for Ubuntu and Debian based systems.
## This will check for docker, install it if missing, drop a docker-compose.yaml in the folder you choose, and bring up Forgejo.
## Companion to: https://github.com/Rorailer/Forgejo-setup-guide

# this will stop the script if anything in this script fails. (nothing will go unnoticed)
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
    echo "║                     Forgejo Setup Script                      ║";
    echo "║                                                               ║";
    echo "║      Spins up Forgejo in Docker. Lazy mode for self-host.     ║";
    echo "╚════════════════════════════════════════════════════════════════╝";
    echo -e "${NC}";
}

spacer(){
    echo -e "${CYAN}--------------------------------------------------------------${NC}";
}


# little helper for asking the user something with a default value
# user can just press enter to take the default
input(){
    local question="$1"
    local default="$2"
    local answer
    read -rp "$(echo -e "${CYAN}[?]${NC} ${question} [${default}]: ")" answer
    echo "${answer:-$default}"
}

# yes/no prompt with a default. press enter = take the default
approve(){
    local msg="$1"
    local default="${2:-N}"
    read -rp "$(echo -e "${YELLOW}[??]${NC} ${msg} [y/N]: ")" choice
    choice="${choice:-$default}"
    [[ "$choice" == "y" || "$choice" == "Y" ]] && return 0 || return 1
}


# making sure user is on Ubuntu or Debian. nothing else is supported here.
whichOS(){
    spacer
    log "Checking OS..."
    spacer

    if [[ ! -f /etc/os-release ]]; then
        err "Cannot tell what OS this is (no /etc/os-release). Aborting."
        exit 1
    fi

    . /etc/os-release
    case "$ID" in
        ubuntu|debian)
            fine "Detected supported OS: $PRETTY_NAME"
            ;;
        *)
            err "Unsupported OS: $ID. Only Ubuntu and Debian are supported."
            exit 1
            ;;
    esac
}


# check if docker is around. if not, ask the user before installing.
docker_exist(){
    spacer
    log "Checking for Docker..."
    spacer

    if command -v docker &> /dev/null; then
        fine "Docker is already installed: $(docker --version)"
        return
    fi

    warn "Docker is not installed."
    if approve "Install Docker now? (uses the official get.docker.com one-liner)"; then
        log "Installing Docker..."
        curl -fsSL https://get.docker.com | sudo sh
        fine "Docker installed."
    else
        err "Docker is required to run Forgejo. Aborting."
        exit 1
    fi
}


# if a forgejo container already exists, just restart it. don't touch their data.
handle_existing_container(){
    if docker ps -a --format '{{.Names}}' | grep -qx "forgejo"; then
        spacer
        warn "A container named 'forgejo' already exists."
        log "Restarting it instead of creating a new one. (your data is safe)"
        spacer
        docker restart forgejo >/dev/null
        fine "Container restarted."
        echo ""
        log "If you wanted a fresh setup, run uninstall.sh first, then re-run this."
        exit 0
    fi
}


# if the folder already exists ask user if they want to bail or wipe it.
handle_existing_folder(){
    local folder="$1"
    if [[ -d "$folder" ]]; then
        warn "Folder '$folder' already exists."
        read -rp "$(echo -e "${YELLOW}[??]${NC} [a]bort or [o]verwrite? [a]: ")" choice
        choice="${choice:-a}"
        case "${choice,,}" in
            o|overwrite)
                log "Wiping the existing folder..."
                rm -rf "$folder"
                fine "Folder removed."
                ;;
            *)
                err "Aborted by user."
                exit 1
                ;;
        esac
    fi
}


# the actual docker-compose.yaml. same one from the guide. nothing fancy.
write_compose(){
    local folder="$1"
    local port="$2"
    cat > "${folder}/docker-compose.yaml" <<EOF
networks:
  forgejo:
    external: false

services:
  server:
    image: codeberg.org/forgejo/forgejo:14
    container_name: forgejo
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    networks:
      - forgejo
    volumes:
      - ./data:/data
      - /etc/localtime:/etc/localtime:ro
    ports:
      - ${port}:3000
EOF
    fine "Wrote docker-compose.yaml"
}


# bring it up and verify it actually started
start(){
    local folder="$1"
    spacer
    log "Starting Forgejo..."
    spacer

    cd "$folder"
    if docker compose up -d; then
        fine "Forgejo container is up."
    else
        err "Failed to start Forgejo. Check the output above."
        exit 1
    fi
    # give it a sec to settle so docker ps shows useful info
    sleep 3
}


# the "you're done, here's where to go" screen
summary(){
    local port="$1"
    local server_ip
    server_ip=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Forgejo is Up and Running                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    log "Container info:"
    docker ps --filter "name=forgejo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""

    echo -e "${GREEN}${BOLD}Open Forgejo at:${NC}"
    echo -e "   ${CYAN}http://${server_ip}:${port}${NC}"
    echo ""
    echo -e "${YELLOW}${BOLD}Next:${NC}"
    echo "  1. Open the URL above in your browser"
    echo "  2. Scroll to the bottom of the setup page"
    echo "  3. Open 'Administrator Account Settings' and create your admin user"
    echo "  4. Click 'Install Forgejo'"
    echo ""
    echo "  Full guide: https://github.com/Rorailer/Forgejo-setup-guide"
    echo ""
}


# ──────────────────────────────────────────────────────────────────────────────
#  Main
# ──────────────────────────────────────────────────────────────────────────────
main(){
    banner

    whichOS
    docker_exist
    handle_existing_container

    # asking the user for the stuff they might want to change
    # press enter at any of these = take the default
    spacer
    log "Press Enter at any prompt to use the default."
    spacer
    PORT=$(input "External port for Forgejo" "3123")
    FOLDER=$(input "Folder to create Forgejo in" "./Forgejo")

    # turn it into an absolute path so the rest of the script doesn't get confused
    FOLDER="$(realpath -m "$FOLDER")"

    handle_existing_folder "$FOLDER"

    log "Creating folder: $FOLDER"
    mkdir -p "$FOLDER"

    write_compose "$FOLDER" "$PORT"
    start "$FOLDER"
    summary "$PORT"
}

main "$@"
