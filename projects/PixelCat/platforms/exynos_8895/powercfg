#!/system/bin/sh
# powercfg template by cjybyjk & yc9559
# License: GPL V3

project_name="橘猫调度"
prj_ver="(prj_ver)"
project_author="橘猫520 @ coolapk"
soc_model="exynos_8895"
generate_date="Sat Mar  2 02:04:54 CST 2019"

is_big_little="true"

DEBUG_FLAG="false"

C0_GOVERNOR_DIR="/sys/devices/system/cpu/cpu0/cpufreq/interactive"
C1_GOVERNOR_DIR="/sys/devices/system/cpu/cpu4/cpufreq/interactive"
C0_CPUFREQ_DIR="/sys/devices/system/cpu/cpu0/cpufreq"
C1_CPUFREQ_DIR="/sys/devices/system/cpu/cpu4/cpufreq"
C0_CORECTL_DIR="/sys/devices/system/cpu/cpu0/core_ctl"
C1_CORECTL_DIR="/sys/devices/system/cpu/cpu4/core_ctl"

if ! $is_big_little ; then
	C0_GOVERNOR_DIR="/sys/devices/system/cpu/cpufreq/interactive"
fi

# $1:timer_rate $2:value
function set_param_little() 
{
	$DEBUG_FLAG && echo "little: set ${1} into ${2}"
	echo ${2} > ${C0_GOVERNOR_DIR}/${1}
}

function set_param_big() 
{
	$DEBUG_FLAG && echo "big: set ${1} into ${2}"
	echo ${2} > ${C1_GOVERNOR_DIR}/${1}
}

function set_param_all() 
{
	set_param_little ${1} "${2}"
	$is_big_little && set_param_big ${1} "${2}"
}

function set_param_HMP()
{
	$DEBUG_FLAG && echo "HMP: set ${1} into ${2}"
	echo ${2} > /proc/sys/kernel/${1}
}

# $1:timer_rate
function print_param() 
{
	if $is_big_little ; then
		print_value "LITTLE: ${1}" ${C0_GOVERNOR_DIR}/${1}
		print_value "big: ${1}" ${C1_GOVERNOR_DIR}/${1}
	else
		print_value "${1}" ${C0_GOVERNOR_DIR}/${1}
	fi
}

function before_modify()
{
	# disable hotplug to switch governor
	set_value 0 /sys/module/msm_thermal/core_control/enabled
	set_value N /sys/module/msm_thermal/parameters/enabled
	# Exynos hotplug
	lock_value 0 /sys/power/cpuhotplug/enabled
	lock_value 0 /sys/devices/system/cpu/cpuhotplug/enabled
	lock_value "interactive" ${C0_CPUFREQ_DIR}/scaling_governor
	chown 0.0 ${C0_GOVERNOR_DIR}/*
	chmod 0666 ${C0_GOVERNOR_DIR}/*
	if $is_big_little ; then
		lock_value "interactive" ${C1_CPUFREQ_DIR}/scaling_governor
		chown 0.0 ${C1_GOVERNOR_DIR}/*
		chmod 0666 ${C1_GOVERNOR_DIR}/*
	fi
	# before_modify_params
}

function after_modify()
{
	chmod 0444 ${C0_GOVERNOR_DIR}/*
	$is_big_little && chmod 0444 ${C1_GOVERNOR_DIR}/*
	# after_modify_params
	verify_param
}

# $1:value $2:file path
function set_value() 
{
	if [ -f $2 ]; then
		$DEBUG_FLAG && echo "set ${2} into ${1}"
		echo $1 > $2
	fi
}

# $1:value $2:file path
function lock_value()
{
	if [ -f $2 ]; then
		# chown 0.0 $2
		chmod 0666 $2
		echo $1 > $2
		chmod 0444 $2
		$DEBUG_FLAG && echo "lock ${2} into ${1}"
	fi                                                  
}

# $1:display-name $2:file path
function print_value() 
{
	if [ -f $2 ]; then
		echo -n "$1: "
		cat $2
	fi
}

function verify_param() 
{
	expected_target=${C0_GOVERNOR_DIR}/target_loads
	if [ "$action" = "powersave" ]; then
		expected_value="(powersave_tload)"
	elif [ "$action" = "balance" ]; then
		expected_value="58 598000:48 832000:68 949000:81 1248000:92 1690000:100"
	elif [ "$action" = "performance" ]; then
		expected_value="(performance_tload)"
	elif [ "$action" = "fast" ]; then
		expected_value="(fast_tload)"
	fi
	if [ "`cat ${expected_target}`" = "${expected_value}" ]; then
		echo "${action} OK"
	elif [ "${expected_value}" = "(${action}_tload)" ]; then
		echo "${action} not included"
	else
		echo "${action} FAIL"
	fi
}

function get_mode()
{
    expected_target=${C0_GOVERNOR_DIR}/target_loads
	case "`cat ${expected_target}`" in
		"(powersave_tload)" ) echo "powersave OK" ;;
		"58 598000:48 832000:68 949000:81 1248000:92 1690000:100" ) echo "balance OK" ;;
		"(performance_tload)" ) echo "performance OK" ;;
		"(fast_tload)" ) echo "fast OK" ;;
	esac
}

# RunOnce
if [ ! -f /dev/perf_runonce ]; then
	# set flag
	touch /dev/perf_runonce
	
	# HMP_params
	# runonce_params
fi

action=$1
if [ ! -n "$action" ]; then
    action="balance"
fi

# wake up clusters
if $is_big_little; then
	if [ -f "$C0_CORECTL_DIR/min_cpus" ]; then
		C0_CORECTL_MINCPUS=`cat $C0_CORECTL_DIR/min_cpus`
		cat $C0_CORECTL_DIR/max_cpus > $C0_CORECTL_DIR/min_cpus
	fi
	if [ -f "$C1_CORECTL_DIR/min_cpus" ]; then
		C1_CORECTL_MINCPUS=`cat $C1_CORECTL_DIR/min_cpus`
		cat $C1_CORECTL_DIR/max_cpus > $C1_CORECTL_DIR/min_cpus
	fi
	set_value 1 /sys/devices/system/cpu/cpu0/online
	set_value 1 /sys/devices/system/cpu/cpu4/online
fi

if [ "$action" = "debug" ]; then
	echo "$project_name"
	echo "Version: $prj_ver"
	echo "Author: $project_author"
	echo "Platform: $soc_model"
	echo "Generated at $generate_date"
	echo ""
	print_param above_hispeed_delay
	print_param target_loads
	get_mode
else
	before_modify
	if [ "$action" = "powersave" ]; then
		echo "applying powersave"
		:
	elif [ "$action" = "balance" ]; then
		echo "applying balance"
		set_param_all boostpulse_duration 4000
		set_param_all boost 1
		set_param_all timer_rate 20000
		set_param_all timer_slack 10000
		set_param_all min_sample_time 12000
		set_param_all io_is_busy 0
		set_param_all ignore_hispeed_on_notif 0
		set_param_big go_hispeed_load 73
		set_param_little go_hispeed_load 65
		set_param_big hispeed_freq 715000
		set_param_little hispeed_freq 455000
		set_param_big above_hispeed_delay "4000 741000:100000 962000:110000 1170000:120000 1469000:130000 1807000:140000 2002000:1500000 2314000:160000"
		set_param_little above_hispeed_delay "4000 455000:70000 715000:90000 1053000:110000 1456000:130000 1690000:1500000"
		set_param_big target_loads "72 858000:54 962000:61 1170000:68 1261000:75 1469000:82 1807000:89 2158000:96 2314000:100"
		set_param_little target_loads "58 598000:48 832000:68 949000:81 1248000:92 1690000:100"

	elif [ "$action" = "performance" ]; then
		echo "applying performance"
		:
	elif [ "$action" = "fast" ]; then
		echo "applying fast"
		:
	fi
	after_modify
fi

if $is_big_little; then
	set_value $C0_CORECTL_MINCPUS $C0_CORECTL_DIR/min_cpus
	set_value $C1_CORECTL_MINCPUS $C1_CORECTL_DIR/min_cpus
fi

exit 0
