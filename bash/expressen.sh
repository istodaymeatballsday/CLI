#get jq filename
jq=$(find . -maxdepth 1 -name "*jq*")

#check if jq is downloaded
if [ -z $jq ]; then
	#get os
	os=$OSTYPE

	echo "Downloading jq..."

	#linux
	if [[ "$os" == "linux-gnu" ]]; then		
		wget -q https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
	#mac
	elif [[ "$os" == "darwin"* ]]; then
		curl -o jq-osx-amd64 https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64
	fi

	echo -e "\nDownload complete\n"

	#get jq filename
	jq=$(find . -maxdepth 1 -name "*jq*")

	#trim jq filename and make file executable
	sudo chmod +x ${jq:2}
fi


#expressen data, standard lang: eng
#optional: download jq library for linux/mac and replace $jq with jq
get_expressen_data() {
	#get eng or swe menu
	lang=1
	if [ "$1" == "s" ]; then
		lang=0
	fi

	expressen_data=$(curl -s $url | $jq '.[] | .startDate, .displayNames['$lang'].dishDisplayName')
}

#expressen api
expressen_api_url() {
	local api='v1/mealprovidingunits/3d519481-1667-4cad-d2a3-08d558129279/dishoccurrences'
	url='http://carbonateapiprod.azurewebsites.net/api/'$api''
}

#return index if string contains 'MEATBALLS' or 'KöTTBULLAR' 
is_it_meatballs() {
	ingredient='MEATBALLS'
	if [ "$2" == "s" ]; then
		ingredient='KöTTBULLAR'
	fi

	local capital="$(echo "$1" | tr a-z A-Z)"
	index="$(echo "$capital" | grep -b -o "$ingredient" | awk 'BEGIN {FS=":"}{print $1}')"
}

#expressen menu 
#$1: £days from today
#$2: language swe/eng, default is swe
lunch() {
#number of days from today
local ndays=0

#check if input null 
if [ ! -z $1 ]; then
	ndays=$1

	#check if input digit or negative
	if ! [[ "$1" =~ ^[0-9]*$ ]] || [ $1 -lt 0 ]; then
		echo -e "\nInvalid input\n"
		return 0
	fi

fi

local today=$(date +'%Y-%m-%d')
local end_date=$(date -d "$today+$ndays days" +'%Y-%m-%d')

#api
expressen_api_url
local url=''$url'?startDate='$today'&endDate='$end_date''

#get data
get_expressen_data "$2"
local data=$expressen_data
if [ -z "$data" ]; then
	echo -e "\nNo data\n"
	return 0
fi
	
#store data in array
IFS=$'\n' read -r -a arr -d '' <<< "$data"

local length=${#arr[@]}
local temp=''
#data is stored: [date0, meat0, date0, veg0, date1, meat1, date1, veg1, ...]
for ((i=0; i<$length; i+=2))
do
	#trim citation
	local date=${arr[i]:1:-1}
	local food=${arr[$((i+1))]:1:-1}

if [ "$date" != "null" ] && [ "$food" != "null" ]; then
	if [ "$date" != "$temp" ]; then
		if [ "$2" == "s" ]; then
			#swedish
			echo -e "\n\e[1m\e[32m$(LC_TIME=sv_SE.utf-8 date --date "$date" +'%A')\e[0m:"
		else
			#english
			echo -e "\n\e[1m\e[32m$(date --date "$date" +'%A')\e[0m:"
		fi

		temp=$date
	fi

	#is it meatballs?
	is_it_meatballs "$food" "$2"
	index=$index
	end="$(echo "$ingredient" | awk '{print length}')"
	
	if [[ ! -z "$index" ]]; then
		echo -e "\e[39m\e[5m${food:$index:$end}\e[0m${food:10}"
	else
		echo -e "$food"
	fi
fi
done
echo -e ""
}

#executes function with input:
# $1: '#days from today'
# $2: 'language', e for english, s for swedish
# default is 0 days and english
lunch $1 $2