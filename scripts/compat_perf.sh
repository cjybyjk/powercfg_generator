#!/bin/sh

basepath=$(cd $(dirname $0); pwd)/../
source $basepath/scripts/util_functions.sh
init
get_soc_info

$text_editor ./perf_text

sed -i 's/:/：/g' ./perf_text
sed -i 's/： /：/g' ./perf_text
sed -i 's/：：/：/g' ./perf_text
sed -i 's/\([0-9]\)：\([0-9]\)/\1:\2/g' ./perf_text
sed -i 's/big：/\nbig：/g' ./perf_text
sed -i 's/little：/\nlittle：/g' ./perf_text
sed -i '/^\s*$/d' ./perf_text
sed -i 's/省电/[powersave]/g' ./perf_text
sed -i 's/均衡/[balance]/g' ./perf_text
sed -i 's/性能/[performance]/g' ./perf_text
sed -i 's/低延迟/[fast]/g' ./perf_text
sed -i 's/：/=/g' ./perf_text
echo -e "\n" >> ./perf_text

echo "完成!"
pause
