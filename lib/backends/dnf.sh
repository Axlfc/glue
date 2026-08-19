#!/usr/bin/env bash
# lib/backends/dnf.sh - DNF / YUM backend for glue

glue_backend_dnf() {
    local action="$1"
    shift

    local bin="dnf"
    if ! command -v dnf >/dev/null 2>&1 && command -v yum >/dev/null 2>&1; then
        bin="yum"
    fi

    GLUE_CMD_SUDO="true"
    GLUE_CMD_ARGS=()

    case "$action" in
        install)
            GLUE_CMD_ARGS=("$bin" "install" "$@")
            ;;
        remove)
            GLUE_CMD_ARGS=("$bin" "remove" "$@")
            ;;
        autoremove)
            GLUE_CMD_ARGS=("$bin" "autoremove" "$@")
            ;;
        update)
            GLUE_CMD_ARGS=("$bin" "makecache")
            ;;
        upgrade)
            GLUE_CMD_ARGS=("$bin" "upgrade" "$@")
            ;;
        search)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("$bin" "search" "$@")
            ;;
        show)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("$bin" "info" "$@")
            ;;
        list_installed)
            GLUE_CMD_SUDO="false"
            GLUE_CMD_ARGS=("$bin" "list" "installed" "$@")
            ;;
        clean)
            GLUE_CMD_ARGS=("$bin" "clean" "all")
            ;;
        *)
            echo "Error: Backend 'dnf' does not support action '$action'" >&2
            return 1
            ;;
    esac
}
