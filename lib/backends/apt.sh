#!/usr/bin/env bash
# lib/backends/apt.sh - APT backend for glue

glue_backend_apt() {
    local action="$1"
    shift

    GLUE_CMD_SUDO="true"
    GLUE_CMD_ARGS=()

    case "$action" in
        install)
            GLUE_CMD_ARGS=("apt" "install" "$@")
            ;;
        remove)
            GLUE_CMD_ARGS=("apt" "remove" "$@")
            ;;
        autoremove)
            GLUE_CMD_ARGS=("apt" "autoremove" "$@")
            ;;
        update)
            GLUE_CMD_ARGS=("apt" "update")
            ;;
        upgrade)
            GLUE_CMD_ARGS=("apt" "upgrade" "$@")
            ;;
        search)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("apt" "search" "$@")
            ;;
        show)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("apt" "show" "$@")
            ;;
        list_installed)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("apt" "list" "--installed" "$@")
            ;;
        clean)
            GLUE_CMD_ARGS=("apt" "clean")
            ;;
        *)
            echo "Error: Backend 'apt' does not support action '$action'" >&2
            return 1
            ;;
    esac
}
