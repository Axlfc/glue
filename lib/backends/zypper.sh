#!/usr/bin/env bash
# lib/backends/zypper.sh - Zypper backend for glue

glue_backend_zypper() {
    local action="$1"
    shift

    GLUE_CMD_SUDO="true"
    GLUE_CMD_ARGS=()

    case "$action" in
        install)
            GLUE_CMD_ARGS=("zypper" "install" "$@")
            ;;
        remove)
            GLUE_CMD_ARGS=("zypper" "remove" "$@")
            ;;
        autoremove)
            if [[ $# -gt 0 ]]; then
                GLUE_CMD_ARGS=("zypper" "remove" "--clean-deps" "$@")
            else
                GLUE_CMD_ARGS=("zypper" "remove" "--clean-deps")
            fi
            ;;
        update)
            GLUE_CMD_ARGS=("zypper" "refresh")
            ;;
        upgrade)
            GLUE_CMD_ARGS=("zypper" "update" "$@")
            ;;
        search)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("zypper" "search" "$@")
            ;;
        show)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("zypper" "info" "$@")
            ;;
        list_installed)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("zypper" "packages" "--installed-only" "$@")
            ;;
        clean)
            GLUE_CMD_ARGS=("zypper" "clean")
            ;;
        *)
            echo "Error: Backend 'zypper' does not support action '$action'" >&2
            return 1
            ;;
    esac
}
