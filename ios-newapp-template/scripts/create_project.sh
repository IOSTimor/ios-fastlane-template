#!/bin/bash

set -euo pipefail

TARGET_DIR=""
FORCE_OVERWRITE=${FORCE_OVERWRITE:-false}
GENERATE_ENV=${GENERATE_ENV:-true}
PROJECT_OVERRIDE=${PROJECT_OVERRIDE:-}
WORKSPACE_OVERRIDE=${WORKSPACE_OVERRIDE:-}
SCHEME_OVERRIDE=${SCHEME_OVERRIDE:-}
APP_NAME_OVERRIDE=${APP_NAME_OVERRIDE:-}

bool_is_true() {
  local raw=${1:-false}
  case "$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|y|on) return 0 ;;
    *) return 1 ;;
  esac
}

portable_sed_in_place() {
  local expression=$1
  local file_path=$2

  if sed --version >/dev/null 2>&1; then
    sed -i "$expression" "$file_path"
  else
    sed -i '' "$expression" "$file_path"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  bash scripts/create_project.sh /absolute/or/relative/path/to/ios-project [options]

Options:
  --force                    Overwrite an existing fastlane setup
  --generate-env             Create fastlane/.env when missing (default)
  --skip-generate-env        Do not create fastlane/.env automatically
  --project NAME.xcodeproj   Explicitly set the project default
  --workspace NAME.xcworkspace
                             Explicitly set the workspace default
  --scheme NAME              Explicitly set the default scheme
  --app-name NAME            Explicitly set the default app name
EOF
}

collect_matches() {
  local target_dir=$1
  local pattern=$2

  find "$target_dir" -mindepth 1 -maxdepth 2 \
    \( -type d \( -name .git -o -name Pods -o -name Carthage -o -name node_modules \) -prune \) -o \
    \( -type d -name "$pattern" ! -path '*.xcodeproj/*' -print \) | sort | while IFS= read -r match; do
      printf '%s\n' "${match#"$target_dir"/}"
    done
}

pick_single_match() {
  local matches=$1
  local count

  count=$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')
  if [[ "$count" == "1" ]]; then
    printf '%s\n' "$matches" | sed -n '/./{p;q;}'
  fi
}

first_match_name() {
  local matches=$1

  printf '%s\n' "$matches" | sed -n '/./{p;q;}'
}

print_match_warning() {
  local label=$1
  local matches=$2
  local option_name=$3
  local count

  count=$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')
  if [[ "$count" -gt 1 ]]; then
    echo "Multiple ${label}s detected. Auto-selection was skipped."
    printf '%s\n' "$matches" | sed '/^$/d' | while read -r match; do
      printf '  - %s\n' "$match"
    done
    echo "Set ${option_name} explicitly and re-run if needed."
  fi
}

print_recommended_command() {
  local project_suggestion=$1
  local workspace_suggestion=$2
  local scheme_suggestion=$3
  local app_name_suggestion=$4
  local needs_recommendation=false
  local command='ios-fastlane-template /path/to/your/ios-project --force'

  [[ -n "$project_suggestion" ]] && {
    command="${command} --project $(printf '%q' "$project_suggestion")"
    needs_recommendation=true
  }
  [[ -n "$workspace_suggestion" ]] && {
    command="${command} --workspace $(printf '%q' "$workspace_suggestion")"
    needs_recommendation=true
  }
  [[ -n "$scheme_suggestion" ]] && {
    command="${command} --scheme $(printf '%q' "$scheme_suggestion")"
    needs_recommendation=true
  }
  [[ -n "$app_name_suggestion" ]] && {
    command="${command} --app-name $(printf '%q' "$app_name_suggestion")"
    needs_recommendation=true
  }

  if bool_is_true "$needs_recommendation"; then
    echo "Recommended explicit install command:"
    echo "  ${command}"
  fi
}

infer_scheme_from_project() {
  local project_name=$1

  if [[ -n "$project_name" ]]; then
    project_name=${project_name##*/}
    printf '%s\n' "${project_name%.xcodeproj}"
  fi
}

set_env_value() {
  local file_path=$1
  local key=$2
  local value=$3
  local encoded escaped

  if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
    echo "Environment values must fit on one line: $key" >&2
    exit 1
  fi
  encoded=$value
  if [[ ! "$value" =~ ^[a-zA-Z0-9_./:-]*$ ]]; then
    encoded=${encoded//\\/\\\\}
    encoded=${encoded//\"/\\\"}
    encoded=${encoded//\$/\\\$}
    encoded="\"${encoded}\""
  fi
  escaped=${encoded//\\/\\\\}
  escaped=${escaped//&/\\&}
  escaped=${escaped//|/\\|}

  if grep -q "^${key}=" "$file_path"; then
    portable_sed_in_place "s|^${key}=.*|${key}=${escaped}|" "$file_path"
  else
    printf "\n%s=%s\n" "$key" "$encoded" >> "$file_path"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        FORCE_OVERWRITE=true
        shift
        ;;
      --generate-env)
        GENERATE_ENV=true
        shift
        ;;
      --skip-generate-env)
        GENERATE_ENV=false
        shift
        ;;
      --project|--workspace|--scheme|--app-name)
        if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
          echo "Missing value for $1" >&2
          exit 1
        fi
        case "$1" in
          --project) PROJECT_OVERRIDE=$2 ;;
          --workspace) WORKSPACE_OVERRIDE=$2 ;;
          --scheme) SCHEME_OVERRIDE=$2 ;;
          --app-name) APP_NAME_OVERRIDE=$2 ;;
        esac
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        if [[ -z "$TARGET_DIR" ]]; then
          TARGET_DIR=$1
          shift
        else
          echo "Unexpected argument: $1"
          usage
          exit 1
        fi
        ;;
    esac
  done
}

parse_args "$@"

if [[ -z "$TARGET_DIR" ]]; then
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || true)"

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist"
  exit 1
fi

if [[ "$TARGET_DIR" == "$TEMPLATE_DIR" ]]; then
  echo "Refusing to install the template onto itself" >&2
  exit 1
fi

if [[ -d "$TARGET_DIR/fastlane" ]] && [[ -n "$(find "$TARGET_DIR/fastlane" -mindepth 1 -print -quit)" ]]; then
  if ! bool_is_true "$FORCE_OVERWRITE"; then
    echo "Existing fastlane configuration detected in $TARGET_DIR/fastlane"
    echo "Refusing to overwrite automatically."
    echo "Re-run with --force or FORCE_OVERWRITE=true if you want to replace the template files."
    exit 1
  fi
fi

PROJECT_MATCHES=$(collect_matches "$TARGET_DIR" "*.xcodeproj")
WORKSPACE_MATCHES=$(collect_matches "$TARGET_DIR" "*.xcworkspace")

PROJECT_SUGGESTION=$(first_match_name "$PROJECT_MATCHES")
WORKSPACE_SUGGESTION=$(first_match_name "$WORKSPACE_MATCHES")
SCHEME_SUGGESTION=$(infer_scheme_from_project "${PROJECT_SUGGESTION}")
APP_NAME_SUGGESTION=${SCHEME_SUGGESTION:-}

DETECTED_PROJECT=${PROJECT_OVERRIDE:-$(pick_single_match "$PROJECT_MATCHES")}
DETECTED_WORKSPACE=${WORKSPACE_OVERRIDE:-$(pick_single_match "$WORKSPACE_MATCHES")}
DETECTED_SCHEME=${SCHEME_OVERRIDE:-$(infer_scheme_from_project "${DETECTED_PROJECT}")}
DETECTED_APP_NAME=${APP_NAME_OVERRIDE:-${DETECTED_SCHEME:-}}

mkdir -p "$TARGET_DIR/fastlane"
mkdir -p "$TARGET_DIR/fastlane/metadata"
mkdir -p "$TARGET_DIR/fastlane/screenshots"

# Replace workflow code only when authorized; preserve existing metadata and screenshots.
cp "$TEMPLATE_DIR/fastlane/Fastfile" "$TARGET_DIR/fastlane/Fastfile"
cp "$TEMPLATE_DIR/fastlane/Appfile" "$TARGET_DIR/fastlane/Appfile"
cp "$TEMPLATE_DIR/fastlane/.env.default" "$TARGET_DIR/fastlane/.env.default"
if [[ ! -f "$TARGET_DIR/fastlane/.env.example" ]]; then
  cp "$TEMPLATE_DIR/fastlane/.env.example" "$TARGET_DIR/fastlane/.env.example"
fi
for asset_dir in metadata screenshots; do
  while IFS= read -r source_file; do
    relative_path=${source_file#"$TEMPLATE_DIR/fastlane/"}
    destination="$TARGET_DIR/fastlane/$relative_path"
    mkdir -p "$(dirname "$destination")"
    if [[ ! -e "$destination" ]]; then
      cp "$source_file" "$destination"
    fi
  done < <(find "$TEMPLATE_DIR/fastlane/$asset_dir" -type f)
done

if [[ ! -f "$TARGET_DIR/Gemfile" ]]; then
  cp "$TEMPLATE_DIR/Gemfile" "$TARGET_DIR/Gemfile"
fi

if [[ ! -f "$TARGET_DIR/Makefile" ]]; then
  cp "$TEMPLATE_DIR/Makefile" "$TARGET_DIR/Makefile"
fi

set_env_value "$TARGET_DIR/fastlane/.env.default" "WORKSPACE" "${DETECTED_WORKSPACE:-}"
set_env_value "$TARGET_DIR/fastlane/.env.default" "PROJECT" "${DETECTED_PROJECT:-}"
set_env_value "$TARGET_DIR/fastlane/.env.default" "SCHEME" "${DETECTED_SCHEME:-}"
set_env_value "$TARGET_DIR/fastlane/.env.default" "APP_NAME" "${DETECTED_APP_NAME:-}"

if bool_is_true "$GENERATE_ENV" && [[ ! -f "$TARGET_DIR/fastlane/.env" ]]; then
  if [[ -f "$TARGET_DIR/.env" ]]; then
    cp "$TARGET_DIR/.env" "$TARGET_DIR/fastlane/.env"
    echo "Imported legacy root .env; edit fastlane/.env for future release configuration."
  else
    cp "$TARGET_DIR/fastlane/.env.example" "$TARGET_DIR/fastlane/.env"
    set_env_value "$TARGET_DIR/fastlane/.env" "PROJECT" "${DETECTED_PROJECT:-}"
    set_env_value "$TARGET_DIR/fastlane/.env" "WORKSPACE" "${DETECTED_WORKSPACE:-}"
    set_env_value "$TARGET_DIR/fastlane/.env" "SCHEME" "${DETECTED_SCHEME:-}"
    set_env_value "$TARGET_DIR/fastlane/.env" "APP_NAME" "${DETECTED_APP_NAME:-}"
  fi
  chmod 600 "$TARGET_DIR/fastlane/.env"
fi

for ignore_pattern in '.env' '.env.local' 'fastlane/.env' 'fastlane/.env.local' 'fastlane/.env.*.local' '*.p8' '*.p12' '*.mobileprovision' '*.ipa' 'build/'; do
  if [[ ! -f "$TARGET_DIR/.gitignore" ]] || ! grep -Fqx -- "$ignore_pattern" "$TARGET_DIR/.gitignore"; then
    printf '\n%s\n' "$ignore_pattern" >> "$TARGET_DIR/.gitignore"
  fi
done

echo "Fastlane template installed into $TARGET_DIR"

if [[ -n "${DETECTED_WORKSPACE:-}" ]]; then
  echo "Detected workspace: $DETECTED_WORKSPACE"
fi
if [[ -n "${DETECTED_PROJECT:-}" ]]; then
  echo "Detected project: $DETECTED_PROJECT"
fi
if [[ -n "${DETECTED_SCHEME:-}" ]]; then
  echo "Suggested default scheme (verify in Xcode): $DETECTED_SCHEME"
fi
if [[ -n "${DETECTED_APP_NAME:-}" ]]; then
  echo "Detected app name: $DETECTED_APP_NAME"
fi

print_match_warning "project" "$PROJECT_MATCHES" "--project"
print_match_warning "workspace" "$WORKSPACE_MATCHES" "--workspace"
print_recommended_command "${PROJECT_SUGGESTION:-}" "${WORKSPACE_SUGGESTION:-}" "${SCHEME_SUGGESTION:-}" "${APP_NAME_SUGGESTION:-}"

if bool_is_true "$GENERATE_ENV"; then
  if [[ -f "$TARGET_DIR/fastlane/.env" ]]; then
    echo "Prepared fastlane/.env in the target project"
  fi
else
  echo "Skipped automatic .env generation"
fi

echo "Next:"
echo "  1. Review fastlane/.env and fastlane/.env.default"
echo "  2. Run 'bundle install', then 'bundle exec fastlane ios validate_setup'"
echo "  3. Run 'bundle exec fastlane ios local_build'"
echo "  4. Use 'bundle exec fastlane ios precheck_assets strict:true' before metadata uploads"
