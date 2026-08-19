#!/usr/bin/env bash
# lib/detect.sh - Comprehensive System detection and backend resolution for glue

glue_detect_system() {
    local os_release="${GLUE_OS_RELEASE:-/etc/os-release}"
    local detected_backend=""
    local id=""
    local id_like=""

    if [[ -f "$os_release" ]]; then
        id=$(grep -E '^ID=' "$os_release" | head -n1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
        id_like=$(grep -E '^ID_LIKE=' "$os_release" | head -n1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
    fi

    # 1. Exact ID match for extensive Linux distribution families
    case "$id" in
        # Arch & derivatives
        arch|manjaro|endeavouros|garuda|arcolinux|cachyos|artix|blackarch|parabola|hyperbola|rebornos|mabox|biglinux|steamos|chimeraos|holoiso|archcraft|exodia|kaos|obarun)
            detected_backend="pacman"
            ;;
        # Debian/Ubuntu & derivatives
        debian|ubuntu|linuxmint|lmde|pop|elementary|zorin|neon|feren|bodhi|linuxlite|peppermint|mx|antix|sparky|devuan|kali|parrot|tails|pureos|trisquel|bunsenlabs|crunchbangplusplus|deepin|jingos|raspbian|dietpi|armbian|openmediavault|proxmox|whonix|pikaos|vanilla|blendos)
            detected_backend="apt"
            ;;
        # Fedora/RHEL & RPM derivatives
        fedora|rhel|centos|rocky|almalinux|ol|amzn|scientific|clearos|miraclelinux|eurolinux|springdale|navy|anolis|qubes|rosa|openmandriva|photon)
            detected_backend="dnf"
            ;;
        # SUSE derivatives
        opensuse*|sles|sl-micro|geckolinux)
            detected_backend="zypper"
            ;;
        # Alpine Linux & postmarketOS
        alpine|postmarketos)
            detected_backend="apk"
            ;;
        # Void Linux
        void)
            detected_backend="xbps"
            ;;
        # Gentoo Linux
        gentoo|funtoo|calculate)
            detected_backend="emerge"
            ;;
        # Solus
        solus)
            detected_backend="eopkg"
            ;;
        # NixOS
        nixos)
            detected_backend="nix"
            ;;
        # Guix System
        guix)
            detected_backend="guix"
            ;;
        # Slackware
        slackware|slackel|salix|porteux)
            detected_backend="slackpkg"
            ;;
        # Clear Linux
        clear-linux-os)
            detected_backend="swupd"
            ;;
        *)
            # 2. Check ID_LIKE fallback
            case "$id_like" in
                *arch*)           detected_backend="pacman" ;;
                *debian*|*ubuntu*) detected_backend="apt" ;;
                *fedora*|*rhel*)  detected_backend="dnf" ;;
                *suse*|*opensuse*) detected_backend="zypper" ;;
                *alpine*)         detected_backend="apk" ;;
                *void*)           detected_backend="xbps" ;;
                *gentoo*)         detected_backend="emerge" ;;
                *nix*)            detected_backend="nix" ;;
                *guix*)           detected_backend="guix" ;;
                *slackware*)      detected_backend="slackpkg" ;;
            esac
            ;;
    esac

    # 3. Binary availability check in PATH if still undetected
    if [[ -z "$detected_backend" ]]; then
        if command -v pacman >/dev/null 2>&1; then
            detected_backend="pacman"
        elif command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
            detected_backend="apt"
        elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
            detected_backend="dnf"
        elif command -v zypper >/dev/null 2>&1; then
            detected_backend="zypper"
        elif command -v apk >/dev/null 2>&1; then
            detected_backend="apk"
        elif command -v xbps-install >/dev/null 2>&1; then
            detected_backend="xbps"
        elif command -v emerge >/dev/null 2>&1; then
            detected_backend="emerge"
        elif command -v eopkg >/dev/null 2>&1; then
            detected_backend="eopkg"
        elif command -v nix >/dev/null 2>&1 || command -v nix-env >/dev/null 2>&1; then
            detected_backend="nix"
        elif command -v guix >/dev/null 2>&1; then
            detected_backend="guix"
        elif command -v slackpkg >/dev/null 2>&1; then
            detected_backend="slackpkg"
        elif command -v swupd >/dev/null 2>&1; then
            detected_backend="swupd"
        fi
    fi

    echo "$detected_backend"
}

glue_resolve_backend() {
    if [[ -n "${GLUE_BACKEND:-}" && "${GLUE_BACKEND}" != "auto" ]]; then
        GLUE_ACTIVE_BACKEND="$GLUE_BACKEND"
    else
        GLUE_ACTIVE_BACKEND=$(glue_detect_system)
    fi

    if [[ -z "$GLUE_ACTIVE_BACKEND" ]]; then
        echo "Error: Could not automatically detect system package manager backend." >&2
        return 1
    fi

    export GLUE_ACTIVE_BACKEND
}
