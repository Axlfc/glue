#!/usr/bin/env bash
# lib/dialects/apt.sh - APT dialect interface for glue

glue_register_dialect_apt() {
    local backend="$1"

    if [[ "$backend" == "apt" ]]; then
        # Native backend is APT - do not override apt command
        unset -f apt 2>/dev/null || true
        return
    fi

    apt() {
        local verb="${1:-}"
        shift 2>/dev/null || true

        case "$verb" in
            install)
                glue_dispatch "install" "$@"
                ;;
            remove|purge)
                glue_dispatch "remove" "$@"
                ;;
            autoremove)
                glue_dispatch "autoremove" "$@"
                ;;
            update)
                glue_dispatch "update" "$@"
                ;;
            upgrade|dist-upgrade|full-upgrade)
                glue_dispatch "upgrade" "$@"
                ;;
            search)
                glue_dispatch "search" "$@"
                ;;
            show)
                glue_dispatch "show" "$@"
                ;;
            list)
                if [[ "${1:-}" == "--installed" ]]; then
                    shift
                    glue_dispatch "list_installed" "$@"
                else
                    glue_dispatch "list_installed" "$@"
                fi
                ;;
            clean|autoclean)
                glue_dispatch "clean"
                ;;
            *)
                echo "apt dialect: delegating unknown action '$verb' to glue_dispatch" >&2
                glue_dispatch "$verb" "$@"
                ;;
        esac
    }
}
