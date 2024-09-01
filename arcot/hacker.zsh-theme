# Colors
local user_color="%F{green}"
local dir_color="%F{blue}"
local git_color="%F{yellow}"
local dirty_color="%F{red}"
local stash_color="%F{magenta}"
local conflict_color="%F{red}"
local reset_color="%f"
local time_color="%F{cyan}"
local cpu_color="%F{purple}"
local ram_color="%F{cyan}"
local battery_color="%F{blue}"

# Git branch
function git_branch() {
  git rev-parse --abbrev-ref HEAD 2> /dev/null
}

# Git dirty status
function git_dirty() {
  [[ -n $(git status --porcelain 2> /dev/null) ]] && echo "$dirty_color✗$reset_color"
}

# Git stash indicator
function git_stash() {
  local stash_count=$(git stash list 2> /dev/null | wc -l)
  [[ $stash_count -gt 0 ]] && echo "$stash_color⚑ $stash_count$reset_color"
}

# Git ahead/behind status
function git_ahead_behind() {
  local ahead=$(git rev-list --count @{u}..HEAD 2> /dev/null)
  local behind=$(git rev-list --count HEAD..@{u} 2> /dev/null)
  [[ $ahead -gt 0 ]] && echo "$git_color↑ $ahead$reset_color"
  [[ $behind -gt 0 ]] && echo "$git_color↓ $behind$reset_color"
}

# Git merge conflicts
function git_conflicts() {
  [[ -n $(git ls-files -u 2> /dev/null) ]] && echo "$conflict_color⚠️ (Merge Conflicts)$reset_color"
}

# Git detached HEAD
function git_detached_head() {
  [[ $(git symbolic-ref -q HEAD) ]] || echo "$git_color⚠️ (Detached HEAD)$reset_color"
}

# Display CPU usage
function cpu_usage() {
  echo "$cpu_color$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}')$reset_color"
}

# Display RAM usage
function ram_usage() {
  echo "$ram_color$(free -m | awk '/Mem:/ {print $3 "MB / " $2 "MB"}')$reset_color"
}

# Display disk usage
function disk_usage() {
  echo "$cpu_color$(df -h | grep '/$' | awk '{print $5 " used"}')$reset_color"
}

# Display battery status (for laptops)
function battery_status() {
  echo "$battery_color$(acpi -b | awk '{print $4 " " $5}' | sed 's/,//g')$reset_color"
}

# Display exit status of the last command
function last_command_status() {
  [[ $? -ne 0 ]] && echo "$dirty_color✖$reset_color"
}

# Check if in a Git repository
function in_git_repo() {
  git rev-parse --is-inside-work-tree &> /dev/null
}

# Startup Animation
function startup_animation() {
  local user_ascii=$(echo "$USER" | figlet -f standard) # Generate ASCII art for the username
  
  echo -e "\033[1;33mStarting up...\033[0m"
  sleep 0.2
  
  # Display the username in ASCII art
  echo "$user_ascii"
  
  # ASCII Cube frames
  frames=(
    "     +---+
    /   /|
   +---+ |
   |   | +
   |   |/
   +---+"

    "   +---+
  /|   /|
 +---+  |
 |   |  +
 |   | / 
 +---+"
  
    "   +---+
  /|  /|
 +---+ |
 |   | +
 |   |/
 +---+"
  
    "    +---+
   /   /|
  +---+ |
  |   | +
  |   |/
  +---+"
  )
  
  # Animate the cube
  for i in {1..8}; do
    echo "starting up terminal"
    echo -e "\033[1;32m${frames[$((i % 4))]}"
    sleep 0.2
    clear
    
    echo "$user_ascii"
  done
  
  sleep 0.1
  
}

# Matrix-style startup animation
function matrix_animation() {
  local i j lines cols chars
  lines=$(tput lines)
  cols=$(tput cols)
  chars=(0 1 2 3 4 5 6 7 8 9)
  
  # Set text color to green
  echo -e "\033[32m"
  
  for ((i = 0; i < $lines; i++)); do
    for ((j = 0; j < $cols; j++)); do
      echo -n "${chars[$RANDOM % ${#chars[@]}]} "
    done
    sleep 0.05
    echo ""
  done
  
  # Reset text color
  echo -e "\033[0m"
  
  sleep 0.5
  clear
}


function os_symbol() {
  local distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
  
  case "$distro" in
    Arch*|arch*)
      echo "🏴‍☠️ Arch"
      ;;
    Kali*|kali*)
      echo "🐉 Kali"
      ;;
    Ubuntu*|ubuntu*)
      echo "🟠 Ubuntu"
      ;;
    Fedora*|fedora*)
      echo "🎩 Fedora"
      ;;
    Debian*|debian*)
      echo "🔴 Debian"
      ;;
    Manjaro*|manjaro*)
      echo "🌲 Manjaro"
      ;;
    *)
      echo "💻 $distro"
      ;;
  esac
}

# Build the prompt with a line separator
PROMPT='
$(os_symbol) | ${user_color}%n@%m${reset_color} ${dir_color}%~${reset_color} $(in_git_repo && echo "${git_color}$(git_branch)$(git_detached_head)$(git_ahead_behind)$(git_dirty)$(git_stash)$(git_conflicts)${reset_color}")
${cpu_color}CPU: $(cpu_usage)${reset_color} ${ram_color}RAM: $(ram_usage)${reset_color} ${cpu_color}Disk: $(disk_usage)${reset_color}
${time_color}%*${reset_color} ${battery_color}Battery: $(battery_status)${reset_color}
────────────────────────────────────────────────────────────────────────────────────────
$ '

# Right prompt (for additional info like battery)
RPROMPT=''

# Call the startup animation
matrix_animation
startup_animation

