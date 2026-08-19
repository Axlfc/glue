#!/usr/bin/env bash
# lib/detect.sh - System detection and backend resolution for glue

glue_detect_system() {
    local os_release="${GLUE_OS_RELEASE:-/etc/os-release}"
    local detected_backend=""
    local id=""
    local id_like=""

    if [[ -f "$os_release" ]]; then
        # Parse ID and ID_LIKE safely without sourcing untrusted code directly
        id=$(grep -E '^ID=' "$os_release" | head -n1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
        id_like=$(grep -E '^ID_LIKE=' "$os_release" | head -n1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]')
    fi

    # 1. Check exact ID match
    case "$id" in
        arch|manjaro|endeavouros|cachyos)  detected_backend="pacman" ;;
        debian|ubuntu|linuxmint|pop)       detected_backend="apt" ;;
        fedora|rhel|rocky|almalinux)       detected_backend="dnf" ;;
        opensuse*|sles)                    detected_backend="zypper" ;;
        alpine)                            detected_backend="apk" ;;
        void)                              detected_backend="xbps" ;;
        *)
            # 2. Check ID_LIKE fallback
            case "$id_like" in
                *arch*)           detected_backend="pacman" ;;
                *debian*|*ubuntu*) detected_backend="apt" ;;
                *fedora*|*rhel*)  detected_backend="dnf" ;;
                *suse*)           detected_backend="zypper" ;;
                *alpine*)         detected_backend="apk" ;;
                *void*)           detected_backend="xbps" ;;
            esac
            ;;
    esac

    # 3. If still undetected, check available binaries in PATH
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
        fi
    fi

    echo "$detected_backend"
}

glue_resolve_backend() {
    # If GLUE_BACKEND is set and not "auto", honor the override
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
