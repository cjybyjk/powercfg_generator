#!/bin/sh

basepath=$(cd $(dirname $0); pwd)/../
source $basepath/scripts/util_functions.sh
init
prjPath="$basepath/projects/$project_id/platforms/"

read -p "输入源SoC:" sourceSoC
[ -z "$sourceSoC" ] && echo "输入不能为空!" && return
read -p "输入目标SoCs(使用空格分割):" targetSoC
[ -z "$targetSoC" ] && echo "输入不能为空!" && return
target_socs=($targetSoC)
for i in ${!target_socs[@]}
do
    mkdir -p $prjPath/${target_socs[$i]}
    echo "$sourceSoC" > $prjPath/${target_socs[$i]}/linkto
    echo "This platform is ${target_socs[$i]}, but using ${sourceSoC}'s powercfg script." > $prjPath/${target_socs[$i]}/NOTICE
    echo "linkto: $sourceSoC <- ${target_socs[$i]} "
done

pause
exit 0
