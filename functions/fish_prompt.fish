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

    set -l git_status "$color_bracket ($git_branch$color_bracket)$color_normal"

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

  set -l failed (_print_failed_status $current_status $color_error $normal)
  set -l arrow (_print_user $color_error $normal)
  set -l time (_print_time $color_normal $color_normal)

  set -l cwd $color_cwd(basename (prompt_pwd))$color_normal
  set -l git_status (_print_git_status $color_git_branch $color_normal $color_bracket $color_unpushed $color_git_dirty $color_unpulled)

  echo -n -s $arrow $time ' ' $cwd $git_status ' ' $failed $color_normal ''
end
