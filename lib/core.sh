#!/usr/bin/env bash
# lib/core.sh - Execution engine for glue

glue_rollback_system() {
    if command -v snapper >/dev/null 2>&1; then
        echo "[glue-snapshot] Snapper detected. Checking snapshots..."
        if [[ "${GLUE_DRY_RUN:-false}" == "true" ]]; then
            echo "snapper list"
            return 0
        fi
        snapper list
    elif command -v timeshift >/dev/null 2>&1; then
        echo "[glue-snapshot] Timeshift detected. Checking snapshots..."
        if [[ "${GLUE_DRY_RUN:-false}" == "true" ]]; then
            echo "sudo timeshift --list"
            return 0
        fi
        sudo timeshift --list
    else
        echo "[glue-snapshot] No supported snapshot manager (snapper/timeshift) detected."
        echo "Creating a glue restore backup tag..."
        local backup_tag="/tmp/glue_restore_point_$(date +%Y%m%d_%H%M%S)"
        glue_export_manifest "$backup_tag"
        echo "Restore point saved to $backup_tag. Use 'glue sync $backup_tag' to restore."
    fi
}

glue_run_plugin_hooks() {
    local hook_stage="$1" # pre or post
    local action="$2"
    shift 2

    local plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/glue/plugins"
    local alt_plugin_dir="$HOME/.glue/plugins"

    local dirs_to_check=()
    [[ -d "$plugin_dir" ]] && dirs_to_check+=("$plugin_dir")
    [[ -d "$alt_plugin_dir" ]] && dirs_to_check+=("$alt_plugin_dir")

    for dir in "${dirs_to_check[@]}"; do
        for plugin in "$dir"/*.sh; do
            if [[ -f "$plugin" && -r "$plugin" ]]; then
                source "$plugin" 2>/dev/null || true
                local hook_fn="glue_plugin_${hook_stage}_${action}"
                if declare -f "$hook_fn" >/dev/null 2>&1; then
                    "$hook_fn" "$@" || true
                fi
            fi
        done
    done
}

glue_wrap_target_cmd() {
    local target="$1"
    shift

    case "$target" in
        docker:*)
            local container="${target#docker:}"
            echo "docker" "exec" "-it" "$container" "$@"
            ;;
        podman:*)
            local container="${target#podman:}"
            echo "podman" "exec" "-it" "$container" "$@"
            ;;
        ssh://*)
            local host="${target#ssh://}"
            echo "ssh" "$host" "$*"
            ;;
        *)
            echo "$@"
            ;;
    esac
}

glue_dispatch_provider() {
    local provider="$1"
    local action="$2"
    shift 2

    GLUE_CMD_SUDO="false"
    GLUE_CMD_ARGS=()

    case "$provider" in
        flatpak)
            case "$action" in
                install) GLUE_CMD_ARGS=("flatpak" "install" "$@") ;;
                remove)  GLUE_CMD_ARGS=("flatpak" "uninstall" "$@") ;;
                update|upgrade) GLUE_CMD_ARGS=("flatpak" "update" "$@") ;;
                search)  GLUE_CMD_ARGS=("flatpak" "search" "$@") ;;
                show)    GLUE_CMD_ARGS=("flatpak" "info" "$@") ;;
                list|list_installed) GLUE_CMD_ARGS=("flatpak" "list" "$@") ;;
                *) echo "Error: Flatpak provider does not support action '$action'" >&2; return 1 ;;
            esac
            ;;
        snap)
            GLUE_CMD_SUDO="true"
            case "$action" in
                install) GLUE_CMD_ARGS=("snap" "install" "$@") ;;
                remove)  GLUE_CMD_ARGS=("snap" "remove" "$@") ;;
                update|upgrade) GLUE_CMD_ARGS=("snap" "refresh" "$@") ;;
                search)  GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("snap" "find" "$@") ;;
                show)    GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("snap" "info" "$@") ;;
                list|list_installed) GLUE_CMD_SUDO="false"; GLUE_CMD_ARGS=("snap" "list" "$@") ;;
                *) echo "Error: Snap provider does not support action '$action'" >&2; return 1 ;;
            esac
            ;;
        pip|pip3)
            case "$action" in
                install) GLUE_CMD_ARGS=("pip" "install" "$@") ;;
                remove)  GLUE_CMD_ARGS=("pip" "uninstall" "$@") ;;
                upgrade) GLUE_CMD_ARGS=("pip" "install" "--upgrade" "$@") ;;
                search)  GLUE_CMD_ARGS=("pip" "search" "$@") ;;
                list|list_installed) GLUE_CMD_ARGS=("pip" "list" "$@") ;;
                *) echo "Error: Pip provider does not support action '$action'" >&2; return 1 ;;
            esac
            ;;
        cargo)
            case "$action" in
                install) GLUE_CMD_ARGS=("cargo" "install" "$@") ;;
                remove)  GLUE_CMD_ARGS=("cargo" "uninstall" "$@") ;;
                search)  GLUE_CMD_ARGS=("cargo" "search" "$@") ;;
                list|list_installed) GLUE_CMD_ARGS=("cargo" "install" "--list") ;;
                *) echo "Error: Cargo provider does not support action '$action'" >&2; return 1 ;;
            esac
            ;;
        npm)
            case "$action" in
                install) GLUE_CMD_ARGS=("npm" "install" "-g" "$@") ;;
                remove)  GLUE_CMD_ARGS=("npm" "uninstall" "-g" "$@") ;;
                update|upgrade) GLUE_CMD_ARGS=("npm" "update" "-g" "$@") ;;
                search)  GLUE_CMD_ARGS=("npm" "search" "$@") ;;
                list|list_installed) GLUE_CMD_ARGS=("npm" "list" "-g" "--depth=0") ;;
                *) echo "Error: NPM provider does not support action '$action'" >&2; return 1 ;;
            esac
            ;;
        *)
            echo "Error: Unknown provider '$provider'" >&2
            return 1
            ;;
    esac
}

glue_dispatch() {
    # Load configuration
    glue_load_config

    local dry_run_override=""
    local verbose_override=""
    local backend_override=""
    local provider_override=""
    local target_override=""
    local clean_args=()

    # Parse global options passed as arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run_override="true"
                shift
                ;;
            --verbose|-v)
                verbose_override="true"
                shift
                ;;
            --backend=*)
                backend_override="${1#*=}"
                shift
                ;;
            --provider=*)
                provider_override="${1#*=}"
                shift
                ;;
            --target=*)
                target_override="${1#*=}"
                shift
                ;;
            *)
                clean_args+=("$1")
                shift
                ;;
        esac
    done

    # Restore positional arguments without global flags
    set -- "${clean_args[@]}"

    local action="${1:-}"
    shift 2>/dev/null || true

    if [[ -z "$action" ]]; then
        echo "Error: No action specified for glue dispatch." >&2
        return 1
    fi

    # Apply overrides if provided
    if [[ -n "$dry_run_override" ]]; then
        GLUE_DRY_RUN="$dry_run_override"
    fi
    if [[ -n "$verbose_override" ]]; then
        GLUE_VERBOSE="$verbose_override"
    fi
    if [[ -n "$backend_override" ]]; then
        GLUE_BACKEND="$backend_override"
    fi

    # Pre-action plugin hook execution
    glue_run_plugin_hooks "pre" "$action" "$@"

    if [[ -n "$provider_override" ]]; then
        glue_dispatch_provider "$provider_override" "$action" "$@" || return 1
        GLUE_ACTIVE_BACKEND="$provider_override"
    else
        glue_resolve_backend || return 1
        local backend="$GLUE_ACTIVE_BACKEND"

        # Package name mapping hook
        local target_pkgs=()
        if declare -f glue_map_packages >/dev/null 2>&1 && [[ "$action" =~ ^(install|remove|show|search)$ ]]; then
            read -r -a target_pkgs <<< "$(glue_map_packages "$backend" "$@")"
            set -- "${target_pkgs[@]}"
        fi

        local backend_fn="glue_backend_${backend}"

        if ! declare -f "$backend_fn" >/dev/null 2>&1; then
            echo "Error: Backend function '$backend_fn' is not defined." >&2
            return 1
        fi

        "$backend_fn" "$action" "$@" || return 1
    fi

    local cmd=("${GLUE_CMD_ARGS[@]}")

    if [[ ${#cmd[@]} -eq 0 ]]; then
        echo "Error: No command generated for action '$action'." >&2
        return 1
    fi

    # Determine whether sudo is needed
    local exec_cmd=()
    if [[ "${GLUE_CMD_SUDO:-false}" == "true" && "$(id -u 2>/dev/null)" -ne 0 ]]; then
        exec_cmd=("sudo" "${cmd[@]}")
    else
        exec_cmd=("${cmd[@]}")
    fi

    # Target execution wrapper (--target=docker:..., --target=ssh://...)
    if [[ -n "$target_override" ]]; then
        read -r -a exec_cmd <<< "$(glue_wrap_target_cmd "$target_override" "${exec_cmd[@]}")"
    fi

    local cmd_str="${exec_cmd[*]}"

    if [[ "${GLUE_VERBOSE:-false}" == "true" || "${GLUE_VERBOSE:-false}" == "1" ]]; then
        echo "[glue] (${GLUE_ACTIVE_BACKEND}) $cmd_str" >&2
    fi

    if [[ "${GLUE_DRY_RUN:-false}" == "true" || "${GLUE_DRY_RUN:-false}" == "1" ]]; then
        echo "$cmd_str"
        return 0
    fi

    # Execute the command
    "${exec_cmd[@]}"
    local exit_code=$?

    # Post-action plugin hook execution
    glue_run_plugin_hooks "post" "$action" "$@"

    return $exit_code
}
