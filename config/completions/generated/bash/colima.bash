# bash completion for colima                               -*- shell-script -*-

__colima_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE:-} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__colima_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__colima_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__colima_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__colima_handle_go_custom_completion()
{
    __colima_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"

    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16

    local out requestComp lastParam lastChar comp directive args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly colima allows handling aliases
    args=("${words[@]:1}")
    # Disable ActiveHelp which is not supported for bash completion v1
    requestComp="COLIMA_ACTIVE_HELP=0 ${words[0]} __completeNoDesc ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __colima_debug "${FUNCNAME[0]}: lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __colima_debug "${FUNCNAME[0]}: Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __colima_debug "${FUNCNAME[0]}: calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __colima_debug "${FUNCNAME[0]}: the completion directive is: ${directive}"
    __colima_debug "${FUNCNAME[0]}: the completions are: ${out}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        # Error code.  No completion.
        __colima_debug "${FUNCNAME[0]}: received error from custom completion go code"
        return
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __colima_debug "${FUNCNAME[0]}: activating no space"
                compopt -o nospace
            fi
        fi
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __colima_debug "${FUNCNAME[0]}: activating no file completion"
                compopt +o default
            fi
        fi
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local fullFilter filter filteringCmd
        # Do not use quotes around the $out variable or else newline
        # characters will be kept.
        for filter in ${out}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __colima_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subdir
        # Use printf to strip any trailing newline
        subdir=$(printf "%s" "${out}")
        if [ -n "$subdir" ]; then
            __colima_debug "Listing directories in $subdir"
            __colima_handle_subdirs_in_dir_flag "$subdir"
        else
            __colima_debug "Listing directories in ."
            _filedir -d
        fi
    else
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${out}" -- "$cur")
    fi
}

__colima_handle_reply()
{
    __colima_debug "${FUNCNAME[0]}"
    local comp
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __colima_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION:-}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi

            if [[ -z "${flag_parsing_disabled}" ]]; then
                # If flag parsing is enabled, we have completed the flags and can return.
                # If flag parsing is disabled, we may not know all (or any) of the flags, so we fallthrough
                # to possibly call handle_go_custom_completion.
                return 0;
            fi
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __colima_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions+=("${must_have_one_noun[@]}")
    elif [[ -n "${has_completion_function}" ]]; then
        # if a go completion function is provided, defer to that function
        __colima_handle_go_custom_completion
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        if declare -F __colima_custom_func >/dev/null; then
            # try command name qualified custom func
            __colima_custom_func
        else
            # otherwise fall back to unqualified for compatibility
            declare -F __custom_func >/dev/null && __custom_func
        fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__colima_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__colima_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__colima_handle_flag()
{
    __colima_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue=""
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __colima_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __colima_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __colima_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __colima_contains_word "${words[c]}" "${two_word_flags[@]}"; then
        __colima_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__colima_handle_noun()
{
    __colima_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __colima_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __colima_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__colima_handle_command()
{
    __colima_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_colima_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __colima_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__colima_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __colima_handle_reply
        return
    fi
    __colima_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __colima_handle_flag
    elif __colima_contains_word "${words[c]}" "${commands[@]}"; then
        __colima_handle_command
    elif [[ $c -eq 0 ]]; then
        __colima_handle_command
    elif __colima_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __colima_handle_command
        else
            __colima_handle_noun
        fi
    else
        __colima_handle_noun
    fi
    __colima_handle_word
}

_colima_completion()
{
    last_command="colima_completion"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    local_nonpersistent_flags+=("-h")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    must_have_one_noun+=("bash")
    must_have_one_noun+=("fish")
    must_have_one_noun+=("powershell")
    must_have_one_noun+=("zsh")
    noun_aliases=()
}

_colima_delete()
{
    last_command="colima_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--data")
    flags+=("-d")
    local_nonpersistent_flags+=("--data")
    local_nonpersistent_flags+=("-d")
    flags+=("--force")
    flags+=("-f")
    local_nonpersistent_flags+=("--force")
    local_nonpersistent_flags+=("-f")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_help()
{
    last_command="colima_help"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_colima_kubernetes_delete()
{
    last_command="colima_kubernetes_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_kubernetes_reset()
{
    last_command="colima_kubernetes_reset"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_kubernetes_start()
{
    last_command="colima_kubernetes_start"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_kubernetes_stop()
{
    last_command="colima_kubernetes_stop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_kubernetes()
{
    last_command="colima_kubernetes"

    command_aliases=()

    commands=()
    commands+=("delete")
    commands+=("reset")
    commands+=("start")
    commands+=("stop")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_list()
{
    last_command="colima_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--json")
    flags+=("-j")
    local_nonpersistent_flags+=("--json")
    local_nonpersistent_flags+=("-j")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_nerdctl_install()
{
    last_command="colima_nerdctl_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    local_nonpersistent_flags+=("--force")
    local_nonpersistent_flags+=("-f")
    flags+=("--path=")
    two_word_flags+=("--path")
    local_nonpersistent_flags+=("--path")
    local_nonpersistent_flags+=("--path=")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_nerdctl()
{
    last_command="colima_nerdctl"

    command_aliases=()

    commands=()
    commands+=("install")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_prune()
{
    last_command="colima_prune"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    local_nonpersistent_flags+=("-a")
    flags+=("--force")
    flags+=("-f")
    local_nonpersistent_flags+=("--force")
    local_nonpersistent_flags+=("-f")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_restart()
{
    last_command="colima_restart"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    local_nonpersistent_flags+=("--force")
    local_nonpersistent_flags+=("-f")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_ssh()
{
    last_command="colima_ssh"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_ssh-config()
{
    last_command="colima_ssh-config"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_start()
{
    last_command="colima_start"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--activate")
    local_nonpersistent_flags+=("--activate")
    flags+=("--arch=")
    two_word_flags+=("--arch")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--arch")
    local_nonpersistent_flags+=("--arch=")
    local_nonpersistent_flags+=("-a")
    flags+=("--binfmt")
    local_nonpersistent_flags+=("--binfmt")
    flags+=("--cpu-type=")
    two_word_flags+=("--cpu-type")
    local_nonpersistent_flags+=("--cpu-type")
    local_nonpersistent_flags+=("--cpu-type=")
    flags+=("--cpus=")
    two_word_flags+=("--cpus")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cpus")
    local_nonpersistent_flags+=("--cpus=")
    local_nonpersistent_flags+=("-c")
    flags+=("--disk=")
    two_word_flags+=("--disk")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--disk")
    local_nonpersistent_flags+=("--disk=")
    local_nonpersistent_flags+=("-d")
    flags+=("--disk-image=")
    two_word_flags+=("--disk-image")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--disk-image")
    local_nonpersistent_flags+=("--disk-image=")
    local_nonpersistent_flags+=("-i")
    flags+=("--dns=")
    two_word_flags+=("--dns")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--dns")
    local_nonpersistent_flags+=("--dns=")
    local_nonpersistent_flags+=("-n")
    flags+=("--dns-host=")
    two_word_flags+=("--dns-host")
    local_nonpersistent_flags+=("--dns-host")
    local_nonpersistent_flags+=("--dns-host=")
    flags+=("--edit")
    flags+=("-e")
    local_nonpersistent_flags+=("--edit")
    local_nonpersistent_flags+=("-e")
    flags+=("--editor=")
    two_word_flags+=("--editor")
    local_nonpersistent_flags+=("--editor")
    local_nonpersistent_flags+=("--editor=")
    flags+=("--env=")
    two_word_flags+=("--env")
    local_nonpersistent_flags+=("--env")
    local_nonpersistent_flags+=("--env=")
    flags+=("--foreground")
    flags+=("-f")
    local_nonpersistent_flags+=("--foreground")
    local_nonpersistent_flags+=("-f")
    flags+=("--hostname=")
    two_word_flags+=("--hostname")
    local_nonpersistent_flags+=("--hostname")
    local_nonpersistent_flags+=("--hostname=")
    flags+=("--k3s-arg=")
    two_word_flags+=("--k3s-arg")
    local_nonpersistent_flags+=("--k3s-arg")
    local_nonpersistent_flags+=("--k3s-arg=")
    flags+=("--k3s-listen-port=")
    two_word_flags+=("--k3s-listen-port")
    local_nonpersistent_flags+=("--k3s-listen-port")
    local_nonpersistent_flags+=("--k3s-listen-port=")
    flags+=("--kubernetes")
    flags+=("-k")
    local_nonpersistent_flags+=("--kubernetes")
    local_nonpersistent_flags+=("-k")
    flags+=("--kubernetes-version=")
    two_word_flags+=("--kubernetes-version")
    local_nonpersistent_flags+=("--kubernetes-version")
    local_nonpersistent_flags+=("--kubernetes-version=")
    flags+=("--memory=")
    two_word_flags+=("--memory")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--memory")
    local_nonpersistent_flags+=("--memory=")
    local_nonpersistent_flags+=("-m")
    flags+=("--mount=")
    two_word_flags+=("--mount")
    two_word_flags+=("-V")
    local_nonpersistent_flags+=("--mount")
    local_nonpersistent_flags+=("--mount=")
    local_nonpersistent_flags+=("-V")
    flags+=("--mount-inotify")
    local_nonpersistent_flags+=("--mount-inotify")
    flags+=("--mount-type=")
    two_word_flags+=("--mount-type")
    local_nonpersistent_flags+=("--mount-type")
    local_nonpersistent_flags+=("--mount-type=")
    flags+=("--nested-virtualization")
    flags+=("-z")
    local_nonpersistent_flags+=("--nested-virtualization")
    local_nonpersistent_flags+=("-z")
    flags+=("--network-address")
    local_nonpersistent_flags+=("--network-address")
    flags+=("--network-host-addresses")
    local_nonpersistent_flags+=("--network-host-addresses")
    flags+=("--network-interface=")
    two_word_flags+=("--network-interface")
    local_nonpersistent_flags+=("--network-interface")
    local_nonpersistent_flags+=("--network-interface=")
    flags+=("--network-mode=")
    two_word_flags+=("--network-mode")
    local_nonpersistent_flags+=("--network-mode")
    local_nonpersistent_flags+=("--network-mode=")
    flags+=("--network-preferred-route")
    local_nonpersistent_flags+=("--network-preferred-route")
    flags+=("--port-forwarder=")
    two_word_flags+=("--port-forwarder")
    local_nonpersistent_flags+=("--port-forwarder")
    local_nonpersistent_flags+=("--port-forwarder=")
    flags+=("--root-disk=")
    two_word_flags+=("--root-disk")
    local_nonpersistent_flags+=("--root-disk")
    local_nonpersistent_flags+=("--root-disk=")
    flags+=("--runtime=")
    two_word_flags+=("--runtime")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--runtime")
    local_nonpersistent_flags+=("--runtime=")
    local_nonpersistent_flags+=("-r")
    flags+=("--save-config")
    local_nonpersistent_flags+=("--save-config")
    flags+=("--ssh-agent")
    flags+=("-s")
    local_nonpersistent_flags+=("--ssh-agent")
    local_nonpersistent_flags+=("-s")
    flags+=("--ssh-config")
    local_nonpersistent_flags+=("--ssh-config")
    flags+=("--ssh-port=")
    two_word_flags+=("--ssh-port")
    local_nonpersistent_flags+=("--ssh-port")
    local_nonpersistent_flags+=("--ssh-port=")
    flags+=("--template")
    local_nonpersistent_flags+=("--template")
    flags+=("--vm-type=")
    two_word_flags+=("--vm-type")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--vm-type")
    local_nonpersistent_flags+=("--vm-type=")
    local_nonpersistent_flags+=("-t")
    flags+=("--vz-rosetta")
    local_nonpersistent_flags+=("--vz-rosetta")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_status()
{
    last_command="colima_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--extended")
    flags+=("-e")
    local_nonpersistent_flags+=("--extended")
    local_nonpersistent_flags+=("-e")
    flags+=("--json")
    flags+=("-j")
    local_nonpersistent_flags+=("--json")
    local_nonpersistent_flags+=("-j")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_stop()
{
    last_command="colima_stop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--force")
    flags+=("-f")
    local_nonpersistent_flags+=("--force")
    local_nonpersistent_flags+=("-f")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_template()
{
    last_command="colima_template"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--editor=")
    two_word_flags+=("--editor")
    local_nonpersistent_flags+=("--editor")
    local_nonpersistent_flags+=("--editor=")
    flags+=("--print")
    local_nonpersistent_flags+=("--print")
    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_update()
{
    last_command="colima_update"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_version()
{
    last_command="colima_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_colima_root_command()
{
    last_command="colima"

    command_aliases=()

    commands=()
    commands+=("completion")
    commands+=("delete")
    commands+=("help")
    commands+=("kubernetes")
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        command_aliases+=("k")
        aliashash["k"]="kubernetes"
        command_aliases+=("k3s")
        aliashash["k3s"]="kubernetes"
        command_aliases+=("k8s")
        aliashash["k8s"]="kubernetes"
        command_aliases+=("kube")
        aliashash["kube"]="kubernetes"
    fi
    commands+=("list")
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        command_aliases+=("ls")
        aliashash["ls"]="list"
    fi
    commands+=("nerdctl")
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        command_aliases+=("n")
        aliashash["n"]="nerdctl"
        command_aliases+=("nerd")
        aliashash["nerd"]="nerdctl"
    fi
    commands+=("prune")
    commands+=("restart")
    commands+=("ssh")
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        command_aliases+=("exec")
        aliashash["exec"]="ssh"
        command_aliases+=("x")
        aliashash["x"]="ssh"
    fi
    commands+=("ssh-config")
    commands+=("start")
    commands+=("status")
    commands+=("stop")
    commands+=("template")
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        command_aliases+=("t")
        aliashash["t"]="template"
        command_aliases+=("tmpl")
        aliashash["tmpl"]="template"
        command_aliases+=("tpl")
        aliashash["tpl"]="template"
    fi
    commands+=("update")
    if [[ -z "${BASH_VERSION:-}" || "${BASH_VERSINFO[0]:-}" -gt 3 ]]; then
        command_aliases+=("u")
        aliashash["u"]="update"
        command_aliases+=("up")
        aliashash["up"]="update"
    fi
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--profile=")
    two_word_flags+=("--profile")
    two_word_flags+=("-p")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--very-verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_colima()
{
    local cur prev words cword split
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __colima_init_completion -n "=" || return
    fi

    local c=0
    local flag_parsing_disabled=
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("colima")
    local command_aliases=()
    local must_have_one_flag=()
    local must_have_one_noun=()
    local has_completion_function=""
    local last_command=""
    local nouns=()
    local noun_aliases=()

    __colima_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_colima colima
else
    complete -o default -o nospace -F __start_colima colima
fi

# ex: ts=4 sw=4 et filetype=sh
