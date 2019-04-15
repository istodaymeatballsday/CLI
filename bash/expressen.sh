#!/usr/bin/env bash
# - - - - Description - - - -
# outputs Chalmers expressen lunch in terminal, highlights 'Köttbullar'


# - - - - How to install - - - -
# $ chmod +x ./expressen.sh <# days from today>


# - - - - How to run - - - -
# $ ./expressen.sh <# days from today>

# sets the current dir to the one the script in run in. This makes in path independent
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

#optional: download jq library for linux/mac and replace ./jq-
get_expressen_data() {
    # idealy this script would be just inline text here
    expressen_data=$(curl -s $url | python ../nice.py)
}

#expressen api
expressen_api_url() {
    # why have api as a variable and not just a long string?
    # i.e.  http://carbonateapiprod.azurewebsites.net/api/v1/mealprovidingunits/3d519481-1667-4cad-d2a3-08d558129279/dishoccurrences
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
    
    # since the date command works differently on the different environments this is necessary
    local today=$(date +'%Y-%m-%d')
    #linux
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        #number of days from today
        local end_date=$(date -d "$today+$1 days" +'%Y-%m-%d')
        #mac
        elif [[ "$OSTYPE" == "darwin"* ]]; then
        #number of days from today
        local end_date=$(date -v+$1d +'%Y-%m-%d')
    fi
    
    
    # api
    expressen_api_url
    local url=''$url'?startDate='$today'&endDate='$end_date''
    
    #get data
    get_expressen_data "$1"
    local data=$expressen_data
    if [ -z "$data" ]; then
        echo -e "\nNo data\n"
        return 0
    fi
    echo $data
    
    # #store data in array
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