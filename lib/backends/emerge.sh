#!/usr/bin/env bash
# lib/backends/emerge.sh - Gentoo Portage (emerge) backend for glue

glue_backend_emerge() {
    local action="$1"
    shift

    GLUE_CMD_SUDO="true"
    GLUE_CMD_ARGS=()

    case "$action" in
        install) GLUE_CMD_ARGS=("emerge" "--ask=n" "$@") ;;
        remove)  GLUE_CMD_ARGS=("emerge" "--unmerge" "$@") ;;
        autoremove) GLUE_CMD_ARGS=("emerge" "--depclean") ;;
        update)  GLUE_CMD_ARGS=("emaint" "sync" "--auto") ;;
        upgrade) GLUE_CMD_ARGS=("emerge" "--update" "--deep" "--newuse" "@world") ;;
        search)  GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("emerge" "--search" "$@") ;;
        show)    GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("emerge" "--info" "$@") ;;
        list_installed) GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("qlist" "-I") ;;
        clean)   GLUE_CMD_ARGS=("eclean" "distfiles") ;;
        *) echo "Error: Backend 'emerge' does not support action '$action'" >&2; return 1 ;;
    esac
}
