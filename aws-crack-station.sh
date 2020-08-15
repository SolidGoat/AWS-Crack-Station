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
declare -a basePackages=("tmux" "unzip" "p7zip-full" "python3-pip" "build-essential" "linux-headers-$(uname -r)" "git"
                        "ocl-icd-libopencl1" "opencl-headers" "clinfo")

# Hashcat URL and file version
hashcat_version="6.1.1"
hashcat_url="https://hashcat.net/files/hashcat-$hashcat_version.7z"

# Get distribution name
distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')

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
    echo -e ${bldgrn}"\n[+]Changing Hostname..."${txtrst}

    hostnamectl set-hostname $hostname

    echo -e ${txtblu}"Hostname set to: "${txtrst}${bldblu}"$(hostname)"${txtrst}
}

# Perform full OS upgrade
function UpgradeOS
{
    echo -e ${bldgrn}"\n[+]Running OS Updates..."${txtrst}
    sleep 3

    apt -y update
    apt -y upgrade
    apt -y full-upgrade
}

# Install base packages from $basePackages
function InstallBasePackages
{
    echo -e ${bldgrn}"\n[+]Install Base Packages..."${txtrst}
    sleep 3

    apt -y install "${basePackages[@]}"
}

# Install base packages from $basePackages
function InstallNVIDIA
{
    echo -e ${bldgrn}"\n[+]Installing NVIDIA Drivers..."${txtrst}
    sleep 3

    # Creating modprobe blacklist file and populate
    echo -e ${txtylw}"\n[-]Writing to modprobe blacklist file..."${txtrst}
    sleep 3

    touch /etc/modprobe.d/blacklist-nouveau.conf
    echo "blacklist nouveau" | tee -a /etc/modprobe.d/blacklist-nouveau.conf
    echo "blacklist lbm-nouveau" | tee -a /etc/modprobe.d/blacklist-nouveau.conf
    echo "options nouveau modeset=0" | tee -a /etc/modprobe.d/blacklist-nouveau.conf
    echo "alias nouveau off" | tee -a /etc/modprobe.d/blacklist-nouveau.conf
    echo "alias lbm-nouveau off" | tee -a /etc/modprobe.d/blacklist-nouveau.conf

    # Creating Nouveau config file
    echo -e ${txtylw}"\n[-]Writing to Nouveau config file..."${txtrst}
    sleep 3

    touch /etc/modprobe.d/nouveau-kms.conf
    echo "options nouveau modeset=0" | tee -a /etc/modprobe.d/nouveau-kms.conf

    # Install NVIDIA CUDA drivers through package manager
    echo -e ${txtylw}"\n[-]Installing NVIDIA CUDA drivers..."${txtrst}
    sleep 3

    # Dowonload CUDA pin for specified distribution
    cd $HOME
    wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-$distribution.pin
    mv cuda-$distribution.pin /etc/apt/preferences.d/cuda-repository-pin-600

    # Install public key
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/7fa2af80.pub

    # Add NVIDIA repo to cuda.list
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64 /" | tee /etc/apt/sources.list.d/cuda.list

    apt -y update
    apt -y install cuda-drivers
}

# Download and extract hashcat
function SetupHashcat
{
    echo -e ${bldgrn}"\n[+]Downloading and Extracting Hashcat..."${txtrst}
    sleep 3

    # Download and extract hashcat
    wget $hashcat_url -O /opt/hashcat-$hashcat_version.7z
    7z x /opt/hashcat-$hashcat_version.7z -o/opt/
    rm hashcat-$hashcat_version.7z
}

# Download wordlists
function SetupWordlists
{
    echo -e ${bldgrn}"\n[+]Downloading Wordlists..."${txtrst}
    sleep 3

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
    InstallBasePackages
    SetupHashcat
    SetupWordlists
    InstallNVIDIA

    echo -e ${bldgrn}"\nSetup of $hostname is complete!\n"${txtrst}
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