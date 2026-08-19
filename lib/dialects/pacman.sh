#!/usr/bin/env bash
# lib/dialects/pacman.sh - Pacman dialect interface for glue

glue_register_dialect_pacman() {
    local backend="$1"

    if [[ "$backend" == "pacman" ]]; then
        # Native backend is pacman - do not override pacman command
        unset -f pacman 2>/dev/null || true
        return
    fi

    pacman() {
        local opt="${1:-}"
        shift 2>/dev/null || true

        case "$opt" in
            -S)
                glue_dispatch "install" "$@"
                ;;
            -R)
                glue_dispatch "remove" "$@"
                ;;
            -Rns)
                glue_dispatch "autoremove" "$@"
                ;;
            -Sy)
                glue_dispatch "update" "$@"
                ;;
            -Syu|-Syyu)
                glue_dispatch "upgrade" "$@"
                ;;
            -Ss)
                glue_dispatch "search" "$@"
                ;;
            -Si|-Qi)
                glue_dispatch "show" "$@"
                ;;
            -Q|-Qe)
                glue_dispatch "list_installed" "$@"
                ;;
            -Sc|-Scc)
                glue_dispatch "clean"
                ;;
            *)
                echo "pacman dialect: unhandled flag '$opt'" >&2
                return 1
                ;;
        esac
    }
}
