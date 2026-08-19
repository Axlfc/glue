#!/usr/bin/env bash
# lib/dialects/zypper.sh - Zypper dialect interface for glue

glue_register_dialect_zypper() {
    local backend="$1"

    if [[ "$backend" == "zypper" ]]; then
        # Native backend is zypper - do not override zypper command
        unset -f zypper 2>/dev/null || true
        return
    fi

    zypper() {
        local verb="${1:-}"
        shift 2>/dev/null || true

        case "$verb" in
            in|install)
                glue_dispatch "install" "$@"
                ;;
            rm|remove)
                glue_dispatch "remove" "$@"
                ;;
            ref|refresh)
                glue_dispatch "update" "$@"
                ;;
            up|update)
                glue_dispatch "upgrade" "$@"
                ;;
            se|search)
                glue_dispatch "search" "$@"
                ;;
            info)
                glue_dispatch "show" "$@"
                ;;
            pa|packages)
                glue_dispatch "list_installed" "$@"
                ;;
            clean)
                glue_dispatch "clean"
                ;;
            *)
                echo "zypper dialect: delegating unknown action '$verb' to glue_dispatch" >&2
                glue_dispatch "$verb" "$@"
                ;;
        esac
    }
}
