#!/bin/bash

#set -x # for DEBUGGING

# Created by stevezhengshiqi on 8 Feb, 2019.
# Only support most 5th-8th CPU yet, older CPUs don't use X86PlatformPlugin.kext.
# This script depends on CPUFriend(https://github.com/acidanthera/CPUFriend) a lot, thanks to PMHeart.

# Current board-id
BOARD_ID="$(ioreg -lw0 | grep -i "board-id" | sed -e '/[^<]*</s///; s/\"//g; s/\>//; s/\>>//')"

# Display style setting
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
OFF="\033[m"

# Corresponding plist
X86_PLIST="/System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/X86PlatformPlugin.kext/Contents/Resources/${BOARD_ID}.plist"

# supported models
EPP_SUPPORTED_MODELS=(
  'Mac-9AE82516C7C6B903' # MacBook9,1
  'Mac-EE2EBD4B90B839A8' # MacBook10,1
  'Mac-827FAC58A8FDFA22' # MacBookAir8,1
  'Mac-226CB3C6A851A671' # MacBookAir8,2
  'Mac-473D31EABEB93F9B' # MacBookPro13,1
  'Mac-66E35819EE2D0D05' # MacBookPro13,2
  'Mac-A5C67F76ED83108C' # MacBookPro13,3
  'Mac-B4831CEBD52A0C4C' # MacBookPro14,1
  'Mac-CAD6701F7CEA0921' # MacBookPro14,2
  'Mac-551B86E5744E2388' # MacBookPro14,3
  'Mac-937A206F2EE63C01' # MacBookPro15,1
  'Mac-827FB448E656EC26' # MacBookPro15,2
  'Mac-1E7E29AD0135F9BC' # MacBookPro15,3
  'Mac-53FDB3D8DB8CA971' # MacBookPro15,4
  'Mac-E1008331FDC96864' # MacBookPro16,1
  'Mac-E7203C0F68AA0004' # MacBookPro16,3
  'Mac-A61BADE1FDAD7B05' # MacBookPro16,4
)

EPP_SUPPORTED_MODELS_SPECIAL=(
  'Mac-7BA5B2DFE22DDD8C' # Macmini8,1
)

LFM_SUPPORTED_MODELS=(
  'Mac-BE0E8AC46FE800CC' # MacBook8,1
  'Mac-9F18E312C5C2BF0B' # MacBookAir7,1
  'Mac-937CB26E2E02BB01' # MacBookAir7,2
  'Mac-E43C1C25D4880AD6' # MacBookPro12,1
  'Mac-A369DDC4E67F1C45' # iMac16,1
  'Mac-FFE5EF870D7BA81A' # iMac16,2
  'Mac-4B682C642B45593E' # iMac18,1
  'Mac-77F17D7DA9285301' # iMac18,2
)

LFM_800_MODELS=(
  'Mac-0CFF9C7C2B63DF8D' # MacBookAir9,1
  'Mac-5F9802EFE386AA28' # MacBookPro16,2
)

function init() {
  if [[ ${OSTYPE} != darwin* ]]; then
    echo "This script can only run in macOS, aborting"
    exit 1
  fi
}

function printHeader() {
  printf '\e[8;40;90t'

  # Interface (ref: http://patorjk.com/software/taag/#p=display&f=Ivrit&t=C%20P%20U%20F%20R%20I%20E%20N%20D)
  echo '  ____   ____    _   _   _____   ____    ___   _____   _   _   ____ '
  echo ' / ___| |  _ \  | | | | |  ___| |  _ \  |_ _| | ____| | \ | | |  _ \ '
  echo '| |     | |_) | | | | | | |_    | |_) |  | |  |  _|   |  \| | | | | | '
  echo '| |___  |  __/  | |_| | |  _|   |  _ <   | |  | |___  | |\  | | |_| | '
  echo ' \____| |_|      \___/  |_|     |_| \_\ |___| |_____| |_| \_| |____/ '
  echo
  echo "Your board-id is ${BOARD_ID}"
  echo '====================================================================='
}

# Check board-id
function checkBoardID() {
  if echo "${EPP_SUPPORTED_MODELS[@]}" | grep -w "${BOARD_ID}" &> /dev/null; then
    support=2
  elif echo "${EPP_SUPPORTED_MODELS_SPECIAL[@]}" | grep -w "${BOARD_ID}" &> /dev/null; then
    support=3
  elif echo "${LFM_800_MODELS[@]}" | grep -w "${BOARD_ID}" &> /dev/null; then
    support=4
  elif echo "${LFM_SUPPORTED_MODELS[@]}" | grep -w "${BOARD_ID}" &> /dev/null; then
    support=1
  else
    echo -e "[ ${RED}ERROR${OFF} ]: Sorry, your board-id has not been supported yet!"
    exit 1
  fi
}

# Exit in case of failure
function networkWarn() {
  echo -e "[ ${RED}ERROR${OFF} ]: Fail to download CPUFriend, please check your connection!"
  clean
  exit 1
}

# Download CPUFriend repository and unzip latest release
function downloadKext() {
  local cfURL
  local HG
  local rcURL

  # new folder for work
  WORK_DIR="$HOME/Desktop/one-key-cpufriend"
  [[ -d "${WORK_DIR}" ]] && sudo rm -rf "${WORK_DIR}"
  mkdir -p "${WORK_DIR}" && cd "${WORK_DIR}" || exit 1

  echo
  echo '----------------------------------------------------------------------------------'
  echo '|* Downloading CPUFriend from https://github.com/acidanthera/CPUFriend @PMheart *|'
  echo '----------------------------------------------------------------------------------'

  # download ResourceConverter.sh
  rcURL='https://raw.githubusercontent.com/acidanthera/CPUFriend/master/Tools/ResourceConverter.sh'
  curl --silent -O "${rcURL}" || networkWarn
  chmod +x ./ResourceConverter.sh || exit 1

  # download CPUFriend.kext
  HG="grep -m 1 RELEASE"
  cfRawURL="https://github.com/acidanthera/CPUFriend/releases/latest"
  cfRawURL=$(curl -Ls -o /dev/null -w "%{url_effective}" "${cfRawURL}" | sed 's/releases\/tag/releases\/expanded_assets/')
  cfURL="https://github.com$(curl -L --silent "${cfRawURL}" | grep '/download/' | eval "${HG}" | sed 's/^[^"]*"\([^"]*\)".*/\1/')"
  if [[ -z ${cfURL} || ${cfURL} == "https://github.com" ]]; then
    networkWarn
  fi
  # GitHub's CDN is hosted on Amazon, so here we add -L for redirection support
  curl -# -L -O "${cfURL}" || networkWarn
  # decompress it
  unzip -qq "*.zip" || exit 1
  echo -e "[ ${GREEN}OK${OFF} ]Download complete"
}

# Copy the target plist
function copyPlist() {
  if [[ ! -f "${X86_PLIST}" ]]; then
    echo -e "[ ${RED}ERROR${OFF} ]: ${X86_PLIST} NOT found!"
    clean
    exit 1
  fi

  cp "${X86_PLIST}" . || exit 1
}

# Change LFM value to adjust lowest frequency
# Reconsider whether this function is necessary because LFM seems doesn't effect energy performance
function changeLFM(){
  echo
  echo "-----------------------------------------"
  echo "|****** Choose Low Frequency Mode ******|"
  echo "-----------------------------------------"
  if [ "${support}" == 4 ]; then
    echo "(1) 1200mhz"
    echo "(2) 800mhz (Remain the same)"
  else
    echo "(1) 1200/1300mhz (Remain the same)"
    echo "(2) 800mhz"
  fi
  echo "(3) Customize"
  echo -e "${BOLD}Which option you want to choose? (1/2/3)${OFF}"
  read -rp ":" lfm_selection
  case ${lfm_selection} in
    1)
    # Deal with LFM_800_MODELS
    # Change 800 to 1200
    if [ "${support}" == 4 ]; then
      # change 0200000008000000 to 020000000c000000
      /usr/bin/sed -i "" "s:AgAAAAgAAAA:AgAAAAwAAAA:g" "$BOARD_ID.plist"
    fi
    ;;

    2)
    # Change 1200/1300 to 800
    if [ "${support}" != 4 ]; then
      # change 020000000d000000 to 0200000008000000
      /usr/bin/sed -i "" "s:AgAAAA0AAAA:AgAAAAgAAAA:g" "$BOARD_ID.plist"

      # change 020000000c000000 to 0200000008000000
      /usr/bin/sed -i "" "s:AgAAAAwAAAA:AgAAAAgAAAA:g" "$BOARD_ID.plist"
    fi
    ;;

    3)
    # Customize LFM
    customizeLFM
    ;;

    *)
    echo -e "[ ${RED}ERROR${OFF} ]: Invalid input, closing the script"
    clean
    exit 1
    ;;
  esac
}

# Customize LFM
function customizeLFM
{
  local Count=0
  local gLFM_RAW=""

  # check count and user input
  while  [ ${Count} -lt 3 ] && [[ ${gLFM_RAW} != 0 ]];
  do
    echo
    echo -e "${BOLD}Enter the lowest frequency in mhz (e.g. 1300, 2700), 0 to quit${OFF}"
    echo "Valid value should between 800 and 3500,"
    echo "and ridiculous value may result in hardware failure!"
    read -rp ": " gLFM_RAW
    if [ "${gLFM_RAW}" == 0 ]; then
      # if user enters 0, back to main function
      return

    # check whether gLFM_RAW is an integer
    elif [[ ${gLFM_RAW} =~ ^[0-9]*$ ]]; then

      # acceptable LFM should in 400~4000
      if [ "${gLFM_RAW}" -ge 400 ] && [ "${gLFM_RAW}" -le 4000 ]; then
        # get 4 denary number from user input, eg. 800 -> 0800
        gLFM_RAW=$(printf '%04d' "${gLFM_RAW}")
        # extract the first two digits
        gLFM_RAW=$(echo "${gLFM_RAW}" | cut -c -2)
        # remove zeros at the head, because like 08, bash will consider it as octonary number
        gLFM_RAW=$(echo "${gLFM_RAW}" | sed 's/0*//')
        # convert gLFM_RAW to hex and insert it in LFM field
        gLFM_VAL=$(printf '02000000%02x000000' "${gLFM_RAW}")
        # convert gLFM_VAL to base64
        gLFM_ENCODE=$(echo "${gLFM_VAL}" | xxd -r -p | base64)
        # extract the first 11 digits
        gLFM_ENCODE=$(echo "${gLFM_ENCODE}" | cut -c -11)

        if [ "${support}" == 4 ]; then
          # change 0200000008000000 to 02000000{Customized Value}000000
          /usr/bin/sed -i "" "s:AgAAAAgAAAA:${gLFM_ENCODE}:g" "$BOARD_ID.plist"
        else
          # change 020000000d000000 to 02000000{Customized Value}000000
          /usr/bin/sed -i "" "s:AgAAAA0AAAA:${gLFM_ENCODE}:g" "$BOARD_ID.plist"
          # change 020000000c000000 to 02000000{Customized Value}000000
          /usr/bin/sed -i "" "s:AgAAAAwAAAA:${gLFM_ENCODE}:g" "$BOARD_ID.plist"
        fi
        return

      else
        # invalid value, give 3 chances to re-input
        echo
        echo -e "[ ${BOLD}WARNING${OFF} ]: Please enter valid value (400~4000)!"
        Count=$((Count+1))
      fi

    else
      # invalid value, give 3 chances to re-input
      echo
      echo -e "[ ${BOLD}WARNING${OFF} ]: Please enter valid value (400~4000)!"
      Count=$((Count+1))
    fi
  done

  if [ ${Count} -gt 2 ]; then
    # if 3 times is over and input value is still invalid, exit
    echo -e "[ ${RED}ERROR${OFF} ]: Invalid input, closing the script"
    clean
    exit 1
  fi
}

# Change EPP value to adjust performance (ref: https://www.tonymacx86.com/threads/skylake-hwp-enable.214915/page-7)
# TO DO: Use a more efficient way to replace frequencyvectors, see https://github.com/Piker-Alpha/freqVectorsEdit.sh
function changeEPP(){
  echo
  echo "----------------------------------------"
  echo "| Choose Energy Performance Preference |"
  echo "----------------------------------------"
  echo "(1) Max Power Saving"

  # Deal with EPP_SUPPORTED_MODELS_SPECIAL
  if [ "${support}" == 2 ] || [ "${support}" == 4 ]; then
    echo "(2) Balance Power (Default)"
    echo "(3) Balance performance"
  elif [ "${support}" == 3 ]; then
    echo "(2) Balance Power"
    echo "(3) Balance performance (Default)"
  fi

  echo "(4) Performance"
  echo -e "${BOLD}Which mode is your favourite? (1/2/3/4)${OFF}"
  read -rp ":" epp_selection
  case ${epp_selection} in
    1)
    # Change 20/80/90/92 to C0, max power saving

    # change 657070000000000000000000000000000000000080 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000080 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:DAAAAAAAAAAAAAAAAAAAAAd:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000092 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000090 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000092 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000080 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" "$BOARD_ID.plist"
    
    # change 657070000000000000000000000000000000000090 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACQ:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000020 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:AgAAAAAAAAAAAAAAAAAAAAd:DAAAAAAAAAAAAAAAAAAAAAd:g" "$BOARD_ID.plist"
    ;;

    2)
    if { [ "${support}" == 2 ] && [ "${lfm_selection}" == 1 ]; } || { [ "${support}" == 4 ] && [ "${lfm_selection}" == 2 ]; }; then
      # Keep default 80/90/92, balance power
      # if also no changes for lfm, exit
      echo "It's nice to keep the same, see you next time."
      clean
      exit 0

    # Deal with EPP_SUPPORTED_MODELS_SPECIAL
    elif [ "${support}" == 3 ]; then
      # Change 20 to 80, balance performance

      # change 657070000000000000000000000000000000000020 to 657070000000000000000000000000000000000080
      /usr/bin/sed -i "" "s:AgAAAAAAAAAAAAAAAAAAAAd:CAAAAAAAAAAAAAAAAAAAAAd:g" "$BOARD_ID.plist"
    fi
    ;;

    3)
    if [ "${support}" == 2 ] || [ "${support}" == 4 ]; then
      # Change 80/90/92 to 40, balance performance

      # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

      # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:BAAAAAAAAAAAAAAAAAAAAAd:g" "$BOARD_ID.plist"

      # change 657070000000000000000000000000000000000092 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

      # change 657070000000000000000000000000000000000090 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

      # change 657070000000000000000000000000000000000092 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" "$BOARD_ID.plist"

      # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" "$BOARD_ID.plist"
      
      # change 657070000000000000000000000000000000000090 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACQ:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" "$BOARD_ID.plist"

    elif [ "${support}" == 3 ] && [ "${lfm_selection}" == 1 ]; then
      # Keep default 20, balance performance
      # if also no changes for lfm, exit
      echo "It's nice to keep the same, see you next time."
      clean
      exit 0
    fi
    ;;

    4)
    # Change 20/80/90/92 to 00, performance

    # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:AAAAAAAAAAAAAAAAAAAAAAd:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000092 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000090 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000092 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" "$BOARD_ID.plist"
    
    # change 657070000000000000000000000000000000000090 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACQ:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" "$BOARD_ID.plist"

    # change 657070000000000000000000000000000000000020 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:AgAAAAAAAAAAAAAAAAAAAAd:AAAAAAAAAAAAAAAAAAAAAAd:g" "$BOARD_ID.plist"
    ;;

    *)
    echo -e "[ ${RED}ERROR${OFF} ]: Invalid input, closing the script"
    clean
    exit 1
    ;;
  esac
}

# Generate CPUFriendDataProvider.kext and move to desktop
function generateKext(){
  echo
  echo "Generating CPUFriendDataProvider.kext"
  ./ResourceConverter.sh --kext "$BOARD_ID.plist" || exit 1
  cp -r CPUFriendDataProvider.kext "$HOME/Desktop/" || exit 1

  # Copy CPUFriend.kext to Desktop
  cp -r CPUFriend.kext "$HOME/Desktop/" || exit 1

  echo -e "[ ${GREEN}OK${OFF} ]Generate complete"
}

# Delete tmp folder and end
function clean(){
  echo
  echo "Cleaning tmp files"
  sudo rm -rf "${WORK_DIR}"
  echo -e "[ ${GREEN}OK${OFF} ]Clean complete"
  echo
}

# Main function
function main(){
  init
  printHeader
  checkBoardID
  downloadKext
  if [ "${support}" == 1 ]; then
    copyPlist
    changeLFM
  elif [ "${support}" == 2 ] || [ "${support}" == 3 ] || [ "${support}" == 4 ]; then
    copyPlist
    changeLFM
    changeEPP
  fi
  generateKext
  clean
  echo -e "[ ${GREEN}OK${OFF} ]This is the end of the script, please copy CPUFriend and CPUFriendDataProvider from desktop"
  echo "Clover: to /CLOVER/kexts/Other/ or L/E/"
  echo "OC: to /OC/Kexts/ and add patches from README to config.plist - Kernel - Add"
  exit 0
}

main
