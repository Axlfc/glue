#!/usr/bin/env bash
# lib/backends/xbps.sh - XBPS (Void Linux) backend for glue

glue_backend_xbps() {
    local action="$1"
    shift

    GLUE_CMD_SUDO="true"
    GLUE_CMD_ARGS=()

    case "$action" in
        install)
            GLUE_CMD_ARGS=("xbps-install" "-S" "$@")
            ;;
        remove)
            GLUE_CMD_ARGS=("xbps-remove" "$@")
            ;;
        autoremove)
            GLUE_CMD_ARGS=("xbps-remove" "-o" "$@")
            ;;
        update)
            GLUE_CMD_ARGS=("xbps-install" "-S")
            ;;
        upgrade)
            GLUE_CMD_ARGS=("xbps-install" "-su" "$@")
            ;;
        search)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("xbps-query" "-Rs" "$@")
            ;;
        show)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("xbps-query" "-S" "$@")
            ;;
        list_installed)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("xbps-query" "-l" "$@")
            ;;
        clean)
            GLUE_CMD_ARGS=("xbps-remove" "-O")
            ;;
        *)
            echo "Error: Backend 'xbps' does not support action '$action'" >&2
            return 1
            ;;
    esac
}
