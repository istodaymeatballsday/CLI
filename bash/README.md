## Description
Outputs Chalmers expressen lunch in terminal & highlights "Meatballs" or "Köttbullar". 

### Linux > macOS
Does NOT work for macOS ATM --> Use optional installation instead until further notice.

## How to install
```
$ sudo chmod +x ./expressen.sh
```

## How to run
```
$ ./expressen.sh $1 $2
```
- `$1`
  -  *optional* 
  -  #days from today
     -  input `0-9`, default is today's menu
- `$2` 
  - *optional*
  - language
    - input `s` for swedish menu, default is english

## Optional installation
1. Download jq library for Linux/macOS:
### macOS
```
$ brew install jq
```
### Linux
```
$ sudo apt-get install jq
```
1. Remove first 26 lines of code in [expressen.sh](expressen.sh) 
2. Replace `$jq` with `jq` in `get_expressen_data()` function