#!/usr/bin/env bash
set -euo pipefail

# detect-structure.sh — Auto-detect codebase structure for create-agents-md
# Usage: detect-structure.sh [--json] [--deep] [repo-root]
#   --json    Output JSON to stdout
#   --deep    Enable deeper analysis (import graph, git history)
#   repo-root Path to repository (default: .)

JSON_OUTPUT=false
DEEP_MODE=false
REPO_ROOT="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON_OUTPUT=true; shift ;;
        --deep) DEEP_MODE=true; shift ;;
        *) REPO_ROOT="$1"; shift ;;
    esac
done

cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Check if tree is installed, offer to install
if ! command -v tree &>/dev/null; then
    if ! $JSON_OUTPUT; then
        echo "tree is not installed."
        if [[ "$(uname -s)" == "Darwin" ]]; then
            echo "Install with: brew install tree"
        elif [[ -f /etc/debian_version ]]; then
            echo "Install with: sudo apt install tree"
        else
            echo "Install tree from your package manager."
        fi
    fi
    exit 1
fi

# sha256sum wrapper (macOS compat)
sha256_cmd() {
    if command -v sha256sum &>/dev/null; then
        sha256sum | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 256 | cut -d' ' -f1
    else
        echo "UNKNOWN"
    fi
}

# Normalize module name: trim trailing slash, extract last component
module_name() {
    local path="$1"
    path="${path%/}"
    echo "${path##*/}"
}

# Detect if a README exists in a directory
has_readme() {
    local dir="$1"
    if ls "$dir"/README.* >/dev/null 2>&1; then
        echo "true"
    else
        echo "false"
    fi
}

# Extract first heading from README
readme_description() {
    local dir="$1"
    local readme_file
    readme_file=$(ls "$dir"/README.md 2>/dev/null | head -1)
    if [[ -z "$readme_file" ]]; then
        echo "null"
        return
    fi
    # Extract first # heading, strip the # prefix and whitespace
    local desc
    desc=$(grep -m1 '^# ' "$readme_file" 2>/dev/null | sed 's/^# //' | xargs)
    if [[ -z "$desc" ]]; then
        echo "null"
    else
        # JSON-escape: replace " with \"
        desc="${desc//\"/\\\"}"
        echo "\"$desc\""
    fi
}

# ---------------------------------------------------------------------------
# Tree Output
# ---------------------------------------------------------------------------

# Use --gitignore if tree supports it (v2.0+), otherwise build an ignore list
TREE_ARGS=(--dirsfirst -d -n --charset=ascii)
if tree --help 2>&1 | grep -q '\-\-gitignore'; then
    TREE_ARGS+=(--gitignore)
else
    # Fallback: common ignore patterns + patterns from .gitignore
    IGNORE_PATTERNS="node_modules|.git|.github|vendor|__pycache__|.venv|venv|dist|build|.cache|.npm|.yarn|coverage|.next|.nuxt"
    if [[ -f ".gitignore" ]]; then
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^# ]] && continue
            [[ -z "$line" ]] && continue
            # Strip leading slash and trailing slash
            line="${line#/}"
            line="${line%/}"
            # Convert glob to grep pattern
            pattern=$(echo "$line" | sed 's/\./\\./g' | sed 's/\*/.*/g' | sed 's/\?/./g')
            [[ -n "$pattern" ]] && IGNORE_PATTERNS="$IGNORE_PATTERNS|$pattern"
        done < .gitignore
    fi
    TREE_ARGS+=(-I "$IGNORE_PATTERNS")
fi

TREE_OUTPUT=$(tree "${TREE_ARGS[@]}" 2>&1 || echo "ERROR: tree command failed")
TREE_HASH=$(echo "$TREE_OUTPUT" | sha256_cmd)

# ---------------------------------------------------------------------------
# Manifest Parsing
# ---------------------------------------------------------------------------

# --- Go ---
GO_DETECTED=false
GO_MODULE_NAME=""
GO_ENTRY_POINTS="[]"
GO_INTERNAL_DIRS="[]"

if [[ -f "go.mod" ]]; then
    GO_DETECTED=true
    GO_MODULE_NAME=$(grep -m1 '^module ' go.mod | awk '{print $2}' || echo "unknown")

    # Entry points: directories containing main.go
    GO_EP=$(find . -maxdepth 3 -name 'main.go' -not -path '*/vendor/*' 2>/dev/null | sed 's|/main.go||' | sed 's|^\./||' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
    GO_ENTRY_POINTS="$GO_EP"

    # internal/ directories
    GO_ID=$(find . -maxdepth 2 -type d -name 'internal' -not -path '*/vendor/*' 2>/dev/null | sed 's|^\./||' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
    GO_INTERNAL_DIRS="$GO_ID"
fi

# --- Python ---
PY_DETECTED=false
PY_PACKAGES="[]"
PY_TESTS_DIR="[]"

if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "setup.cfg" ]]; then
    PY_DETECTED=true

    # Find directories with __init__.py as packages (max depth 3)
    PY_PKGS=$(find . -maxdepth 3 -name '__init__.py' -not -path '*/node_modules/*' -not -path '*/.venv/*' -not -path '*/venv/*' -not -path '*/__pycache__/*' 2>/dev/null | sed 's|/__init__.py||' | sed 's|^\./||' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
    PY_PACKAGES="$PY_PKGS"

    # Tests directory
    PY_TD=$(find . -maxdepth 2 -type d \( -name 'tests' -o -name 'test' \) -not -path '*/node_modules/*' -not -path '*/.venv/*' 2>/dev/null | sed 's|^\./||' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
    PY_TESTS_DIR="$PY_TD"
fi

# --- TypeScript/JS ---
TS_DETECTED=false
TS_WORKSPACES="[]"
TS_BUILD_TARGETS="{}"

if [[ -f "package.json" ]]; then
    TS_DETECTED=true

    # Workspaces
    TS_WS=$(jq -r '.workspaces // [] | if type == "array" then .[] else .packages[]? // empty end' package.json 2>/dev/null | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
    TS_WORKSPACES="$TS_WS"

    # Build targets from scripts
    TS_BT=$(jq -c '{build: .scripts.build // null, test: .scripts.test // null, lint: .scripts.lint // null, start: .scripts.start // null}' package.json 2>/dev/null || echo "{}")
    TS_BUILD_TARGETS="$TS_BT"
fi

# --- Makefile ---
MAKEFILE_TARGETS="[]"
if [[ -f "Makefile" ]]; then
    MAKEFILE_TARGETS=$(grep -E '^[a-zA-Z_-]+:' Makefile 2>/dev/null | sed 's/:.*//' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
fi

# ---------------------------------------------------------------------------
# Module Detection via Directory Conventions
# ---------------------------------------------------------------------------

MODULES_JSON="[]"
MODULES_TMP=$(mktemp)

# Build ignore path patterns for find (respect .gitignore + common patterns)
FIND_IGNORE=(
    '-not' '-path' './.*'
    '-not' '-path' './.git/*'
    '-not' '-path' './.github/*'
    '-not' '-path' '*/vendor/*'
    '-not' '-path' '*/node_modules/*'
    '-not' '-path' '*/.venv/*'
    '-not' '-path' '*/venv/*'
    '-not' '-path' '*/__pycache__/*'
    '-not' '-path' '*/.cache/*'
    '-not' '-path' '*/dist/*'
    '-not' '-path' '*/build/*'
    '-not' '-path' '*/coverage/*'
    '-not' '-path' '*/.next/*'
    '-not' '-path' '*/.nuxt/*'
)

# Add .gitignore patterns to find ignore list
if [[ -f ".gitignore" ]]; then
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] && continue
        [[ -z "$line" ]] && continue
        line="${line#/}"
        line="${line%/}"
        # Only add directory-level patterns (containing / or *)
        if [[ "$line" == */* ]] || [[ "$line" == *\** ]]; then
            FIND_IGNORE+=('-not' '-path' "*/$line" '-not' '-path' "*/$line/*")
        fi
    done < .gitignore
fi

# Get top-level and second-level directories
ALL_DIRS=$(find . -maxdepth 2 -type d "${FIND_IGNORE[@]}" 2>/dev/null | sed 's|^\./||' | sort -u)

# Convention patterns and their confidence
declare -A CONVENTION_PATTERNS
CONVENTION_PATTERNS["cmd/|cmd/.+"]="Go command entry points | HIGH"
CONVENTION_PATTERNS["internal/|internal/.+"]="Go internal packages (unexported) | HIGH"
CONVENTION_PATTERNS["pkg/|pkg/.+"]="Go public library packages | MEDIUM"
CONVENTION_PATTERNS["handlers/|handlers/.+"]="HTTP/gRPC handlers | MEDIUM"
CONVENTION_PATTERNS["services/|services/.+"]="Business logic services | MEDIUM"
CONVENTION_PATTERNS["repos/|repos/.+"]="Data repositories | MEDIUM"
CONVENTION_PATTERNS["models/|models/.+"]="Data models/entities | MEDIUM"
CONVENTION_PATTERNS["routes/|routes/.+"]="API route definitions | MEDIUM"
CONVENTION_PATTERNS["middleware/|middleware/.+"]="HTTP middleware | MEDIUM"
CONVENTION_PATTERNS["config/|config/.+"]="Configuration | MEDIUM"
CONVENTION_PATTERNS["utils/|utils/.+"]="Utilities/helpers | LOW"
CONVENTION_PATTERNS["lib/|lib/.+"]="Library code | LOW"
CONVENTION_PATTERNS["src/|src/.+"]="Source root (Python/TS convention) | MEDIUM"
CONVENTION_PATTERNS["tests/|tests/.+"]="Test suite | HIGH"
CONVENTION_PATTERNS["test/|test/.+"]="Test suite | MEDIUM"
CONVENTION_PATTERNS["app/|app/.+"]="Application layer (TS/Python) | MEDIUM"
CONVENTION_PATTERNS["components/|components/.+"]="UI components | HIGH"
CONVENTION_PATTERNS["docs/|docs/.+"]="Documentation | HIGH"
CONVENTION_PATTERNS["scripts/|scripts/.+"]="Build/dev scripts | HIGH"
CONVENTION_PATTERNS["api/|api/.+"]="API definitions | HIGH"
CONVENTION_PATTERNS["shared/|shared/.+"]="Shared code/resources | LOW"

# Build modules array as JSON
FIRST=true
echo "[" > "$MODULES_TMP"

while IFS= read -r dir; do
    # Skip '.' itself
    [[ "$dir" == "." ]] && continue

    # Skip if this is a nested dir whose parent is also detected
    # (we want top-level + dirs that appear as standalone module boundaries)
    name=$(module_name "$dir")
    path="$dir"

    # Determine dominant language
    dominant_lang="unknown"
    if $GO_DETECTED && (echo "$dir" | grep -qE '^cmd|^internal|^pkg'); then
        dominant_lang="go"
    elif $PY_DETECTED && (echo "$dir" | grep -qE '^src|^tests|^test'); then
        dominant_lang="python"
    elif $TS_DETECTED && (echo "$dir" | grep -qE '^app|^components|^lib|^src'); then
        dominant_lang="typescript"
    fi

    # Check for README
    readme_exists=$(has_readme "$dir")
    readme_desc="null"
    if [[ "$readme_exists" == "true" ]]; then
        readme_desc=$(readme_description "$dir")
    fi

    # Match conventions
    convention_match="None"
    confidence="LOW"
    for pattern_info in "${!CONVENTION_PATTERNS[@]}"; do
        pattern="${pattern_info}"
        if echo "$dir" | grep -qE "^($pattern)$"; then
            convention_match="${CONVENTION_PATTERNS[$pattern_info]%% | *}"
            confidence="${CONVENTION_PATTERNS[$pattern_info]##* | }"
            break
        fi
    done

    # Dependencies from manifests (approximate)
    depends_on="[]"
    if $GO_DETECTED && [[ -f "go.mod" ]]; then
        # Check if this dir imports from other detected dirs
        local_deps=$(find "$dir" -maxdepth 2 -name '*.go' -exec grep -hE '"[^"]+"' {} \; 2>/dev/null | grep -oE '"[^"]+"' | tr -d '"' | grep -F "$GO_MODULE_NAME" | sed "s|$GO_MODULE_NAME/||" | grep -v '^$' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
        depends_on="$local_deps"
    fi

    # Entry points
    entry_points="[]"
    if $GO_DETECTED && ls "$dir"/main.go >/dev/null 2>&1; then
        entry_points="[\"$dir\"]"
    fi

    # Emit module JSON
    if ! $FIRST; then
        echo "," >> "$MODULES_TMP"
    fi
    FIRST=false

    cat >> "$MODULES_TMP" <<EOF
    {
      "name": "$name",
      "path": "$path",
      "convention_match": "$convention_match",
      "confidence": "$confidence",
      "dominant_lang": "$dominant_lang",
      "has_readme": $readme_exists,
      "readme_description": $readme_desc,
      "depends_on": $depends_on,
      "entry_points": $entry_points
    }
EOF

done <<< "$ALL_DIRS"

echo "]" >> "$MODULES_TMP"
MODULES_JSON=$(cat "$MODULES_TMP")
rm -f "$MODULES_TMP"

# ---------------------------------------------------------------------------
# Warnings
# ---------------------------------------------------------------------------
WARNINGS="[]"
WARN_TMP=$(mktemp)
echo "[" > "$WARN_TMP"

FIRST_WARN=true
add_warning() {
    if ! $FIRST_WARN; then echo "," >> "$WARN_TMP"; fi
    FIRST_WARN=false
    echo "\"$1\"" >> "$WARN_TMP"
}

# Check for missing README at project root
if ! ls README.* >/dev/null 2>&1; then
    add_warning "No README found in project root"
fi

# Multiple package managers detected
PM_COUNT=0
$GO_DETECTED && PM_COUNT=$((PM_COUNT + 1))
$PY_DETECTED && PM_COUNT=$((PM_COUNT + 1))
$TS_DETECTED && PM_COUNT=$((PM_COUNT + 1))
if [[ $PM_COUNT -gt 1 ]]; then
    add_warning "Multiple package managers detected (Go + Python + TypeScript)"
fi

# No package manager detected
if [[ $PM_COUNT -eq 0 ]]; then
    add_warning "No package manager detected. Parsing limited to directory conventions only."
fi

echo "]" >> "$WARN_TMP"
WARNINGS=$(cat "$WARN_TMP")
rm -f "$WARN_TMP"

# ---------------------------------------------------------------------------
# Deep Mode Extras
# ---------------------------------------------------------------------------
DEPENDENCY_GRAPH="{}"
GIT_CHURN="{}"

if $DEEP_MODE; then
    # --- Dependency graph via grep on import statements ---
    if $GO_DETECTED || $PY_DETECTED || $TS_DETECTED; then
        DEP_TMP=$(mktemp)
        echo "{" > "$DEP_TMP"

        # Go imports
        if $GO_DETECTED; then
            echo '"go": [' >> "$DEP_TMP"
            find . -name '*.go' -not -path '*/vendor/*' 2>/dev/null | while read -r file; do
                imports=$(grep -E '^\s+\"' "$file" 2>/dev/null | grep -oE '"[^"]+"' | tr -d '"' | grep -v '^$' | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
            done
            echo '],' >> "$DEP_TMP"
        fi

        # Python imports (basic)
        if $PY_DETECTED; then
            echo '"python": [],' >> "$DEP_TMP"
        fi

        # TypeScript imports
        if $TS_DETECTED; then
            echo '"typescript": []' >> "$DEP_TMP"
        fi

        echo "}" >> "$DEP_TMP"
        # Simplified: deep mode full dependency graph is a placeholder for now
    fi

    # --- Git churn analysis ---
    if git rev-parse --git-dir >/dev/null 2>&1; then
        GIT_CHURN=$(git log --pretty=format: --name-only --since="6 months ago" 2>/dev/null | sort | uniq -c | sort -rn | head -30 | awk '{printf "\"%s\": %s", $2, $1}' | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "{}")
    fi
fi

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

# JSON-escape the tree output for embedding
TREE_JSON=$(echo "$TREE_OUTPUT" | jq -R -s '.')

if $JSON_OUTPUT; then
    # Check if jq is available for pretty-printing
    if command -v jq &>/dev/null; then
        jq -n \
            --argjson tree "$TREE_JSON" \
            --arg tree_hash "$TREE_HASH" \
            --argjson go_detected "$GO_DETECTED" \
            --arg go_module_name "$GO_MODULE_NAME" \
            --argjson go_entry_points "$GO_ENTRY_POINTS" \
            --argjson go_internal_dirs "$GO_INTERNAL_DIRS" \
            --argjson py_detected "$PY_DETECTED" \
            --argjson py_packages "$PY_PACKAGES" \
            --argjson py_tests_dir "$PY_TESTS_DIR" \
            --argjson ts_detected "$TS_DETECTED" \
            --argjson ts_workspaces "$TS_WORKSPACES" \
            --argjson ts_build_targets "$TS_BUILD_TARGETS" \
            --argjson makefile_targets "$MAKEFILE_TARGETS" \
            --argjson modules "$MODULES_JSON" \
            --argjson warnings "$WARNINGS" \
            --argjson dependency_graph "$DEPENDENCY_GRAPH" \
            --argjson git_churn "$GIT_CHURN" \
            '{
                tree: $tree,
                tree_hash: $tree_hash,
                ecosystems: {
                    go: {
                        detected: $go_detected,
                        module_name: $go_module_name,
                        entry_points: $go_entry_points,
                        internal_dirs: $go_internal_dirs
                    },
                    python: {
                        detected: $py_detected,
                        packages: $py_packages,
                        tests_dir: $py_tests_dir
                    },
                    typescript: {
                        detected: $ts_detected,
                        workspaces: $ts_workspaces,
                        build_targets: $ts_build_targets
                    }
                },
                makefile_targets: $makefile_targets,
                modules: $modules,
                warnings: $warnings,
                dependency_graph: $dependency_graph,
                git_churn: $git_churn
            }'
    else
        # Fallback without jq — basic JSON assembly
        cat <<EOF
{
  "tree": $TREE_JSON,
  "tree_hash": "$TREE_HASH",
  "ecosystems": {
    "go": { "detected": $GO_DETECTED, "module_name": "$GO_MODULE_NAME", "entry_points": $GO_ENTRY_POINTS, "internal_dirs": $GO_INTERNAL_DIRS },
    "python": { "detected": $PY_DETECTED, "packages": $PY_PACKAGES, "tests_dir": $PY_TESTS_DIR },
    "typescript": { "detected": $TS_DETECTED, "workspaces": $TS_WORKSPACES, "build_targets": $TS_BUILD_TARGETS }
  },
  "makefile_targets": $MAKEFILE_TARGETS,
  "modules": $MODULES_JSON,
  "warnings": $WARNINGS,
  "dependency_graph": $DEPENDENCY_GRAPH,
  "git_churn": $GIT_CHURN
}
EOF
    fi
else
    echo "=== Structure Detection ==="
    echo ""
    echo "Ecosystems:"
    echo "  Go:         $GO_DETECTED ($GO_MODULE_NAME)"
    echo "  Python:     $PY_DETECTED"
    echo "  TypeScript: $TS_DETECTED"
    echo ""
    echo "Directory Tree:"
    echo "$TREE_OUTPUT"
    echo ""
    echo "Modules detected: $(echo "$MODULES_JSON" | jq '. | length' 2>/dev/null || echo "?")"
    echo "Warnings: $(echo "$WARNINGS" | jq '. | length' 2>/dev/null || echo "?")"
fi
