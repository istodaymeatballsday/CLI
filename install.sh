#!/usr/bin/env bash

install_clunch () {
	export FILE="clunch"
	curl "https://raw.githubusercontent.com/istodaymeatballsday/CLI/master/python/clunch.py" > ~/$FILE
	chmod +x ~/$FILE
	sudo mv ~/$FILE /usr/local/bin
}

install_clunch
