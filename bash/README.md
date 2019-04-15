## Description
Outputs Chalmers expressen lunch in terminal & highlights "Köttbullar". 

### Linux > macOS
Does NOT work for macOS ATM --> Use optional installation instead until further notice.

## How to install
```
$ sudo chmod +x ./expressen.sh <# days from today>
```

## How to run
```
$ ./expressen.sh <# days from today>
```

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
1. Remove first 20 lines of code in [expressen.sh](expressen.sh) 
2. Replace `$jq` with `jq` in `get_expressen_data()` function