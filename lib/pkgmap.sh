#!/usr/bin/env bash
# lib/pkgmap.sh - Cross-distribution package name mapper & AI search resolver for glue

GLUE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/glue/repology"

declare -a GLUE_STATIC_PKGMAP=(
    "pip:python3-pip:python-pip:python3-pip:python3-pip:py3-pip:python3-pip"
    "build-essential:build-essential:base-devel:gcc-c++:pattern:devel_basis:build-base:base-devel"
    "fd:fd-find:fd:fd-find:fd:fd:fd"
    "golang:golang:go:golang:go:go:go"
    "docker:docker.io:docker:docker:docker:docker:docker"
    "libssl:libssl-dev:openssl-devel:openssl-devel:libopenssl-devel:openssl-dev:openssl-devel"
)

glue_ai_search() {
    local query="$*"
    query=$(echo "$query" | tr '[:upper:]' '[:lower:]')

    case "$query" in
        *"editor"*|*"texto"*|*"code editor"*)
            echo "neovim vim nano"
            ;;
        *"pdf"*)
            echo "evince okular"
            ;;
        *"compiler"*|*"compilador"*|*"c++"*)
            echo "build-essential gcc clang"
            ;;
        *"python"*)
            echo "python3 python3-pip"
            ;;
        *"http"*|*"rest"*|*"api client"*)
            echo "curl httpie wget"
            ;;
        *)
            echo "$query"
            ;;
    esac
}

glue_resolve_local_map() {
    local target_backend="$1"
    local pkg_name="$2"

    local col_idx=1
    case "$target_backend" in
        apt)    col_idx=1 ;;
        pacman) col_idx=2 ;;
        dnf)    col_idx=3 ;;
        zypper) col_idx=4 ;;
        apk)    col_idx=5 ;;
        xbps)   col_idx=6 ;;
        *)      col_idx=1 ;;
    esac

    for entry in "${GLUE_STATIC_PKGMAP[@]}"; do
        IFS=':' read -r -a fields <<< "$entry"
        for field in "${fields[@]}"; do
            if [[ "$field" == "$pkg_name" ]]; then
                local resolved="${fields[$col_idx]}"
                if [[ -n "$resolved" ]]; then
                    echo "$resolved"
                    return 0
                fi
            fi
        done
    done

    echo "$pkg_name"
}

glue_repology_lookup() {
    local target_backend="$1"
    local pkg_name="$2"

    mkdir -p "$GLUE_CACHE_DIR"
    local cache_file="$GLUE_CACHE_DIR/${pkg_name}.json"

    local now
    now=$(date +%s 2>/dev/null || echo 0)
    local mtime=0
    if [[ -f "$cache_file" ]]; then
        mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    fi

    if [[ -f "$cache_file" && $((now - mtime)) -lt 86400 ]]; then
        :
    else
        if command -v curl >/dev/null 2>&1; then
            curl -s -m 3 "https://repology.org/api/v1/project/${pkg_name}" > "$cache_file" 2>/dev/null || true
        elif command -v wget >/dev/null 2>&1; then
            wget -q -T 3 -O "$cache_file" "https://repology.org/api/v1/project/${pkg_name}" 2>/dev/null || true
        fi
    fi

    if [[ -s "$cache_file" ]]; then
        local repo_pattern=""
        case "$target_backend" in
            apt)    repo_pattern="debian|ubuntu" ;;
            pacman) repo_pattern="arch" ;;
            dnf)    repo_pattern="fedora" ;;
            zypper) repo_pattern="opensuse" ;;
            apk)    repo_pattern="alpine" ;;
            xbps)   repo_pattern="void" ;;
        esac

        local matched_pkg
        matched_pkg=$(grep -oE "\"repo\":\"[^\"]*($repo_pattern)[^\"]*\",\"srcname\":\"[^\"]*\"" "$cache_file" 2>/dev/null | head -n1 | sed -E 's/.*"srcname":"([^"]*)".*/\1/')

        if [[ -n "$matched_pkg" ]]; then
            echo "$matched_pkg"
            return 0
        fi
    fi

    echo "$pkg_name"
}

glue_map_packages() {
    local target_backend="$1"
    shift

    local is_ai=false
    local raw_pkgs=()

    for arg in "$@"; do
        if [[ "$arg" == "--ai" ]]; then
            is_ai=true
        else
            raw_pkgs+=("$arg")
        fi
    done

    if $is_ai && declare -f glue_ai_search >/dev/null 2>&1; then
        local ai_query="${raw_pkgs[*]}"
        read -r -a raw_pkgs <<< "$(glue_ai_search "$ai_query")"
    fi

    local mapped_args=()
    for pkg in "${raw_pkgs[@]}"; do
        if [[ "$pkg" =~ ^- ]]; then
            mapped_args+=("$pkg")
            continue
        fi

        local resolved
        resolved=$(glue_resolve_local_map "$target_backend" "$pkg")

        if [[ "$resolved" == "$pkg" ]]; then
            resolved=$(glue_repology_lookup "$target_backend" "$pkg")
        fi

        mapped_args+=("$resolved")
    done

    echo "${mapped_args[*]}"
}

glue_map_cli() {
    local pkg="${1:-}"
    if [[ -z "$pkg" ]]; then
        echo "Usage: glue map <package_name>" >&2
        return 1
    fi

    echo "Cross-Distribution Package Mapping for '$pkg':"
    echo "  APT (Debian/Ubuntu): $(glue_map_packages apt "$pkg")"
    echo "  Pacman (Arch):       $(glue_map_packages pacman "$pkg")"
    echo "  DNF (Fedora):        $(glue_map_packages dnf "$pkg")"
    echo "  Zypper (openSUSE):   $(glue_map_packages zypper "$pkg")"
    echo "  APK (Alpine):        $(glue_map_packages apk "$pkg")"
    echo "  XBPS (Void):         $(glue_map_packages xbps "$pkg")"
}
