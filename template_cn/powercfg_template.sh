#!/system/bin/sh
# powercfg template by yc9559 & cjybyjk
# License: GPL V3

project_name="template"
prj_ver="(prj_ver)"
project_author="yc9559 & cjybyjk"
generate_date=""
soc_name="template"

project_info="$project_name
Version: $prj_ver
Author: $project_author
Platform: $soc_name
Generated at $generate_date"

CUR_LEVEL_FILE="/dev/perf_cur_level"
PARAM_BAK_FILE="/dev/perf_param_bak"

# const variables
PARAM_NUM=0

# global dirs
[GLOBAL_DIRS]

# sysfs_obj
[sysfs_obj]

# levels
[levels]

# global variables
NOT_MATCH_NUM=0

# $1:value $2:file path
lock_value() 
{
    if [ -f ${2} ]; then
        chmod 0666 ${2}

        echo ${1} > ${2}
        chmod 0444 ${2}
    fi
}

# $1:level_number
check_level()
{
    eval tmp="$"level${1}_val${PARAM_NUM}
    if [ -z "$tmp" ]; then
        echo "这个 powercfg 不包含 level $1."
        exit 1
    fi
}

# $1:level_number
apply_level() 
{
    check_level $1
    # 1. backup
    backup_default
    # 2. apply modification
    for n in `seq ${PARAM_NUM}`
    do
        eval obj="$"sysfs_obj${n}
        eval val="$"level${1}_val${n}
        lock_value "${val}" ${obj}
    done
    # 3. save current level to file
    echo ${1} > ${CUR_LEVEL_FILE}
}

# $1:value $2:file path
check_value() 
{
    if [ -f ${2} ]; then
        expected="${1}"
        actual="`cat ${2}`"
        if [ "${actual}" != "${expected}" ]; then
            # input_boost_freq has a additional line break
            case1=$(echo "${actual}" | grep "${expected}")
            # Actual scaling_min_freq is 633600, but given is 633000. That's OK
            case2=$(echo "${2}" | grep -E "scaling_m.{2}_freq$")
            # skip msm_performance/parameters: cpu_min_freq and cpu_max_freq
            case3=$(echo "${2}" | grep -E "cpu_m.{2}_freq$")
            if [ "${case1}" == "" ] && [ "${case2}" == "" ] && [ "${case3}" == "" ]; then
                NOT_MATCH_NUM=$(expr ${NOT_MATCH_NUM} + 1)
                echo "[失败] ${2}"
                echo "期望值: ${expected}"
                echo "当前值: ${actual}"
            fi
        fi
    else
        echo "[忽略] ${2}"
    fi
}

# $1:level_number
verify_level() 
{
    check_level $1
    for n in `seq ${PARAM_NUM}`
    do
        eval obj="$"sysfs_obj${n}
        eval val="$"level${1}_val${n}
        check_value "${val}" ${obj}
    done
    echo "校验了${PARAM_NUM}个参数,其中有${NOT_MATCH_NUM}个校验失败"
}

backup_default()
{
    if [ ${HAS_BAK} -eq 0 ]; then
        # clear previous backup file
        echo "" > ${PARAM_BAK_FILE}
        for n in `seq ${PARAM_NUM}`
        do
            eval obj="$"sysfs_obj${n}
            echo "bak_obj${n}=${obj}" >> ${PARAM_BAK_FILE}
            echo "bak_val${n}=\"`cat ${obj}`\"" >> ${PARAM_BAK_FILE}
        done
        echo "默认参数备份完成"
    else
        echo "备份已存在, 跳过备份过程"
    fi
}

restore_default()
{
    if [ -f ${PARAM_BAK_FILE} ]; then
        # read backup variables
        while read line
        do
            eval ${line}
        done < ${PARAM_BAK_FILE}
        # set backup variables
        for n in `seq ${PARAM_NUM}`
        do
            eval obj="$"bak_obj${n}
            eval val="$"bak_val${n}
            lock_value "${val}" ${obj}
        done
        echo "恢复完成"
    else
        echo "未找到默认参数的备份."
        echo "恢复失败"
    fi
}

# suppress stderr
(

echo ""

# backup runonce flag
if [ -f ${PARAM_BAK_FILE} ]; then
    HAS_BAK=1
fi

action=$1
# default option is "balance"
[ -z "$action" ] && action="balance"

if [ "$action" = "-h" ]; then
    echo "$project_info"
    echo "
用法: powercfg [选项]
选项:
    -h                  显示这条帮助信息
    -s [mode]           在启动时应用指定的 [mode]
    debug               执行参数校验
    restore             还原备份的参数
    level [0-6]         设置性能等级
    powersave           省电模式,等同于 \"level 5\"
    balance             均衡模式,等同于 \"level 3\"
    performance         性能模式,等同于 \"level 1\"
    fast                低延迟模式,等同于 \"level 0\"
"
fi

if [ "$action" = "-s" ]; then
    shift
    $action="$1"
    echo "$*" > /data/perf_mode
fi

if [ "$action" = "debug" ]; then
    echo "$project_info"
    echo ""
    # perform parameter verification
    cur_level=`cat ${CUR_LEVEL_FILE}`
    if [ -n "${cur_level}" ]; then
        echo "当前性能等级: ${cur_level}"
        verify_level ${cur_level}
    else
        echo "当前性能等级: (未选择)"
    fi
    echo ""
    exit 0
fi

if [ "$action" = "restore" ]; then
    restore_default
fi

if [ "$action" = "powersave" ]; then
    echo "正在应用 powersave..."
    apply_level 5
    echo "已应用 powersave."
fi

if [ "$action" = "balance" ]; then
    echo "正在应用 balance..."
    apply_level 3
    echo "已应用 balance."
fi

if [ "$action" = "performance" ]; then
    echo "正在应用 performance..."
    apply_level 1
    echo "已应用 performance."
fi

if [ "$action" = "fast" ]; then
    echo "正在应用 fast..."
    apply_level 0
    echo "已应用fast."
fi

if [ "$action" = "level" ]; then
    level=${2}
    if [ "${level}" -ge "0" ] && [ "${level}" -le "6" ]; then
        echo "正在应用 level ${level}..."
        apply_level ${level}
        echo "已应用 level ${level}."
    else
        echo "不支持 level ${level}."
    fi
fi

echo ""

# suppress stderr
) 2>/dev/null

exit 0
