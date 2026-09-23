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
# PLATFORMS is the canonical list; deriving from it rather than hardcoding one here is
# what makes a fourth platform visible to every check below instead of silently skipped.
eval "$(sed -n '/^PLATFORMS=(/,/^)/p; /^DOTFILES_[A-Z_]*=(/,/^)/p' "$SETUP")"

platform_table() { printf 'DOTFILES_%s\n' "$(printf '%s' "$1" | tr 'a-z-' 'A-Z_')"; }

# Guard before the expansion, not after: bash 4.4 and later expand an unset array to
# nothing under `set -u`, but 3.2 aborts, and a suite that dies on its own parse failure
# reports nothing at all.
declare -p PLATFORMS >/dev/null 2>&1
report "setup.sh declares no PLATFORMS at all (did the parse break?)" $?

PLATFORMS_KEYS=()
if declare -p PLATFORMS >/dev/null 2>&1; then
    for entry in "${PLATFORMS[@]}"; do
        IFS=':' read -r key _label _desc <<< "$entry"
        PLATFORMS_KEYS+=("$key")
    done
fi

# ── T0: platforms, tables and directories do not drift apart ──────────────────
for platform in "${PLATFORMS_KEYS[@]}"; do
    table="$(platform_table "$platform")"

    declare -p "$table" >/dev/null 2>&1
    report "setup.sh offers platform $platform but declares no $table table" $?

    [[ -d "$REPO/$platform" ]]
    report "setup.sh offers platform $platform but $platform/ does not exist" $?

done

# The other direction: a directory that ships an rc file but that no platform offers is
# dead weight at best, and at worst a config nobody validates.
for dir in "$REPO"/*/; do
    platform="$(basename "$dir")"
    [[ -f "$dir/.zshrc" ]] || continue
    printf '%s\n' "${PLATFORMS_KEYS[@]}" | grep -qx "$platform"
    report "$platform/.zshrc exists but setup.sh offers no $platform platform, so nothing checks it" $?
done

# ── T1: every source declared in a DOTFILES_* table exists on disk ──────────────
for platform in "${PLATFORMS_KEYS[@]}"; do
    table="$(platform_table "$platform")"
    declare -p "$table" >/dev/null 2>&1 || continue
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

# ── T3: the seneca banner prints above the p10k instant prompt block ────────────
# Powerlevel10k warns about any console output produced after the instant prompt
# preamble, so a banner below it turns every new shell into a warning.
# Every platform sources the p10k theme, so the constraint holds on all of them, not
# only on WSL. seneca itself is platform independent, so the banner belongs on all of them too.
zshrc="$REPO/ubuntu-wsl/.zshrc"

for platform in "${PLATFORMS_KEYS[@]}"; do
    candidate="$REPO/$platform/.zshrc"
    [[ -f "$candidate" ]] || continue

    banner_line="$(grep -n 'seneca banner' "$candidate" | head -1 | cut -d: -f1)"
    instant_line="$(grep -n 'p10k-instant-prompt' "$candidate" | head -1 | cut -d: -f1)"

    if [[ -z "$banner_line" ]]; then
        ko "$platform/.zshrc does not call 'seneca banner'"
    elif [[ -z "$instant_line" ]]; then
        ko "$platform/.zshrc has no p10k instant prompt block to position the banner against"
    else
        [[ "$banner_line" -lt "$instant_line" ]]
        report "$platform/.zshrc calls 'seneca banner' at line $banner_line, below the instant prompt block at line $instant_line: p10k will warn on every shell" $?
    fi
done

# ── T3b: the banner finds seneca before .zshrc has put ~/.local/bin on PATH ────
# The banner has to run above the instant prompt block, and every .zshrc adds
# ~/.local/bin to PATH much further down. On WSL ~/.zshenv happens to add it first,
# but this repo does not ship a .zshenv, so on a fresh Arch or Linux `command -v`
# would miss it and the banner would stay silent. Run the real line with a PATH
# that lacks ~/.local/bin and a stub seneca there.
if command -v zsh >/dev/null 2>&1; then
    banner_home="$(mktemp -d)"
    mkdir -p "$banner_home/.local/bin"
    printf '#!/bin/sh\necho "stub $1"\n' > "$banner_home/.local/bin/seneca"
    chmod +x "$banner_home/.local/bin/seneca"
    for platform in "${PLATFORMS_KEYS[@]}"; do
        candidate="$REPO/$platform/.zshrc"
        [[ -f "$candidate" ]] || continue
        line="$(grep 'seneca banner' "$candidate" | head -1)"
        out="$(env -i HOME="$banner_home" PATH=/usr/bin:/bin zsh -f -c "$line" 2>&1)"
        [[ "$out" == "stub banner" ]]
        report "$platform/.zshrc banner does not find ~/.local/bin/seneca off PATH (got: $out)" $?
        out="$(env -i HOME="$banner_home/none" PATH=/usr/bin:/bin zsh -f -c "$line; echo rc=\$?" 2>&1)"
        [[ "$out" == "rc=0" ]]
        report "$platform/.zshrc banner is not a silent no-op without seneca (got: $out)" $?
    done
    rm -rf "$banner_home"
else
    printf 'SKIP: zsh not installed, cannot run the banner line\n'
fi

# ── T4: the shipped zshrc carries BROWSER, and no personal paths (public repo) ──
grep -q '^export BROWSER=' "$zshrc"
report "ubuntu-wsl/.zshrc does not export BROWSER, so browser-pick is installed but never used" $?

for platform in "${PLATFORMS_KEYS[@]}"; do
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

# ── T5: shellcheck stays clean at warning severity ──────────────────────────────
# Every shell file the repo ships, this suite included, since a test that lints
# everything except itself leaves one file where a defect can sit unread.
if command -v shellcheck >/dev/null 2>&1; then
    for sh in "$SETUP" "$REPO/ubuntu-wsl/.local/bin/browser-pick" "${BASH_SOURCE[0]}"; do
        shellcheck -S warning "$sh" >/dev/null 2>&1
        report "shellcheck -S warning reports problems in ${sh#"$REPO/"}" $?
    done
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
