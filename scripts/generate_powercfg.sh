#!/bin/sh

basepath=$(cd $(dirname $0); pwd)/../
source $basepath/scripts/util_functions.sh
init

function get_clusters()
{
	while read soctext
	do
		tmparr=(${soctext//:/ })
		if [ "${tmparr[1]}" = "$socModel" ]; then
			is_big_little="${tmparr[2]}"
			cluster_0="${tmparr[3]}"
			cluster_1="${tmparr[4]}"
			return 0
		fi
	done < $basepath/config/list_of_socs
	is_big_little=false
	yesNo "是否使用big.LITTLE架构" "y" && is_big_little=true
	cluster_0=$(readDefault "cluster0" "cpu0")
	$is_big_little && cluster_1=$(readDefault "cluster1" "cpu4")
	if [ yesNo "添加这个SoC到支持列表中"  "y" ]; then
		read -p "输入SoC代号(支持正则表达式):" socCodename
		echo "$socCodename:$socModel:$is_big_little:$cluster_0:$cluster_1" >> $basepath/config/list_of_socs
	fi
}

function getLikelyRank()
{
	local tmpRank=0
	local tmpL2R=0
	local tmpR2L=0
	local iMax=${#1}
	[ $iMax -gt ${#2} ] && iMax=${#2}
	let iMax=iMax-1
	for((i=0;i<=$iMax;i++));
	do
		l2r=$((i))
		r2l=$((i+1))
		if [ "${1:$l2r:1}" = "${2:$l2r:1}" ]; then
			let tmpL2R=tmpL2R+1
		elif [ "${1:0-$r2l:1}" = "${2:0-$r2l:1}" ]; then
			tmpR2L=$((tmpR2L+1))
		else
			break
		fi
	done
	tmpRank=$((tmpL2R*tmpL2R+tmpR2L*tmpR2L))
	echo $tmpRank
}

function check_timer_rate()
{
	local likelyRank=0
	local lkRankTmp
	local mostLikely
	while read allowed_timer_rate
    do 
		[ "$timer_rate" = "$allowed_timer_rate" ] && return 0
		lkRankTmp=$(getLikelyRank "$timer_rate" "$allowed_timer_rate")
		if [ $lkRankTmp -gt $likelyRank ]; then
			likelyRank=$lkRankTmp
			mostLikely="$allowed_timer_rate"
		fi
	done < $basepath/config/list_of_allowed_params
	echo "目标 \"$timer_rate\" 可能存在错误, 与它最相似的是 \"$mostLikely\""
	read -p "请在此进行修改(默认为 $mostLikely):" timer_rate <&3
	[ -z "$rightTimerRate" ] && timer_rate="$mostLikely"
}

function savemode()
{
	if [ "" != "$modeText" ]; then
		sed -i "s/# ${mode}_params/$modeText/g" powercfg
		modeText=""
		echo "$mode saved"
	fi
}

# 备份标准输入
exec 3<&0

read -p "输入SoC型号:" socModel
platformPath="$basepath/projects/$project_id/platforms/$socModel"
get_clusters
mkdir -p $platformPath
cd $platformPath
if [ -f "./linkto" ]; then
	rm ./linkto
	rm ./NOTICE
fi
cp $basepath/template/powercfg_template ./powercfg
$text_editor ./perf_text

mode="balance"
OLD_IFS="$IFS" 
IFS="="
while read lineinText
do 
	[ -z "$lineinText" ] && continue
	# cut string like [mode]
	modeTmp=${lineinText#[}
	modeTmp=${modeTmp%]}
	if [ "$lineinText" != "$modeTmp" ]; then
	    savemode
	    mode="$modeTmp"
	    echo "$mode start"
	    continue
	fi
	lineinText=${lineinText/\//\\\/}
	arrCmd=($lineinText)
	if [ "runonce" = "$mode" ] || [[ "$mode" =~ "modify" ]]; then
	    modeText=${modeText}"$lineinText\n	" 
	else
	    timer_rate="${arrCmd[0]}"
	    if [ "$timer_rate" = "big" ] || [ "$timer_rate" = "little" ]; then
		    timer_rate=$timer_rate_bak
		    cluster="${arrCmd[0]}" 
		    param="${arrCmd[1]}"
	    else
		    timer_rate_bak=$timer_rate
		    if [ "${arrCmd[1]}" != "big" ] && [ "${arrCmd[1]}" != "little" ] ; then
			    cluster="all"
			    [ "HMP" = "$mode" ] && cluster="HMP"
			    param="${arrCmd[1]}"
		    else
			    cluster="${arrCmd[1]}" 
			    param="${arrCmd[2]}"
		    fi
	    fi
	    param=`trim "$param"`
	    cluster=`trim "$cluster"`
	    timer_rate=`echo $timer_rate | tr -d '[ \t]'`
	    [ -z "$param" ] && continue
	    [ "HMP" != "$mode" ] && $param_allowance_check && check_timer_rate
	    [ "$timer_rate" = "target_loads" ] && [ "$cluster" = "little" -o ! $is_big_little ] && sed -i "s/(${mode}_tload)/$param/g" powercfg
	    [[ "$param" =~ " " ]] && param="\"$param\""
	    modeText=${modeText}"set_param_$cluster $timer_rate $param\n	" 
	fi
done < ./perf_text
savemode
IFS="$OLD_IFS"

# 写入相关信息
sed -i "s/(soc_model)/$socModel/g" powercfg
sed -i "s/cluster_0/$cluster_0/g" powercfg
sed -i "s/cluster_1/$cluster_1/g" powercfg
sed -i "s/is_big_little=true/is_big_little=$is_big_little/g" powercfg
sed -i "s/(generate_date)/`date`/g" powercfg

sed -i "s/# balance_params/:/g" powercfg
sed -i "s/# powersave_params/:/g" powercfg
sed -i "s/# performance_params/:/g" powercfg
sed -i "s/# fast_params/:/g" powercfg

pause
