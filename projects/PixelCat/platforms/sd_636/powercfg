#!/system/bin/sh
# powercfg template by cjybyjk & yc9559
# License: GPL V3

project_name="橘猫调度"
prj_ver="(prj_ver)"
project_author="橘猫520 @ coolapk"
soc_model="sd_636"
generate_date="Sat Mar  2 02:05:10 CST 2019"

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
		expected_value="70 633000:49 902000:59 1113000:66 1401000:77 1536000:83 1612000:95"
	elif [ "$action" = "balance" ]; then
		expected_value="633000:19 902000:31 1113000:43 1401000:49 1536000"
	elif [ "$action" = "performance" ]; then
		expected_value="40 633000:23 902000:34 1113000:41 1401000:48 1536000:52 1612000:64"
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
		"70 633000:49 902000:59 1113000:66 1401000:77 1536000:83 1612000:95" ) echo "powersave OK" ;;
		"633000:19 902000:31 1113000:43 1401000:49 1536000" ) echo "balance OK" ;;
		"40 633000:23 902000:34 1113000:41 1401000:48 1536000:52 1612000:64" ) echo "performance OK" ;;
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
		set_param_all boostpulse_duration 25000
		set_param_all boost 1
		set_param_all timer_rate 18000
		set_param_all timer_slack 160000
		set_param_all min_sample_time 9000
		set_param_all align_windows 0
		set_param_all max_freq_hysteresis 18000
		set_param_all use_sched_load 1
		set_param_all use_migration_notif 1
		set_param_all go_hispeed_load 70
		set_param_all hispeed_freq "1113000 633000"
		set_param_big above_hispeed_delay "25000 1113000:43000 1401000:49000 1747000:56000 1804000:69000"
		set_param_little above_hispeed_delay "125000 633000:49000 902000:57000 1113000:63000 1401000:69000 1536000:77000 1612000:85000"
		set_param_big target_loads "70 1113000:49 1401000:53 1747000:59 11804000:67"
		set_param_little target_loads "70 633000:49 902000:59 1113000:66 1401000:77 1536000:83 1612000:95"

	elif [ "$action" = "balance" ]; then
		echo "applying balance"
		set_param_all boostpulse_duration 15000
		set_param_all boost 1
		set_param_all timer_rate 20000
		set_param_all timer_slack 140000
		set_param_all min_sample_time 3000
		set_param_all align_windows 0
		set_param_all max_freq_hysteresis 38000
		set_param_all enable_prediction 0
		set_param_all io_is_busy 0
		set_param_all ignore_hispeed_on_notif 0
		set_param_all use_sched_load 0
		set_param_all use_migration_notif 0
		set_param_big go_hispeed_load 27
		set_param_little go_hispeed_load 19
		set_param_big hispeed_freq 1113000
		set_param_little hispeed_freq 633000
		set_param_big above_hispeed_delay "15000 1747000:15000"
		set_param_little above_hispeed_delay "15000 1113000:13000"
		set_param_big target_loads "85 11130:15 1401000:27 1747000:39 1804000:49"
		set_param_little target_loads "633000:19 902000:31 1113000:43 1401000:49 1536000"

	elif [ "$action" = "performance" ]; then
		echo "applying performance"
		set_param_all boostpulse_duration 7000
		set_param_all boost 1
		set_param_all timer_rate 10000
		set_param_all timer_slack 40000
		set_param_all min_sample_time 1000
		set_param_all align_windows 0
		set_param_all max_freq_hysteresis 1000
		set_param_all use_sched_load 1
		set_param_all use_migration_notif 1
		set_param_all go_hispeed_load 40
		set_param_all hispeed_freq "1401000 902000"
		set_param_big above_hispeed_delay "7000 1113000:27000 1401000:34000 1747000:42000 1804000:58000"
		set_param_little above_hispeed_delay "7000 633000:21000 902000:33000 1113000:41000 1401000:49000 1536000:52000 1612000:67000"
		set_param_big target_loads "40 1113000:27 1401000:39 1747000:43 1804000:59"
		set_param_little target_loads "40 633000:23 902000:34 1113000:41 1401000:48 1536000:52 1612000:64"

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
