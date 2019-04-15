# - - - - Description - - - -
# script to get Chalmers expressen lunch
# highlights 'Köttbullar'

# - - - - How to run - - - -
# execute command below to copy code into bash file:
# $ sudo chmod +x my_script.sh && . expressen.sh <path to bash file>

# execute command below to call function
# $ lunch <number of days from today>

#path to bash
local path=$1

#get os
local os=$OSTYPE

#linux
if [[ "$os" == "linux-gnu" ]]; then
	sudo apt-get install jq
#mac
elif [[ "$os" == "darwin"* ]]; then
	sudo brew install jq
fi

#copy code to bash file
echo -e "\n\n" >> $path
cat >> $path << 'EOF'
#expressen data
get_expressen_data() {
	expressen_data=$(curl -s $url | jq '.[] | .startDate, .displayNames[0].dishDisplayName')
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
EOF

#reload bash
if [[ "$os" == "linux-gnu" ]]; then
	. $path
elif [[ "$os" == "darwin"* ]]; then
	. $path
fi