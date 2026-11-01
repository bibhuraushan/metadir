#!/bin/zsh

set -euo pipefail

readonly ROOT_DIR="${0:A:h}"
readonly APP_DIR="$ROOT_DIR/app"
readonly CLI_DIR="$ROOT_DIR/cli"
readonly DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
readonly APP_OUTPUT="$APP_DIR/build/Build/Products/Release/MetaDir.app"
readonly CLI_OUTPUT="$CLI_DIR/.build/release/metadir"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    readonly BLUE=$'\e[1;34m'
    readonly CYAN=$'\e[36m'
    readonly GREEN=$'\e[1;32m'
    readonly RED=$'\e[1;31m'
    readonly DIM=$'\e[2m'
    readonly RESET=$'\e[0m'
else
    readonly BLUE="" CYAN="" GREEN="" RED="" DIM="" RESET=""
fi

print_usage() {
    cat <<EOF
${BLUE}MetaDir Builder${RESET}

Usage: ./build.zsh [command]

Commands:
  all       Build the macOS app and CLI (default)
  app       Build the macOS app and embedded extensions
  cli       Build the release CLI
  test      Run the app and CLI test suites
  help      Show this message

Set NO_COLOR=1 to disable colored output.
EOF
}

print_header() {
    print
    print "${BLUE}╭──────────────────────────────────────╮${RESET}"
    print "${BLUE}│            MetaDir Builder           │${RESET}"
    print "${BLUE}╰──────────────────────────────────────╯${RESET}"
    print "${DIM}  Command: $1${RESET}"
    print
}

section() {
    print "${CYAN}▶ $1${RESET}"
}

success() {
    print "${GREEN}✓ $1${RESET}"
}

failure() {
    print -u2 "${RED}✗ $1${RESET}"
}

require_xcode() {
    if [[ ! -d "$DEVELOPER_DIR" ]]; then
        failure "Xcode was not found at /Applications/Xcode.app"
        print -u2 "  Install Xcode or update DEVELOPER_DIR in build.zsh."
        exit 1
    fi
}

run_logged() {
    local label="$1"
    local log_file="$2"
    shift 2

    mkdir -p "${log_file:h}"
    "$@" >"$log_file" 2>&1 &
    local command_pid=$!
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame_index=1

    if [[ -t 1 ]]; then
        while kill -0 "$command_pid" 2>/dev/null; do
            printf "\r  ${CYAN}%s${RESET} %s" "${frames[$frame_index]}" "$label"
            frame_index=$((frame_index % ${#frames} + 1))
            sleep 0.1
        done
        printf "\r\033[2K"
    fi

    if wait "$command_pid"; then
        success "$label"
    else
        local status=$?
        failure "$label"
        print -u2 "${DIM}  Last 40 log lines:${RESET}"
        tail -n 40 "$log_file" >&2
        print -u2
        print -u2 "  Full log: $log_file"
        return "$status"
    fi
}

configure_roots() {
    section "Preparing Finder configuration"
    (
        cd "$APP_DIR"
        run_logged "Configured monitored roots" "$APP_DIR/build/logs/configure-roots.log" ./Scripts/configure-local-roots.sh
    )
}

build_app() {
    configure_roots
    section "Building macOS app"
    run_logged "Built MetaDir.app" "$APP_DIR/build/logs/app-release.log" \
        env DEVELOPER_DIR="$DEVELOPER_DIR" xcodebuild \
        -project "$APP_DIR/MetaDir.xcodeproj" \
        -scheme MetaDir \
        -configuration Release \
        -destination "platform=macOS" \
        -derivedDataPath "$APP_DIR/build" \
        build
    print "  ${DIM}$APP_OUTPUT${RESET}"
    print
}

build_cli() {
    section "Building command-line tool"
    (
        cd "$CLI_DIR"
        run_logged "Built metadir CLI" "$CLI_DIR/.build/logs/cli-release.log" \
            env DEVELOPER_DIR="$DEVELOPER_DIR" swift build -c release
    )
    print "  ${DIM}$CLI_OUTPUT${RESET}"
    print
}

test_all() {
    section "Testing macOS app"
    run_logged "App tests passed" "$APP_DIR/build-tests/logs/tests.log" \
        env DEVELOPER_DIR="$DEVELOPER_DIR" xcodebuild \
        -project "$APP_DIR/MetaDir.xcodeproj" \
        -scheme MetaDir \
        -destination "platform=macOS" \
        -derivedDataPath "$APP_DIR/build-tests" \
        test

    section "Testing command-line tool"
    (
        cd "$CLI_DIR"
        run_logged "CLI tests passed" "$CLI_DIR/.build/logs/tests.log" \
            env DEVELOPER_DIR="$DEVELOPER_DIR" swift test
    )
    print
}

finish() {
    print "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    success "Finished successfully"
    print "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

main() {
    local command="${1:-all}"

    case "$command" in
        help|-h|--help)
            print_usage
            return
            ;;
        all|app|cli|test)
            ;;
        *)
            failure "Unknown command: $command"
            print_usage >&2
            exit 2
            ;;
    esac

    require_xcode
    print_header "$command"

    case "$command" in
        all)
            build_app
            build_cli
            ;;
        app)
            build_app
            ;;
        cli)
            build_cli
            ;;
        test)
            test_all
            ;;
    esac

    finish
}

main "$@"
