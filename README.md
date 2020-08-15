# AWS-Crack-Station

Just a simple bash script I created to help setup an AWS EC2 instance with Hashcat.

## What it does
1. Changes hostname of server (takes argument)
2. Performs full OS upgrade
3. Installs base packages from $basePackages
    1. tmux
    2. unzip
    3. p7zip-full
    4. python3-pip
    5. build-essential
    6. linux-headers
    7. git
    8. ocl-icd-libopencl1
    9. opencl-headers
    10. clinfo
4. Downloads and extract hashcat
5. Downloads wordlists
    1. Sources:
    * https://github.com/danielmiessler/SecLists.git
    * http://downloads.skullsecurity.org/passwords/rockyou.txt.bz2
6. Installs NVIDIA CUDA drivers

## Usage
```
Usage: ./aws-crack-station.sh [-h <hostname>]
```