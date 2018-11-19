#!/bin/sh

# 可以自行添加 timer_rate
allowed_timer_rate=(
above_hispeed_delay
align_windows
boost
boostpulse
boostpulse_duration 
enable_prediction 
fast_ramp_down
go_hispeed_load
hispeed_freq
ignore_hispeed_on_notif
io_is_busy
max_freq_hysteresis
min_sample_time
sampling_down_factor
sync_freq
target_loads
timer_rate
timer_slack
up_threshold_any_cpu_freq
up_threshold_any_cpu_load
use_migration_notif
use_sched_load
)

function trim()
{
	echo $1 | sed -e 's/^[ \t]*//g' -e 's/[ \t]*$//g'
}

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
	done < $basepath/project/common/list_of_socs
	read -p "是否使用big.LITTLE架构(y/n)" is_big_little
	[ -z "$is_big_little" ] && is_big_little="y"
	read -p "请输入cluster0(默认为 cpu0):" cluster_0
	[ -z "$cluster_0" ] && cluster_0="cpu0"
	if [ "$is_big_little" = "y" ]; then
		read -p "请输入cluster1(默认为 cpu4):" cluster_1
		[ -z "$cluster_1" ] && cluster_1="cpu4"
	fi
	read -p "添加这个SoC到列表中?(y/n):" add2list
	if [ "y" = "$add2list" ]; then
		read -p "输入SoC代号(支持正则表达式):" socCodename
		echo "$socCodename:$socModel:$is_big_little:$cluster_0:$cluster_1" >> $basepath/project/common/list_of_socs
	fi
}

function savemode()
{
	if [ "" != "$modeText" ]; then
		sed -i "s/# ${mode}_params/$modeText/g" powercfg
		modeText=""
		echo "$mode saved"
	fi
}

function getLikelyRank()
{
	tmpRank=0
	tmpL2R=0
	tmpR2L=0
	iMax=${#1}
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
	likelyRank=0
	for i in ${!allowed_timer_rate[@]}
	do
		[ "$timer_rate" = "${allowed_timer_rate[$i]}" ] && return 0
		lkRankTmp=$(getLikelyRank "$timer_rate" "${allowed_timer_rate[$i]}")
		if [ $lkRankTmp -gt $likelyRank ]; then
			likelyRank=$lkRankTmp
			mostLikely=${allowed_timer_rate[$i]}
		fi
	done
	echo "目标 \"$timer_rate\" 可能存在错误, 与它最相似的是 \"$mostLikely\""
	read -p "请在此进行修改(默认为 $mostLikely):" rightTimerRate <&3
	[ -z "$rightTimerRate" ] && rightTimerRate="$mostLikely"
	timer_rate="$rightTimerRate"
}

# 备份标准输入
exec 3<&0

basepath="$1"

read -p "输入SoC型号:" socModel
platformPath="$basepath/project/platforms/$socModel"
get_clusters

mkdir -p $platformPath
cd $platformPath

if [ -f "./linkto" ]; then
	rm ./linkto
	rm ./NOTICE
fi	

cp $basepath/powercfg_template ./powercfg

vim ./perf_text

# 对复制的调度进行处理
echo -n "规范化调度参数(y/n):"
read flag_TextReplace
if [ "$flag_TextReplace" = "y" ]; then
	sed -i 's/:/：/g' ./perf_text
	sed -i 's/： /：/g' ./perf_text
	sed -i 's/：：/：/g' ./perf_text
	sed -i 's/\([0-9]\)：\([0-9]\)/\1:\2/g' ./perf_text
	sed -i 's/big：/\nbig：/g' ./perf_text
	sed -i 's/little：/\nlittle：/g' ./perf_text
	sed -i '/^\s*$/d' ./perf_text
	echo -e "\n" >> ./perf_text
fi

# default
mode="balance"

OLD_IFS="$IFS" 
IFS="："

while read lineinText
do 
	[ -z "$lineinText" ] && continue
	if [[ "$lineinText" =~ "省电" ]]; then
		savemode
		mode="powersave"
		continue
	elif [[ "$lineinText" =~ "性能" ]]; then
		savemode
		mode="performance"
		continue
	elif [[ "$lineinText" =~ "均衡" ]]; then
		savemode
		mode="balance"
		continue
	elif [[ "$lineinText" =~ "低延迟" ]]; then
		savemode
		mode="fast"
		continue
	fi

	arrCmd=($lineinText)
	timer_rate="${arrCmd[0]}"
	if [ "$timer_rate" = "big" ] || [ "$timer_rate" = "little" ]; then
		timer_rate=$timer_rate_bak
		cluster="${arrCmd[0]}" 
		param="${arrCmd[1]}"
	else
		timer_rate_bak=$timer_rate
		if [ "${arrCmd[1]}" != "big" ] && [ "${arrCmd[1]}" != "little" ] ; then
			cluster="all" 
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
	check_timer_rate
	[ "$timer_rate" = "target_loads" ] && [ "$cluster" = "little" -o "n" = "$is_big_little" ] && sed -i "s/${mode}_tload/$param/g" powercfg
	[[ "$param" =~ " " ]] && param="\"$param\""
	modeText=${modeText}"set_param_$cluster $timer_rate $param\n	" 
done < ./perf_text

savemode

IFS="$OLD_IFS"

# 写入相关信息
sed -i "s/(soc_model)/$socModel/g" powercfg
sed -i "s/cluster_0/$cluster_0/g" powercfg
sed -i "s/cluster_1/$cluster_1/g" powercfg
sed -i "s/is_big_little/$is_big_little/g" powercfg
sed -i "s/(generate_date)/`date`/g" powercfg

sed -i "s/# balance_params/:/g" powercfg
sed -i "s/# powersave_params/:/g" powercfg
sed -i "s/# performance_params/:/g" powercfg
sed -i "s/# fast_params/:/g" powercfg

exit 0
