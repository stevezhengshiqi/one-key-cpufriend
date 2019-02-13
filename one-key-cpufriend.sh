#!/bin/bash
# Created by stevezhengshiqi on 8 Feb, 2019.
# Only support most 5th-8th CPU yet, older CPUs don't use X86PlatformPlugin.kext.
# This script depends on CPUFriend(https://github.com/acidanthera/CPUFriend) a lot, thanks to Acidanthera and PMHeart.

# Interface (Ref: http://patorjk.com/software/taag/#p=display&f=Ivrit&t=C%20P%20U%20F%20R%20I%20E%20N%20D)
function interface(){
    printf "\e[8;40;110t"
    boardid=($(ioreg -lw0 | grep -i "board-id" | sed -e "/[^<]*</s///" -e "s/\>//" | sed 's/"//g'))
    support=0
    echo "  ____   ____    _   _   _____   ____    ___   _____   _   _   ____ "
    echo " / ___| |  _ \  | | | | |  ___| |  _ \  |_ _| | ____| | \ | | |  _ \ "
    echo "| |     | |_) | | | | | | |_    | |_) |  | |  |  _|   |  \| | | | | | "
    echo "| |___  |  __/  | |_| | |  _|   |  _ <   | |  | |___  | |\  | | |_| | "
    echo " \____| |_|      \___/  |_|     |_| \_\ |___| |_____| |_| \_| |____/ "
    echo "Your board-id is $boardid"
    echo "===================================================================== "
}

# Exit if connection fails
function networkwarn(){
    echo "ERROR: Fail to download CPUFriend, please check the network state"
    exit 0
}

# Download CPUFriend repository and unzip latest release
function download(){
    mkdir -p Desktop/tmp/one-key-cpufriend
    cd Desktop/tmp/one-key-cpufriend
    echo "--------------------------------------------------------------------------"
    echo "|* Downloading CPUFriend from github.com/acidanthera/CPUFriend @PMHeart *|"
    echo "--------------------------------------------------------------------------"
    curl -fsSL https://raw.githubusercontent.com/acidanthera/CPUFriend/master/ResourceConverter/ResourceConverter.sh -o ./ResourceConverter.sh || networkwarn
    sudo chmod +x ./ResourceConverter.sh
    curl -fsSL https://github.com/acidanthera/CPUFriend/releases/download/1.1.6/1.1.6.RELEASE.zip -o ./1.1.6.RELEASE.zip && unzip 1.1.6.RELEASE.zip && cp -r CPUFriend.kext ../../ || networkwarn
}

# Check board-id
function checkboardid(){
    if [ $boardid = "Mac-BE0E8AC46FE800CC" -o $boardid = "Mac-9F18E312C5C2BF0B" -o $boardid = "Mac-937CB26E2E02BB01" -o $boardid = "Mac-E43C1C25D4880AD6" -o $boardid = "Mac-A369DDC4E67F1C45" -o $boardid = "Mac-FFE5EF870D7BA81A" -o $boardid = "Mac-4B682C642B45593E" -o $boardid = "Mac-77F17D7DA9285301" ]; then
        support=1
    elif [ $boardid = "Mac-9AE82516C7C6B903" -o $boardid = "Mac-EE2EBD4B90B839A8" -o $boardid = "Mac-473D31EABEB93F9B" -o $boardid = "Mac-66E35819EE2D0D05" -o $boardid = "Mac-A5C67F76ED83108C" -o $boardid = "Mac-B4831CEBD52A0C4C" -o $boardid = "Mac-CAD6701F7CEA0921" -o $boardid = "Mac-551B86E5744E2388" -o $boardid = "Mac-937A206F2EE63C01" -o $boardid = "Mac-827FB448E656EC26" ]; then
        support=2
    else
        support=0
    fi
}

# Copy the target plist
function copyplist(){
    sudo cp -r /System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/X86PlatformPlugin.kext/Contents/Resources/$boardid.plist ./
}

# chenge LFM value to adjust lowest frequency
function changelfm(){
    echo "-----------------------------------------"
    echo "|****** Choose Low Frequency Mode ******|"
    echo "-----------------------------------------"
    echo "(1) Remain the same (1200/1300mhz)"
    echo "(2) 800mhz (Save power in low load)"
    read -p "Which option you want to choose? (1/2):" lfm_selection
    case $lfm_selection in
        1)
        # Keep default
        ;;

        2)
        # Change 1200/1300 to 800
        sudo /usr/bin/sed -i "" "s:AgAAAA0AAAA:AgAAAAgAAAA:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:AgAAAAwAAAA:AgAAAAgAAAA:g" $boardid.plist
        ;;

        *)
        echo "ERROR: Invalid input, closing the script"
        exit 0
        ;;
    esac
}

# change EPP value to adjust performance (ref: https://www.tonymacx86.com/threads/skylake-hwp-enable.214915/page-7)
function changeepp(){
    echo "----------------------------------------"
    echo "| Choose Energy Performance Preference |"
    echo "----------------------------------------"
    echo "(1) Max Power Saving"
    echo "(2) Balance Power (Default)"
    echo "(3) Balance performance"
    echo "(4) Performance"
    read -p "Which mode is your favourite? (1/2/3/4):" epp_selection
    case $epp_selection in
        1)
        # Change 80/90/92 to C0, max power saving
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:DAAAAAAAAAAAAAAAAAAAAAd:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" $boardid.plist
        ;;

        2)
        # Keep default 80/90/92, balance power
        ;;

        3)
        # Change 80/90/92 to 40, balance performance
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:BAAAAAAAAAAAAAAAAAAAAAd:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" $boardid.plist
        ;;

        4)
        # Change 80/90/92 to 00, performance
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:AAAAAAAAAAAAAAAAAAAAAAd:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" $boardid.plist
        ;;

        *)
        echo "ERROR: Invalid input, closing the script"
        exit 0
        ;;
    esac
}

# Generate CPUFriendDataProvider.kext and move to desktop
function generatekext(){
    echo "Generating CPUFriendDataProvider.kext"
    sudo ./ResourceConverter.sh --kext $boardid.plist
    cp -r CPUFriendDataProvider.kext ../../
}

# Delete tmp folder and end
function clean(){
    sudo rm -rf ../../tmp

    echo "Great! This is the end of the script, please copy CPUFriend and CPUFriendDataProvider from desktop to /CLOVER/kexts/Other/"
    exit 0
}

# Main function
function main(){
    interface
    echo " "
    download
    echo " "
    checkboardid
    if [ $support == 1 ];then
        copyplist
        changelfm
    elif [ $support == 2 ];then
        copyplist
        changelfm
        echo " "
        changeepp
    else
        echo "Sorry, this script doesn't support your board-id yet"
        exit 0
    fi
    echo " "
    generatekext
    echo " "
    clean
    exit 0
}

main
