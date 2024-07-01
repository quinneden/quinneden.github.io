#!/usr/bin/env bash

init() {
    # Vars
    CURRENT_USERNAME='quinn'
    HOST='main'

    # Colors
    NORMAL=$(tput sgr0)
    WHITE=$(tput setaf 7)
    BLACK=$(tput setaf 0)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BRIGHT=$(tput bold)
    UNDERLINE=$(tput smul)
}

confirm() {
    echo -en "[${GREEN}y${NORMAL}/${RED}n${NORMAL}]: "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 0
    fi
}

# print_header() {
#     echo -E "$CYAN
#       _____              _   ____  _                      _        
#      |  ___| __ ___  ___| |_|  _ \| |__   ___   ___ _ __ (_)_  __  
#      | |_ | '__/ _ \/ __| __| |_) | '_ \ / _ \ / _ \ '_ \| \ \/ /  
#      |  _|| | | (_) \__ \ |_|  __/| | | | (_) |  __/ | | | |>  <   
#      |_|  |_|  \___/|___/\__|_|   |_| |_|\___/ \___|_| |_|_/_/\_\  
#      _   _ _       ___        ___           _        _ _           
#     | \ | (_)_  __/ _ \ ___  |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
#     |  \| | \ \/ / | | / __|  | || '_ \/ __| __/ _' | | |/ _ \ '__|
#     | |\  | |>  <| |_| \__ \  | || | | \__ \ || (_| | | |  __/ |   
#     |_| \_|_/_/\_\\___/|___/ |___|_| |_|___/\__\__,_|_|_|\___|_| 

#       ! To make sure everything runs correctly DO NOT run as root ! $GREEN
#                         -> '"./install.sh"' $NORMAL

#     "
# }
print_header() {
    echo -E $CYAN'''
 __   __   __   __  __   ______   ______                                       
/\ "-.\ \ /\ \ /\_\_\_\ /\  __ \ /\  ___\                                      
\ \ \-.  \\ \ \\/_/\_\/_\ \ \/\ \\ \___  \                                     
 \ \_\\"\_\\ \_\ /\_\/\_\\ \_____\\/\_____\                                    
  \/_/ \/_/ \/_/ \/_/\/_/ \/_____/ \/_____/                                    
 __   __   __   ______   ______  ______   __       __       ______   ______    
/\ \ /\ "-.\ \ /\  ___\ /\__  _\/\  __ \ /\ \     /\ \     /\  ___\ /\  == \   
\ \ \\ \ \-.  \\ \___  \\/_/\ \/\ \  __ \\ \ \____\ \ \____\ \  __\ \ \  __<   
 \ \_\\ \_\\"\_\\/\_____\  \ \_\ \ \_\ \_\\ \_____\\ \_____\\ \_____\\ \_\ \_\ 
  \/_/ \/_/ \/_/ \/_____/   \/_/  \/_/\/_/ \/_____/ \/_____/ \/_____/ \/_/ /_/ 
                                                                               
'''
}

get_username() {
    echo -en "Enter your$GREEN username$NORMAL : $YELLOW"
    read username
    echo -en "$NORMAL"
    echo -en "Use$YELLOW "$username"$NORMAL as ${GREEN}username${NORMAL} ? "
    confirm
}

set_username() {
    sed -i -e "s/${CURRENT_USERNAME}/${username}/g" ./flake.nix
    sed -i -e "s/${CURRENT_USERNAME}/${username}/g" ./modules/home/audacious/config
}

# get_host() {
#     echo -en "Choose a ${GREEN}host${NORMAL}, either [${YELLOW}D${NORMAL}]esktop or [${YELLOW}L${NORMAL}]aptop: "
#     read -n 1 -r
#     echo

#     if [[ $REPLY =~ ^[Dd]$ ]]; then
#         HOST='main'
#     elif [[ $REPLY =~ ^[Ll]$ ]]; then
#         HOST='laptop'
#     else
#         echo "Invalid choice. Please select either 'D' for desktop or 'L' for laptop."
#         exit 1
#     fi
    
#     echo -en "$NORMAL"
#     echo -en "Use the$YELLOW "$HOST"$NORMAL ${GREEN}host${NORMAL} ? "
#     confirm
# }

install() {
    echo -e "\n${RED}START INSTALL PHASE${NORMAL}\n"
    sleep 0.2

    if [[ ! -d $HOME/Documents && ! -d $HOME/Music && ! -d $HOME/Pictures/wallpapers ]]; then
        # Create basic directories
        echo -e "Creating folders:"
        echo -e "    - ${MAGENTA}~/Music${NORMAL}"
        echo -e "    - ${MAGENTA}~/Documents${NORMAL}"
        echo -e "    - ${MAGENTA}~/Pictures/wallpapers/others${NORMAL}"
        mkdir -p ~/Music
        mkdir -p ~/Documents
        mkdir -p ~/Pictures/wallpapers/others
        sleep 0.2
        # Copy the wallpapers
        echo -e "Copying all ${MAGENTA}wallpapers${NORMAL}"
        cp -r wallpapers/wallpaper.png ~/Pictures/wallpapers
        cp -r wallpapers/otherWallpaper/catppuccin/* ~/Pictures/wallpapers/others/
        cp -r wallpapers/otherWallpaper/nixos/* ~/Pictures/wallpapers/others/
        cp -r wallpapers/otherWallpaper/others/* ~/Pictures/wallpapers/others/
        sleep 0.2
    fi

    # Get the hardware configuration
    # echo -e "Copying ${MAGENTA}/etc/nixos/hardware-configuration.nix${NORMAL} to ${MAGENTA}./hosts/${HOST}/${NORMAL}\n"
    # cp /etc/nixos/hardware-configuration.nix hosts/${HOST}/hardware-configuration.nix
    # sleep 0.2

    # Fill in partition UUID's in hardware.nix
    if [[ -f /etc/nixos/hardware-configuration.nix ]]; then
        ROOT_UUID=$(cat /etc/nixos/hardware-configuration.nix | tr -d '{};=' | grep -A1 'fileSystems."/"' | grep -o 'uuid/.*"' | sed s/'uuid\/'/''/g | tr -d '"')
        BOOT_UUID=$(cat /etc/nixos/hardware-configuration.nix | tr -d '{};=' | grep -A1 'fileSystems."/boot"' | grep -o 'uuid/.*"' | sed s/'uuid\/'/''/g | tr -d '"')
        sed -i s/'ROOT_UUID'/"$ROOT_UUID"/g modules/core/hardware.nix
        sed -i s/'BOOT_UUID'/"$BOOT_UUID"/g modules/core/hardware.nix
    else
        ROOT_UUID=$(lsblk -l -f --noheadings /dev/nvme0n1 | tr -s ' ' | grep -i "nixos" | grep -v "/boot" | cut -f 4 -d ' ')
        BOOT_UUID=$(blkid -t TYPE=vfat | grep -o 'UUID="\w\{4\}-\w\{4\}"' | sed 's/UUID=//' | tr -d '"')
        sed -i s/'ROOT_UUID'/"$ROOT_UUID"/g modules/core/hardware.nix
        sed -i s/'BOOT_UUID'/"$BOOT_UUID"/g modules/core/hardware.nix
    fi
    unset ROOT_UUID
    unset BOOT_UUID
    sleep 0.2

    # Last Confirmation
    echo -en "You are about to start the system build, continue? "
    confirm

    # Build the system (flakes + home manager)
    echo -e "\nBuilding the system...\n"
    sudo nix flake update .#${HOST}
    sudo nixos-rebuild switch --flake .#${HOST} --impure
}

main() {
    init

    print_header

    # get_username
    # set_username
    # get_host

    install
}

main && exit 0
