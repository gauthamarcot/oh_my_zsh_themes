
setopt PROMPT_SUBST
local OS_TYPE="$(uname -s)" 
local m_bright="%F{046}"  # Bright Phosphor Green
local m_dim="%F{028}"     # Dim/Dark Green
local m_alert="%F{196}"   # Operator Alert Red
local m_grey="%F{240}"    # Terminal Grey
local reset="%f"

local SSH_DIR_FILE="$HOME/.matrix_ssh_dir"
[[ -f "$SSH_DIR_FILE" ]] && source "$SSH_DIR_FILE"

function ssh() {
  local target=""
  local args=("$@")
  
  for arg in "${args[@]}"; do
    if [[ "$arg" =~ ^[a-zA-Z0-9_.-]+@[a-zA-Z0-9_.-]+$ ]] || [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      target="$arg"
      break
    fi
  done

  if [[ -n "$target" ]]; then
    if [[ ! -f "$SSH_DIR_FILE" ]] || ! grep -Fq "ssh $*" "$SSH_DIR_FILE"; then
      echo -n -e "\033[1;33m[ SYSTEM ] Unregistered target detected: $target\033[0m\n"
      echo -n -e "\033[1;37mSave this connection to the Matrix SSH Directory? [y/N]: \033[0m"
      
      local choice
      read choice
      
      if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -n -e "\033[1;32mAssign an alias (e.g., 'prod', 'db-server', 'neo'): \033[0m"
        local alias_name
        read alias_name
        
        if [[ -n "$alias_name" ]]; then
          echo "alias $alias_name=\"command ssh $*\"" >> "$SSH_DIR_FILE"
          
          alias $alias_name="command ssh $*"
          
          echo -e "\033[1;32m[ OK ] Node saved. In the future, simply type: $alias_name\033[0m"
          sleep 1.5
        fi
      fi
    fi
  fi

  command ssh "$@"
}

function ssh_indicator() {
  if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]; then
    echo "${m_alert}󰒋 SSH ${m_dim}:: ${reset}"
  fi
}

function render_buddy() {
  local exit_code=$1
  local c_pet="%F{255}"   
  local c_msg="%F{046}"   
  local c_err="%F{196}"   
  local c_heart="%F{196}" 

  local tick=$(( SECONDS % 6 ))
  local eyes="(o.o)"
  local ears="(\\_/)"
  
  if [[ $tick -eq 0 ]]; then
    eyes="(-.-)"
    ears="(/_/)" 
  elif [[ $tick -eq 3 ]]; then
    eyes="(>.<)"
  fi

  if [[ "$BUDDY_MOOD" == "loved" ]]; then
    echo " ${c_heart}♥ ♥ ♥${reset}"
    echo "${c_pet} (\\_/) ${reset}"
    echo "${c_pet} (^.^) ${c_msg}<( *happy thumps* )${reset}"
    echo "${c_pet} (> <) ${reset}"
    export BUDDY_MOOD="" 
  elif [[ "$BUDDY_MOOD" == "fed" ]]; then
    echo ""
    echo "${c_pet} (\\_/) ${reset}"
    echo "${c_pet} (>.<) ${c_msg}<( *munch munch* )${reset}"
    echo "${c_pet} (>o<) ${reset}"
    export BUDDY_MOOD="" 
  elif [[ $exit_code -ne 0 ]]; then
    echo ""
    echo "${c_pet} (\\_/) ${reset}"
    echo "${c_pet} (x_x) ${c_err}<( ERR_SEQ DETECTED! )${reset}"
    echo "${c_pet} (> <) ${reset}"
  else
    local rand=$((RANDOM % 20))
    local thought=""
    [[ $rand -eq 0 ]] && thought="${m_dim}<( follow me. )${reset}"
    [[ $rand -eq 1 ]] && thought="${m_dim}<( wake up, ${(C)USER}... )${reset}"
    [[ $rand -eq 2 ]] && thought="${m_dim}<( the matrix has you. )${reset}"
    
    echo ""
    echo "${c_pet} ${ears} ${reset}"
    echo "${c_pet} ${eyes} ${thought}"
    echo "${c_pet} (> <) ${reset}"
  fi
}

function animated_rabbit_run() {
  tput civis 
  clear
  local cols=$(tput cols)
  local row=$(( $(tput lines) / 2 - 3 )) 
  
  local w="\033[38;5;15m"
  local p="\033[38;5;211m"
  local r="\033[0m"
  local c="\033[K"

  for ((i=0; i<cols-15; i+=4)); do
    tput cup $row 0
    local pad=$(printf "%${i}s" "")
    local frame=$(( (i/4) % 2 ))
    
    if [[ $frame -eq 0 ]]; then
      echo -e "${w}${pad}  ▄▄   ▄▄    ${r}${c}"
      echo -e "${w}${pad} ███  ███    ${r}${c}"
      echo -e "${w}${pad} ████████    ${r}${c}"
      echo -e "${w}${pad} ██${p}▄${w}██${p}▄${w}██    ${r}${c}"
      echo -e "${w}${pad} ▀███████▀   ${r}${c}"
    else
      echo -e "${w}${pad}   ▄▄   ▄▄   ${r}${c}"
      echo -e "${w}${pad}  ███  ███   ${r}${c}"
      echo -e "${w}${pad}  ████████   ${r}${c}"
      echo -e "${w}${pad}  ██${p}▀${w}██${p}▀${w}██   ${r}${c}"
      echo -e "${w}${pad}  ▀███████▀  ${r}${c}"
    fi
    sleep 0.12
  done
}


function buddy() {
  case "$1" in
    pet)  export BUDDY_MOOD="loved"; true ;;
    feed) export BUDDY_MOOD="fed"; true ;;
    
    nodes)
      clear
      echo -e "\033[1;32m[ MATRIX SSH DIRECTORY ]\033[0m\n"
      if [[ -s "$HOME/.matrix_ssh_dir" ]]; then
        cat "$HOME/.matrix_ssh_dir" | sed "s/alias //g" | sed 's/="command / \t -> /g' | sed 's/"//g' | awk -F'\t' '{printf "\033[1;37m%-15s\033[0m %s\n", $1, $2}'
      else
        echo -e "\033[1;31mNo nodes registered. Use 'ssh user@ip' to link a node.\033[0m"
      fi
      echo ""
      true
      ;;

    setup)
      clear
      tput cnorm
      echo -e "\033[1;32m[ SYSTEM ] Initiating System Setup & Dependency Check...\033[0m\n"
      
      if [[ "$OS_TYPE" != "Darwin" ]]; then
        echo -e "\033[1;33m[ SYSTEM ] Administrator privileges required for core dependencies.\033[0m"
        sudo -v || { echo -e "\033[1;31m[ ERR ] Sudo access denied. Aborting.\033[0m"; return 1; }
      fi
      
      if ! command -v mpv &> /dev/null || ! command -v curl &> /dev/null; then
        echo -e "\033[1;33m[ SYSTEM ] Missing core binaries. Installing now...\033[0m"
        if [[ "$OS_TYPE" == "Darwin" ]]; then
          if command -v brew &> /dev/null; then 
            brew install mpv curl
          else 
            echo -e "\033[1;31m[ ERR ] Homebrew missing. Cannot install dependencies.\033[0m"
          fi
        elif command -v apt &> /dev/null; then
          sudo apt update && sudo apt install -y mpv curl fontconfig python3-venv python3-pip
        elif command -v pacman &> /dev/null; then
          sudo pacman -S --noconfirm mpv curl fontconfig python
        elif command -v dnf &> /dev/null; then
          sudo dnf install -y mpv curl fontconfig python3
        fi
      else
        echo -e "\033[1;32m[ OK ] Core projector binaries are already installed.\033[0m"
      fi

      local font_dir=""
      if [[ "$OS_TYPE" == "Darwin" ]]; then font_dir="$HOME/Library/Fonts"; else font_dir="$HOME/.local/share/fonts"; mkdir -p "$font_dir"; fi
      local font_dest="$font_dir/MesloLGS NF Regular.ttf"

      if [[ ! -s "$font_dest" ]]; then
        echo -e "\n\033[1;33m[ SYSTEM ] Downloading Matrix Typography (Nerd Font)....\033[0m"
        curl -L --progress-bar -o "$font_dest" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
        
        if [[ -s "$font_dest" ]]; then
          if [[ "$OS_TYPE" != "Darwin" ]] && command -v fc-cache &> /dev/null; then fc-cache -f "$font_dir"; fi
          echo -e "\033[1;32m[ OK ] Font successfully installed to: $font_dest\033[0m"
        fi
      else
        echo -e "\033[1;32m[ OK ] Nerd Font is already installed.\033[0m"
      fi
      ;;

    follow)
      tput civis
      clear
      sleep 1
      
      type_text() {
        local text="$1"
        for (( i=1; i<=${#text}; i++ )); do
          echo -n -e "\033[1;32m${text[$i]}\033[0m"
          sleep 0.12
        done
        sleep 1.5
        clear
      }
      
      type_text "Wake up, ${(C)USER}..."
      type_text "The Matrix has you..."
      type_text "Follow the white rabbit."
      
      animated_rabbit_run
      
      echo -n -e "\033[1;32mKnock, knock, ${(C)USER}.\033[0m\n"
      sleep 2
      clear
      
      echo -e "\033[1;32mThis is your last chance. After this, there is no turning back.\033[0m\n"
      sleep 1.5
      echo -e "\033[1;34mYou take the blue pill - the story ends, you wake up in your bed and believe whatever you want to believe.\033[0m"
      sleep 2
      echo -e "\033[1;31mYou take the red pill - you stay in Wonderland and I show you how deep the rabbit hole goes.\033[0m\n"
      sleep 2
      
      tput cnorm 
      local choice
      echo -n -e "\033[1;37mTake the [r]ed pill or [b]lue pill? \033[0m"
      read choice
      
      if [[ "$choice" =~ ^[Rr] ]]; then
        tput civis
        clear
        
        local VENV_PATH="$HOME/.matrix_construct"

        if [[ ! -d "$VENV_PATH" ]]; then
          echo -e "\033[1;33m[ SYSTEM ] Establishing isolated Construct subsystem...\033[0m"
          python3 -m venv "$VENV_PATH"
          echo -e "\033[1;33m[ SYSTEM ] Injecting mov-cli and consumet plugins...\033[0m"
          tput cnorm
          "$VENV_PATH/bin/pip" install --upgrade pip certifi
          "$VENV_PATH/bin/pip" install mov-cli consumet-mc
          tput civis
        fi

        echo -e "\033[1;32m[ SYSTEM ] Hardwiring Matrix config to bypass blocked plugins...\033[0m"
        
        "$VENV_PATH/bin/python" -m mov_cli --version > /dev/null 2>&1
        
        local CONFIG_DIR=""
        if [[ "$OS_TYPE" == "Darwin" ]]; then CONFIG_DIR="$HOME/Library/Application Support/mov-cli"; else CONFIG_DIR="$HOME/.config/mov-cli"; fi
        
        mkdir -p "$CONFIG_DIR"
        rm -f "$CONFIG_DIR/config.toml"
        cat <<EOF > "$CONFIG_DIR/config.toml"
[mov-cli.plugins]
consumet = "consumet-mc"
EOF
        
        echo -e "\033[1;32m[ OK ] Loading Construct...\033[0m"
        sleep 1
        tput cnorm
        clear
        
        if [[ -f "$VENV_PATH/bin/activate" ]]; then
          source "$VENV_PATH/bin/activate"
          
          # FORCE the script to use the venv's certifi path, covering all HTTP libraries
          local CERT_PATH=$("$VENV_PATH/bin/python" -m certifi)
          export SSL_CERT_FILE="$CERT_PATH"
          export REQUESTS_CA_BUNDLE="$CERT_PATH"
          export CURL_CA_BUNDLE="$CERT_PATH"
          
          mov-cli -s consumet.flixhq "The Matrix (1999)"
          deactivate
        else
          echo -e "\033[1;31m[ ERR ] Python failed to build the Construct.\033[0m"
          sleep 3
          export SHLVL=1 
          export TMUX=""
          matrix_boot_sequence
        fi
        
      else
        clear
        echo -e "\033[1;32mYou wake up in your bed, and believe whatever you want to believe.\033[0m"
        sleep 2
        clear
        tput cnorm
      fi
      true
      ;;
    *)
      echo "Buddy Commands:"
      echo "  buddy pet    - Pet the white rabbit"
      echo "  buddy feed   - Give it a digital carrot"
      echo "  buddy nodes  - View your saved SSH directory aliases"
      echo "  buddy setup  - Visibly install fonts and video projector"
      echo "  buddy follow - See how deep the rabbit hole goes..."
      ;;
  esac
}


function git_branch() { git rev-parse --abbrev-ref HEAD 2> /dev/null }
function git_dirty() { [[ -n $(git status --porcelain 2> /dev/null) ]] && echo "${m_alert}*${reset}" }
function git_ahead_behind() {
  local ahead=$(git rev-list --count @{u}..HEAD 2> /dev/null)
  local behind=$(git rev-list --count HEAD..@{u} 2> /dev/null)
  [[ $ahead -gt 0 ]] && echo "${m_bright}+${ahead}${reset}"
  [[ $behind -gt 0 ]] && echo "${m_alert}-${behind}${reset}"
}

function build_git_prompt() {
  if git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "${m_dim}[ ${m_bright}GIT:$(git_branch)$(git_dirty)$(git_ahead_behind) ${m_dim}]${reset}"
  fi
}

function os_icon() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then echo ""
  elif [[ -f /etc/os-release ]]; then
    local distro=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
    case "$distro" in
      ubuntu) echo "" ;; arch) echo "" ;; fedora) echo "" ;; debian) echo "" ;;
      kali) echo "" ;; manjaro) echo "" ;; mint) echo "󰣭" ;; *) echo "" ;; 
    esac
  else echo ""; fi
}

function cpu_usage() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    ps -A -o %cpu | awk -v cores=$(sysctl -n hw.logicalcpu) '{s+=$1} END {printf "CPU:%.1f%%", s/cores}'
  else
    top -bn1 2>/dev/null | awk '/[Cc]pu\(s\)/ {printf "CPU:%.1f%%", $2 + $4}'
  fi
}

function ram_usage() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    vm_stat | awk '/Pages active/ {printf "MEM:%.1fG", ($3 * 4096) / 1073741824}'
  else
    free -m 2>/dev/null | awk '/Mem:/ {printf "MEM:%.1fG", $3/1024}'
  fi
}


function matrix_boot_sequence() {
  if [[ "$SHLVL" -eq 1 && -z "$TMUX" ]]; then
    tput civis 
    clear
    
    local lines=$(tput lines)
    local cols=$(tput cols)
    
    local target="[ SYSTEM ACCESS GRANTED ]"
    local t_len=${#target}
    local start_col=$(( (cols - t_len) / 2 ))
    local start_row=$(( lines / 2 ))
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*"
    
    for (( step=0; step<=t_len; step++ )); do
      tput cup $start_row $start_col
      echo -n -e "\033[1;32m${target[1,step]}\033[0m"
      
      for (( j=step; j<t_len; j++ )); do
        local rand_idx=$(( RANDOM % ${#chars} + 1 ))
        echo -n -e "\033[32m${chars[$rand_idx]}\033[0m"
      done
      sleep 0.05
    done
    sleep 0.8
    clear

    local m_chars=(
      0 1 0 1 2 3 4 5 6 7 8 9
      A B C D E F Z X C V B N M
      Á É Í Ó Ú Ñ Ç À È Ù Â Ê Î Ô Û Ä Ë Ï Ö Ü Æ Œ
      ｱ ｲ ｳ ｴ ｵ ｶ ｷ ｸ ｹ ｺ ｻ ｼ ｽ ｾ ｿ ﾀ ﾁ ﾂ ﾃ ﾄ
      Д Ж Ф Ц Ч Ш Щ Ω Σ Δ Θ
      𓀀 𓁹 𓋹 𓆣 𓅓 𓆙 𓉐 𓄿 𓅷
    )
    
    for ((i = 0; i < lines; i++)); do
      local line_str=""
      for ((j = 0; j < cols; j++)); do
        if [[ $((RANDOM % 3)) -eq 0 ]]; then
          line_str+="\033[1;37m${m_chars[$RANDOM % ${#m_chars[@]} + 1]}\033[0m"
        elif [[ $((RANDOM % 2)) -eq 0 ]]; then
          line_str+=" " 
        else
          line_str+="\033[32m${m_chars[$RANDOM % ${#m_chars[@]} + 1]}\033[0m"
        fi
      done
      echo -e -n "$line_str\n"
      sleep 0.03
    done
    
    local msg=" WELCOME, ${(U)USER} " 
    local msg_len=${#msg}
    local center_col=$(( (cols - msg_len - 2) / 2 ))
    local center_row=$(( lines / 2 ))
    
    tput cup $((center_row - 1)) $center_col
    echo -e "\033[1;32m┌$(printf '─%.0s' {1..$msg_len})┐\033[0m"
    tput cup $center_row $center_col
    echo -e "\033[1;32m│\033[1;37m$msg\033[1;32m│\033[0m"
    tput cup $((center_row + 1)) $center_col
    echo -e "\033[1;32m└$(printf '─%.0s' {1..$msg_len})┘\033[0m"
    
    sleep 1.5
    clear
    tput cnorm 
  fi
}

PROMPT='
$(render_buddy $?)
${m_dim}┌──[ $(ssh_indicator)${m_bright}$(os_icon) %~ ${m_dim}]──$(build_git_prompt)
${m_dim}└─ ${m_bright}%n@%m ${m_grey}>${reset} '

RPROMPT='${m_dim}[ ${m_bright}$(cpu_usage) ${m_dim}| ${m_bright}$(ram_usage) ${m_dim}]${reset}'


matrix_boot_sequence
