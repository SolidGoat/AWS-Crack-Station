#!/bin/bash

#=========================================================
#Terminal Color Codes
#=========================================================
# Regular Text
txtblk='\e[0;30m' # Black
txtred='\e[0;31m' # Red
txtgrn="\e[0;32m" # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
###############################
# Bold Text
bldblk='\e[1;30m' # Black
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
###############################
# Underline Text
unkblk='\e[4;30m' # Black
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
###############################
# Background Color
bakblk='\e[40m'   # Black
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
###############################
# Rest Color
txtrst='\e[0m'    # Text Reset - Useful for avoiding color bleed

# Array of base packages to install
declare -a basePackages=("tmux" "unzip" "p7zip-full" "python3-pip" "build-essential" "linux-headers-$(uname -r)" "git")

# Check if running as root; exit if not
function CheckRoot
{
	if [ $EUID -ne 0 ]
	then
		echo -e ${bldred}"Must run as root."${txtrst}
		exit 0
	fi
}

# Change hostname of server
function ChangeHostname
{
    echo -e ${bldgrn}"Changing Hostname..."${txtrst}

    hostnamectl set-hostname linuxize

    echo -e ${txtblu}"Hostname set to: "${txtrst}${bldblu}"$(hostname)"${txtrst}
}

# Perform full OS upgrade
function UpgradeOS
{
    echo -e ${bldgrn}"Running Updates..."${txtrst}

    apt -y update
    apt -y upgrade
    apt -y full-upgrade
}

# Install base packages from $basePackages
function SetupBasePackages
{
    echo -e ${bldgrn}"Install Base Packages..."${txtrst}

    apt -y install "${basePackages[@]}"
}

# Download and extract hashcat
function SetupHashcat
{
    echo -e ${bldgrn}"Downloading and Extracting Hashcat..."${txtrst}

    # Download and extract hashcat
    wget https://hashcat.net/files/hashcat-6.0.0.7z -O /opt
    7z x /opt/hashcat-6.0.0.7z
}

# Download wordlists
function SetupWordlists
{
    echo -e ${bldgrn}"Downloading Wordlists..."${txtrst}

    # Create wordlists directory in /opt
    mkdir /opt/wordlists
    cd /opt/wordlists

    # Download SecLists from Github
    git clone https://github.com/danielmiessler/SecLists.git

    # Download Rockyou.txt
    wget -nH http://downloads.skullsecurity.org/passwords/rockyou.txt.bz2
    bunzip2 ./rockyou.txt.bz2
}

# Shell usage
function Usage
{
    echo -e ${txtylw}"Usage: $0 [-h <hostname>]"${txtrst}
    exit 1
}

# Main function
function Main
{
    CheckRoot
    ChangeHostname
    UpgradeOS
    SetupBasePackages
    SetupHashcat
    SetupWordlists
}

# Parse arguments
while getopts ":h:" opt
do
    case ${opt} in
        h) hostname=$OPTARG ;;
        \?) echo -e ${bldred}"Invalid option: $OPTARG"${txtrst} 1>&2 ;;
        :) echo -e ${bldred}"Invalid option: $OPTARG requires an argument"${txtrst} 1>&2 ;;
        *) Usage ;;
    esac
done
shift $((OPTIND -1))

if [ -z "${hostname}" ]
then
    Usage
else
    Main
fi