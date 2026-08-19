#!/usr/bin/env bash
# glue.sh - Main entrypoint for glue

GLUE_DIR="${GLUE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Source core components
source "$GLUE_DIR/lib/config.sh"
source "$GLUE_DIR/lib/detect.sh"
source "$GLUE_DIR/lib/pkgmap.sh" 2>/dev/null || true
source "$GLUE_DIR/lib/backends/apt.sh"
source "$GLUE_DIR/lib/backends/pacman.sh"
source "$GLUE_DIR/lib/backends/dnf.sh"
source "$GLUE_DIR/lib/backends/zypper.sh"
source "$GLUE_DIR/lib/backends/apk.sh"
source "$GLUE_DIR/lib/backends/xbps.sh"
source "$GLUE_DIR/lib/core.sh"

# Sourcing dialect wrappers
source "$GLUE_DIR/lib/dialects/apt.sh"
source "$GLUE_DIR/lib/dialects/pacman.sh"
source "$GLUE_DIR/lib/dialects/dnf.sh"
source "$GLUE_DIR/lib/dialects/zypper.sh"
source "$GLUE_DIR/lib/dialects/apk.sh"
source "$GLUE_DIR/lib/dialects/xbps.sh"

# Register dialect functions based on configuration
glue_load_config
glue_resolve_backend >/dev/null 2>&1

glue_setup_dialects() {
    local dialect="${GLUE_DIALECT:-apt}"
    local backend="${GLUE_ACTIVE_BACKEND:-auto}"

    # Setup configured dialect handlers
    if declare -f "glue_register_dialect_${dialect}" >/dev/null 2>&1; then
        "glue_register_dialect_${dialect}" "$backend"
    fi
}

glue_setup_dialects

# Neutral glue CLI function
glue() {
    local global_flags=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|--verbose|-v|--backend=*)
                global_flags+=("$1")
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "$cmd" in
        config)
            local subcmd="${1:-}"
            shift 2>/dev/null || true
            case "$subcmd" in
                get)
                    glue_config_get "$1"
                    ;;
                set)
                    glue_config_set "$1" "$2"
                    # Refresh dialects if dialect changed
                    if [[ "$1" == "dialect" || "$1" == "GLUE_DIALECT" ]]; then
                        glue_setup_dialects
                    fi
                    ;;
                show|list|"")
                    glue_config_show
                    ;;
                *)
                    echo "Usage: glue config {get|set|show}" >&2
                    return 1
                    ;;
            esac
            ;;
        map)
            if declare -f glue_map_cli >/dev/null 2>&1; then
                glue_map_cli "$@"
            else
                echo "Package mapper component not loaded." >&2
                return 1
            fi
            ;;
        install|remove|autoremove|update|upgrade|search|show|list|clean)
            if [[ "$cmd" == "list" && "${1:-}" == "--installed" ]]; then
                shift
                glue_dispatch "${global_flags[@]}" "list_installed" "$@"
            elif [[ "$cmd" == "list" ]]; then
                glue_dispatch "${global_flags[@]}" "list_installed" "$@"
            else
                glue_dispatch "${global_flags[@]}" "$cmd" "$@"
            fi
            ;;
        help|--help|-h|"")
            echo "glue - Universal Linux Package Manager Glue"
            echo ""
            echo "Usage:"
            echo "  glue [flags] <action> [options] [packages]"
            echo "  glue config <get|set|show>"
            echo "  glue map <query>"
            echo ""
            echo "Global Flags:"
            echo "  --dry-run          Show command without executing"
            echo "  --verbose, -v      Print translation command"
            echo "  --backend=<name>   Force a specific backend"
            echo ""
            echo "Actions:"
            echo "  install <pkg...>   Install package(s)"
            echo "  remove <pkg...>    Remove package(s)"
            echo "  autoremove         Remove orphaned packages"
            echo "  update             Refresh package indexes"
            echo "  upgrade [pkg...]   Upgrade installed packages"
            echo "  search <query...>  Search for packages"
            echo "  show <pkg...>      Show package information"
            echo "  list [--installed] List packages"
            echo "  clean              Clean package cache"
            echo ""
            echo "Dialects & Backend:"
            echo "  Current Dialect: ${GLUE_DIALECT:-apt}"
            echo "  Active Backend:  ${GLUE_ACTIVE_BACKEND:-auto}"
            ;;
        *)
            echo "Error: Unknown glue command '$cmd'" >&2
            return 1
            ;;
    esac
}
