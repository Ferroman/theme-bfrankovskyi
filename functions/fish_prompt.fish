# Define functions to be used in fish prompt

# Function to get the name of the current git branch
# Returns empty string if not in a git repository
function __git_branch_name
  echo (command git branch --show-current 2> /dev/null)
end

# Function to check if there are uncommitted changes in the current git repository
# Returns empty string if there are no changes
function __is_git_dirty
  echo (command git status -s --ignore-submodules=dirty 2> /dev/null)
end

# Function to check if the specified git branch has a remote tracking branch
# Returns the name of the remote tracking branch if it exists, or an empty string if it does not
function __git_has_remote -a branch_name
  echo (command git branch -r 2> /dev/null | grep "$branch_name")
end

# Function to get the number of commits ahead of the remote tracking branch
# of the current git branch
# Returns 0 if there are no commits ahead
function __git_ahead_commits_count 
  set -l branch_name (__git_branch_name)
  echo (command git rev-list origin/$branch_name..HEAD --count 2> /dev/null)
end

# Function to get the number of commits behind of the remote tracking branch
# of the current git branch
# Returns 0 if there are no commits behind
function __git_behind_commits_count 
  set -l branch_name (__git_branch_name)
  echo (command git rev-list HEAD..origin/$branch_name --count 2> /dev/null)
end

# Function to print current time with the specified color
function _print_time -a color -a color_normal
  set -l current (date '+%H:%M')
  echo $color'['$current']'$color_normal
end

# Function to print current time with the specified color
function _print_cwd -a color -a color_normal
  echo $color(basename (prompt_pwd))$color_normal
end

# Function to print the failed status (if there was a failure)
# in the prompt, with the specified color and normal color
# If the status is 0, returns an empty string
function _print_failed_status -a current_status -a color -a normal
  if [ $current_status != 0 ]
    echo "$color($current_status)$normal "
  else
    echo ""
  end
end

# Function to print the user prompt (with the arrow)
# with the specified color and normal color
# If the current user is root, displays the arrow with a different color
function _print_user -a color -a normal
  if [ 'root' = (whoami) ]
    echo "$color#$normal  "
  else
    echo ''
  end
end

# Function to print the git branch name in the prompt,
# with the specified main color, color for unpushed branch, and normal color
# Also checks if the current git branch has a remote tracking branch,
# and if not, adds an arrow symbol to indicate that it is not pushed to a remote
function _print_branch_name -a git_branch_name -a main_color -a color_unpushed -a color_normal 
  set -l has_remote (__git_has_remote $git_branch_name)
  
  set -l git_branch $main_color$git_branch_name$color_normal
  if [ ! $has_remote ]
    set git_branch "$color_unpushed↑$git_branch$color_normal"
  end

  echo $git_branch
end

# Function to print the git branch name in the prompt,
# with the specified main color, color for unpushed branch, and normal color
# Also checks if the current git branch has a remote tracking branch,
# and if not, adds an arrow symbol to indicate that it is not pushed to a remote
function _print_branch_name -a git_branch_name -a main_color -a color_unpushed -a color_normal 
  set -l has_remote (__git_has_remote $git_branch_name)
  
  set -l git_branch $main_color$git_branch_name$color_normal
  if [ ! $has_remote ]
    set git_branch "$color_unpushed↑$git_branch$color_normal"
  end

  echo $git_branch
end

# Function to print the git information in the prompt
# with the specified colors for the git branch, normal text,
# brackets, unpushed commits, and dirty repository status
# If not in a git repository, returns an empty string
function _print_git_status -a main_color -a color_normal -a color_bracket -a color_unpushed -a color_dirty -a color_unpulled
  set -l git_branch_name (__git_branch_name)

  if [ $git_branch_name ]
    set -l git_pending_commits_count (__git_ahead_commits_count)
    set -l git_fetch_commits_count (__git_behind_commits_count)

    set -l git_branch (_print_branch_name $git_branch_name $main_color $color_unpushed $color_normal)

    set -l git_status "$color_bracket($git_branch$color_bracket)$color_normal"

    if [ $git_pending_commits_count != 0 ]
      set git_status "$git_status $color_unpushed↑$git_pending_commits_count$color_normal"
    end

    if [ $git_fetch_commits_count != 0 ]
      set git_status "$git_status $color_unpulled↓$git_fetch_commits_count$color_normal"
    end

    if [ (__is_git_dirty) ]
      set -l dirty "$color_dirty ✗$color_normal"
      set git_status "$git_status$dirty"
    end

    echo $git_status
  end

  echo ""
end 

function _print_kubeconfig -a main_color -a color_normal -a color_bracket
  if type -q kubeprompt
    set -l current_kubeconfig (command kubeprompt -f "{{if .Enabled}}[{{ slice .Ctx 12 35 | Yellow }}{{ slice .Ctx 43 | Yellow | Bold }}]{{end}}")
    set -l kubeconfig "$current_kubeconfig"
    
    echo $kubeconfig
  end
end

# Function to fast retrieve current language set by asdf
# https://github.com/asdf-vm/asdf/issues/290#issuecomment-958929157
function _asdf_current -a lang
    set current (pwd)
    set versions
    set root (dirname $HOME)
    set asdf (asdf --version 2> /dev/null)

    env_lang_version=ASDF_(string upper $lang)_VERSION set env_version $$env_lang_version

    # if no asdf do nothing
    if test -z "$asdf"
      return
    end

    if test -n "$env_version"
        echo $env_version
        return 0
    end

    while test "$current" != "$root"
        if test -e $current/.tool-versions
            set -a versions (string split "\n" < $current/.tool-versions)
        end
        set current (string join "/" (string split "/" $current)[..-2])
    end

    for ver in $versions
        if string match --quiet "$lang *" $ver
            echo (string split -f2 " " "$ver")
            return 0
        end
    end
end

# Split command line to two lines if prompt is bigger than half
# of the screen. It also adds indication line connecting two
# prompt lines to indicate movement
function _print_spit_too_long -a prompt -a arrow
  
  if [ (string length --visible $prompt) -gt (math -s0 $COLUMNS / 2) ]
    echo $prompt\\n'└'$arrow''
  else
    echo $prompt$arrow''
  end
end

# print asdf version of the given tool
function _print_asdf -a tool -a short -a main_color -a color_normal -a color_bracket
  set -l current_tool (_asdf_current $tool)
  if test -n "$current_tool"
    echo "[$main_color$short$color_normal:$current_tool]"
  end
end

# print all versions set by asdf
# curretly supports Python and JS
function _print_asdf_line -a main_color -a color_normal -a color_bracket
  set -l asdf_python (_print_asdf 'python' 'py' $main_color $color_normal $color_bracket)
  set -l asdf_nodejs (_print_asdf 'nodejs' 'js' $main_color $color_normal $color_bracket)

  set -l line "$asdf_python$asdf_nodejs"

  if test -n "$line"
    echo "$color_bracket($color_normal$line$color_bracket)$color_normal"
  end
end

function fish_prompt
  # get latest status first thing - because functions may 
  # change it later on
  set -l current_status $status

  # Define colors to be used in fish prompt
  # Depend on global fish variables which allow to use themes
  # in the prompt
  set -l color_error (set_color -o $fish_color_error)
  set -l color_normal (set_color -o $fish_color_normal)
  set -l color_cwd (set_color -o $fish_color_cwd)
  set -l color_git_info (set_color -o $fish_color_command)
  set -l color_unpushed (set_color -o $fish_color_user)
  set -l color_unpulled (set_color -o $fish_color_error)
  set -l color_git_dirty (set_color -o $fish_color_param)
  set -l color_bracket (set_color -o $normal)
  set -l color_git_branch (set_color -o $fish_color_operator)
  set -l color_kubeconfig (set_color -o $fish_color_operator)
  set -l color_asdf (set_color -o $fish_color_operator)

  set -l failed (_print_failed_status $current_status $color_error $normal)
  set -l user (_print_user $color_error $normal)
  set -l arrow '⋊>'
  set -l time (_print_time $color_normal $color_normal)

  set -l cwd # $color_cwd(basename (prompt_pwd))$color_normal
  set -l git_status (_print_git_status $color_git_branch $color_normal $color_bracket $color_unpushed $color_git_dirty $color_unpulled)
  set -l kubeconfig (_print_kubeconfig $color_kubeconfig $color_normal $color_bracket)

  set -l command_line "$user$time $cwd$kubeconfig$git_status$failed$color_normal"
  set -l asdf_line (_print_asdf_line $color_asdf $color_normal $color_bracket)
  set -l split (_print_spit_too_long $command_line $arrow)
  echo -s $asdf_line $color_cwd(pwd) ' ↓'$color_normal
  echo -s -e $split
end
