#!/bin/bash

# Created by stevezhengshiqi on 8 Feb, 2019.
# Only support most 5th-8th CPU yet, older CPUs don't use X86PlatformPlugin.kext.
# This script depends on CPUFriend(https://github.com/acidanthera/CPUFriend) a lot, thanks to PMHeart.

# current board-id
BOARD_ID="$(ioreg -lw0 | grep -i "board-id" | sed -e '/[^<]*</s///; s/\"//g; s/\>//')"

# corresponding plist
X86_PLIST="/System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/X86PlatformPlugin.kext/Contents/Resources/${BOARD_ID}.plist"

# supported models
EPP_SUPPORTED_MODELS=(
  'Mac-9AE82516C7C6B903' # MacBook9,1
  'Mac-EE2EBD4B90B839A8' # MacBook10,1
  'Mac-827FAC58A8FDFA22' # MacBookAir8,1
  'Mac-473D31EABEB93F9B' # MacBookPro13,1
  'Mac-66E35819EE2D0D05' # MacBookPro13,2
  'Mac-A5C67F76ED83108C' # MacBookPro13,3
  'Mac-B4831CEBD52A0C4C' # MacBookPro14,1
  'Mac-CAD6701F7CEA0921' # MacBookPro14,2
  'Mac-551B86E5744E2388' # MacBookPro14,3
  'Mac-937A206F2EE63C01' # MacBookPro15,1
  'Mac-827FB448E656EC26' # MacBookPro15,2
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

function printHeader() {
  printf '\e[8;40;110t'

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
  elif echo "${LFM_SUPPORTED_MODELS[@]}" | grep -w "${BOARD_ID}" &> /dev/null; then
    support=1
  else
    echo 'ERROR: Sorry, your board-id has not been supported yet!'
    exit 1
  fi
}

function getGitHubLatestRelease() {
  local repoURL='https://api.github.com/repos/acidanthera/CPUFriend/releases/latest'
  ver="$(curl --silent "${repoURL}" | grep 'tag_name' | head -n 1 | awk -F ":" '{print $2}' | tr -d '"' | tr -d ',' | tr -d ' ')"

  if [[ -z "${ver}" ]]; then
    echo "WARNING: Failed to retrieve latest release from ${repoURL}."
    exit 1
  fi
}

# Exit in case of failure
function networkWarn() {
  echo "ERROR: Fail to download CPUFriend, please check your connection!"
  exit 1
}

# Download CPUFriend repository and unzip latest release
function downloadKext() {
  WORK_DIR="/Users/`users`/Desktop/one-key-cpufriend"
  [[ -d "${WORK_DIR}" ]] && sudo rm -rf "${WORK_DIR}"
  mkdir -p "${WORK_DIR}" && cd "${WORK_DIR}"

  echo
  echo '----------------------------------------------------------------------------------'
  echo '|* Downloading CPUFriend from https://github.com/acidanthera/CPUFriend @PMheart *|'
  echo '----------------------------------------------------------------------------------'

  # download ResourceConverter.sh
  local rcURL='https://raw.githubusercontent.com/acidanthera/CPUFriend/master/ResourceConverter/ResourceConverter.sh'
  curl --silent -O "${rcURL}" && chmod +x ./ResourceConverter.sh || networkWarn

  # download CPUFriend.kext
  local cfVER="${ver}"
  local cfFileName="${cfVER}.RELEASE.zip"
  local cfURL="https://github.com/acidanthera/CPUFriend/releases/download/${cfVER}/${cfFileName}"
  # GitHub's CDN is hosted on Amazon, so here we add -L for redirection support
  curl --silent -L -O "${cfURL}" || networkWarn
  # decompress it
  unzip -qu "${cfFileName}"
  # remove stuffs we do not need
  rm -rf "${cfFileName}" 'CPUFriend.kext.dSYM'
  echo 'Download complete'
  echo
}

# Copy the target plist
function copyPlist() {
  if [[ ! -f "${X86_PLIST}" ]]; then
    echo "ERROR: ${X86_PLIST} NOT found!"
    exit 1
  fi

  cp "${X86_PLIST}" .
}

# chenge LFM value to adjust lowest frequency
# Reconsider whether this function is necessary because LFM seems doesn't effect energy performance
function changeLFM(){
  echo "-----------------------------------------"
  echo "|****** Choose Low Frequency Mode ******|"
  echo "-----------------------------------------"
  echo "(1) Remain the same (1200/1300mhz)"
  echo "(2) 800mhz"
  read -p "Which option you want to choose? (1/2):" lfm_selection
  case "${lfm_selection}" in
    1)
    # Keep default
    ;;

    2)
    # Change 1200/1300 to 800

    # Change 020000000d000000 to 0200000008000000
    /usr/bin/sed -i "" "s:AgAAAA0AAAA:AgAAAAgAAAA:g" $BOARD_ID.plist

    # Change 020000000c000000 to 0200000008000000
    /usr/bin/sed -i "" "s:AgAAAAwAAAA:AgAAAAgAAAA:g" $BOARD_ID.plist
    ;;

    *)
    echo "ERROR: Invalid input, closing the script"
    exit 1
    ;;
  esac
}

# change EPP value to adjust performance (ref: https://www.tonymacx86.com/threads/skylake-hwp-enable.214915/page-7)
# TO DO: Use a more efficient way to replace frequencyvectors, see https://github.com/Piker-Alpha/freqVectorsEdit.sh
function changeEPP(){
  echo "----------------------------------------"
  echo "| Choose Energy Performance Preference |"
  echo "----------------------------------------"
  echo "(1) Max Power Saving"

  # Deal with EPP_SUPPORTED_MODELS_SPECIAL
  if [ "${support}" == 2 ]; then
    echo "(2) Balance Power (Default)"
    echo "(3) Balance performance"
  elif [ "${support}" == 3 ]; then
    echo "(2) Balance Power"
    echo "(3) Balance performance (Default)"
  fi

  echo "(4) Performance"
  read -p "Which mode is your favourite? (1/2/3/4):" epp_selection
  case "${epp_selection}" in
    1)
    # Change 20/80/90/92 to C0, max power saving

    # change 657070000000000000000000000000000000000080 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000080 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:DAAAAAAAAAAAAAAAAAAAAAd:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000092 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000090 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000092 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000080 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000020 to 6570700000000000000000000000000000000000c0
    /usr/bin/sed -i "" "s:AgAAAAAAAAAAAAAAAAAAAAd:DAAAAAAAAAAAAAAAAAAAAAd:g" $BOARD_ID.plist
    ;;

    2)
    if [ "${support}" == 2 ] && [ "${lfm_selection}" == 1 ]; then
      # Keep default 80/90/92, balance power
      # if also no changes for lfm, exit
      echo "It's nice to keep the same, see you next time."
      echo
      clean
      exit 0

    # Deal with EPP_SUPPORTED_MODELS_SPECIAL
    elif [ "${support}" == 3 ]; then
      # Change 20 to 80, balance performance

      # change 657070000000000000000000000000000000000020 to 657070000000000000000000000000000000000080
      /usr/bin/sed -i "" "s:AgAAAAAAAAAAAAAAAAAAAAd:CAAAAAAAAAAAAAAAAAAAAAd:g" $BOARD_ID.plist
    fi
    ;;

    3)
    if [ "${support}" == 2 ]; then
      # Change 80/90/92 to 40, balance performance

      # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

      # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:BAAAAAAAAAAAAAAAAAAAAAd:g" $BOARD_ID.plist

      # change 657070000000000000000000000000000000000092 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

      # change 657070000000000000000000000000000000000090 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

      # change 657070000000000000000000000000000000000092 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" $BOARD_ID.plist

      # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000040
      /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" $BOARD_ID.plist

    elif [ "${support}" == 3 ] && [ "${lfm_selection}" == 1 ]; then
      # Keep default 20, balance performance
      # if also no changes for lfm, exit
      echo "It's nice to keep the same, see you next time."
      echo
      clean
      exit 0
    fi
    ;;

    4)
    # Change 20/80/90/92 to 00, performance

    # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:AAAAAAAAAAAAAAAAAAAAAAd:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000092 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000090 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000092 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000080 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" $BOARD_ID.plist

    # change 657070000000000000000000000000000000000020 to 657070000000000000000000000000000000000000
    /usr/bin/sed -i "" "s:AgAAAAAAAAAAAAAAAAAAAAd:AAAAAAAAAAAAAAAAAAAAAAd:g" $BOARD_ID.plist
    ;;

    *)
    echo "ERROR: Invalid input, closing the script"
    exit 1
    ;;
  esac
}

# Generate CPUFriendDataProvider.kext and move to desktop
function generateKext(){
  echo "Generating CPUFriendDataProvider.kext"
  ./ResourceConverter.sh --kext $BOARD_ID.plist
  cp -r CPUFriendDataProvider.kext /Users/`users`/Desktop/

  # Copy CPUFriend.kext to Desktop
  cp -r CPUFriend.kext /Users/`users`/Desktop/

  echo "Generate complete"
  echo
}

# Delete tmp folder and end
function clean(){
  echo "Cleaning tmp files"
  sudo rm -rf "${WORK_DIR}"
  echo "Clean complete"
  echo
}

# Main function
function main(){
  printHeader
  checkBoardID
  getGitHubLatestRelease
  downloadKext
  if [ "${support}" == 1 ]; then
    copyPlist
    changeLFM
  elif [ "${support}" == 2 ] || [ "${support}" == 3 ]; then
    copyPlist
    changeLFM
    echo
    changeEPP
  fi
  echo
  generateKext
  clean
  echo "Great! This is the end of the script, please copy CPUFriend and CPUFriendDataProvider from desktop to /CLOVER/kexts/Other/(or /Library/Extensions/)"
  exit 0
}

main
