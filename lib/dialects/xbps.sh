#!/usr/bin/env bash
# lib/dialects/xbps.sh - XBPS dialect interface for glue

glue_register_dialect_xbps() {
    local backend="$1"

    if [[ "$backend" == "xbps" ]]; then
        # Native backend is xbps - do not override xbps commands
        unset -f xbps-install xbps-remove xbps-query 2>/dev/null || true
        return
    fi

    xbps-install() {
        if [[ "${1:-}" == "-S" ]]; then
            shift
            if [[ $# -eq 0 ]]; then
                glue_dispatch "update"
            else
                glue_dispatch "install" "$@"
            fi
        elif [[ "${1:-}" == "-su" || "${1:-}" == "-u" ]]; then
            shift
            glue_dispatch "upgrade" "$@"
        else
            glue_dispatch "install" "$@"
        fi
    }

    xbps-remove() {
        if [[ "${1:-}" == "-o" ]]; then
            shift
            glue_dispatch "autoremove" "$@"
        elif [[ "${1:-}" == "-O" ]]; then
            shift
            glue_dispatch "clean"
        else
            glue_dispatch "remove" "$@"
        fi
    }

    xbps-query() {
        if [[ "${1:-}" == "-Rs" ]]; then
            shift
            glue_dispatch "search" "$@"
        elif [[ "${1:-}" == "-S" ]]; then
            shift
            glue_dispatch "show" "$@"
        elif [[ "${1:-}" == "-l" ]]; then
            shift
            glue_dispatch "list_installed" "$@"
        else
            glue_dispatch "search" "$@"
        fi
    }
}
