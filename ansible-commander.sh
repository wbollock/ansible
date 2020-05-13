#!/bin/bash
# Ansible Commander
# Script designed to assist the user in writing Ansible commands
# By Kyle Muller and Will Bollock

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'
BOLD="\033[1m"
YELLOW='\033[0;33m'



# CONFIG
playbookLocation=/etc/ansible/playbooks
# needed to get rid of * for playbook path in command
#playbookPath=/etc/ansible/playbooks
hostsLocation=/etc/ansible/hosts

# displays groups from $hostsLocation
# elimanates variable sets, e.g [all:vars]


groupGrabber(){
clear
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
echo -e "${RED}ANSIBLE COMMANDER: HOST GROUPS${NC}"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "Your command so far: ${YELLOW}$command${NC}"
echo ""
echo -e "The following playbooks are available in ${BLUE}$hostsLocation${NC}:"
echo ""




# Grep hosts group file, only match names inside brackets, remove brackets, delete special host groups with colons (used for Vault, etc.)
hostgroups=$(grep -oP '\[(.*?)\]' $hostsLocation | sed 's/[][]//g; /:/d')

# Select command configuration #
# Select uses PS3 variable for user prompt, line break for formatting
PS3="
Select an Ansible host group: "
# Set columns to low number, forcing each menu item on new line
COLUMNS=5

select hostgroup in $hostgroups
do
    # Leave the loop if the user says 'stop'
    if [[ "$REPLY" == stop ]]; then break; fi
    # If no valid selection was made, loop to ask again
    if [[ "$hostgroup" == "" ]]
    then
        echo ""
        echo -e "Error: '$REPLY' is not a valid host group"
        echo ""
        continue
    fi
        # If user enters correct number, create final variable for command 
    echo "" 
    selectedHostGroup="$hostgroup"
    # Menu will ask for another entry unless we leave the loop
    break
done
}



# Gives  a nice confirmation for the command
#pause(){
 # read -p "Press [Enter] key to continue..." fackEnterKey
  # not sure what fackEnterKey means
#}

# init command string
command=""

# logic break for playbook, seperates from ad-hoc
choosePlaybook(){
	echo -e "${GREEN}Ansible Playbook chosen.${NC}"
        #pause
        command="sudo ansible-playbook"
        echo -e "Your command so far: ${YELLOW}$command${NC}"
        playbookPuller
    
    sleep .5
}
 
# logic tree choice of Ad-hoc instead of playbook
chooseAdhoc(){
    command="sudo ansible"
        serverSelector 2
}

# Listing playbooks for user
playbookPuller(){
# Change working directory to playbookLocation so playbook names do not contain full path in menu
if [[ -d $1 ]]
then
# if you print a $1, it'll be a directory, so CD then
    cd $1 || exit
else
    cd $playbookLocation || exit
fi
clear
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
echo -e "${RED}ANSIBLE COMMANDER: PLAYBOOKS${NC}"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "The following playbooks are available in ${BLUE}$playbookLocation${NC}:"
echo ""

# Select command configuration #
# Select uses PS3 variable for user prompt, line break for formatting
PS3="
Please select an Ansible playbook: "
# Set columns to low number, forcing each menu item on new line
COLUMNS=5


select playbook in *
do
    while [[ -d "$playbook" ]] 
    do
        playbookPuller "$playbook"
        # while your selection is still a directory, call the function again
    done
   # Leave the loop if the user says 'stop'
    if [[ "$REPLY" == stop ]]; then break; fi

    # If no valid selection was made, loop to ask again
    if [[ "$playbook" == "" ]]
    then
        echo ""
        echo -e "${RED}Error: '$REPLY' is not a valid playbook${NC}"
        echo ""
        continue
    fi

    # If user enters correct number, concat full path and playbook name for final variable in command
    echo "" 
    #selectedPlaybook="$playbookLocation/$playbook"
    selectedPlaybook="$(pwd)/$playbook"
    echo -e "Selected playbook: $selectedPlaybook"
    # Appending playbook selection to command
        append=" $selectedPlaybook"
        command="$command$append"
        echo -e "Your command so far: ${YELLOW}$command${NC}"
        serverSelector 1

    # Menu will ask for another entry unless we leave the loop
    break
done
# Change working directory back to previous location (~ option prevents printing directory to screen)
cd ~-
}

# function needs to work for both ad-hoc and 
serverSelector(){
    echo -e "${BLUE}Please choose your server targets. Start with a host group, and limit from there.${NC}"
    echo ""
    echo "Choose your host group:"

    # Display valid groups in /etc/ansible/hosts
    groupGrabber
    #sleep .5
    
    # if it's a playbook
    if [ "$1" == 1 ]
    then
        append=" -l $selectedHostGroup"
        command="$command$append"
        echo -e "Your command so far: ${YELLOW}$command${NC}"
        serverLimiter 1
    # if it's a ad hoc
    elif [ "$1" == 2 ]
    then
    # no -l needed w/ ad hoc
        append=" $selectedHostGroup"
        command="$command$append"
        echo -e "Your command so far: ${YELLOW}$command${NC}"
        serverLimiter 2
    else
        echo "${RED}ERROR${NC}: occured in serverSelector function."
    fi
    
}

serverLimiter(){
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo -e "${RED}ANSIBLE COMMANDER: HOST LIMIT${NC}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "Your command so far: ${YELLOW}$command${NC}"
    echo ""
    echo -e "Would you like to ${BLUE}limit it to a server${NC}, or certain servers? (y/N)"
    read -r limitChoice
     case $limitChoice in
            y|Y) 
                echo ""
                echo "Enter the servers you want to limit from $cluster: (e.g server1.cci.fsu.edu,server2.cci.fsu.edu):"
                read -r serverList
                echo "Limiting to $serverList"
                append=" --limit=$serverList"
                command="$command$append"
                echo -e "Your command so far: ${YELLOW}$command${NC}"
                if [ "$1" ==  1 ]
                then
                    userSelector 1
                elif [ "$1" == 2 ]
                then
                    adhocCreator
                else
                    echo "Error occured in serverSelector function."
                fi
    
                ;;
            n|N|"") 
                if [ "$1" ==  1 ]
                then
                    userSelector 1
                elif [ "$1" == 2 ]
                then
                    adhocCreator
                else
                    echo "Error occured in serverSelector function."
                fi;;
            *) echo -e "${RED}Error...${NC}" && sleep .5
        esac
}

# let user input their command
adhocCreator(){
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo -e "${RED}ANSIBLE COMMANDER: AD HOC${NC}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "Your command so far: ${YELLOW}$command${NC}"
    echo ""
    echo "The following quick commands are available:"
    echo ""
    
    echo -e "1) Schedule reboot [${BLUE}shutdown -r +MINUTESFROMNOW${NC}]"
    echo -e "2) Cancel reboot [${BLUE}shutdown -c${NC}] "
	echo -e "3) Check free space on /boot [${BLUE}df -h | grep "/boot" | grep -v "/boot/efi"${NC}]"
	echo -e "4) Check uptime [${BLUE}uptime -p${NC}]"
    echo -e "5) Other"
    echo ""
    
    read -p "Please select an ad hoc command: " -r choice
    	case $choice in
		1) read -p "Please enter the scheduled reboot time [in minutes from now]: " -r minutes
            cmdText='shutdown -r'
            append=" -m shell -a '$cmdText +$minutes'"
            command="$command$append"
            userSelector 2
            ;;
		2) cmdText='shutdown -c'
            append=" -m shell -a '$cmdText'"
            command="$command$append"
            userSelector 2
            ;;
		3) cmdText='df -h | grep "/boot" | grep -v "/boot/efi"'
            append=" -m shell -a '$cmdText'"
            command="$command$append"
            userSelector 2
            ;;
        4) cmdText='uptime -p'
            append=" -m shell -a '$cmdText'"
            command="$command$append"
            userSelector 2
            ;;
		5)  read -p "Please enter your ad hoc command: " -r cmdText
            append=" -m shell -a '$cmdText'"
            command="$command$append"
            echo -e "Your command so far: ${YELLOW}$command${NC}"
            userSelector 2;;
        *) "${RED}"ERROR"${NC}"
	esac

}




userSelector(){
    # Is there a problem with hardcoding the users?
    # TODO: implement ansible vault
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo -e "${RED}ANSIBLE COMMANDER: USER SELECTION${NC}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "Your command so far: ${YELLOW}$command${NC}"
    echo ""
    echo "The following users are available to run your Ansible command:"
    echo ""

    echo "1) cci-service"
    echo "2) km12n"
    echo "3) adm-cci-web15c"
    echo "4) other"
    echo ""
    read -rp "Please select a user: " choice
	case $choice in
		1) userChoice="cci-service" ;;
		2) userChoice="km12n" ;;
		3) userChoice="adm-cci-web15c" ;;
        4) read -p "Enter username:" -r userChoice;;

		*) echo -e "${RED}Error...${NC}" && sleep .5 ;;
	esac
        # same for playbook and ad hoc
        append=" --user=$userChoice --ask-pass --ask-become-pass --become"
        command="$command$append"
        echo -e "Your command so far: ${YELLOW}$command${NC}"
        #sudoSelector
	finalOutput
}



finalOutput(){
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo -e "${RED}ANSIBLE COMMANDER: OUTPUT${NC}"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo ""
    echo "Do you need a dry run (What-If)? (y/N):"
    read -r dryChoice
    case $dryChoice in
    y|Y) 
    	append=" --check"
    	command="$command$append"
    	echo -e "Your command so far: ${YELLOW}$command${NC}"
    	;;
    n|N|"") 
        #echo -e "Your command so far: ${YELLOW}$command${NC}"
        ;;
    *) echo -e "${RED}Error...${NC}" && sleep .5
    esac

        echo -e "${BLUE}Please review your command below before it is run!${NC}"
        echo ""
        echo -e "Your command: ${YELLOW}$command${NC}"
        echo ""
        sleep 1
        # run command
        eval "$command"
        exit

# TODO: ask user if they'd like to do a dry-run (check mode/What If)
# https://docs.ansible.com/ansible/latest/user_guide/playbooks_checkmode.html#id1

}

# Menu Function
# Display list of options, start at top of decision tree
# Inspiration from https://bash.cyberciti.biz/guide/Menu_driven_scripts

show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
	echo -e "${RED}ANSIBLE COMMANDER${NC}"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "The following Ansible options are available:"
    echo ""
	echo "1) Run Ansible Playbook"
	echo "2) Run Ansible Ad-Hoc Command"
	echo "3) Exit"
}
# Read options. Call another function from 1 or 2.
read_options(){
	local choice
    echo ""
	read -rp "Please select an Ansible option: " choice
	case $choice in
		1) choosePlaybook ;;
		2) chooseAdhoc ;;
		3) clear
           exit 0 ;;
		*) echo -e "${RED}Error...${NC}" && sleep .5
	esac
}

# ----------------------------------------------
# Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
#trap '' SIGINT SIGQUIT SIGTSTP
 
# -----------------------------------
# Main logic - infinite loop
# ------------------------------------
while true
do
	show_menus
	read_options
done

