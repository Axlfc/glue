#!/usr/bin/env bash
# lib/backends/pacman.sh - Pacman backend for glue

glue_backend_pacman() {
    local action="$1"
    shift

    local aur_helper="${GLUE_USE_AUR_HELPER:-yay}"
    local bin="pacman"
    local use_sudo="true"

    # Check if configured AUR helper is available
    if [[ "$aur_helper" == "yay" ]] && command -v yay >/dev/null 2>&1; then
        bin="yay"
        use_sudo="false" # yay handles sudo escalation internally
    elif [[ "$aur_helper" == "paru" ]] && command -v paru >/dev/null 2>&1; then
        bin="paru"
        use_sudo="false" # paru handles sudo escalation internally
    fi

    GLUE_CMD_SUDO="$use_sudo"
    GLUE_CMD_ARGS=()

    case "$action" in
        install)
            GLUE_CMD_ARGS=("$bin" "-S" "$@")
            ;;
        remove)
            GLUE_CMD_ARGS=("$bin" "-R" "$@")
            ;;
        autoremove)
            if [[ $# -gt 0 ]]; then
                GLUE_CMD_ARGS=("$bin" "-Rns" "$@")
            else
                local orphans
                orphans=$("$bin" -Qtdq 2>/dev/null || true)
                if [[ -n "$orphans" ]]; then
                    # Read orphans into array
                    read -r -a orphan_array <<< "$orphans"
                    GLUE_CMD_ARGS=("$bin" "-Rns" "${orphan_array[@]}")
                else
                    # No orphans found
                    GLUE_CMD_ARGS=("echo" "No orphaned packages to remove.")
                    GLUE_CMD_SUDO="false"
                fi
            fi
            ;;
        update|upgrade)
            # Safe pacman update: never execute -Sy alone, always chain/run -Syu
            GLUE_CMD_ARGS=("$bin" "-Syu" "$@")
            ;;
        search)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("$bin" "-Ss" "$@")
            ;;
        show)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("$bin" "-Si" "$@")
            ;;
        list_installed)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("$bin" "-Q" "$@")
            ;;
        clean)
            GLUE_CMD_ARGS=("$bin" "-Sc")
            ;;
        *)
            echo "Error: Backend 'pacman' does not support action '$action'" >&2
            return 1
            ;;
    esac
}
