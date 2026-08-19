#!/usr/bin/env bash
# lib/backends/apk.sh - APK backend for glue

glue_backend_apk() {
    local action="$1"
    shift

    GLUE_CMD_SUDO="true"
    GLUE_CMD_ARGS=()

    case "$action" in
        install)
            GLUE_CMD_ARGS=("apk" "add" "$@")
            ;;
        remove)
            GLUE_CMD_ARGS=("apk" "del" "$@")
            ;;
        autoremove)
            GLUE_CMD_ARGS=("apk" "del" "$@")
            ;;
        update)
            GLUE_CMD_ARGS=("apk" "update")
            ;;
        upgrade)
            GLUE_CMD_ARGS=("apk" "upgrade" "$@")
            ;;
        search)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("apk" "search" "$@")
            ;;
        show)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("apk" "info" "$@")
            ;;
        list_installed)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("apk" "list" "--installed" "$@")
            ;;
        clean)
            GLUE_CMD_ARGS=("apk" "cache" "clean")
            ;;
        *)
            echo "Error: Backend 'apk' does not support action '$action'" >&2
            return 1
            ;;
    esac
}
