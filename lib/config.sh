#!/usr/bin/env bash
# lib/config.sh - Configuration management for glue

glue_get_config_file() {
    if [[ -n "${GLUE_CONFIG_FILE:-}" ]]; then
        echo "$GLUE_CONFIG_FILE"
        return
    fi

    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}/glue/config"
    local dot_config="$HOME/.glue/config"

    if [[ -f "$xdg_config" ]]; then
        echo "$xdg_config"
    elif [[ -f "$dot_config" ]]; then
        echo "$dot_config"
    else
        # Default target location when creating a new config file
        echo "$xdg_config"
    fi
}

glue_set_defaults() {
    GLUE_DIALECT="${GLUE_DIALECT:-apt}"
    GLUE_BACKEND="${GLUE_BACKEND:-auto}"
    GLUE_USE_AUR_HELPER="${GLUE_USE_AUR_HELPER:-yay}"
    GLUE_DRY_RUN="${GLUE_DRY_RUN:-false}"
    GLUE_VERBOSE="${GLUE_VERBOSE:-true}"
}

glue_load_config() {
    glue_set_defaults

    local config_file
    config_file=$(glue_get_config_file)

    if [[ -f "$config_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Strip comments and trim whitespace
            line=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            [[ -z "$line" ]] && continue

            if [[ "$line" == *"="* ]]; then
                local key="${line%%=*}"
                local val="${line#*=}"

                key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                val=$(echo "$val" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

                # Strip quotes if any
                val="${val%\"}"
                val="${val#\"}"
                val="${val%\'}"
                val="${val#\'}"

                case "$key" in
                    GLUE_DIALECT)         GLUE_DIALECT="$val" ;;
                    GLUE_BACKEND)         GLUE_BACKEND="$val" ;;
                    GLUE_USE_AUR_HELPER)  GLUE_USE_AUR_HELPER="$val" ;;
                    GLUE_DRY_RUN)         GLUE_DRY_RUN="$val" ;;
                    GLUE_VERBOSE)         GLUE_VERBOSE="$val" ;;
                esac
            fi
        done < "$config_file"
    fi
}

glue_config_get() {
    local key="$1"
    glue_load_config

    case "$key" in
        GLUE_DIALECT|dialect)               echo "$GLUE_DIALECT" ;;
        GLUE_BACKEND|backend)               echo "$GLUE_BACKEND" ;;
        GLUE_USE_AUR_HELPER|use_aur_helper) echo "$GLUE_USE_AUR_HELPER" ;;
        GLUE_DRY_RUN|dry_run)               echo "$GLUE_DRY_RUN" ;;
        GLUE_VERBOSE|verbose)               echo "$GLUE_VERBOSE" ;;
        *)
            echo "Error: Unknown config key '$key'" >&2
            return 1
            ;;
    esac
}

glue_config_set() {
    local key="$1"
    local val="$2"

    if [[ -z "$key" || -z "$val" ]]; then
        echo "Usage: glue config set <key> <value>" >&2
        return 1
    fi

    # Normalize key name
    case "$key" in
        dialect|GLUE_DIALECT)               key="GLUE_DIALECT" ;;
        backend|GLUE_BACKEND)               key="GLUE_BACKEND" ;;
        use_aur_helper|GLUE_USE_AUR_HELPER) key="GLUE_USE_AUR_HELPER" ;;
        dry_run|GLUE_DRY_RUN)               key="GLUE_DRY_RUN" ;;
        verbose|GLUE_VERBOSE)               key="GLUE_VERBOSE" ;;
        *)
            echo "Error: Unknown config key '$key'" >&2
            return 1
            ;;
    esac

    local config_file
    config_file=$(glue_get_config_file)
    local config_dir
    config_dir="$(dirname "$config_file")"

    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi

    if [[ ! -f "$config_file" ]]; then
        touch "$config_file"
    fi

    if grep -q "^[[:space:]]*${key}=" "$config_file"; then
        # Replace existing key
        sed -i.bak "s|^[[:space:]]*${key}=.*|${key}=${val}|" "$config_file" && rm -f "${config_file}.bak"
    else
        # Append new key
        echo "${key}=${val}" >> "$config_file"
    fi

    # Update current session environment variable
    declare -g "$key=$val" 2>/dev/null || eval "$key=\"$val\""
    echo "Configuration updated: $key=$val"
}

glue_config_show() {
    glue_load_config
    local config_file
    config_file=$(glue_get_config_file)

    echo "Glue Configuration:"
    echo "  Config File:         ${config_file} $( [[ -f "$config_file" ]] && echo "(exists)" || echo "(not found, using defaults)" )"
    echo "  GLUE_DIALECT:        $GLUE_DIALECT"
    echo "  GLUE_BACKEND:        $GLUE_BACKEND"
    echo "  GLUE_USE_AUR_HELPER: $GLUE_USE_AUR_HELPER"
    echo "  GLUE_DRY_RUN:        $GLUE_DRY_RUN"
    echo "  GLUE_VERBOSE:        $GLUE_VERBOSE"
}
