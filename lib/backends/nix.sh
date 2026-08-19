#!/usr/bin/env bash
# lib/backends/nix.sh - NixOS / Nix package manager backend for glue

glue_backend_nix() {
    local action="$1"
    shift

    GLUE_CMD_SUDO="false"
    GLUE_CMD_ARGS=()

    case "$action" in
        install) GLUE_CMD_ARGS=("nix-env" "-iA" "$@") ;;
        remove)  GLUE_CMD_ARGS=("nix-env" "-e" "$@") ;;
        autoremove) GLUE_CMD_ARGS=("nix-collect-garbage" "-d") ;;
        update)  GLUE_CMD_ARGS=("nix-channel" "--update") ;;
        upgrade) GLUE_CMD_ARGS=("nix-env" "-u" "*") ;;
        search)  GLUE_CMD_ARGS=("nix-env" "-qaP" "$@") ;;
        show)    GLUE_CMD_ARGS=("nix-env" "-qaP" "--description" "$@") ;;
        list_installed) GLUE_CMD_ARGS=("nix-env" "-q") ;;
        clean)   GLUE_CMD_ARGS=("nix-store" "--gc") ;;
        *) echo "Error: Backend 'nix' does not support action '$action'" >&2; return 1 ;;
    esac
}
