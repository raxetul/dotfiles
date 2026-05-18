#!/usr/bin/env bash
# scripts/gpg-setup.sh — one-shot GPG signing wizard.
#
# Bridges the gap between the declarative GPG config in
# home/modules/gpg.nix (which knows how to use a key) and the real,
# per-host key material that has to live outside the repo. Companion to
# the Phase 7 git ergonomics: it flips Q4 from "skip GPG" to a working
# signing setup without breaking any host that never runs the wizard.
#
# What it does, in order:
#   1. Sanity-check: gpg + git are installed; git user.name and user.email
#      are set (we use the email as the key's UID).
#   2. Detect existing signing-capable keys for that email. If one is
#      already there, skip generation and reuse it.
#   3. Otherwise, generate an Ed25519 primary + Cv25519 encryption subkey
#      via `gpg --quick-generate-key`, with the user's git email as the
#      UID and a 2-year expiry.
#   4. Extract the long key-ID of the signing subkey.
#   5. Write ~/.config/git/signing.gitconfig with [user] signingkey = …,
#      [commit] gpgsign = true, [tag] gpgsign = true. That file is
#      `include`d by the HM-managed ~/.gitconfig (home/modules/git.nix),
#      so signing turns on with zero further config.
#   6. Print the public key block and a one-line `gh ssh-key add` /
#      GitHub-pubkey-upload pointer.
#
# Idempotent: re-running with a key already present just verifies the
# include file and prints the public key.
#
# Usage:
#   scripts/gpg-setup.sh                  # default: prompt for missing bits
#   scripts/gpg-setup.sh --batch          # non-interactive (no passphrase)
#   scripts/gpg-setup.sh --rotate         # force generating a new primary key
#   scripts/gpg-setup.sh --print-pubkey   # only print the existing key + exit
set -euo pipefail

BATCH=0
ROTATE=0
PRINT_ONLY=0
for arg in "$@"; do
    case "${arg}" in
        --batch)         BATCH=1 ;;
        --rotate)        ROTATE=1 ;;
        --print-pubkey)  PRINT_ONLY=1 ;;
        -h|--help)
            sed -n '2,33p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown argument: ${arg}" >&2
            exit 1
            ;;
    esac
done

log()   { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
fatal() { printf '\033[1;31mERR:\033[0m  %s\n' "$*" >&2; exit 1; }

# 1. preflight ----------------------------------------------------------------

command -v gpg >/dev/null 2>&1 || fatal "gpg not on PATH. Run home-manager switch first."
command -v git >/dev/null 2>&1 || fatal "git not on PATH."

GIT_NAME="$(git config --global user.name  || true)"
GIT_EMAIL="$(git config --global user.email || true)"
[ -n "${GIT_NAME}"  ] || fatal "git user.name is empty.  Set it before running this wizard."
[ -n "${GIT_EMAIL}" ] || fatal "git user.email is empty. Set it before running this wizard."

INCLUDE_PATH="${HOME}/.config/git/signing.gitconfig"
mkdir -p "$(dirname "${INCLUDE_PATH}")"

# 2. find existing signing-capable key for this email -------------------------

# `gpg --list-secret-keys --with-colons` emits machine-readable records.
# The capability flag includes "s" for signing-capable. We grab the long
# key-ID (16 hex chars) of the first usable match.
find_signing_key() {
    gpg --list-secret-keys --with-colons --keyid-format=long "${GIT_EMAIL}" 2>/dev/null \
        | awk -F: '
            $1 == "sec" && $12 ~ /s/ { primary = $5; }
            $1 == "ssb" && $12 ~ /s/ { print $5; exit }
            END { if (primary && !found) print primary }
        '
}

EXISTING_KEY="$(find_signing_key || true)"

# 3. generate (or skip) -------------------------------------------------------

if [ "${PRINT_ONLY}" = "1" ]; then
    [ -n "${EXISTING_KEY}" ] || fatal "--print-pubkey: no signing key found for ${GIT_EMAIL}."
    log "Public key for ${GIT_EMAIL} (key ${EXISTING_KEY}):"
    gpg --armor --export "${EXISTING_KEY}"
    exit 0
fi

if [ -n "${EXISTING_KEY}" ] && [ "${ROTATE}" != "1" ]; then
    log "Found existing signing key for ${GIT_EMAIL}: ${EXISTING_KEY}. Reusing."
    KEY_ID="${EXISTING_KEY}"
else
    if [ "${ROTATE}" = "1" ] && [ -n "${EXISTING_KEY}" ]; then
        warn "--rotate: generating a new primary; the old key (${EXISTING_KEY}) is NOT deleted."
    fi
    log "Generating Ed25519 primary + Cv25519 encryption subkey for ${GIT_NAME} <${GIT_EMAIL}>."
    if [ "${BATCH}" = "1" ]; then
        # --batch + --passphrase '' means no passphrase. Good for headless
        # CI hosts; not recommended for daily-driver laptops.
        gpg --batch --passphrase '' \
            --quick-generate-key "${GIT_NAME} <${GIT_EMAIL}>" ed25519 sign 2y
        gpg --batch --passphrase '' --pinentry-mode loopback \
            --quick-add-key "${GIT_EMAIL}" cv25519 encr 2y
    else
        gpg --quick-generate-key "${GIT_NAME} <${GIT_EMAIL}>" ed25519 sign 2y
        gpg --quick-add-key       "${GIT_EMAIL}" cv25519 encr 2y
    fi
    KEY_ID="$(find_signing_key)"
    [ -n "${KEY_ID}" ] || fatal "Generation finished but no signing key visible. Check 'gpg --list-secret-keys'."
fi

# 4. write the git include file -----------------------------------------------

# We rewrite the file in full every run so the wizard is the single source
# of truth for signing config. The HM-managed ~/.gitconfig includes this
# path, so editing it never fights home-manager.
cat > "${INCLUDE_PATH}" <<EOF
# Generated by scripts/gpg-setup.sh. Edits will be overwritten on the
# next run of the wizard. Included from ~/.gitconfig via home/modules/git.nix.
[user]
    signingkey = ${KEY_ID}
[commit]
    gpgsign = true
[tag]
    gpgsign = true
EOF

log "Wrote signing config -> ${INCLUDE_PATH}"
log "Commit and tag signing are now ON for ${GIT_EMAIL}."

# 5. print the public key + GitHub hint ---------------------------------------

echo
log "Public key (paste into https://github.com/settings/gpg/new):"
gpg --armor --export "${KEY_ID}"
echo
log "Done. Try it:   git commit --allow-empty -m 'test signing' && git log --show-signature -1"
