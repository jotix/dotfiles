#
# ~/.bashrc
#

test -s ~/.alias && . ~/.alias || true

export COLORTERM=truecolor

function _update_ps1() {
    PS1="$(powerline-go -error $? -jobs $(jobs -p | wc -l))"
}

#if [ "$TERM" != "linux" ] && [ -f "powerline-go" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
#fi

neofetch

