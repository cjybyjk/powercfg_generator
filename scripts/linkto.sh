#!/bin/sh

basepath="$1"

rm -rf $basepath/project/platforms/$2
mkdir -p $basepath/project/platforms/$2
echo "$3" > $basepath/project/platforms/$2/linkto
echo "This platform is $2, but using $3's powercfg script." > $basepath/project/platforms/$2/NOTICE

echo "linkto: $3 <- $2 "

exit 0
