qs() {
    local CONFIG_FILE="$HOME/.qs_default"

    # Load default path if config exists
    local DEFAULT_PATH=""
    [[ -f "$CONFIG_FILE" ]] && DEFAULT_PATH="$(< "$CONFIG_FILE")"

    # Fallback default if no config file
    [[ -z "$DEFAULT_PATH" ]] && DEFAULT_PATH="$HOME/uv-global"

    # Detect uv project
    is_uv_project() {
        [[ -f "$1/pyproject.toml" && -f "$1/.venv/bin/python" ]]
    }

    # Get python version from venv or uv project
    get_python_version() {
        local PROJ="$1"

        # Normalize to absolute path
        PROJ="$(cd "$PROJ" 2>/dev/null && pwd)"
        local VENV="$PROJ/.venv"

        if [[ -x "$VENV/bin/python" ]]; then
            "$VENV/bin/python" --version 2>/dev/null | awk '{print $2}'
            return
        fi

        if [[ -x "$VENV/bin/python3" ]]; then
            "$VENV/bin/python3" --version 2>/dev/null | awk '{print $2}'
            return
        fi

        if command -v uv >/dev/null 2>&1; then
            (cd "$PROJ" && uv run python --version 2>/dev/null) | awk '{print $2}'
            return
        fi

        echo "unknown"
    }

    # Activate traditional venv
    activate_venv() {
        local VENV="$1"
        deactivate 2>/dev/null
        source "$VENV/bin/activate"
        export VIRTUAL_ENV_NAME="$(basename "$VENV")"
        unset UV_PROJECT_ACTIVE UV_PROJECT_NAME UV_PROJECT_PYTHON UV_PROJECT_PATH
        echo "Activated venv '$VIRTUAL_ENV_NAME' (Python $(get_python_version "$VENV"))"
        p10k reload 2>/dev/null
    }

    # Activate uv project
    activate_uv_project() {
        local PROJ="$1"
    
        # Always absolute, always safe
        local ABS_PROJ="$(cd "$PROJ" 2>/dev/null && pwd)"
        local PYV="$(get_python_version "$ABS_PROJ")"
    
        cd "$ABS_PROJ" || return
    
        export UV_PROJECT_ACTIVE=1
        export UV_PROJECT_NAME="$(basename "$ABS_PROJ")"
        export UV_PROJECT_PYTHON="$PYV"
        export UV_PROJECT_PATH="$ABS_PROJ"
    
        deactivate 2>/dev/null
    
        echo "Entered uv project '$UV_PROJECT_NAME' (Python $PYV)"
        p10k reload 2>/dev/null
    }

    # Exit uv project
    exit_uv_project() {
        unset UV_PROJECT_ACTIVE UV_PROJECT_NAME UV_PROJECT_PYTHON UV_PROJECT_PATH
        cd ~
        echo "Exited uv project"
        p10k reload 2>/dev/null
    }

    # Exit venv
    exit_venv() {
        deactivate 2>/dev/null
        echo "Deactivated venv"
        p10k reload 2>/dev/null
    }

    # Help
    if [[ "$1" == "-help" ]]; then
        cat <<EOF
qs                         # toggle uv/venv or enter default
qs default                 # show current default path
qs --set default <name>    # set/change default path
qs list                    # list all venv and uv projects
qs <name>                  # activate venv or enter uv project
EOF
        return
    fi

    # Show default
    if [[ "$1" == "default" ]]; then
        if is_uv_project "$DEFAULT_PATH"; then
            local PYV="$(get_python_version "$DEFAULT_PATH")"
            echo "Default path: $DEFAULT_PATH  (uv project, Python $PYV)"
        elif [[ -f "$DEFAULT_PATH/bin/activate" ]]; then
            local PYV="$(get_python_version "$DEFAULT_PATH")"
            echo "Default path: $DEFAULT_PATH  (venv, Python $PYV)"
        else
            echo "Default path: $DEFAULT_PATH  (not a venv or uv project)"
        fi
        return
    fi

    # Set default
    if [[ "$1" == "--set" && "$2" == "default" ]]; then
        if [[ -z "$3" ]]; then
            echo "Usage: qs --set default <path>"
            return
        fi
        echo "$3" > "$CONFIG_FILE"
        if is_uv_project "$3"; then
            local PYV="$(get_python_version "$3")"
            echo "Default path set to: $3  (uv project, Python $PYV)"
        elif [[ -f "$3/bin/activate" ]]; then
            local PYV="$(get_python_version "$3")"
            echo "Default path set to: $3  (venv, Python $PYV)"
        else
            echo "Default path set to: $3  (not a venv or uv project)"
        fi

        return
    fi

    # List all
    if [[ "$1" == "list" ]]; then
        echo "venv environments:"
        for d in "$HOME"/*/; do
            [[ -f "$d/bin/activate" ]] && \
                echo "  $(basename "$d")  (Python $(get_python_version "$d"))"
        done
        echo ""
        echo "uv projects:"
        for d in "$HOME"/*/; do
            is_uv_project "$d" && \
                echo "  $(basename "$d")  (Python $(get_python_version "$d/.venv"))"
        done
        return 0
    fi

    # No args → toggle or enter default
    if [[ $# -eq 0 ]]; then
        if [[ -n "$UV_PROJECT_ACTIVE" ]]; then
            exit_uv_project
            return
        fi
        if [[ -n "$VIRTUAL_ENV" ]]; then
            exit_venv
            return
        fi
        if is_uv_project "$DEFAULT_PATH"; then
            activate_uv_project "$DEFAULT_PATH"
            return
        fi
        if [[ -f "$DEFAULT_PATH/bin/activate" ]]; then
            activate_venv "$DEFAULT_PATH"
            return
        fi
        echo "Default path '$DEFAULT_PATH' is not a venv or uv project"
        return
    fi

    # Match name
    local TARGET=""
    for d in "$HOME"/*/ "$PWD"/*/; do
        [[ -d "$d" ]] || continue
        [[ "$(basename "$d")" == *"$1"* ]] || continue
        TARGET="$d"
        break
    done

    if [[ -z "$TARGET" ]]; then
        echo "No venv or uv project matching '$1'"
        return
    fi

    if is_uv_project "$TARGET"; then
        activate_uv_project "$TARGET"
    elif [[ -f "$TARGET/bin/activate" ]]; then
        activate_venv "$TARGET"
    else
        echo "'$TARGET' is not a venv or uv project"
    fi
}
