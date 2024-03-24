#!/usr/bin/env bash

# Defined user variables
workspace_by_screen=10
window_rules_file=~/.config/hypr/themes/luna/rules.conf
log_file=~/.config/hypr/scripts/hyprsome.log

# Initialize variables
needed_workspace=""
needed_screen=""
dispacher_type=""
rules=0
verbose=0

# Check if hyprctl is installed
if ! command -v hyprctl >/dev/null 2>&1; then
	echo "hyprctl could not be found. Please install it and try again."
	exit 1
fi

# Function to display help
display_help() {
	echo "Usage: $(basename "$0") [option...] {param...}"
	echo "  Dispatchers:"
	echo "   -W, --window     Move a window to an specified screen and workspace"
	echo "   -S, --silent     Move a window with a silent dispatcher to an specified screen and workspace"
	echo "   -F, --focus      Move to an specific workspace"
	echo "  Options:"
	echo "   -w, --workspace  Specify the workspace to move window \"value\" or \"+value\" or \"-value\""
	echo "   -s, --screen     Specify the screen to move window \"value\" or \"+value\" or \"-value\" or \"cur\" for current"
	echo "   -r, --rule       Move to the default rule workspace"
	echo
	echo "   -v, --verbose    Display verbose output"
	echo "   -h, --help       Display help"
	echo
	exit 1
}

window_rule() {
	# Retrieve the active class of the window
	active_class=$(hyprctl -j activewindow | jq '.class')
	active_class=$(echo "$active_class" | tr -d \")

	# Read the file and store lines containing 'workspace' in an array
	grep 'workspace' $window_rules_file | while IFS= read -r line; do
		workspace_value=$(echo "$line" | sed -n -e 's/^.*workspace \([0-9]*\)[ ,].*$/\1/p')
		class_value=$(echo "$line" | sed -n -e 's/^.*class:\s*\(.*\)$/\1/p')
		regex=$class_value

		if [ -n "$workspace_value" ] && [ -n "$class_value" ]; then
			regex_test=$(echo "$active_class" | grep -E "$regex")
			# Compare the retrieved value with the active class of the window
			if [ "$regex_test" != "" ]; then
				# The class matches the active class of the window. Workspace value to apply: $workspace_value
				# Return the workspace window value
				echo "$workspace_value"
				return
			fi
		fi
	done
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
	case "$1" in
	-w | --workspace)
		needed_workspace="$2"
		shift 2
		;;
	-s | --screen)
		needed_screen="$2"
		shift 2
		;;
	-W | --window)
		dispacher_type="movetoworkspace"
		shift
		;;
	-S | --silent)
		dispacher_type="movetoworkspacesilent"
		shift
		;;
	-F | --focus)
		dispacher_type="workspace"
		shift
		;;
	-r | --rule)
		rules=1
		shift
		;;
	-v | --verbose)
		verbose=1
		shift
		;;
	-h | --help) display_help ;;
	--)
		shift
		break
		;;
	*) display_help ;;
	esac
done

# Check if verbose mode is enabled
[ "$verbose" -eq 1 ] && echo "Verbose mode is enabled"

# Defined max screen and current workspace of the current window
mini_screen=$(hyprctl -j monitors | jq '.[] | .id' | head -n 1)
max_screen=$(hyprctl -j monitors | jq '.[] | .id' | tail -n 1)
cur_workspace=$(hyprctl -j clients | jq '.[] | select(.focusHistoryID == 0) | .workspace.id')
active_class=$(hyprctl -j activewindow | jq '.class')

# Check --rules for this activewindow
if [ "$rules" -eq 1 ]; then
	# Defined workspace by the rules
	return_workspace=$(window_rule)
	# Force to the specific workspace
	if [ "$return_workspace" != "" ]; then
		# If nothing is set at --screen
		if [ -z "$needed_screen" ]; then
			# new rule screen / rule workspace
			cur_workspace=$return_workspace
		# If "cur" or something is set at --screen
		else
			# new current screen / rule workspace
			rule_workspace=$((return_workspace % 10))
			rule_screen=$((cur_workspace / 10))
			cur_workspace=$rule_screen$rule_workspace
		fi
		[ "$verbose" -eq 1 ] && echo "rule_workspace=$cur_workspace"
	else
		[ "$verbose" -eq 1 ] && echo "no rule for this window, nothing to do"
		exit 0
	fi
fi

# Separate tens and units
number=$cur_workspace
tens=$((number / 10))
units=$((number % 10))
[ $units -eq 0 ] && units=10 && tens=$((tens - 1))

# Current workspace and screen
cur_workspace=$units
cur_screen=$tens

# New screen
# Check if empty || alpha char only
if [ -z "$needed_screen" ] || echo "$needed_screen" | grep -qE '^[[:alpha:]]*$'; then
	new_screen=$cur_screen
# Check if the parameter is a positive number with the + sign or - sign.
elif [ "${needed_screen#-}" != "$needed_screen" ] || [ "${needed_screen#+}" != "$needed_screen" ]; then
	new_screen=$((cur_screen + needed_screen))
else
	new_screen=$needed_screen
fi
# Check if in range
if [ "$new_screen" -gt "$max_screen" ]; then
	new_screen=$mini_screen
fi
if [ "$new_screen" -lt "$mini_screen" ]; then
	new_screen=$max_screen
fi

# New workspace
# Check if empty || alpha char only
if [ -z "$needed_workspace" ] || echo "$needed_workspace" | grep -qE '^[[:alpha:]]*$'; then
	new_workspace=$cur_workspace
# Check if the parameter is a positive number with the + sign or - sign.
elif [ "${needed_workspace#-}" != "$needed_workspace" ] || [ "${needed_workspace#+}" != "$needed_workspace" ]; then
	new_workspace=$(($cur_workspace + $needed_workspace))
else
	new_workspace=$needed_workspace
fi
# Check if in range
if [ "$new_workspace" -lt 1 ] || [ "$new_workspace" -gt "$workspace_by_screen" ]; then
	# bad new workspace, nothing to do
	[ "$verbose" -eq 1 ] && echo "bad new workspace, nothing to do"
	exit 0
fi

if [ "$verbose" -eq 1 ]; then
	echo "cur_screen=$cur_screen -> new_screen=$new_screen"
	echo "cur_workspace=$cur_workspace -> new_workspace=$new_workspace"
	echo
	echo "moving current window to screen:$new_screen workspace:$new_workspace dispacher_type:$dispacher_type"

	echo "hyprctl dispatch $dispacher_type $new_screen$new_workspace - window_class:$active_class" >>$log_file
fi

# Do the window move with syntax sceen:workspace like is defined in hypr workspace.conf [1..10] [11..20] [31..40]
hyprctl dispatch "$dispacher_type" "$new_screen$new_workspace" && hyprctl dispatch centerwindow 1 && hyprctl dispatch resizeactive exact 75% 75% && hyprctl dispatch centerwindow 1
