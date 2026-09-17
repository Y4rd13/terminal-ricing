#!/usr/bin/env bash
# Structural tests for setup.sh and the dotfiles it ships.
#
# These are not behavioural tests of the wizard: it is interactive and writes to $HOME,
# so driving it here would be more harness than value. What breaks in practice is the
# contract between the DOTFILES_* tables and the files on disk -- a script committed but
# never added to the installer, a source path renamed, a personal path leaking into a
# public repo -- and that is what is checked here, statically.
#
# Run: bash tests/setup.test.sh

set -uo pipefail

REPO="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$REPO/setup.sh"

passed=0
failed=0
failures=()

ok() { passed=$((passed + 1)); }

ko() {
    failed=$((failed + 1))
    failures+=("$1")
    printf 'FAIL: %s\n' "$1"
}

# report <msg> <exit-status>
report() { [[ "$2" -eq 0 ]] && ok || ko "$1"; }

# The arrays are plain bash literals, so the declarations can be lifted out of setup.sh
# without sourcing it (sourcing would launch the wizard).
eval "$(sed -n '/^DOTFILES_UBUNTU_WSL=(/,/^)/p; /^DOTFILES_LINUX=(/,/^)/p; /^DOTFILES_ARCH=(/,/^)/p' "$SETUP")"

platform_table() {
    case "$1" in
        ubuntu-wsl) echo "DOTFILES_UBUNTU_WSL" ;;
        linux) echo "DOTFILES_LINUX" ;;
        arch) echo "DOTFILES_ARCH" ;;
    esac
}

platform_of() {
    case "$1" in
        DOTFILES_UBUNTU_WSL) echo "ubuntu-wsl" ;;
        DOTFILES_LINUX) echo "linux" ;;
        DOTFILES_ARCH) echo "arch" ;;
    esac
}

# Not every branch carries every platform, so work from the tables actually declared.
TABLES=()
for table in DOTFILES_UBUNTU_WSL DOTFILES_LINUX DOTFILES_ARCH; do
    declare -p "$table" >/dev/null 2>&1 && TABLES+=("$table")
done

[[ "${#TABLES[@]}" -gt 0 ]]
report "setup.sh declares no DOTFILES_* table at all (did the parse break?)" $?

# ── T0: tables and platform directories do not drift apart ────────────────────
for table in "${TABLES[@]}"; do
    [[ -d "$REPO/$(platform_of "$table")" ]]
    report "$table is declared but its platform directory $(platform_of "$table")/ does not exist" $?
done
for dir in "$REPO"/*/; do
    platform="$(basename "$dir")"
    case "$platform" in ubuntu-wsl | linux | arch) ;; *) continue ;; esac
    printf '%s\n' "${TABLES[@]}" | grep -qx "$(platform_table "$platform")"
    report "$platform/ exists but setup.sh declares no $(platform_table "$platform") table" $?
done

# ── T1: every source declared in a DOTFILES_* table exists on disk ──────────────
for table in "${TABLES[@]}"; do
    platform="$(platform_of "$table")"
    declare -n entries="$table"
    for entry in "${entries[@]}"; do
        IFS=':' read -r src _target _desc _requires <<< "$entry"
        [[ -e "$REPO/$platform/$src" ]]
        report "$table declares $src but $platform/$src does not exist" $?
    done
    unset -n entries
done

# ── T2: browser-pick is deployed by the installer, not only committed ───────────
printf '%s\n' "${DOTFILES_UBUNTU_WSL[@]}" | grep -q '^\.local/bin/browser-pick:'
report "DOTFILES_UBUNTU_WSL has no entry for .local/bin/browser-pick (script is committed but never installed)" $?

[[ -x "$REPO/ubuntu-wsl/.local/bin/browser-pick" ]]
report "ubuntu-wsl/.local/bin/browser-pick is not executable (deploy_dotfile symlinks it, so the mode must live in the repo)" $?

# ── T3: the session-recall banner prints above the p10k instant prompt block ────
# Powerlevel10k warns about any console output produced after the instant prompt
# preamble, so a banner below it turns every new shell into a warning.
zshrc="$REPO/ubuntu-wsl/.zshrc"
banner_line="$(grep -n 'sr banner' "$zshrc" | head -1 | cut -d: -f1)"
instant_line="$(grep -n 'p10k-instant-prompt' "$zshrc" | head -1 | cut -d: -f1)"

if [[ -z "$banner_line" ]]; then
    ko "ubuntu-wsl/.zshrc does not call 'sr banner'"
elif [[ -z "$instant_line" ]]; then
    ko "ubuntu-wsl/.zshrc has no p10k instant prompt block to position the banner against"
else
    [[ "$banner_line" -lt "$instant_line" ]]
    report "ubuntu-wsl/.zshrc calls 'sr banner' at line $banner_line, below the instant prompt block at line $instant_line: p10k will warn on every shell" $?
fi

# ── T4: the shipped zshrc carries BROWSER, and no personal paths (public repo) ──
grep -q '^export BROWSER=' "$zshrc"
report "ubuntu-wsl/.zshrc does not export BROWSER, so browser-pick is installed but never used" $?

for table in "${TABLES[@]}"; do
    platform="$(platform_of "$table")"
    candidate="$REPO/$platform/.zshrc"
    if [[ ! -f "$candidate" ]]; then
        ko "$platform/.zshrc is missing, so it cannot be checked for hardcoded paths"
        continue
    fi
    ! grep -qE '/home/[a-z_][a-z0-9_-]*' "$candidate"
    report "$platform/.zshrc hardcodes an absolute /home path; this repo is public, use \$HOME" $?
done

# ── T6: browser-pick asks only where there is a terminal to ask on ────────────────
# /dev/tty exists as a device node almost everywhere, so a guard written against its
# existence never fires, and a run with no controlling terminal falls through to a prompt
# that writes nowhere. A guard written against stdin instead would be wrong the other way:
# gh runs this with stdin redirected while a usable terminal is still attached.
bp="$REPO/ubuntu-wsl/.local/bin/browser-pick"
sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT

cat > "$sandbox/brave-stub" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$1" >> "$sandbox/brave-calls"
STUB
chmod +x "$sandbox/brave-stub"

wait_for_file() {
    local f="$1" i
    for ((i = 0; i < 100; i++)); do
        [[ -s "$f" ]] && return 0
        sleep 0.05
    done
    return 1
}

# No controlling terminal: open the default straight away, quietly.
noterm_err="$(setsid env BROWSER_PICK_BRAVE="$sandbox/brave-stub" BROWSER_PICK_TIMEOUT=1 \
    "$bp" https://example.com/noterm 2>&1 >/dev/null < /dev/null)"

wait_for_file "$sandbox/brave-calls"
report "browser-pick with no controlling terminal never reached the browser" $?

grep -q 'https://example.com/noterm' "$sandbox/brave-calls" 2>/dev/null
report "browser-pick with no controlling terminal did not pass the URL through" $?

[[ -z "$noterm_err" ]]
report "browser-pick with no controlling terminal wrote to stderr: $noterm_err" $?

# A terminal is attached but stdin is redirected, which is how gh calls it: still ask.
if command -v script >/dev/null 2>&1; then
    out="$(printf '' | script -qec "env BROWSER_PICK_BRAVE='$sandbox/brave-stub' BROWSER_PICK_TIMEOUT=1 '$bp' https://example.com/tty < /dev/null" /dev/null 2>&1)"
    grep -q 'Open in:' <<< "$out"
    report "browser-pick skipped the prompt although a terminal was attached (stdin redirected is the gh case)" $?
else
    printf 'SKIP: script(1) not installed, cannot test the pty case\n'
fi

# ── T5: shellcheck stays clean at error severity ────────────────────────────────
# Warning severity has 3 pre-existing findings in setup.sh; errors are the gate.
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -S error "$SETUP" >/dev/null 2>&1
    report "shellcheck -S error reports problems in setup.sh" $?

    shellcheck -S error "$REPO/ubuntu-wsl/.local/bin/browser-pick" >/dev/null 2>&1
    report "shellcheck -S error reports problems in ubuntu-wsl/.local/bin/browser-pick" $?
else
    printf 'SKIP: shellcheck not installed\n'
fi

# ── Summary ─────────────────────────────────────────────────────────────────────
echo ""
if [[ "$failed" -eq 0 ]]; then
    printf '%d passed\n' "$passed"
    exit 0
fi
printf '%d passed, %d failed\n' "$passed" "$failed"
exit 1
