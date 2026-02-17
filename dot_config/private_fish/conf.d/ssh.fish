# ~/.config/fish/conf.d/ssh.fish
status --is-interactive; or exit

# If we're in an SSH session, prefer agent forwarding/passthrough.
if set -q SSH_CONNECTION; or set -q SSH_TTY
    exit
end

function __first_sock
    for s in $argv
        if test -S "$s"
            echo "$s"
            return 0
        end
    end
    return 1
end

# If SSH_AUTH_SOCK is already valid, keep it.
if set -q SSH_AUTH_SOCK; and test -S "$SSH_AUTH_SOCK"
    exit
end

# Prefer Bitwarden SSH agent if its socket exists (probe common locations).
set -l bw_sock (__first_sock \
    "$XDG_RUNTIME_DIR/bitwarden/ssh-agent.socket" \
    "$XDG_RUNTIME_DIR/Bitwarden/ssh-agent.socket" \
    "$XDG_RUNTIME_DIR/bitwarden-ssh-agent.sock" \
    "$HOME/.bitwarden-ssh-agent.sock"
)
if test -n "$bw_sock"
    set -gx SSH_AUTH_SOCK "$bw_sock"
    exit
end

# Fallback: use keychain if available; otherwise do nothing (no agent management).
# Configure your key pattern here.
set -l key (ls -t ~/.ssh/id_ed25519* 2>/dev/null | string match -rv '\.pub$' | head -n1)

if command -sq keychain
    if test -n "$key"
        keychain --quiet --eval "$key" \
        | string replace -r '^export ' 'set -gx ' \
        | string replace -r ';$' '' \
        | source
    else
        keychain --quiet --eval \
        | string replace -r '^export ' 'set -gx ' \
        | string replace -r ';$' '' \
        | source
    end
end
