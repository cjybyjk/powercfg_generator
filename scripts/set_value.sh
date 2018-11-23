#!/bin/sh

function set_value() {
	echo "$2" > $basepath/configs/$1
	get_values
}

[ ! -d $basepath/configs ] && mkdir $basepath/configs

function get_values() {
	for param in $(ls $basepath/configs/)
	do
		read "$param" < $basepath/configs/$param
	done
}

