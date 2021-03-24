#!/bin/bash

expressen() {
	#osx
	if [[ "$OSTYPE" == "darwin"* ]]; then
		JQ='jq-osx-amd64'
	#linux
	else
		JQ='./jq-linux64'
	fi
	local num_of_days=0
	#set language
	if equals $2 en; then
		lang='en_US.utf8'
	else
		lang='sv_SE.utf-8'
	fi

	if ! is_empty $1; then
		if ! is_digit $1 || is_negative $1; then
			echo -e "\nINVALID INPUT\n"
			return 0
		fi
		num_of_days=$(($1 - 1))
	fi

	local start_date=$(date +'%Y-%m-%d') # '2019-04-01' for testing
	local end_date=$(date -d "$start_date+$num_of_days days" +'%Y-%m-%d')
	#api url
	local url=$(API)
	#init colors etc.
	DEFAULT='\e[0m'
	BOLD='\e[1m'
	BLINK='\e[39m\e[5m'
	GREEN='\e[32m'

	echo -e ${GREEN}${BOLD}'[INFO]'${DEFAULT}' FETCHING DATA...'

	get_data $2
	if is_empty $raw_data; then
		echo -e "\nNO DATA\n"
		return 0
	fi
	#store data in array
	to_array
	#map food to formatted dates in order to sort by date
	declare -A local parsed_data
	parse_data
	#sort data because of shitty json
	IFS=';'
	read -r -a sorted -d '' <<<"$(
		for key in "${!parsed_data[@]}"; do
			printf "%s\n" "$key ${parsed_data[$key]}"
		done | sort -k1
	)"
	unset IFS
	#print data
	print $2 $3
}

get_data() {
	#0 is Swedish menu
	local arg=0
	if equals $1 en; then
		arg=1
	fi

	raw_data=$(
		curl -s $url | $JQ -r '.[] | 
		.startDate, .displayNames['$arg'].dishDisplayName'
	)
}

#expressen API
API() {
	local hostname='http://carbonateapiprod.azurewebsites.net/'
	local key='3d519481-1667-4cad-d2a3-08d558129279'
	local api='api/v1/mealprovidingunits/'$key'/dishoccurrences'
	echo ''$hostname''$api'?startDate='$start_date'&endDate='$end_date''
}

#date is stored as '4/23/2019 12:00:00 AM', which is a not valid format
#+ makes it tricky to read data into array
to_array() {
	#IFS (Internal Field Separator), used to determine characters
	IFS=$'\n'
	#store data in array
	read -r -a data -d '' <<<"$raw_data"
	#reset back to DEFAULT value
	unset IFS
}

parse_data() {
	local -r date_format='+%Y-%m-%d'
	local length=${#data[@]}

	for ((i = 0; i < $length; i += 2)); do
		local date=${data[i]}
		local dish=${data[$((i + 1))]}
		local fdate=$(date --date "$date" $date_format)
		local prev=${parsed_data[$fdate]}

		#store dates as keys mapping to dishes
		if is_empty $prev; then
			parsed_data+=([$fdate]=";$dish;")
		else
			parsed_data[$fdate]="$prev$dish;"
		fi
	done
}

print() {
	local length=${#sorted[@]}
	for ((i = 0; i < $length; i += 1)); do
		local param=${sorted[i]}

		if is_date $param; then
			local day=$(LC_TIME=$lang date --date "$param" +'%a')
			echo -e "\n${BOLD}${GREEN}${day}${DEFAULT}"

		elif ! is_empty $param; then
			find_match $1 $2

			if ! is_empty $index; then
				print_dish
			else
				echo $param
			fi
		fi
	done
	echo ""
}

#return index of ingredients
find_match() {
	if ! is_digit $2 || ! is_empty $2; then
		ingredient=$2
	else
		if equals $1 en; then
			ingredient="meatballs"
		else
			ingredient="köttbullar"
		fi
	fi

	local match="\"\\\b$ingredient\\\b\"; \"i\""
	index=$(echo \"$param\" | $JQ "match($match).offset")
}

print_dish() {
	local end_dish=$(echo $ingredient | $JQ -R "length")
	local end=$(($index + $end_dish))

	local head="${param:0:$index}"
	local body="${BLINK}${param:$index:$end_dish}"
	local tail="${DEFAULT}${param:$end}"

	echo -e "${head}${body}${tail}"
}

equals() {
	[ "$1" == "$2" ]
}

is_empty() {
	[ -z "$1" ]
}

is_digit() {
	[[ "$1" =~ ^[0-9]*$ ]]
}

is_negative() {
	[ $1 -lt 0 ]
}

is_date() {
	[[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] &&
		date -d "$1" >/dev/null
}

expressen $1 $2 $3
