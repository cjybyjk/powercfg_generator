#!/bin/sh
# powercfg_generator
# by cjybyjk @ coolapk
# License: GPL v3

# utility functions

projects_path=$basepath/projects
scripts_path=$basepath/scripts
config_path=$basepath/config
template_path=$basepath/template

function init()
{
    source $config_path/config.sh
    [ -f $config_path/project_pointer ] && prjPtr=$(cat $config_path/project_pointer)
    [ -f $projects_path/$prjPtr/project_config.sh ] && source $projects_path/$prjPtr/project_config.sh
    generatorInfo="powercfg_generator VER:$VER
by cjybyjk @ coolapk
License: GPL v3

当前项目: $project_id
  项目名称：$project_name
  项目作者：$project_author
"
}

# convert strings to lower case
function lcase()
{
    echo "$*" | tr '[A-Z]' '[a-z]'
}

# $1:menuText $2:keyList
function showMenu()
{
    [ -z "$1" ] && return 1
    [ -z "$2" ] && return 1
    local menuItems="$1"
    local keyList=($2)
    local selected
    selectedKey=""
    while true
    do
        clear
        echo -e "${generatorInfo}${menuItems}\n"
        read -p "请输入选项: " selected
        selected=$(lcase $selected) 
        for i in ${!keyList[@]}
        do
            if [ "${keyList[$i]}" = "$selected" ]; then
                selectedKey=$selected
                return 0
            fi
        done
    done
    return 0
}

# $1:name $2:value [$3:conf_file]
function write_value()
{
    [ -z "$(trim $1)" ] && return 1
    [ -z "$(trim $2)" ] && return 1
    local configFile=$3
    [ -z "$configFile" ] && configFile=$config_path/config.sh

    local tmp=$(grep "^$1=" $configFile)
    if [ -z "$tmp" ]; then
        echo "$1=\"$2\"" >> $configFile
    else
        sed -i "s#^$tmp#$1=\"$2\"#g" $configFile
    fi
    return $?
}

# true -> false and false -> true
function toggle_boolean()
{
    if [ "true" = "$1" ]; then
        echo "false"
    else
        echo "true"
    fi
}

function pause()
{
    read -n 1 -p "按任意键继续......"
    echo ""
}

function trim()
{
    echo $1 | sed -e 's/^[ \t]*//g' -e 's/[ \t]*$//g'
}

# $1:text $2:default value
function readDefault()
{
    local tmpvalue
    read -p "请输入$1 (留空则使用 $2): " tmpvalue
    [ -z "$(trim $tmpvalue)" ] && tmpvalue=$2
    echo $tmpvalue
}

# $1:text $2:default(y/n)
function yesNo()
{
    local tmpyn
    if [ "y" = "$(lcase $2)" ]; then
        read -p "$1 (Y/n) : " tmpyn
        [ "n" != "$(lcase $tmpyn)" ] && return 0
    else
        read -p "$1 (y/N) : " tmpyn
        [ "y" = "$(lcase $tmpyn)" ] && return 0
    fi
    return 1
}

function get_soc_info()
{
	[ "" = "$socModel" ] && read -p "输入SoC型号: " socModel
	platformPath="$projects_path/$project_id/platforms/$socModel"
	mkdir -p $platformPath
	cd $platformPath
	while read -r soctext
	do
		tmparr=(${soctext//:/ })
		if [ "${tmparr[1]}" = "$socModel" ]; then
			is_big_little="${tmparr[2]}"
			cluster_0="${tmparr[3]}"
			cluster_1="${tmparr[4]}"
			return 0
		fi
	done < $config_path/list_of_socs
	is_big_little=false
	yesNo "是否使用big.LITTLE架构" "y" && is_big_little=true
	cluster_0=$(readDefault "cluster0" "cpu0")
	$is_big_little && cluster_1=$(readDefault "cluster1" "cpu4")
	yesNo "添加这个SoC到支持列表中"  "y"
	if [ $? -eq 0 ]; then
		read -p "输入SoC代号(支持正则表达式):" socCodename
		echo "$socCodename:$socModel:$is_big_little:$cluster_0:$cluster_1" >> $config_path/list_of_socs
	fi
}

function check_proj()
{
	if [ "(unknown)" = "$project_id" ]; then
		echo "错误：未指定项目"
		pause
		return 1
	fi
	return 0
}

