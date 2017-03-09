#!/usr/bin/env bash
#  will unzip and scrape all information inside pptx
#  checkData
#  USAGE: ./runScrape.bash  -d "output" -f "<rscript to run>" -c "<cond>"
#   -d) Which directory to unzip and enter into
#   -f) Which Rscript to run
#   -c) Conditions run into R|php script
#
#  Created by Serdar Akin on 2017-03-01.
#USAGE ./runScrape.bash -u -d 2016-12-21.zip
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
## Global
HOMES="$PWD"
SRC="${HOMES}/src"
_UNZIPTO="${HOMES}/DATASET"
_FULLPATH=""
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



######################################################################
## USAGE extractFile <full path>
## args1 <full path> Where the unzip happend to
## test : extractFile "${_UNZIPTO}/${noExtenstion}"
######################################################################
extractFile(){
	local args=("$@")
	local path="${args[0]}"
    local array=()
	local dirs=() ## where the fullpath is located
    local _REPLY=''
    local REPLY=''
    local tmpFile="tmp.txt"
    local tmp=pptx=''


	while IFS= read -r -d '' file; do
		# single filename is in $file
		echo "file is ${file}"
		_REPLY=$(echo "${file}" | tr '[:space:]' '_')
		 mv -i "${file}" "${_REPLY%?}"
		array+=("${_REPLY%?}")

	done < <(find . -name '*.*pptx' -type f -print0)


    for pptx in "${array[@]}"
    do
        tmp="${pptx%.pptx}"
        unzip "${pptx}" -d "${pptx%.pptx}"
		## rm the ./ infront of tmp
		dirs+=("${path}/${tmp/\.\//}")
    done
    echo "${dirs[@]}"
} ## end of function


######################################################################
## USAGE renameRels <dirs where change happen>
## args1 <dirs> Where the unzip happend to
## test : renameRels <dir> <dirTofilesForRename>
##renameRels <dir> charts
######################################################################
renameRels(){
	local args=("$@")
	local i
	local z
	local path="${args[0]}"
	local dirs="${args[@]:1}" # extract all but the first


	step1=($(find "${path}" -iname "${i}*rels" -type f))
	for z in "${step1[@]}"
	do
		mv "$z" "${z/\.rels/}"
	done


}

######################################################################
## USAGE extractZIP "zip file"
## extract the zip and places it into $_UNZIPTO dir
######################################################################

extractZIP(){
## shoud be zip file, must be from $1, $0 is the bash file
	local args="$1"
	local Extension=${args##*.}
	[ "${Extension}" == "zip" ] || exit 1
	local noExtenstion=${args%%.$Extension}
	local toUpperExtension=$(echo "${Extension}" | tr '[:lower:]' '[:upper:]')
	_FULLPATH="${_UNZIPTO}/${noExtenstion}"
	if [ "$update" = "yes" ]
	then
		seq  -f "-" -s '' 60
		printf "\n${RED}Ta bort mapp om den återfinns i systemet ${NO_COLOUR} \n"
		seq  -f "-" -s '' 60

		find "${_UNZIPTO}"  -mindepth 1 -maxdepth 1 | xargs rm -rf

	fi
	unzip "${args}" -d "${_UNZIPTO}"
}


######################################################################
## USAGE runR
######################################################################
runR(){
	local args=("$@")
	cd "${SRC}"
	ls -las
	./main.R "${args[0]}"
} ## end of function
######################################################################


######################################################################
# main function
######################################################################

main() {
	local args=("$@")
	extractZIP "${args[0]}"
	## If dont exist then take the fill path
	local _path="${_FULLPATH}"
	cd "${_FULLPATH}"

	## Which ddirectory that should be cleand from rels suffixe
	declare -a fileDir=(slide chart)
	local locationToDir=()
## make pptx files to unzipped dirs
	extractFile "${_path}"



	## Locate all the dir that have been unziped
	locationToDir=($(find . -maxdepth 1 -type d))
	if [ "${#locationToDir[@]}" -gt 0 ]; then
	for dir in "${locationToDir[@]}"
	do
		seq  -f "-" -s '' 60
		printf "\nGoing to run dir %s\n" "$dir"


		#step=($(renameRels "$dir" "slide" "chart" ))
		for ff in "${fileDir[@]}"
		do
			seq  -f "-" -s '' 60
			printf "\nFile dir  %s\n" "$ff"
			renameRels "$dir" "$ff"

			seq  -f "-" -s '' 60

		done

		seq  -f "-" -s '' 60
	done
	else
		echo empty
	exit 1
	fi

	cd "${_UNZIPTO}"
	echo "$_FULLPATH"
	ls -las
	runR "$_FULLPATH"
} ## end of main


######################################################################


DIR=${DIR:-"2016-12-21.zip"}


main "${DIR}"

