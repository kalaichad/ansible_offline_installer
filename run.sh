#!/usr/bin/bash
current_path=$(pwd)
if [ ! -d ${current_path}/logs ]
then
    mkdir ${current_path}/logs
fi

c_echo() {
     echo "$@" | sed \
             -e "s/\(\(@\(red\|green\|yellow\|blue\|magenta\|cyan\|white\|reset\|b\|u\)\)\+\)[[]\{2\}\(.*\)[]]\{2\}/\1\4@reset/g" \
             -e "s/@red/$(tput setaf 1)/g" \
             -e "s/@green/$(tput setaf 2)/g" \
             -e "s/@yellow/$(tput setaf 3)/g" \
             -e "s/@blue/$(tput setaf 4)/g" \
             -e "s/@magenta/$(tput setaf 5)/g" \
             -e "s/@cyan/$(tput setaf 6)/g" \
             -e "s/@white/$(tput setaf 7)/g" \
             -e "s/@reset/$(tput sgr0)/g" \
             -e "s/@b/$(tput bold)/g" \
             -e "s/@u/$(tput sgr 0 1)/g"
}

statuslog=${current_path}/logs/status.log
errorlog=${current_path}/logs/error.log
infolog=${current_path}/logs/info.log

echo -e "\n=~=~=~=~=~=~=~=~=~=~=~=~=~=~=" >> ${errorlog}
date >> ${errorlog}
echo -e "=~=~=~=~=~=~=~=~=~=~=~=~=~=~=\n" >> ${errorlog}

echo "Inprogress" | tee ${infolog} | tee ${statuslog} &> /dev/null

if [ $(whoami) != "root" ]
then
    echo "Script need to run with root user privilege." >> ${errorlog}
    echo "failed" > ${statuslog}
    exit 1
fi

function dependency_tools {
ec=0
which ansible &> /dev/null
if [ ${?} -ne 0 ]
then
    if [ -s ${current_path}/lib/ansible ]
    then
	cd ${current_path}/lib/ansible
	dpkg -i *.deb &> ${current_path}/logs/ansible_install.log
	if [ ${?} -ne 0 ]
	then
	    echo "Ansible failed to install. Check the log" | tee ${infolog} | tee -a ${errorlog} &> /dev/null
	    c_echo "Failed to install dependency package's. Check the logs :@b@red[[ Failed ]]"
	    echo "failed" > ${statuslog}
	    cd ${current_path}
	    exit 1
	else
	    echo "Ansible installed successfully." | tee ${infolog} | tee -a ${errorlog} &> /dev/null
	    ec=143
	    cd ${current_path}
	fi
    else
	echo "${current_path}/lib/ansible under deb packages not found." | tee ${infolog} | tee -a ${errorlog} &> /dev/null
	c_echo "Failed to install dependency package's. Check the logs :@b@red[[ Failed ]]"
	echo "failed" > ${statuslog}
	exit 1
    fi
fi
sleep 2
which sshpass &> /dev/null
if [ ${?} -ne 0 ]
then
    if [ -s ${current_path}/lib/sshpass ]
    then
	cd ${current_path}/lib/sshpass
	dpkg -i *.deb &> ${current_path}/logs/sshpass_install.log
	if [ ${?} -ne 0 ]
	then
	    echo "sshpass failed to install. Check the log" | tee ${infolog} | tee -a ${errorlog} &> /dev/null
	    c_echo "Failed to install dependency package's. Check the logs :@b@red[[ Failed ]]"
            echo "failed" > ${statuslog}
            cd ${current_path}
            exit 1
        else
            echo "sshpass installed successfully." | tee ${infolog} | tee -a ${errorlog} &> /dev/null
	    ec=143
            cd ${current_path}
        fi
    else
        echo "${current_path}/lib/sshpass under deb packages not found." | tee ${infolog} | tee -a ${errorlog} &> /dev/null
	c_echo "Failed to install dependency package's. Check the logs :@b@red[[ Failed ]]"
        echo "failed" > ${statuslog}
        exit 1
    fi
fi
sleep 2
if [ ${ec} -eq 143 ]
then
    which ansible &>> ${errorlog} && which sshpass &>> ${errorlog}
    if [ ${?} -eq 0 ]
    then
	ansible_version="2.12"
        ansible --version | head -n 3 | grep -E "${ansible_version}" &>/dev/null
        if [ ${?} -ne 0 ]
        then
            echo "This $(ansible --version 2>/dev/null | head -n 1) version not compatible to execute the scripts." | tee -a ${errorlog} | tee ${infolog}
            echo "failed" > ${statuslog}
            c_echo "Failed to install dependency package's. Check the logs :@b@red[[ Failed ]]"
            exit 1
        fi
        c_echo "JumpServer Dependency Packages Installed :@b@green[[ Success ]]"
        echo "JumpServer Dependency Packages Installed." | tee ${infolog} | tee -a ${errorlog} &> /dev/null
	echo "success" > ${statuslog}
    else
	echo "failed" > ${statuslog}
        c_echo "Failed to install dependency package's. Check the logs :@b@red[[ Failed ]]"
        echo "Failed to install dependency package's. Check the logs" | tee ${infolog} | tee -a ${errorlog} &> /dev/null
        exit 1
    fi
fi
}
ec=0
echo -e "\n=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
c_echo JumpServer Dependency Packages Installation :@b@yellow[[ In-Progress ]]
echo -e "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"
echo -e "\nJumpServer Dependency Packages Installation In-Progress" | tee ${infolog} | tee -a ${errorlog} &> /dev/null

ubuntu_val=$(grep -Ec "NAME=\"Ubuntu\"|VERSION_ID=\"20.04\"|20.04.6" /etc/os-release 2>> ${errorlog})
if [ ${ubuntu_val} -ne 3 ]
then
    echo "The script will not work in $(grep -Ec "^NAME=|^VERSION_ID=" /etc/os-release)" | tee -a ${errorlog} | tee ${infolog} &> /dev/null
    echo "failed" > ${statuslog}
    c_echo "Failed - Ubuntu 20.04.6 required. Check the logs :@b@red[[ Failed ]]"
    exit 1
fi

python3 --version 2> /dev/null | grep "3.8.10" &> /dev/null
if [ ${?} -ne 0 ]
then
    echo "Python 3.8.10 version is required." | tee ${infolog} | tee -a ${errorlog} &> /dev/null
    echo "failed" > ${statuslog}
    c_echo "Failed due to prerequisite package's. Check the logs :@b@red[[ Failed ]]"
    exit 1
fi

ansible_version="2.12"
which ansible &> /dev/null
if [ ${?} -eq 0 ]
then
    ansible --version | head -n 3 | grep -E "${ansible_version}" &>/dev/null
    if [ ${?} -ne 0 ]
    then
        echo -e "Ansible already installed. But $(ansible --version 2>/dev/null | head -n 1) version not compatible to execute the scripts." | tee -a ${errorlog} | tee ${infolog}
        echo "failed" > ${statuslog}
        exit 1
    fi
fi
for i in $(echo ansible sshpass)
do
    if ! which ${i} &>> ${errorlog}
    then
        ec=143
        echo "This package ${i} not available. Now it's installing a package's." | tee ${infolog} | tee -a ${errorlog} &> /dev/null
    fi
done
if [ ${ec} -eq 143 ]
then
    dependency_tools
else
    echo "Dependency package's already installed." | tee ${infolog} | tee -a ${errorlog} &> /dev/null
    c_echo "@b@green[[ Dependency package's already installed ]]"
    echo "success" > ${statuslog}
fi
