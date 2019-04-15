#get jq-filename
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

	#get and trim jq-filename
	jq=$(find . -maxdepth 1 -name "*jq*")
	sudo chmod +x ${jq:2}
fi


#expressen data
#optional: download jq library for linux/mac and replace $jq with jq
get_expressen_data() {
	expressen_data=$(curl -s $url | $jq '.[] | .startDate, .displayNames[0].dishDisplayName')
}

#expressen api
expressen_api_url() {
	local api='v1/mealprovidingunits/3d519481-1667-4cad-d2a3-08d558129279/dishoccurrences'
	url='http://carbonateapiprod.azurewebsites.net/api/'$api''
}

#return index if string contains 'KöTTBULLAR' 
is_it_meatballs() {
	local capital="$(echo "$1" | tr a-z A-Z)"
	index="$(echo "$capital" | grep -b -o 'KöTTBULLAR' | awk 'BEGIN {FS=":"}{print $1}')"
}

#expressen menu
lunch() {
#check if input null or digit or negative
if [ -z $1 ] || ! [[ "$1" =~ ^[0-9]+$ ]] || [ $1 -lt 0 ]; then
	echo -e "\nInvalid input\n"
	return 0
fi

local today=$(date +'%Y-%m-%d')

#number of days from today
local end_date=$(date -d "$today+$1 days" +'%Y-%m-%d')

#api
expressen_api_url
local url=''$url'?startDate='$today'&endDate='$end_date''

#get data
get_expressen_data "$1"
local data=$expressen_data
if [ -z "$data" ]; then
	echo -e "\nNo data\n"
	return 0
fi
	
#store data in array
IFS=$'\n' read -r -a arr -d '' <<< "$data"

local length=${#arr[@]}
local temp=''
#data is stored: [date, meat, veg, ...]
for ((i=0; i<$length; i+=2))
do
	#trim citation
	local date=${arr[i]:1:-1}
	local food=${arr[$((i+1))]:1:-1}

if [ "$date" != "null" ] && [ "$food" != "null" ]; then
	if [ "$date" != "$temp" ]; then
		echo -e "\n\e[1m\e[32m$(date --date "$date" +'%A')\e[0m:"
		temp=$date
	fi

	#is it meatballs?
	is_it_meatballs "$food"
	index=$index
	if [[ ! -z "$index" ]]; then
		echo -e "\e[39m\e[5m${food:$index:10}\e[0m${food:10}"
	else
		echo -e "$food"
	fi
fi
done
echo -e ""
}

#executes function with input $1 as '# of days from today'
lunch $1