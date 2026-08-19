#!/usr/bin/env bash
# lib/backends/eopkg.sh - Solus eopkg backend for glue

glue_backend_eopkg() {
    local action="$1"
    shift

    GLUE_CMD_SUDO="true"
    GLUE_CMD_ARGS=()

    case "$action" in
        install) GLUE_CMD_ARGS=("eopkg" "install" "$@") ;;
        remove)  GLUE_CMD_ARGS=("eopkg" "remove" "$@") ;;
        autoremove) GLUE_CMD_ARGS=("eopkg" "remove-orphans") ;;
        update)  GLUE_CMD_ARGS=("eopkg" "update-repo") ;;
        upgrade) GLUE_CMD_ARGS=("eopkg" "upgrade" "$@") ;;
        search)  GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("eopkg" "search" "$@") ;;
        show)    GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("eopkg" "info" "$@") ;;
        list_installed) GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("eopkg" "list-installed") ;;
        clean)   GLUE_CMD_ARGS=("eopkg" "delete-cache") ;;
        *) echo "Error: Backend 'eopkg' does not support action '$action'" >&2; return 1 ;;
    esac
}
