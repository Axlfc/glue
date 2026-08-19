#!/usr/bin/env bash
# lib/dialects/dnf.sh - DNF dialect interface for glue

glue_register_dialect_dnf() {
    local backend="$1"

    if [[ "$backend" == "dnf" ]]; then
        # Native backend is dnf - do not override dnf command
        unset -f dnf 2>/dev/null || true
        return
    fi

    dnf() {
        local verb="${1:-}"
        shift 2>/dev/null || true

        case "$verb" in
            install)
                glue_dispatch "install" "$@"
                ;;
            remove|erase)
                glue_dispatch "remove" "$@"
                ;;
            autoremove)
                glue_dispatch "autoremove" "$@"
                ;;
            makecache|check-update)
                glue_dispatch "update" "$@"
                ;;
            upgrade|update)
                glue_dispatch "upgrade" "$@"
                ;;
            search)
                glue_dispatch "search" "$@"
                ;;
            info)
                glue_dispatch "show" "$@"
                ;;
            list)
                if [[ "${1:-}" == "installed" ]]; then
                    shift
                    glue_dispatch "list_installed" "$@"
                else
                    glue_dispatch "list_installed" "$@"
                fi
                ;;
            clean)
                glue_dispatch "clean"
                ;;
            *)
                echo "dnf dialect: delegating unknown action '$verb' to glue_dispatch" >&2
                glue_dispatch "$verb" "$@"
                ;;
        esac
    }
}
