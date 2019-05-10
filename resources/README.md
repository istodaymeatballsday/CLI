## Description
Gets, maps, sorts & outputs Chalmers Expressen lunch menu in terminal & highlights *Köttbullar* as default) from Chalmers Expressen lunch [api](https://chalmerskonferens.se/en/api/). 

<img src="gif-sh-1.gif" width="640">
<img src="gif-sh-2.gif" width="640">

## Get jq
Alt 1
1. Install jq
```
$ sudo apt-get install jq
```

Alt 2
1. Download jq
```
$ wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
```
2. Make script executable
```
$ sudo chmod +x ./jq-linux64.sh 
```
1. Replace `jq` with `./jq-linux64` in [*expressen.sh*](../bash/expressen.sh)


## How to run
1. Make script executable
```
$ sudo chmod +x ./expressen.sh 
```

2. Run script
```
$ ./expressen.sh $1 $2 $3
```
- `$1`
  -  *optional* 
  -  #days from today
     -  input `0-9`, default is today's menu
- `$2` 
  - *optional*
  - requires `$1`
  - language
    - input `en` for English menu, default is Swedish
- `$3` 
  - *optional*
  - requires `$2`
    - input `en` or `a-z` for Swedish
  - ingredient to highlight
    - input `a-z`
      - example
        - potatis
        - rice
    - case insensitive
    - exact match (whole word only)
      - if input is "potatis", it will match "potatis" and not "potatismos"