#!/bin/bash

#expressen menu
#$1: <#days from today>
#$2: <language> (en for English, DEFAULT is Swedish)
lunch() {
	#number of days from today
	local ndays=0

	#set language
	local lang='sv_SE.utf-8'
	if equals $2 en; then
		lang='en_US.utf8'
	fi

	if ! isempty $1; then
		if ! isdigit $1 || isnegative $1; then
			echo -e "\nInvalid input\n"
			return 0
		fi
		ndays=$1
	fi

	local today=$(date +'%Y-%m-%d')
	local todate=$(date -d "$today+$ndays days" +'%Y-%m-%d')

	#api url
	local url=$(expressen_url)

	#get data
	expressen_data $2
	if isempty $rawdata; then
		echo -e "\nNo data\n"
		return 0
	fi

	#store data in array
	toarray

	#map food to formatd dates in order to sort by date
	declare -A local newdata
	format

	#sort data because of shitty json
	IFS=';'
	read -r -a sorted -d '' <<<"$(
		for key in "${!newdata[@]}"; do
			printf "%s\n" "$key ${newdata[$key]}"
		done | sort -k1
	)"
	unset IFS

	#init colors etc.
	style

	#print data
	print $2 $3
}

expressen_data() {
	#0 is Swedish menu
	local arg=0
	if equals $1 en; then
		arg=1
	fi

	rawdata=$(
		curl -s $url | jq -r '.[] | 
		.startDate, .displayNames['$arg'].dishDisplayName'
	)
}

#expressen api
expressen_url() {
	local hostname='http://carbonateapiprod.azurewebsites.net/'
	local key='3d519481-1667-4cad-d2a3-08d558129279'
	local api='api/v1/mealprovidingunits/'$key'/dishoccurrences'
	echo ''$hostname''$api'?startDate='$today'&endDate='$todate''
}

#date is stored as '4/23/2019 12:00:00 AM', which is a not valid format
#+ makes it tricky to read data into array
toarray() {
	#IFS (internal field separator) variable is used to determine what characters
	#+ bash defines as words boundaries when processing character strings.
	IFS=$'\n'

	#store data in array
	read -r -a data -d '' <<<"$rawdata"

	#reset back to DEFAULT value
	unset IFS
}

format() {
	local -r dateformat='+%Y-%m-%d'
	local length=${#data[@]}
	for ((i = 0; i < $length; i += 2)); do

		local date=${data[i]}
		local dish=${data[$((i + 1))]}
		local formated=$(date --date "$date" $dateformat)
		local prev=${newdata[$formated]}

		#store dates as keys mapping to dishes
		if isempty $prev; then
			newdata+=([$formated]=";$dish;")
		else
			newdata[$formated]="$prev$dish;"
		fi
	done
}

print() {
	local length=${#sorted[@]}
	for ((i = 0; i < $length; i += 1)); do
		local wildcard=${sorted[i]}

		if isdate $wildcard; then
			local day=$(LC_TIME=$lang date --date "$wildcard" +'%a')
			echo -e "\n${BOLD}${GREEN}${day}${DEFAULT}"

		elif ! isempty $wildcard; then
			is_it_ingredient $1 $2

			if ! isempty $index; then
				printdish
			else
				echo $wildcard
			fi
		fi
	done
	echo ""
}

#return index of ingredients
is_it_ingredient() {
	ingredient="köttbullar"
	if equals $1 en; then
		ingredient="meatballs"
	fi

	if ! isdigit $2 || ! isempty $2; then
		ingredient=$2
	fi

	local param="\"\\\b$ingredient\\\b\"; \"i\""
	index=$(echo \"$wildcard\" | jq "match($param).offset")
}

printdish() {
	local dishend=$(echo $ingredient | jq -R "length")
	local end=$(($index + $dishend))

	local head="${wildcard:0:$index}"
	local body="${BLINK}${wildcard:$index:$dishend}"
	local tail="${DEFAULT}${wildcard:$end}"

	echo -e "${head}${body}${tail}"
}

style() {
	DEFAULT='\e[0m'
	BOLD='\e[1m'
	BLINK='\e[39m\e[5m'
	GREEN='\e[32m'
}

equals() { [ "$1" == "$2" ]; }

isempty() { [ -z "$1" ]; }

isdigit() { [[ "$1" =~ ^[0-9]*$ ]]; }

isnegative() { [ $1 -lt 0 ]; }

isdate() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] &&
	date -d "$1" >/dev/null; }

lunch $1 $2 $3
