#
# complete - a package for Tcl command completion
# (c) 2018 Ashok P. Nadkarni
# See file LICENSE for licensing terms
#
# Credits: thanks to tkcon and various Wiki snippets

package require Tcl 8.6

namespace eval complete {}

proc complete::command {prefix {ip {}} {ns ::}} {
    # Finds all command names with the specified prefix
    #  prefix - a prefix to be matched with command names
    #  ip     - the interpreter whose context is to be used.
    #           Defaults to current interpreter.
    #  ns     - the namespace context for the command. Defaults to
    #           the global namespace if unspecified or the empty string.
    #
    # The command looks for all commands in the specified
    # interpreter and namespace context that begin with the specified
    # prefix.
    #
    # The return value is a pair consisting of the longest common
    # prefix of all matching commands and a sorted list of all matching
    # commands.
    # If no commands matched, the first element is the passed in prefix
    # and the second element is an empty list.

    # Escape glob special characters in the prefix
    set esc_prefix [string map {* \\* ? \\? \\ \\\\} $prefix]

    #ruff
    # If the $ns is specified as the empty string, it defaults to the
    # global namespace.
    if {$ns eq ""} {
        set ns ::
    }

    # Look for matches in the target context
    set matches [lsort [interp eval $ip \
                            [list namespace eval $ns \
                                 [list info commands ${esc_prefix}*]]]]
    return [_return_matches $prefix $matches]
}

proc complete::variable {prefix {ip {}} {ns ::}} {
    # Finds all variable names with the specified prefix
    #  prefix - a prefix to be matched with variable names
    #  ip     - the interpreter whose context is to be used.
    #           Defaults to current interpreter.
    #  ns     - the namespace context for the command. Defaults to
    #           the global namespace if unspecified or the empty string.
    #
    # The command looks for variable names in the specified
    # interpreter and namespace context that begin with the specified
    # prefix.
    #
    # The return value is a pair consisting of the longest common
    # prefix of all matching commands and a sorted list of all matching
    # names.
    # If no variable names matched, the first element is the passed in prefix
    # and the second element is an empty list.

    # Escape glob special characters in the prefix
    set esc_prefix [string map {* \\* ? \\? \\ \\\\} $prefix]

    if {$ns eq ""} {
        set ns ::
    }

    # If $prefix is a partial array variable, the matching is done
    # against the array variables
    # Thanks to tkcon for this fragment
    if {[regexp {([^\(]*)\((.*)} $prefix -> arr elem]} {
        # Escape glob special characters
        set esc_elem [string map {* \\* ? \\? \\ \\\\} $elem]
        set elems [lsort [interp eval $ip \
                            [list namespace eval $ns \
                                 [list array names $arr ${esc_elem}*]]]]
        if {[llength $elems] == 1} {
	    set var "$arr\([lindex $elems 0]\)"
            return [list $var [list $var]]
	} elseif {[llength $elems] > 1} {
            set common [tcl::prefix longest $elems $prefix]
            set vars [lmap elem $elems {
                return -level 0 "$arr\($elem\)"
            }]
            return [list "$arr\($common" $vars]
        }
        # Nothing matched
        return [list $prefix {}]
    } else {
        # Does not look like an array
        set matches [lsort [interp eval $ip \
                                [list namespace eval $ns \
                                     [list info vars ${esc_prefix}*]]]]
        return [_return_matches $prefix $matches]
    }
}

# Just a helper proc for constructing return values from match commands
proc complete::_return_matches {prefix matches} {
    if {[llength $matches] == 1} {
        # Single element list. Only one match found
        return [list [lindex $matches 0] $matches]
    } elseif {[llength $matches] > 1} {
        # Multiple matches. Return longest common prefix.
        # Note we need to use $prefix and not $esc_prefix here.
        return [list [tcl::prefix longest $matches $prefix] $matches]
    } else {
        return [list $prefix {}]
    }
}
