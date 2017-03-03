#!/usr/bin/env bash
#  will unzip and scrape all information inside pptx
#  checkData
#  USAGE: ./runPrepoint.bash  -d "output" -f "<rscript to run>" -c "<cond>"
#   -d) Which directory to unzip and enter into
#   -f) Which Rscript to run
#   -c) Conditions run into R|php script
#
#  Created by Serdar Akin on 2017-03-01.
#USAGE ./runPrepoint.bash -u -d 2016-12-21.zip
#



#------------------------------------------------------------
# Function needed to enable the analysis
#------------------------------------------------------------
PATH=$PATH:/usr/bin
GREEN="\033[0;32m"
NO_COLOUR="\033[0m"
RED="\033[1;31m"
BLUE="\033[0;34m"
LIGHT_BLUE="\033[1;34m"
PURPLE="\033[1;35m"
BLACK="\033[1;30m"
Rpath=$(which Rscript);
RR="${Rpath} --verbose"

#------------------------------------------------------------
# Parse command line options/arguments
#------------------------------------------------------------
if (! getopts "hfu:d:c:" name); then
echo "Usage: ${0##*/} script,-h for help"
exit $E_OPTERROR
fi

while getopts huf:d:c: option
do
case ${option} in
    h) usage;
    exit;;
    v) version;
    exit ;;
    f) Rfile="$OPTARG"
    ;;
    u) update="yes"
    ;;
    c) cond="$OPTARG"
    ;;
    d) DIR="$OPTARG" ## Returns the argumen
    ;;
    \?) Syntax;
    alert "${scriptname}: usage: [-m ], [-d <dataDir>], [-f <Rfile> ] [-c <condition>]"
    exit 2
    ;;
esac
done
shift "$(( OPTIND - 1 ))"

_DIR=$(find . -iname '*.*zip')
argum=${DIR:=_DIR}
## Find the extension
Extension=${argum##*.}
noExtenstion=${argum%%.$Extension}
toUpperExtension=$(echo "${Extension}" | tr '[:lower:]' '[:upper:]')



## And whitout extension
_UNZIPTO="${toUpperExtension}_${noExtenstion}"
if [ "$update" = "yes" ]
then
    seq  -f "-" -s '' 60
    printf "\n${RED}Ta bort mapp om den återfinns i systemet ${NO_COLOUR} \n"
    seq  -f "-" -s '' 60
    test -d "${_UNZIPTO}" && rm -r "${_UNZIPTO}"
fi
mkdir -p "${_UNZIPTO}"
unzip "${argum}" -d "${_UNZIPTO}"
test -d "${_UNZIPTO}/${noExtenstion}" && cd "${_UNZIPTO}/${noExtenstion}"
######################################################################
## USAGE extractFile
######################################################################
extractFile(){
    local array=()
    local dirs=()
    local _REPLY=''
    local REPLY=''
    local tmpFile="tmp.txt"
    local tmp=pptx=''

    find . -name '*.*pptx' -type f -print0 > "${tmpFile}"
    while IFS=  read -r -d $'\0'
    do
    ## make all space to underscore
    _REPLY=$(echo "${REPLY}" | tr '[:space:]' '_')
    ## last character is underscore, before rm take that away
    ## from end %?
    mv -i "${REPLY}" "${_REPLY%?}"
    array+=("${_REPLY%?}")
    done < "${tmpFile}"

    for pptx in "${array[@]}"
    do
        tmp="${pptx%.pptx}"
        unzip "${pptx}" -d "${pptx%.pptx}"
        dirs+=("${tmp}")
    done
    echo "${dirs[@]}"
} ## end of function
######################################################################




######################################################################
# main function
######################################################################

main() {
## Call the functions and get the output from the func
dirs1=($(extractFile))
	if [ "${#dirs1[@]}" -gt 0 ]; then
	for dir in "${dirs1[@]}"
	do
		echo "$dir"
	done
	else
		echo empty
	exit 1
	fi
} ## end of main


######################################################################



main "$@"

