#!/bin/sh

basepath=$(cd $(dirname $0); pwd)/../
source $basepath/scripts/util_functions.sh
init

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
	while read -r allowed_timer_rate
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
		while read -r templateText
		do
			if [[ "$templateText" =~ "${mode}_params" ]]; then
				echo -e "$modeText" >> ./powercfg
			else
				echo "$templateText" >> ./powercfg
			fi
		done < ./powercfg_template
		modeText=""
		rm powercfg_template
		mv powercfg powercfg_template
		echo "$mode saved"
	fi
}

# 备份标准输入
exec 3<&0

get_soc_info
if [ -f "./linkto" ]; then
	rm ./linkto
	rm ./NOTICE
fi
cp $basepath/template/powercfg_template ./
rm ./powercfg
$text_editor ./perf_text

mode="balance"
OLD_IFS="$IFS" 
IFS="="
while read -r lineinText
do 
	[ -z "$lineinText" ] && continue
	# cut string like [mode]
	if [ "${lineinText:0:1}" = "[" ] && [ "${lineinText:0-1:1}" = "]" ]; then
		modeTmp=${lineinText#[}
		modeTmp=${modeTmp%]}
	    savemode
	    mode="$modeTmp"
	    echo "$mode start"
	    continue
	fi
	arrCmd=($lineinText)
	if [ "runonce" = "$mode" ] || [[ "$mode" =~ "modify" ]]; then
	    modeText=${modeText}"\t$lineinText\n"
	else
	    timer_rate="${arrCmd[0]}"
	    if [ "$timer_rate" = "big" ] || [ "$timer_rate" = "little" ]; then
		    timer_rate=$timer_rate_bak
		    cluster="${arrCmd[0]}" 
		    param="${arrCmd[1]}"
	    else
		    timer_rate_bak=$timer_rate
		    if [ "${arrCmd[1]}" != "big" ] && [ "${arrCmd[1]}" != "little" ] && [ "${arrCmd[1]}" != "HMP" ] ; then
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
	    [ "$timer_rate" = "target_loads" ] && [ "$cluster" != "big" ] && sed -i "s/(${mode}_tload)/$param/g" powercfg_template
	    [[ "$param" =~ " " ]] && param="\"$param\""
	    modeText=${modeText}"\tset_param_$cluster $timer_rate $param\n" 
	fi
done < ./perf_text
savemode
IFS="$OLD_IFS"

mv powercfg_template powercfg

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
