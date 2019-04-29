#!/bin/bash

#expressen menu
#$1: <#days from today>
#$2: <language> (en for English, default is Swedish)
lunch() {
	#number of days from today
	local ndays=0

	local lang='sv_SE.utf-8'
	if equals $2 en; then
		lang='en_US.utf8'
	fi

	#check if input null
	if ! isempty $1; then

		#check if input digit or negative
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

	#init colors etc.
	style

	declare local index
	declare local end
	declare local tempdate
	local length=${#data[@]}

	#data is stored: [date0, meat0, date0, veg0, date1, meat1, date1, veg1, ...]
	#+ because of shitty json
	for ((i = 0; i < $length; i += 2)); do

		local date=${data[i]}
		local food=${data[$((i + 1))]}

		if isvalid "$date" "$food"; then
			if ! equals "$date" "$tempdate"; then

				day=$(LC_TIME=$lang date --date "$date" +'%a')
				echo -e "\n${bold}${green}${day}${default}"

				tempdate=$date
			fi

			is_it_meatballs $2
			if ! isempty $index; then

				end="$(echo $ingredient | awk '{print length}')"
				echo -e "${blink}${bold}${orange}${food:$index:$end}${default}${food:$end}"
			else
				echo -e "$food"
			fi
		fi
	done

	echo -e ""
}

#expressen data, default language: SV
expressen_data() {
	#get SV or EN menu
	local arg=0
	if equals $1 en; then
		arg=1
	fi

	#sort because of shitty json
	rawdata=$(curl -s $url | jq -r 'sort_by(.startDate) |
	 (.[] | .startDate, .displayNames['$arg'].dishDisplayName)')
}

#expressen api
expressen_url() {
	local hostname='http://carbonateapiprod.azurewebsites.net/'
	local api='api/v1/mealprovidingunits/3d519481-1667-4cad-d2a3-08d558129279/dishoccurrences'
	echo ''$hostname''$api'?startDate='$today'&endDate='$todate''
}

#return index if string contains 'MEATBALLS' or 'KöTTBULLAR'
is_it_meatballs() {

	ingredient='KöTTBULLAR'
	if equals $1 en; then
		ingredient='MEATBALLS'
	fi

	local capital="$(echo $food | tr a-z A-Z)"
	index="$(echo $capital | grep -b -o $ingredient | awk 'BEGIN {FS=":"}{print $1}')"
}

#date is stored as '4/23/2019 12:00:00 AM' in shitty json,
#+ which is a not valid format
toarray() {
	#IFS (internal field separator) variable is used to determine what characters
	#+ bash defines as words boundaries when processing character strings.
	IFS=$'\n'

	#store data in array
	read -r -a data -d '' <<<"$rawdata"

	#reset back to default value
	unset IFS
}

style() {
	default='\e[0m'
	bold='\e[1m'
	blink='\e[39m\e[5m'
	green='\e[32m'
	orange='\e[38;5;208m'
}

equals() {
	[ "$1" == "$2" ]
}

isempty() {
	[ -z "$1" ]
}

isdigit() {
	[[ "$1" =~ ^[0-9]*$ ]]
}

isnegative() {
	[ $1 -lt 0 ]
}

isvalid() {
	[ "$1" != "null" ] && [ "$2" != "null" ]
}

lunch $1 $2
