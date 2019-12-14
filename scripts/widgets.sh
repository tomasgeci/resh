
# shellcheck source=hooks.sh
. ~/.resh/hooks.sh

__resh_helper_arrow_pre() {
    # this is a very bad workaround
    # force bash-preexec to run repeatedly because otherwise premature run of bash-preexec overshadows the next poper run
    # I honestly think that it's impossible to make widgets work in bash without hacks like this
    # shellcheck disable=2034
    __bp_preexec_interactive_mode="on"
    # set recall strategy
    __RESH_HIST_RECALL_STRATEGY="bash_recent - history-search-{backward,forward}"
    # set prefix
    __RESH_PREFIX=${BUFFER:0:$CURSOR}
    # cursor not at the end of the line => end "NO_PREFIX_MODE"
    [ "$CURSOR" -ne "${#BUFFER}" ] && __RESH_HIST_NO_PREFIX_MODE=0
    # if user made any edits from last recall action => restart histno AND deactivate "NO_PREFIX_MODE"
    [ "$BUFFER" != "$__RESH_HIST_PREV_LINE" ] && __RESH_HISTNO=0 && __RESH_HIST_NO_PREFIX_MODE=0
    # "NO_PREFIX_MODE" => set prefix to empty string
    [ "$__RESH_HIST_NO_PREFIX_MODE" -eq 1 ] && __RESH_PREFIX=""
    # histno == 0 => save current line
    [ "$__RESH_HISTNO" -eq 0 ] && __RESH_HISTNO_ZERO_LINE=$BUFFER
}
__resh_helper_arrow_post() {
    # cursor at the beginning of the line => activate "NO_PREFIX_MODE"
    [ "$CURSOR" -eq 0 ] && __RESH_HIST_NO_PREFIX_MODE=1
    # "NO_PREFIX_MODE" => move cursor to the end of the line
    [ "$__RESH_HIST_NO_PREFIX_MODE" -eq 1 ] && CURSOR=${#BUFFER}
    # save current line so we can spot user edits next time
    __RESH_HIST_PREV_LINE=$BUFFER
}

__resh_widget_arrow_up() {
    # run helper function
    __resh_helper_arrow_pre
    # append curent recall action
    __RESH_HIST_RECALL_ACTIONS="$__RESH_HIST_RECALL_ACTIONS;arrow_up:$__RESH_PREFIX"
    # increment histno
    __RESH_HISTNO=$((__RESH_HISTNO+1))
    if [ "${#__RESH_HISTNO_MAX}" -gt 0 ] && [ "${__RESH_HISTNO}" -gt "${__RESH_HISTNO_MAX}" ]; then
        # end of the session -> don't recall, do nothing
        # fix histno
        __RESH_HISTNO=$((__RESH_HISTNO-1))
    elif [ "$__RESH_HISTNO" -eq 0 ]; then
        # back at histno == 0 => restore original line
        BUFFER=$__RESH_HISTNO_ZERO_LINE
    else
        # run recall
        local NEW_BUFFER
        NEW_BUFFER="$(__resh_collect --recall --prefix-search "$__RESH_PREFIX" 2> ~/.resh/arrow_up_last_run_out.txt)"
        # IF new buffer in non-empty THEN use the new buffer ELSE revert histno change
        # shellcheck disable=SC2015
        if [ "${#NEW_BUFFER}" -gt 0 ]; then
            BUFFER=$NEW_BUFFER
        else
            __RESH_HISTNO=$((__RESH_HISTNO-1))
            __RESH_HISTNO_MAX=$__RESH_HISTNO
        fi
    fi
    # run post helper
    __resh_helper_arrow_post
}
__resh_widget_arrow_down() {
    # run helper function
    __resh_helper_arrow_pre
    # append curent recall action
    __RESH_HIST_RECALL_ACTIONS="$__RESH_HIST_RECALL_ACTIONS;arrow_down:$__RESH_PREFIX"
    # increment histno
    __RESH_HISTNO=$((__RESH_HISTNO-1))
    # prevent HISTNO from getting negative (for now)
    [ "$__RESH_HISTNO" -lt 0 ] && __RESH_HISTNO=0
    # back at histno == 0 => restore original line
    if [ "$__RESH_HISTNO" -eq 0 ]; then
        BUFFER=$__RESH_HISTNO_ZERO_LINE
    else
        # run recall
        local NEW_BUFFER
        NEW_BUFFER="$(__resh_collect --recall --prefix-search "$__RESH_PREFIX" 2> ~/.resh/arrow_down_last_run_out.txt)"
        # IF new buffer in non-empty THEN use the new buffer ELSE revert histno change
        # shellcheck disable=SC2015
        [ "${#NEW_BUFFER}" -gt 0 ] && BUFFER=$NEW_BUFFER || (( __RESH_HISTNO++ ))
    fi
    __resh_helper_arrow_post
}
__resh_widget_control_R() {
    local __RESH_PREFIX=${BUFFER:0:CURSOR}
    __RESH_HIST_RECALL_ACTIONS="$__RESH_HIST_RECALL_ACTIONS;control_R:$__RESH_PREFIX"
    # resh-collect --hstr
    hstr
}

__resh_widget_arrow_up_compat() {
   __bindfunc_compat_wrapper __resh_widget_arrow_up
}

__resh_widget_arrow_down_compat() {
   __bindfunc_compat_wrapper __resh_widget_arrow_down
}

__resh_widget_control_R_compat() {
   __bindfunc_compat_wrapper __resh_widget_control_R
}