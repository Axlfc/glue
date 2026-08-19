#!/usr/bin/env bash
# lib/dialects/apk.sh - APK dialect interface for glue

glue_register_dialect_apk() {
    local backend="$1"

    if [[ "$backend" == "apk" ]]; then
        # Native backend is apk - do not override apk command
        unset -f apk 2>/dev/null || true
        return
    fi

    apk() {
        local verb="${1:-}"
        shift 2>/dev/null || true

        case "$verb" in
            add)
                glue_dispatch "install" "$@"
                ;;
            del)
                glue_dispatch "remove" "$@"
                ;;
            update)
                glue_dispatch "update" "$@"
                ;;
            upgrade)
                glue_dispatch "upgrade" "$@"
                ;;
            search)
                glue_dispatch "search" "$@"
                ;;
            info)
                glue_dispatch "show" "$@"
                ;;
            list)
                glue_dispatch "list_installed" "$@"
                ;;
            cache)
                if [[ "${1:-}" == "clean" ]]; then
                    shift
                    glue_dispatch "clean"
                else
                    glue_dispatch "clean"
                fi
                ;;
            *)
                echo "apk dialect: delegating unknown action '$verb' to glue_dispatch" >&2
                glue_dispatch "$verb" "$@"
                ;;
        esac
    }
}
