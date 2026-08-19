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

glue_load_config
glue_resolve_backend >/dev/null 2>&1

glue_setup_dialects() {
    local dialect="${GLUE_DIALECT:-apt}"
    local backend="${GLUE_ACTIVE_BACKEND:-auto}"

    if declare -f "glue_register_dialect_${dialect}" >/dev/null 2>&1; then
        "glue_register_dialect_${dialect}" "$backend"
    fi
}

glue_setup_dialects

glue_launch_webui() {
    local port="${1:-8080}"
    echo "Starting Glue Web UI Dashboard on http://localhost:${port}..."
    echo "Active Backend: ${GLUE_ACTIVE_BACKEND:-auto}"
    echo "Active Dialect: ${GLUE_DIALECT:-apt}"

    local web_dir="/tmp/glue_webui_html"
    mkdir -p "$web_dir"
    cat << EOF > "$web_dir/index.html"
<!DOCTYPE html>
<html>
<head>
    <title>Glue Package Manager Dashboard</title>
    <style>
        body { font-family: system-ui, sans-serif; background: #121212; color: #e0e0e0; margin: 2rem; }
        .card { background: #1e1e1e; padding: 1.5rem; border-radius: 8px; border: 1px solid #333; }
        h1 { color: #4eaa25; }
        .badge { background: #2a2a2a; color: #4eaa25; padding: 0.2rem 0.5rem; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>🧩 Glue Package Manager Dashboard</h1>
        <p>Active Backend: <span class="badge">${GLUE_ACTIVE_BACKEND:-auto}</span></p>
        <p>Active Dialect: <span class="badge">${GLUE_DIALECT:-apt}</span></p>
        <p>Status: <span style="color:#4eaa25;">Operational</span></p>
    </div>
</body>
</html>
EOF

    if [[ "${GLUE_DRY_RUN:-false}" == "true" ]]; then
        echo "WebUI dry-run server ready."
        return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        (cd "$web_dir" && python3 -m http.server "$port" 2>/dev/null &)
        echo "WebUI running with PID $!"
    elif command -v nc >/dev/null 2>&1; then
        echo "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n$(cat "$web_dir/index.html")" | nc -l -p "$port" 2>/dev/null &
        echo "WebUI running with netcat."
    else
        echo "WebUI Dashboard endpoint configured on port $port."
    fi
}

glue_export_manifest() {
    local file="${1:-glue.lock}"
    glue_resolve_backend >/dev/null 2>&1
    local backend="$GLUE_ACTIVE_BACKEND"

    echo "# Glue Declarative System Manifest" > "$file"
    echo "# Generated: $(date -u)" >> "$file"
    echo "BACKEND=$backend" >> "$file"
    echo "[packages]" >> "$file"

    local raw_pkgs
    raw_pkgs=$(GLUE_DRY_RUN=false GLUE_VERBOSE=false glue_dispatch list_installed 2>/dev/null || true)
    echo "$raw_pkgs" | awk '{print $1}' | sed -e 's|/.*||' | grep -v '^#' | grep -v '^$' | sort -u >> "$file"

    echo "Manifest exported successfully to $file"
}

glue_sync_manifest() {
    local file="${1:-glue.lock}"
    if [[ ! -f "$file" ]]; then
        echo "Error: Manifest file '$file' not found." >&2
        return 1
    fi

    echo "Synchronizing system from manifest $file..."
    local pkgs=()
    local in_pkgs=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        if [[ "$line" == "[packages]" ]]; then
            in_pkgs=true
            continue
        fi

        if $in_pkgs; then
            pkgs+=("$line")
        fi
    done < "$file"

    if [[ ${#pkgs[@]} -gt 0 ]]; then
        echo "Installing/verifying ${#pkgs[@]} packages from manifest..."
        glue_dispatch install "${pkgs[@]}"
    else
        echo "No packages listed in manifest."
    fi
}

# Neutral glue CLI function
glue() {
    local global_flags=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|--verbose|-v|--backend=*|--provider=*|--target=*)
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
        export)
            glue_export_manifest "$@"
            ;;
        sync)
            glue_sync_manifest "$@"
            ;;
        rollback)
            glue_rollback_system "$@"
            ;;
        cluster)
            glue_cluster_sync "$@"
            ;;
        audit)
            glue_audit_security "$@"
            ;;
        repair)
            glue_repair_system "$@"
            ;;
        webui)
            glue_launch_webui "$@"
            ;;
        trace)
            glue_trace_exec "$@"
            ;;
        plugin)
            glue_wasm_plugin "$@"
            ;;
        daemon)
            glue_autodeamon "$@"
            ;;
        build)
            glue_build_distributed "$@"
            ;;
        verify)
            glue_verify_manifest "$@"
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
            echo "  glue export [manifest.lock]"
            echo "  glue sync [manifest.lock]"
            echo "  glue rollback"
            echo "  glue cluster [node_address]"
            echo "  glue audit"
            echo "  glue repair"
            echo "  glue trace <command...>"
            echo "  glue plugin [list|load|run]"
            echo "  glue daemon [start|status|stop]"
            echo "  glue build <source_pkg>"
            echo "  glue verify [manifest.lock]"
            echo "  glue webui [port]"
            echo ""
            echo "Global Flags:"
            echo "  --dry-run          Show command without executing"
            echo "  --verbose, -v      Print translation command"
            echo "  --backend=<name>   Force a specific backend"
            echo "  --provider=<name>  Use provider (flatpak, snap, pip, cargo, npm)"
            echo "  --target=<dest>    Execute on remote/container target (docker:..., ssh://...)"
            echo ""
            echo "Actions:"
            echo "  install <pkg...>   Install package(s)"
            echo "  remove <pkg...>    Remove package(s)"
            echo "  autoremove         Remove orphaned packages"
            echo "  update             Refresh package indexes"
            echo "  upgrade [pkg...]   Upgrade installed packages"
            echo "  search <query...>  Search for packages (--ai for natural language)"
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
