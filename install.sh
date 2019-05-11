#!/usr/bin/env bash
install_express () {
	export FILE="express"
	curl "https://raw.githubusercontent.com/istodaymeatballsday/CLI/master/python/expressen.py" > ~/$FILE
	chmod +x ~/$FILE
	sudo mv ~/$FILE /usr/local/bin
}
install_express