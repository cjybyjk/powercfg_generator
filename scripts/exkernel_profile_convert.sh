#!/bin/sh
basepath=$(cd $(dirname $0); pwd)/../
source $basepath/scripts/util_functions.sh
init
get_soc_info

$text_editor ./perf_text

if $is_big_little ; then
	sed -i "s#.*$cluster_0.*interactive\/\([a-zA-Z_]*\) #\1=big=#g" ./perf_text
	sed -i "s#.*$cluster_1.*interactive\/\([a-zA-Z_]*\) #\1=little=#g" ./perf_text
else
	sed -i "s#.*interactive\/\([a-zA-Z_]*\) #\1=#g" ./perf_text
fi
echo -e "\n" >> ./perf_text

echo "完成!"
pause
